import Foundation

extension TelemetryEnvironment {
    var uploadEndpoint: URL { endpoint(path: "events") }
    var deletionEndpoint: URL { endpoint(path: "delete") }

    /// Release has no Development/Staging selection. Staging is an explicit Debug-only launch
    /// argument, and no caller can inject a URL or environment from remote data.
    static func current(arguments: [String] = ProcessInfo.processInfo.arguments) -> Self {
        #if DEBUG
        arguments.contains("-telemetry-staging") ? .staging : .development
        #else
        .production
        #endif
    }

    private func endpoint(path: String) -> URL {
        let host = switch self {
        case .development: "mindbudget-telemetry-dev.yehao1105.workers.dev"
        case .staging: "mindbudget-telemetry-staging.yehao1105.workers.dev"
        case .production: "mindbudget-telemetry.yehao1105.workers.dev"
        }
        guard let endpoint = URL(string: "https://\(host)/v1/\(path)") else {
            preconditionFailure("The reviewed telemetry endpoint is malformed")
        }
        return endpoint
    }
}

enum TelemetryHTTPTransportError: Error, Equatable, Sendable {
    case invalidEnvelope
    case responseTooLarge
    case nonHTTPResponse
    case responseURLMismatch
    case redirectRejected
    case unexpectedResponseBody
    case rejectedStatus(Int)
    case serverUnavailable
}

extension TelemetryHTTPTransportError: TelemetryTerminalFailureProviding {
    var telemetryTerminalFailure: TelemetryTerminalFailure? {
        guard case let .rejectedStatus(statusCode) = self else { return nil }
        return switch statusCode {
        case 404: .endpointNotFound
        case 405: .methodNotAllowed
        case 421: .misdirectedRequest
        default: nil
        }
    }
}

struct TelemetryHTTPResponse: Sendable {
    let data: Data
    let response: HTTPURLResponse
}

protocol TelemetryHTTPLoading: Sendable {
    func load(request: URLRequest, maximumResponseBytes: Int) async throws -> TelemetryHTTPResponse
}

private final class TelemetryRedirectRejector: NSObject, URLSessionTaskDelegate,
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

/// An ephemeral, redirect-free loader stops buffering after the empty-response allowance. It owns
/// no cookie store, credential store, cache, caller URL, or cross-request identifier.
actor BoundedTelemetryHTTPLoader: TelemetryHTTPLoading {
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
            delegate: TelemetryRedirectRejector(),
            delegateQueue: nil
        )
    }

    func load(
        request: URLRequest,
        maximumResponseBytes: Int
    ) async throws -> TelemetryHTTPResponse {
        let (bytes, response) = try await session.bytes(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw TelemetryHTTPTransportError.nonHTTPResponse
        }
        if response.expectedContentLength > Int64(maximumResponseBytes) {
            throw TelemetryHTTPTransportError.responseTooLarge
        }
        var data = Data()
        if response.expectedContentLength > 0 {
            data.reserveCapacity(min(Int(response.expectedContentLength), maximumResponseBytes))
        }
        for try await byte in bytes {
            guard data.count < maximumResponseBytes else {
                throw TelemetryHTTPTransportError.responseTooLarge
            }
            data.append(byte)
        }
        return TelemetryHTTPResponse(data: data, response: response)
    }
}

private struct TelemetryWireQueuedEvent: Encodable {
    let event: TelemetryEvent
    let id: UUID
    let identityIdentifier: UUID
    let occurredAt: Int64

    init(_ event: TelemetryQueuedEvent) throws {
        self.event = event.event
        id = event.id
        identityIdentifier = event.identityIdentifier
        occurredAt = try TelemetryWireDate.millisecondsSinceUnixEpoch(event.occurredAt)
    }
}

private enum TelemetryWireDate {
    private static let unixEpoch = Date(timeIntervalSince1970: 0)
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// The wire timestamp uses checked integer calendar components so this non-money boundary does
    /// not introduce a floating-point type into the app's closed deterministic source policy.
    static func millisecondsSinceUnixEpoch(_ date: Date) throws -> Int64 {
        let components = calendar.dateComponents(
            [.second, .nanosecond],
            from: unixEpoch,
            to: date
        )
        guard let seconds = components.second,
              seconds >= 0 else {
            throw TelemetryHTTPTransportError.invalidEnvelope
        }
        let (secondMilliseconds, multiplyOverflow) = Int64(seconds)
            .multipliedReportingOverflow(by: 1_000)
        let nanoseconds = components.nanosecond ?? 0
        guard !multiplyOverflow,
              nanoseconds >= 0 else {
            throw TelemetryHTTPTransportError.invalidEnvelope
        }
        let (milliseconds, addOverflow) = secondMilliseconds
            .addingReportingOverflow(Int64(nanoseconds / 1_000_000))
        guard !addOverflow else {
            throw TelemetryHTTPTransportError.invalidEnvelope
        }
        return milliseconds
    }
}

private struct TelemetryWireUpload: Encodable {
    let schemaVersion: Int
    let environment: TelemetryEnvironment
    let appVersion: TelemetryAppVersion
    let pseudonymousIdentifier: UUID
    let deletionHandle: String
    let events: [TelemetryWireQueuedEvent]

    init(_ batch: TelemetryUploadBatch) throws {
        schemaVersion = batch.schemaVersion
        environment = batch.environment
        appVersion = batch.appVersion
        pseudonymousIdentifier = batch.pseudonymousIdentifier
        deletionHandle = batch.deletionHandle
        events = try batch.events.map { try TelemetryWireQueuedEvent($0) }
    }
}

private struct TelemetryWireDeletionProof: Encodable {
    let pseudonymousIdentifier: UUID
    let deletionSecret: Data
}

private struct TelemetryWireDeletion: Encodable {
    let schemaVersion: Int
    let environment: TelemetryEnvironment
    let proofs: [TelemetryWireDeletionProof]

    init(_ request: TelemetryDeletionRequest) {
        schemaVersion = request.schemaVersion
        environment = request.environment
        proofs = request.proofs.map {
            TelemetryWireDeletionProof(
                pseudonymousIdentifier: $0.pseudonymousIdentifier,
                deletionSecret: $0.deletionSecret
            )
        }
    }
}

/// The C5-04 factory is the sole production construction site. It selects one compile-time
/// environment, accepts no caller URL, and remains inert until the customer explicitly opts in.
actor FixedTelemetryTransport: TelemetryTransporting {
    static let maximumUploadBytes = 32 * 1_024
    static let maximumDeleteBytes = 2 * 1_024
    static let maximumResponseBytes = 1_024

    private let environment: TelemetryEnvironment
    private let loader: any TelemetryHTTPLoading
    private var uploadOperation: (id: UUID, task: Task<TelemetryHTTPResponse, Error>)?

    init(
        environment: TelemetryEnvironment,
        loader: any TelemetryHTTPLoading = BoundedTelemetryHTTPLoader()
    ) {
        self.environment = environment
        self.loader = loader
    }

    func upload(_ batch: TelemetryUploadBatch) async throws -> TelemetryTransportUploadResolution {
        guard batch.schemaVersion == TelemetryPolicy.schemaVersion,
              batch.environment == environment,
              batch.events.count > 0,
              batch.events.count <= TelemetryPolicy.maximumBatchEvents,
              batch.events.allSatisfy({
                  $0.identityIdentifier == batch.pseudonymousIdentifier
              }) else {
            throw TelemetryHTTPTransportError.invalidEnvelope
        }
        let body = try Self.encoder.encode(TelemetryWireUpload(batch))
        guard body.count <= Self.maximumUploadBytes else {
            throw TelemetryHTTPTransportError.invalidEnvelope
        }
        let endpoint = environment.uploadEndpoint
        let loaded = try await performUpload(request: Self.request(endpoint: endpoint, body: body))
        try Self.validate(loaded, endpoint: endpoint)
        switch loaded.response.statusCode {
        case 202:
            return .accepted
        case 400, 409, 413, 422:
            return .rejected
        case 429:
            guard let value = loaded.response.value(forHTTPHeaderField: "Retry-After"),
                  let seconds = Int(value),
                  (60...TelemetryPolicy.maximumRetryDelaySeconds).contains(seconds) else {
                throw TelemetryHTTPTransportError.rejectedStatus(429)
            }
            return .retryAfter(seconds: seconds)
        case 500...599:
            throw TelemetryHTTPTransportError.serverUnavailable
        default:
            throw TelemetryHTTPTransportError.rejectedStatus(loaded.response.statusCode)
        }
    }

    func delete(_ request: TelemetryDeletionRequest) async throws {
        guard request.schemaVersion == TelemetryPolicy.schemaVersion,
              request.environment == environment,
              !request.proofs.isEmpty,
              request.proofs.count <= TelemetryPolicy.maximumIdentityGenerations,
              request.proofs.allSatisfy({ $0.deletionSecret.count == 32 }),
              Set(request.proofs.map(\.pseudonymousIdentifier)).count == request.proofs.count else {
            throw TelemetryHTTPTransportError.invalidEnvelope
        }
        let body = try Self.encoder.encode(TelemetryWireDeletion(request))
        guard body.count <= Self.maximumDeleteBytes else {
            throw TelemetryHTTPTransportError.invalidEnvelope
        }
        let endpoint = environment.deletionEndpoint
        let loaded = try await loader.load(
            request: Self.request(endpoint: endpoint, body: body),
            maximumResponseBytes: Self.maximumResponseBytes
        )
        try Self.validate(loaded, endpoint: endpoint)
        guard loaded.response.statusCode == 204 else {
            if (500...599).contains(loaded.response.statusCode) {
                throw TelemetryHTTPTransportError.serverUnavailable
            }
            throw TelemetryHTTPTransportError.rejectedStatus(loaded.response.statusCode)
        }
    }

    func cancelInFlightUpload() async {
        uploadOperation?.task.cancel()
    }

    private func performUpload(request: URLRequest) async throws -> TelemetryHTTPResponse {
        let loader = loader
        let id = UUID()
        let task = Task {
            try await loader.load(
                request: request,
                maximumResponseBytes: Self.maximumResponseBytes
            )
        }
        uploadOperation = (id, task)
        defer {
            if uploadOperation?.id == id {
                uploadOperation = nil
            }
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private static func request(endpoint: URL, body: Data) -> URLRequest {
        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 8
        )
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Keep transport metadata invariant across app, OS, and locale versions. The receiver
        // rejects any ambient URLSession identity or language value outside this closed contract.
        request.setValue("MindBudget", forHTTPHeaderField: "User-Agent")
        request.setValue("", forHTTPHeaderField: "Accept-Language")
        return request
    }

    private static func validate(_ loaded: TelemetryHTTPResponse, endpoint: URL) throws {
        guard loaded.response.url == endpoint else {
            throw TelemetryHTTPTransportError.responseURLMismatch
        }
        if (300..<400).contains(loaded.response.statusCode) {
            throw TelemetryHTTPTransportError.redirectRejected
        }
        guard loaded.data.isEmpty else {
            throw TelemetryHTTPTransportError.unexpectedResponseBody
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()
}
