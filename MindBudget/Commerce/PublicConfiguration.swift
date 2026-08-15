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

    private func strictDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
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
/// losing the high-water mark must fail closed to the built-in presentation.
actor FilePublicConfigurationPersistence: PublicConfigurationPersisting {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func read() -> PublicConfigurationPersistenceRead {
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

    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) throws {
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

    init(
        verifier: PublicConfigurationVerifier,
        persistence: any PublicConfigurationPersisting
    ) {
        self.verifier = verifier
        self.persistence = persistence
    }

    func resolveCached(now: Date) async -> PublicConfigurationResolution {
        guard case let .stored(snapshot) = await persistence.read(),
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
            source: .verifiedCache,
            acceptedConfigVersion: verified.payload.configVersion
        )
    }

    func acceptRemote(
        envelopeData: Data,
        now: Date
    ) async -> PublicConfigurationResolution {
        guard let verified = try? verifier.verify(envelopeData: envelopeData, now: now) else {
            return await resolveCached(now: now)
        }

        let storedRead = await persistence.read()
        switch storedRead {
        case .invalid:
            return .conservativeDefault
        case .empty:
            break
        case let .stored(snapshot):
            guard verified.payload.configVersion >= snapshot.highestAcceptedVersion else {
                return await resolveCached(now: now)
            }
            if verified.payload.configVersion == snapshot.highestAcceptedVersion,
               verified.payloadDigest != snapshot.highestAcceptedPayloadDigest {
                return await resolveCached(now: now)
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
            return await resolveCached(now: now)
        }

        return PublicConfigurationResolution(
            presentation: verified.payload.presentation,
            source: .remote,
            acceptedConfigVersion: verified.payload.configVersion
        )
    }
}
