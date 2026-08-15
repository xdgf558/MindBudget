import Foundation
import OSLog

enum PublicConfigurationDeploymentEnvironment: String, CaseIterable, Equatable, Hashable, Sendable {
    case development
    case staging
    case production

    var endpoint: URL {
        let value = switch self {
        case .development:
            "https://mindbudget-public-config-dev.yehao1105.workers.dev/v1/config"
        case .staging:
            "https://mindbudget-public-config-staging.yehao1105.workers.dev/v1/config"
        case .production:
            "https://mindbudget-public-config.yehao1105.workers.dev/v1/config"
        }
        guard let endpoint = URL(string: value) else {
            preconditionFailure("The reviewed public-configuration endpoint is malformed")
        }
        return endpoint
    }

    /// A Release build has no code path to Development or Staging. Staging is intentionally an
    /// explicit Debug launch choice rather than remotely selectable data or a caller-provided URL.
    static func current(arguments: [String] = ProcessInfo.processInfo.arguments) -> Self {
        #if DEBUG
        arguments.contains("-public-configuration-staging") ? .staging : .development
        #else
        .production
        #endif
    }
}

struct PublicConfigurationRequestMetadata: Equatable, Sendable {
    static let maximumAppVersionBytes = 32

    let appVersion: String
    let lastAcceptedConfigVersion: UInt64?

    var isValid: Bool {
        guard !appVersion.isEmpty,
              appVersion.utf8.count <= Self.maximumAppVersionBytes,
              appVersion.range(
                  of: #"^[0-9A-Za-z][0-9A-Za-z._-]*$"#,
                  options: .regularExpression
              ) != nil else {
            return false
        }
        return lastAcceptedConfigVersion.map { $0 > 0 } ?? true
    }
}

enum PublicConfigurationTransportFailureReason: String, Equatable, Sendable {
    case invalidRequestMetadata
    case cancelled
    case timedOut
    case offline
    case connectionFailed
    case redirectRejected
    case responseURLMismatch
    case invalidHTTPStatus
    case invalidContentType
    case responseTooLarge
    case emptyResponse
}

enum PublicConfigurationFetchResult: Equatable, Sendable {
    case envelope(Data)
    case failed(PublicConfigurationTransportFailureReason)
}

protocol PublicConfigurationFetching: Sendable {
    func fetch(metadata: PublicConfigurationRequestMetadata) async -> PublicConfigurationFetchResult
}

struct PublicConfigurationHTTPResponse: Sendable {
    let data: Data
    let response: HTTPURLResponse
}

protocol PublicConfigurationHTTPLoading: Sendable {
    func load(
        request: URLRequest,
        maximumResponseBytes: Int
    ) async throws -> PublicConfigurationHTTPResponse
}

private enum PublicConfigurationHTTPLoadingError: Error {
    case responseTooLarge
    case nonHTTPResponse
}

/// A dedicated ephemeral session rejects redirects and stops buffering as soon as the reviewed
/// envelope bound is crossed. It has no cookies, credential storage, shared cache, or arbitrary
/// request entry point.
actor BoundedPublicConfigurationHTTPLoader: PublicConfigurationHTTPLoading {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 12
        configuration.waitsForConnectivity = false
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 1
        session = URLSession(
            configuration: configuration,
            delegate: PublicConfigurationRedirectRejector(),
            delegateQueue: nil
        )
    }

    func load(
        request: URLRequest,
        maximumResponseBytes: Int
    ) async throws -> PublicConfigurationHTTPResponse {
        let (bytes, response) = try await session.bytes(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw PublicConfigurationHTTPLoadingError.nonHTTPResponse
        }
        if response.expectedContentLength > Int64(maximumResponseBytes) {
            throw PublicConfigurationHTTPLoadingError.responseTooLarge
        }

        var data = Data()
        if response.expectedContentLength > 0 {
            data.reserveCapacity(min(Int(response.expectedContentLength), maximumResponseBytes))
        }
        for try await byte in bytes {
            guard data.count < maximumResponseBytes else {
                throw PublicConfigurationHTTPLoadingError.responseTooLarge
            }
            data.append(byte)
        }
        return PublicConfigurationHTTPResponse(data: data, response: response)
    }
}

private final class PublicConfigurationRedirectRejector: NSObject, URLSessionTaskDelegate,
    @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        nil
    }
}

struct FixedPublicConfigurationTransport: PublicConfigurationFetching {
    static let appVersionHeader = "X-MindBudget-App-Version"
    static let configVersionHeader = "X-MindBudget-Config-Version"

    private let environment: PublicConfigurationDeploymentEnvironment
    private let loader: any PublicConfigurationHTTPLoading

    init(
        environment: PublicConfigurationDeploymentEnvironment,
        loader: any PublicConfigurationHTTPLoading = BoundedPublicConfigurationHTTPLoader()
    ) {
        self.environment = environment
        self.loader = loader
    }

    func fetch(metadata: PublicConfigurationRequestMetadata) async -> PublicConfigurationFetchResult {
        guard metadata.isValid else { return .failed(.invalidRequestMetadata) }

        let endpoint = environment.endpoint
        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 8
        )
        request.httpMethod = "GET"
        request.httpBody = nil
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(metadata.appVersion, forHTTPHeaderField: Self.appVersionHeader)
        if let version = metadata.lastAcceptedConfigVersion {
            request.setValue(String(version), forHTTPHeaderField: Self.configVersionHeader)
        }

        do {
            let loaded = try await loader.load(
                request: request,
                maximumResponseBytes: PublicConfigurationVerificationPolicy.maximumEnvelopeBytes
            )
            guard loaded.response.url == endpoint else { return .failed(.responseURLMismatch) }
            if (300..<400).contains(loaded.response.statusCode) {
                return .failed(.redirectRejected)
            }
            guard loaded.response.statusCode == 200 else { return .failed(.invalidHTTPStatus) }
            guard loaded.response.mimeType?.lowercased() == "application/json" else {
                return .failed(.invalidContentType)
            }
            guard !loaded.data.isEmpty else { return .failed(.emptyResponse) }
            guard loaded.data.count <= PublicConfigurationVerificationPolicy.maximumEnvelopeBytes else {
                return .failed(.responseTooLarge)
            }
            return .envelope(loaded.data)
        } catch PublicConfigurationHTTPLoadingError.responseTooLarge {
            return .failed(.responseTooLarge)
        } catch is CancellationError {
            return .failed(.cancelled)
        } catch let error as URLError {
            switch error.code {
            case .cancelled: return .failed(.cancelled)
            case .timedOut: return .failed(.timedOut)
            case .notConnectedToInternet, .networkConnectionLost:
                return .failed(.offline)
            default: return .failed(.connectionFailed)
            }
        } catch {
            return .failed(.connectionFailed)
        }
    }
}

protocol PublicConfigurationReasonObserving: Sendable {
    func record(transport reason: PublicConfigurationTransportFailureReason)
    func record(resolution reason: PublicConfigurationResolutionReason)
}

struct PublicConfigurationReasonLogger: PublicConfigurationReasonObserving {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MindBudget",
        category: "PublicConfiguration"
    )

    func record(transport reason: PublicConfigurationTransportFailureReason) {
        logger.notice("reason=transport.\(reason.rawValue, privacy: .public)")
    }

    func record(resolution reason: PublicConfigurationResolutionReason) {
        logger.notice("reason=resolution.\(reason.rawValue, privacy: .public)")
    }
}

protocol PublicConfigurationServicing: Sendable {
    func resolveCached(now: Date) async -> PublicConfigurationResolution
    func refresh(now: Date) async -> PublicConfigurationResolution
}

/// Orchestrates only cache/transport/verification. It publishes no entitlement and exposes no
/// envelope bytes. Refreshes are serialized so a slower older response cannot replace a newer
/// accepted presentation in the caller after actor reentrancy.
actor PublicConfigurationService: PublicConfigurationServicing {
    private let controller: PublicConfigurationController
    private let transport: any PublicConfigurationFetching
    private let observer: any PublicConfigurationReasonObserving
    private let appVersion: String
    private var refreshTail: Task<PublicConfigurationResolution, Never>?

    init(
        controller: PublicConfigurationController,
        transport: any PublicConfigurationFetching,
        observer: any PublicConfigurationReasonObserving,
        appVersion: String
    ) {
        self.controller = controller
        self.transport = transport
        self.observer = observer
        self.appVersion = appVersion
    }

    func resolveCached(now: Date) async -> PublicConfigurationResolution {
        let result = await controller.resolveCachedResult(now: now)
        observer.record(resolution: result.reason)
        return result.resolution
    }

    func refresh(now: Date) async -> PublicConfigurationResolution {
        let predecessor = refreshTail
        let controller = controller
        let transport = transport
        let observer = observer
        let appVersion = appVersion
        let operation = Task {
            _ = await predecessor?.value
            let metadata = PublicConfigurationRequestMetadata(
                appVersion: appVersion,
                lastAcceptedConfigVersion: await controller.highestAcceptedVersion()
            )
            switch await transport.fetch(metadata: metadata) {
            case let .failed(reason):
                observer.record(transport: reason)
                let fallback = await controller.resolveCachedResult(now: now)
                observer.record(resolution: fallback.reason)
                return fallback.resolution
            case let .envelope(data):
                let result = await controller.acceptRemoteResult(envelopeData: data, now: now)
                observer.record(resolution: result.reason)
                return result.resolution
            }
        }
        refreshTail = operation
        return await operation.value
    }
}

enum PublicConfigurationProductionTrust {
    static let keyID = "mb-config-2026-01"
    static let publicKeyBase64 = "1nSPWfbGJuNSLBocaZVhUZj+KFsLxe7U3vl0i9VFFtg="

    static var verificationPolicy: PublicConfigurationVerificationPolicy {
        guard let publicKey = Data(base64Encoded: publicKeyBase64) else {
            preconditionFailure("The reviewed public-configuration public key is malformed")
        }
        return PublicConfigurationVerificationPolicy(publicKeysByID: [keyID: publicKey])
    }
}

enum PublicConfigurationServiceFactory {
    static func live(
        environment: PublicConfigurationDeploymentEnvironment = .current()
    ) -> any PublicConfigurationServicing {
        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let persistence = FilePublicConfigurationPersistence(
            fileURL: supportDirectory
                .appendingPathComponent("MindBudget", isDirectory: true)
                .appendingPathComponent("PublicConfiguration", isDirectory: true)
                .appendingPathComponent("signed-state.json", isDirectory: false)
        )
        let controller = PublicConfigurationController(
            verifier: PublicConfigurationVerifier(
                policy: PublicConfigurationProductionTrust.verificationPolicy
            ),
            persistence: persistence
        )
        return PublicConfigurationService(
            controller: controller,
            transport: FixedPublicConfigurationTransport(environment: environment),
            observer: PublicConfigurationReasonLogger(),
            appVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? ""
        )
    }
}
