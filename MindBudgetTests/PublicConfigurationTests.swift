import CryptoKit
import Foundation
import Testing
@testable import MindBudget

@Suite(.serialized)
struct PublicConfigurationTests {
    @Test
    func validEd25519EnvelopeProducesOnlyTheClosedPresentationSnapshot() throws {
        let fixture = try SignedConfigurationFixture()
        let verified = try fixture.verifier.verify(
            envelopeData: fixture.envelopeData(version: 1, enabled: true),
            now: fixture.now
        )

        #expect(verified.payload.schemaVersion == 1)
        #expect(verified.payload.configVersion == 1)
        #expect(verified.payload.presentation.proValueTriggersEnabled)
        #expect(verified.payloadDigest.count == SHA256.byteCount)
    }

    @Test
    func invalidEnvelopeSignatureKeyAndUnknownFieldsFailClosed() throws {
        let fixture = try SignedConfigurationFixture()
        let valid = try fixture.envelopeData(version: 1, enabled: true)

        #expect(throws: PublicConfigurationVerificationError.invalidSignature) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithInvalidSignature(valid),
                now: fixture.now
            )
        }

        #expect(throws: PublicConfigurationVerificationError.unknownKey) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeData(version: 1, enabled: true, keyID: "unknown"),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.unsupportedAlgorithm) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeData(
                    version: 1,
                    enabled: true,
                    algorithm: "P256"
                ),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.invalidEnvelopeSchema) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithUnknownEnvelopeField(),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.invalidPayloadSchema) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithUnknownPayloadField(),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.invalidPayloadSchema) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithUnknownPresentationField(),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.invalidEncoding) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithInvalidBase64(),
                now: fixture.now
            )
        }
    }

    @Test
    func versionTimeAndSizeBoundsRejectUnsafeDocuments() throws {
        let fixture = try SignedConfigurationFixture()

        #expect(throws: PublicConfigurationVerificationError.invalidVersion) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeData(version: 0, enabled: false),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.issuedInFuture) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeData(
                    version: 1,
                    enabled: false,
                    issuedAt: fixture.now.addingTimeInterval(301)
                ),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.expired) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeData(
                    version: 1,
                    enabled: false,
                    issuedAt: fixture.now.addingTimeInterval(-100),
                    expiresAt: fixture.now
                ),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.invalidValidityWindow) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeData(
                    version: 1,
                    enabled: false,
                    issuedAt: fixture.now,
                    expiresAt: fixture.now.addingTimeInterval(
                        PublicConfigurationVerificationPolicy.maximumValidityInterval + 1
                    )
                ),
                now: fixture.now
            )
        }

        let oversized = Data(
            repeating: 0,
            count: PublicConfigurationVerificationPolicy.maximumEnvelopeBytes + 1
        )
        #expect(throws: PublicConfigurationVerificationError.envelopeTooLarge) {
            try fixture.verifier.verify(envelopeData: oversized, now: fixture.now)
        }
        #expect(throws: PublicConfigurationVerificationError.payloadTooLarge) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithOversizedSignedPayload(),
                now: fixture.now
            )
        }
    }

    @Test
    func remoteRollbackAndSameVersionEquivocationKeepTheVerifiedCache() async throws {
        let fixture = try SignedConfigurationFixture()
        let persistence = InMemoryPublicConfigurationPersistence()
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )

        let accepted = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(version: 2, enabled: true),
            now: fixture.now
        )
        #expect(accepted.source == .remote)
        #expect(accepted.presentation.proValueTriggersEnabled)

        let rollback = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(version: 1, enabled: false),
            now: fixture.now
        )
        #expect(rollback.source == .verifiedCache)
        #expect(rollback.acceptedConfigVersion == 2)
        #expect(rollback.presentation.proValueTriggersEnabled)

        let equivocation = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(version: 2, enabled: false),
            now: fixture.now
        )
        #expect(equivocation.source == .verifiedCache)
        #expect(equivocation.presentation.proValueTriggersEnabled)
    }

    @Test
    func offlineUsesOnlyANonexpiredVerifiedCacheThenFallsBackBuiltIn() async throws {
        let fixture = try SignedConfigurationFixture()
        let persistence = InMemoryPublicConfigurationPersistence()
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )
        _ = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(
                version: 3,
                enabled: true,
                expiresAt: fixture.now.addingTimeInterval(60)
            ),
            now: fixture.now
        )

        let cached = await controller.resolveCached(now: fixture.now.addingTimeInterval(30))
        #expect(cached.source == .verifiedCache)
        #expect(cached.presentation.proValueTriggersEnabled)

        let expired = await controller.resolveCached(now: fixture.now.addingTimeInterval(60))
        #expect(expired == .conservativeDefault)
        #expect(expired.presentation.proValueTriggersEnabled == false)
    }

    @Test
    func invalidPersistenceCannotBeOverwrittenAndNeverEnablesPresentation() async throws {
        let fixture = try SignedConfigurationFixture()
        let persistence = InMemoryPublicConfigurationPersistence(initial: .invalid)
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )

        let resolution = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(version: 9, enabled: true),
            now: fixture.now
        )

        #expect(resolution == .conservativeDefault)
        #expect(await persistence.writeCount() == 0)
    }

    @Test
    func persistenceFailureDoesNotActivateAnUnstoredConfiguration() async throws {
        let fixture = try SignedConfigurationFixture()
        let persistence = InMemoryPublicConfigurationPersistence(failsWrites: true)
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )

        let resolution = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(version: 1, enabled: true),
            now: fixture.now
        )

        #expect(resolution == .conservativeDefault)
    }

    @Test
    func atomicFilePersistenceRoundTripsOnlySignedPublicState() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PublicConfigurationTests.\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("configuration.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let fixture = try SignedConfigurationFixture()
        let persistence = FilePublicConfigurationPersistence(fileURL: fileURL)
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )
        _ = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(version: 4, enabled: true),
            now: fixture.now
        )

        let reloaded = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: FilePublicConfigurationPersistence(fileURL: fileURL)
        )
        let resolution = await reloaded.resolveCached(now: fixture.now)
        #expect(resolution.source == .verifiedCache)
        #expect(resolution.acceptedConfigVersion == 4)
        #expect(resolution.presentation.proValueTriggersEnabled)
    }
}

private struct SignedConfigurationFixture {
    let now = Date(timeIntervalSince1970: 1_786_656_000)
    let privateKey: Curve25519.Signing.PrivateKey
    let verifier: PublicConfigurationVerifier

    init() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        self.privateKey = privateKey
        verifier = PublicConfigurationVerifier(
            policy: PublicConfigurationVerificationPolicy(
                publicKeysByID: ["mb-config-2026-01": privateKey.publicKey.rawRepresentation]
            )
        )
    }

    func envelopeData(
        version: UInt64,
        enabled: Bool,
        keyID: String = "mb-config-2026-01",
        algorithm: String = PublicConfigurationVerificationPolicy.algorithm,
        issuedAt: Date? = nil,
        expiresAt: Date? = nil
    ) throws -> Data {
        let payload = PublicConfigurationPayload(
            schemaVersion: PublicConfigurationVerificationPolicy.schemaVersion,
            configVersion: version,
            issuedAt: issuedAt ?? now.addingTimeInterval(-60),
            expiresAt: expiresAt ?? now.addingTimeInterval(3_600),
            presentation: PublicConfigurationPresentation(
                proValueTriggersEnabled: enabled
            )
        )
        return try signedEnvelope(payloadData: encode(payload), keyID: keyID, algorithm: algorithm)
    }

    func envelopeDataWithUnknownEnvelopeField() throws -> Data {
        let data = try envelopeData(version: 1, enabled: false)
        var object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        object["unexpected"] = true
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func envelopeDataWithInvalidSignature(_ data: Data) throws -> Data {
        var object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let encodedSignature = try #require(object["signatureBase64"] as? String)
        var signature = try #require(Data(base64Encoded: encodedSignature))
        signature[signature.startIndex] ^= 1
        object["signatureBase64"] = signature.base64EncodedString()
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func envelopeDataWithUnknownPayloadField() throws -> Data {
        let payload = PublicConfigurationPayload(
            schemaVersion: 1,
            configVersion: 1,
            issuedAt: now.addingTimeInterval(-60),
            expiresAt: now.addingTimeInterval(3_600),
            presentation: .conservativeDefault
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: encode(payload)) as? [String: Any]
        )
        object["unexpected"] = "blocked"
        let payloadData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return try signedEnvelope(payloadData: payloadData)
    }

    func envelopeDataWithUnknownPresentationField() throws -> Data {
        var object = try #require(
            JSONSerialization.jsonObject(
                with: payloadData(version: 1, enabled: false)
            ) as? [String: Any]
        )
        var presentation = try #require(object["presentation"] as? [String: Any])
        presentation["unexpected"] = true
        object["presentation"] = presentation
        return try signedEnvelope(
            payloadData: JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        )
    }

    func envelopeDataWithInvalidBase64() throws -> Data {
        let data = try envelopeData(version: 1, enabled: false)
        var object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        object["signatureBase64"] = "%%%"
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func envelopeDataWithOversizedSignedPayload() throws -> Data {
        var object = try #require(
            JSONSerialization.jsonObject(
                with: payloadData(version: 1, enabled: false)
            ) as? [String: Any]
        )
        object["padding"] = String(
            repeating: "x",
            count: PublicConfigurationVerificationPolicy.maximumPayloadBytes
        )
        return try signedEnvelope(
            payloadData: JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        )
    }

    private func payloadData(version: UInt64, enabled: Bool) -> Data {
        encode(
            PublicConfigurationPayload(
                schemaVersion: PublicConfigurationVerificationPolicy.schemaVersion,
                configVersion: version,
                issuedAt: now.addingTimeInterval(-60),
                expiresAt: now.addingTimeInterval(3_600),
                presentation: PublicConfigurationPresentation(
                    proValueTriggersEnabled: enabled
                )
            )
        )
    }

    private func signedEnvelope(
        payloadData: Data,
        keyID: String = "mb-config-2026-01",
        algorithm: String = PublicConfigurationVerificationPolicy.algorithm
    ) throws -> Data {
        let envelope = SignedPublicConfigurationEnvelope(
            algorithm: algorithm,
            keyID: keyID,
            payloadBase64: payloadData.base64EncodedString(),
            signatureBase64: try privateKey.signature(for: payloadData).base64EncodedString()
        )
        return try encode(envelope)
    }

    private func encode<T: Encodable>(_ value: T) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try! encoder.encode(value)
    }
}

private actor InMemoryPublicConfigurationPersistence: PublicConfigurationPersisting {
    private var value: PublicConfigurationPersistenceRead
    private let failsWrites: Bool
    private var writes = 0

    init(
        initial: PublicConfigurationPersistenceRead = .empty,
        failsWrites: Bool = false
    ) {
        value = initial
        self.failsWrites = failsWrites
    }

    func read() -> PublicConfigurationPersistenceRead { value }

    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) throws {
        guard !failsWrites else {
            throw PublicConfigurationPersistenceError.writeFailed
        }
        writes += 1
        value = .stored(snapshot)
    }

    func writeCount() -> Int { writes }
}
