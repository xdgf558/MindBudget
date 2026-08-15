import CryptoKit
import Foundation

/// The complete C3-03 presentation vocabulary. Remote configuration is intentionally incapable
/// of naming a StoreKit product, price, trial, entitlement, notification, Lifetime product, or
/// cloud feature. Settings, Restore Purchases, and Manage Subscription remain locally available.
struct PublicConfigurationPresentation: Codable, Equatable, Sendable {
    let proValueTriggersEnabled: Bool

    static let conservativeDefault = PublicConfigurationPresentation(
        proValueTriggersEnabled: false
    )
}

struct PublicConfigurationPayload: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let configVersion: UInt64
    let issuedAt: Date
    let expiresAt: Date
    let presentation: PublicConfigurationPresentation
}

struct SignedPublicConfigurationEnvelope: Codable, Equatable, Sendable {
    let algorithm: String
    let keyID: String
    let payloadBase64: String
    let signatureBase64: String
}

struct VerifiedPublicConfiguration: Equatable, Sendable {
    let payload: PublicConfigurationPayload
    let envelopeData: Data
    let payloadDigest: Data
}

enum PublicConfigurationVerificationError: Error, Equatable, Sendable {
    case envelopeTooLarge
    case payloadTooLarge
    case invalidEnvelopeSchema
    case unsupportedAlgorithm
    case unknownKey
    case invalidEncoding
    case invalidSignature
    case invalidPayloadSchema
    case unsupportedSchemaVersion
    case invalidVersion
    case issuedInFuture
    case expired
    case invalidValidityWindow
}

struct PublicConfigurationVerificationPolicy: Sendable {
    static let algorithm = "Ed25519"
    static let schemaVersion = 1
    static let maximumEnvelopeBytes = 16 * 1_024
    static let maximumPayloadBytes = 8 * 1_024
    static let maximumValidityInterval: TimeInterval = 7 * 24 * 60 * 60
    static let allowedFutureClockSkew: TimeInterval = 5 * 60

    let publicKeysByID: [String: Data]
}

/// The signer and verifier share one timestamp grammar. Signatures cover the exact payload bytes,
/// so accepting Foundation's wider ISO-8601 variants here would make otherwise equivalent
/// documents depend on encoder-specific fractional-second behavior.
enum PublicConfigurationTimestamp {
    static let grammar = "yyyy-MM-dd'T'HH:mm:ss'Z'"

    static func string(from date: Date) -> String {
        formatter().string(from: date)
    }

    static func date(from value: String) -> Date? {
        guard value.utf8.count == 20,
              value.range(
                  of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"#,
                  options: .regularExpression
              ) != nil,
              let date = formatter().date(from: value),
              formatter().string(from: date) == value else {
            return nil
        }
        return date
    }

    private static func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = grammar
        formatter.isLenient = false
        return formatter
    }
}

struct PublicConfigurationVerifier: Sendable {
    let policy: PublicConfigurationVerificationPolicy

    func verify(
        envelopeData: Data,
        now: Date
    ) throws -> VerifiedPublicConfiguration {
        guard envelopeData.count <= PublicConfigurationVerificationPolicy.maximumEnvelopeBytes else {
            throw PublicConfigurationVerificationError.envelopeTooLarge
        }
        try requireExactObjectKeys(
            in: envelopeData,
            expected: ["algorithm", "keyID", "payloadBase64", "signatureBase64"],
            error: .invalidEnvelopeSchema
        )
        try requireExactKeyOccurrences(
            in: envelopeData,
            expected: ["algorithm", "keyID", "payloadBase64", "signatureBase64"],
            error: .invalidEnvelopeSchema
        )

        let envelope: SignedPublicConfigurationEnvelope
        do {
            envelope = try strictDecoder().decode(
                SignedPublicConfigurationEnvelope.self,
                from: envelopeData
            )
        } catch {
            throw PublicConfigurationVerificationError.invalidEnvelopeSchema
        }

        guard envelope.algorithm == PublicConfigurationVerificationPolicy.algorithm else {
            throw PublicConfigurationVerificationError.unsupportedAlgorithm
        }
        guard let publicKeyData = policy.publicKeysByID[envelope.keyID] else {
            throw PublicConfigurationVerificationError.unknownKey
        }
        guard let payloadData = Data(base64Encoded: envelope.payloadBase64),
              let signatureData = Data(base64Encoded: envelope.signatureBase64) else {
            throw PublicConfigurationVerificationError.invalidEncoding
        }
        guard payloadData.count <= PublicConfigurationVerificationPolicy.maximumPayloadBytes else {
            throw PublicConfigurationVerificationError.payloadTooLarge
        }

        let publicKey: Curve25519.Signing.PublicKey
        do {
            publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        } catch {
            throw PublicConfigurationVerificationError.invalidEncoding
        }
        guard publicKey.isValidSignature(signatureData, for: payloadData) else {
            throw PublicConfigurationVerificationError.invalidSignature
        }

        let payloadObject = try requireExactObjectKeys(
            in: payloadData,
            expected: ["schemaVersion", "configVersion", "issuedAt", "expiresAt", "presentation"],
            error: .invalidPayloadSchema
        )
        try requireExactKeyOccurrences(
            in: payloadData,
            expected: [
                "schemaVersion",
                "configVersion",
                "issuedAt",
                "expiresAt",
                "presentation",
                "proValueTriggersEnabled"
            ],
            error: .invalidPayloadSchema
        )
        guard let presentationObject = payloadObject["presentation"] as? [String: Any],
              Set(presentationObject.keys) == ["proValueTriggersEnabled"] else {
            throw PublicConfigurationVerificationError.invalidPayloadSchema
        }

        let payload: PublicConfigurationPayload
        do {
            payload = try strictDecoder().decode(PublicConfigurationPayload.self, from: payloadData)
        } catch {
            throw PublicConfigurationVerificationError.invalidPayloadSchema
        }
        guard payload.schemaVersion == PublicConfigurationVerificationPolicy.schemaVersion else {
            throw PublicConfigurationVerificationError.unsupportedSchemaVersion
        }
        guard payload.configVersion > 0 else {
            throw PublicConfigurationVerificationError.invalidVersion
        }
        guard payload.issuedAt <= now.addingTimeInterval(
            PublicConfigurationVerificationPolicy.allowedFutureClockSkew
        ) else {
            throw PublicConfigurationVerificationError.issuedInFuture
        }
        guard payload.expiresAt > now else {
            throw PublicConfigurationVerificationError.expired
        }
        let validityInterval = payload.expiresAt.timeIntervalSince(payload.issuedAt)
        guard validityInterval > 0,
              validityInterval <= PublicConfigurationVerificationPolicy.maximumValidityInterval else {
            throw PublicConfigurationVerificationError.invalidValidityWindow
        }

        return VerifiedPublicConfiguration(
            payload: payload,
            envelopeData: envelopeData,
            payloadDigest: Data(SHA256.hash(data: payloadData))
        )
    }

    @discardableResult
    private func requireExactObjectKeys(
        in data: Data,
        expected: Set<String>,
        error: PublicConfigurationVerificationError
    ) throws -> [String: Any] {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw error
        }
        guard let dictionary = object as? [String: Any],
              Set(dictionary.keys) == expected else {
            throw error
        }
        return dictionary
    }

    /// JSONSerialization intentionally does not diagnose duplicate object keys. This bounded
    /// lexical pass counts every decoded key token before either Foundation decoder may collapse
    /// one. The schema is closed, so an exact occurrence set rejects duplicates at every depth.
    private func requireExactKeyOccurrences(
        in data: Data,
        expected: Set<String>,
        error: PublicConfigurationVerificationError
    ) throws {
        guard let json = String(data: data, encoding: .utf8) else {
            throw error
        }
        let expression: NSRegularExpression
        do {
            expression = try NSRegularExpression(
                pattern: #"\"(?:\\.|[^\"\\])*\"\s*:"#
            )
        } catch {
            throw error
        }
        let fullRange = NSRange(json.startIndex..<json.endIndex, in: json)
        let matches = expression.matches(in: json, range: fullRange)
        var keys: [String] = []
        keys.reserveCapacity(matches.count)
        let decoder = JSONDecoder()
        for match in matches {
            guard let range = Range(match.range, in: json) else {
                throw error
            }
            let matched = json[range]
            guard let colon = matched.lastIndex(of: ":") else {
                throw error
            }
            let token = matched[..<colon].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let tokenData = token.data(using: .utf8),
                  let key = try? decoder.decode(String.self, from: tokenData) else {
                throw error
            }
            keys.append(key)
        }
        guard keys.count == expected.count,
              Set(keys) == expected else {
            throw error
        }
    }

    private func strictDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = PublicConfigurationTimestamp.date(from: value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected UTC timestamp using \(PublicConfigurationTimestamp.grammar)"
                )
            }
            return date
        }
        return decoder
    }
}

struct PublicConfigurationPersistenceSnapshot: Codable, Equatable, Sendable {
    let envelopeData: Data
    let highestAcceptedVersion: UInt64
    let highestAcceptedPayloadDigest: Data
}

enum PublicConfigurationPersistenceRead: Equatable, Sendable {
    case empty
    case stored(PublicConfigurationPersistenceSnapshot)
    case invalid
}

protocol PublicConfigurationPersisting: Sendable {
    func read() async -> PublicConfigurationPersistenceRead
    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) async throws
}

enum PublicConfigurationPersistenceError: Error, Equatable, Sendable {
    case writeFailed
}

/// Stores only signed public bytes and rollback metadata. It contains no person, device, ledger,
/// StoreKit, or entitlement data. A corrupt rollback record is not overwritten automatically:
/// losing the high-water mark must fail closed to the built-in presentation. Release code exposes
/// no reset seam; recovery requires deleting the app and its container (Offload is insufficient),
/// unless a separately reviewed signed recovery protocol is added in a later phase.
actor FilePublicConfigurationPersistence: PublicConfigurationPersisting {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func read() async -> PublicConfigurationPersistenceRead {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(
            PublicConfigurationPersistenceSnapshot.self,
            from: data
        ), snapshot.highestAcceptedVersion > 0,
           !snapshot.envelopeData.isEmpty,
           snapshot.highestAcceptedPayloadDigest.count == SHA256.byteCount else {
            return .invalid
        }
        return .stored(snapshot)
    }

    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) async throws {
        let data = try JSONEncoder().encode(snapshot)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
        guard (try? Data(contentsOf: fileURL)) == data else {
            throw PublicConfigurationPersistenceError.writeFailed
        }
    }
}

enum PublicConfigurationResolutionSource: Equatable, Sendable {
    case remote
    case verifiedCache
    case builtIn
}

struct PublicConfigurationResolution: Equatable, Sendable {
    let presentation: PublicConfigurationPresentation
    let source: PublicConfigurationResolutionSource
    let acceptedConfigVersion: UInt64?

    static let conservativeDefault = PublicConfigurationResolution(
        presentation: .conservativeDefault,
        source: .builtIn,
        acceptedConfigVersion: nil
    )
}

/// Owns acceptance and rollback ordering, but no network transport. The C3-03 transport packet
/// may hand this actor bytes from the one fixed GET endpoint; consumers receive presentation only.
actor PublicConfigurationController {
    private let verifier: PublicConfigurationVerifier
    private let persistence: any PublicConfigurationPersisting
    /// Serializes the complete read/compare/write/read-back acceptance transaction. Actor
    /// isolation alone is insufficient because persistence awaits permit reentrancy and could let
    /// an older concurrent document overwrite a newer high-water mark.
    private var acceptanceTail: Task<PublicConfigurationResolution, Never>?

    init(
        verifier: PublicConfigurationVerifier,
        persistence: any PublicConfigurationPersisting
    ) {
        self.verifier = verifier
        self.persistence = persistence
    }

    func resolveCached(now: Date) async -> PublicConfigurationResolution {
        Self.resolveStored(
            read: await persistence.read(),
            verifier: verifier,
            now: now,
            source: .verifiedCache
        )
    }

    func acceptRemote(
        envelopeData: Data,
        now: Date
    ) async -> PublicConfigurationResolution {
        let predecessor = acceptanceTail
        let verifier = verifier
        let persistence = persistence
        let operation = Task {
            _ = await predecessor?.value
            return await Self.performAcceptance(
                envelopeData: envelopeData,
                now: now,
                verifier: verifier,
                persistence: persistence
            )
        }
        acceptanceTail = operation
        return await operation.value
    }

    private static func performAcceptance(
        envelopeData: Data,
        now: Date,
        verifier: PublicConfigurationVerifier,
        persistence: any PublicConfigurationPersisting
    ) async -> PublicConfigurationResolution {
        guard let verified = try? verifier.verify(envelopeData: envelopeData, now: now) else {
            return resolveStored(
                read: await persistence.read(),
                verifier: verifier,
                now: now,
                source: .verifiedCache
            )
        }

        let storedRead = await persistence.read()
        switch storedRead {
        case .invalid:
            return .conservativeDefault
        case .empty:
            break
        case let .stored(snapshot):
            guard verified.payload.configVersion >= snapshot.highestAcceptedVersion else {
                return resolveStored(
                    read: storedRead,
                    verifier: verifier,
                    now: now,
                    source: .verifiedCache
                )
            }
            if verified.payload.configVersion == snapshot.highestAcceptedVersion,
               verified.payloadDigest != snapshot.highestAcceptedPayloadDigest {
                return resolveStored(
                    read: storedRead,
                    verifier: verifier,
                    now: now,
                    source: .verifiedCache
                )
            }
        }

        let snapshot = PublicConfigurationPersistenceSnapshot(
            envelopeData: verified.envelopeData,
            highestAcceptedVersion: verified.payload.configVersion,
            highestAcceptedPayloadDigest: verified.payloadDigest
        )
        do {
            try await persistence.write(snapshot)
        } catch {
            return resolveStored(
                read: await persistence.read(),
                verifier: verifier,
                now: now,
                source: .verifiedCache
            )
        }

        // Verify through the persistence abstraction, not only the file adapter's private
        // read-back. A lying/no-op/custom persistence cannot activate an unstored document.
        return resolveStored(
            read: await persistence.read(),
            expectedSnapshot: snapshot,
            verifier: verifier,
            now: now,
            source: .remote
        )
    }

    private static func resolveStored(
        read: PublicConfigurationPersistenceRead,
        expectedSnapshot: PublicConfigurationPersistenceSnapshot? = nil,
        verifier: PublicConfigurationVerifier,
        now: Date,
        source: PublicConfigurationResolutionSource
    ) -> PublicConfigurationResolution {
        guard case let .stored(snapshot) = read else {
            return .conservativeDefault
        }
        let matchesExpectedSnapshot = expectedSnapshot.map { expected in
            expected == snapshot
        } ?? true
        guard matchesExpectedSnapshot,
              let verified = try? verifier.verify(
                  envelopeData: snapshot.envelopeData,
                  now: now
              ),
              verified.payload.configVersion == snapshot.highestAcceptedVersion,
              verified.payloadDigest == snapshot.highestAcceptedPayloadDigest else {
            return .conservativeDefault
        }
        return PublicConfigurationResolution(
            presentation: verified.payload.presentation,
            source: source,
            acceptedConfigVersion: verified.payload.configVersion
        )
    }
}
