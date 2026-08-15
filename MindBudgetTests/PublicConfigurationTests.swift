import CryptoKit
import Foundation
import Testing
@testable import MindBudget

@Suite(.serialized)
struct PublicConfigurationTests {
    @Test
    func fixedGoldenEnvelopeUsesTheFixedTimestampByteContract() throws {
        let publicKey = try #require(
            Data(base64Encoded: "A6EHv/POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg=")
        )
        let envelopeData = Data(
            #"{"algorithm":"Ed25519","keyID":"golden-2026-01","payloadBase64":"eyJjb25maWdWZXJzaW9uIjo3LCJleHBpcmVzQXQiOiIyMDI2LTA4LTIxVDAwOjAwOjAwWiIsImlzc3VlZEF0IjoiMjAyNi0wOC0xNFQwMDowMDowMFoiLCJwcmVzZW50YXRpb24iOnsicHJvVmFsdWVUcmlnZ2Vyc0VuYWJsZWQiOnRydWV9LCJzY2hlbWFWZXJzaW9uIjoxfQ==","signatureBase64":"cazLg8SFbV19REHbjhYvy0ilHJTeCCyzZB1tjwMM49D2bVf2KQUi5G2tfcJsU8JH4zHghTWPuFwE98gqBq8FDQ=="}"#.utf8
        )
        let verifier = PublicConfigurationVerifier(
            policy: PublicConfigurationVerificationPolicy(
                publicKeysByID: ["golden-2026-01": publicKey]
            )
        )
        let now = try #require(PublicConfigurationTimestamp.date(from: "2026-08-15T00:00:00Z"))

        let verified = try verifier.verify(envelopeData: envelopeData, now: now)

        #expect(verified.payload.configVersion == 7)
        #expect(verified.payload.presentation.proValueTriggersEnabled)
        #expect(
            PublicConfigurationTimestamp.string(from: verified.payload.issuedAt)
                == "2026-08-14T00:00:00Z"
        )
    }

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
        #expect(throws: PublicConfigurationVerificationError.invalidEnvelopeSchema) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithDuplicateEnvelopeKey(),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.invalidPayloadSchema) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithDuplicatePayloadKey(),
                now: fixture.now
            )
        }
        #expect(throws: PublicConfigurationVerificationError.invalidPayloadSchema) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeDataWithFractionalTimestamp(),
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
        #expect(throws: PublicConfigurationVerificationError.invalidValidityWindow) {
            try fixture.verifier.verify(
                envelopeData: try fixture.envelopeData(
                    version: 1,
                    enabled: false,
                    issuedAt: fixture.now.addingTimeInterval(60),
                    expiresAt: fixture.now.addingTimeInterval(60)
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
    func persistenceReadBackMustConfirmTheExactAcceptedSnapshot() async throws {
        let fixture = try SignedConfigurationFixture()
        let persistence = NoOpPublicConfigurationPersistence()
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )

        let resolution = await controller.acceptRemote(
            envelopeData: try fixture.envelopeData(version: 1, enabled: true),
            now: fixture.now
        )

        #expect(resolution == .conservativeDefault)
        #expect(await persistence.writeCount() == 1)
    }

    @Test
    func concurrentAcceptanceCannotLowerThePersistedHighWaterMark() async throws {
        let fixture = try SignedConfigurationFixture()
        let persistence = ReorderingPublicConfigurationPersistence()
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )
        let lowerEnvelope = try fixture.envelopeData(version: 1, enabled: false)
        let higherEnvelope = try fixture.envelopeData(version: 2, enabled: true)

        let lower = Task {
            await controller.acceptRemote(envelopeData: lowerEnvelope, now: fixture.now)
        }
        #expect(await persistence.waitForLowerWriteEntry())
        let higher = Task {
            await controller.acceptRemote(envelopeData: higherEnvelope, now: fixture.now)
        }

        let lowerResolution = await lower.value
        let higherResolution = await higher.value
        let cached = await controller.resolveCached(now: fixture.now)

        #expect(lowerResolution.acceptedConfigVersion == 1)
        #expect(higherResolution.acceptedConfigVersion == 2)
        #expect(cached.acceptedConfigVersion == 2)
        #expect(cached.presentation.proValueTriggersEnabled)
        #expect(await persistence.lowerWriteObservedHigherWrite() == false)
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

    @Test
    func cancelledFileWriteBeforeTheCommitPointLeavesNoCache() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PublicConfigurationCancellationTests.\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("configuration.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let fixture = try SignedConfigurationFixture()
        let envelopeData = try fixture.envelopeData(version: 4, enabled: true)
        let verified = try fixture.verifier.verify(envelopeData: envelopeData, now: fixture.now)
        let snapshot = PublicConfigurationPersistenceSnapshot(
            envelopeData: envelopeData,
            highestAcceptedVersion: verified.payload.configVersion,
            highestAcceptedPayloadDigest: verified.payloadDigest
        )
        let persistence = FilePublicConfigurationPersistence(fileURL: fileURL)
        let gate = PublicConfigurationPersistenceTestGate()

        let write = Task {
            await gate.enterAndWait()
            try await persistence.write(snapshot)
        }
        await gate.waitUntilEntered()
        write.cancel()
        await gate.release()

        do {
            try await write.value
            Issue.record("A write canceled before its commit point unexpectedly succeeded")
        } catch is CancellationError {
            // Expected: the persistence actor observes cancellation before filesystem mutation.
        } catch {
            Issue.record("Unexpected persistence cancellation error: \(error)")
        }
        #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
        #expect(await persistence.read() == .empty)
    }

    @Test
    func cancellingAcceptanceWhilePersistenceIsSuspendedCannotCommitTheSnapshot() async throws {
        let fixture = try SignedConfigurationFixture()
        let persistence = GatedCancellationPublicConfigurationPersistence()
        let controller = PublicConfigurationController(
            verifier: fixture.verifier,
            persistence: persistence
        )
        let envelopeData = try fixture.envelopeData(version: 1, enabled: true)

        let acceptance = Task {
            try await controller.acceptRemoteResult(
                envelopeData: envelopeData,
                now: fixture.now
            )
        }
        await persistence.waitUntilWriteEntered()
        acceptance.cancel()
        await persistence.releaseWrite()

        do {
            _ = try await acceptance.value
            Issue.record("Canceled acceptance unexpectedly returned a resolution")
        } catch is CancellationError {
            // Expected: cancellation crosses the actor hop and reaches the pre-commit check.
        } catch {
            Issue.record("Unexpected acceptance cancellation error: \(error)")
        }
        #expect(await persistence.read() == .empty)
        #expect(await persistence.writeCount() == 0)
    }

    @Test
    func filePersistenceTreatsMalformedRollbackRecordsAsStickyInvalidState() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PublicConfigurationInvalidTests.\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let invalidSnapshots = [
            Data(),
            Data("{}".utf8),
            try JSONEncoder().encode(
                PublicConfigurationPersistenceSnapshot(
                    envelopeData: Data(),
                    highestAcceptedVersion: 1,
                    highestAcceptedPayloadDigest: Data(repeating: 1, count: SHA256.byteCount)
                )
            ),
            try JSONEncoder().encode(
                PublicConfigurationPersistenceSnapshot(
                    envelopeData: Data("signed".utf8),
                    highestAcceptedVersion: 1,
                    highestAcceptedPayloadDigest: Data(repeating: 1, count: SHA256.byteCount - 1)
                )
            )
        ]

        for (index, data) in invalidSnapshots.enumerated() {
            let fileURL = directory.appendingPathComponent("invalid-\(index).json")
            try data.write(to: fileURL)
            let persistence = FilePublicConfigurationPersistence(fileURL: fileURL)
            #expect(await persistence.read() == .invalid)
        }
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

    func envelopeDataWithDuplicateEnvelopeKey() throws -> Data {
        let valid = try envelopeData(version: 1, enabled: false)
        let object = try #require(JSONSerialization.jsonObject(with: valid) as? [String: Any])
        let payload = try #require(object["payloadBase64"] as? String)
        let signature = try #require(object["signatureBase64"] as? String)
        return Data(
            #"{"algorithm":"Ed25519","algorithm":"Ed25519","keyID":"mb-config-2026-01","payloadBase64":"\#(payload)","signatureBase64":"\#(signature)"}"#.utf8
        )
    }

    func envelopeDataWithDuplicatePayloadKey() throws -> Data {
        let issuedAt = PublicConfigurationTimestamp.string(from: now.addingTimeInterval(-60))
        let expiresAt = PublicConfigurationTimestamp.string(from: now.addingTimeInterval(3_600))
        let payload = Data(
            #"{"schemaVersion":1,"configVersion":1,"configVersion":2,"issuedAt":"\#(issuedAt)","expiresAt":"\#(expiresAt)","presentation":{"proValueTriggersEnabled":false}}"#.utf8
        )
        return try signedEnvelope(payloadData: payload)
    }

    func envelopeDataWithFractionalTimestamp() throws -> Data {
        let expiresAt = PublicConfigurationTimestamp.string(from: now.addingTimeInterval(3_600))
        let payload = Data(
            #"{"schemaVersion":1,"configVersion":1,"issuedAt":"2026-08-14T00:00:00.000Z","expiresAt":"\#(expiresAt)","presentation":{"proValueTriggersEnabled":false}}"#.utf8
        )
        return try signedEnvelope(payloadData: payload)
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
        return encode(envelope)
    }

    private func encode<T: Encodable>(_ value: T) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(PublicConfigurationTimestamp.string(from: date))
        }
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

    func read() async -> PublicConfigurationPersistenceRead { value }

    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) async throws {
        guard !failsWrites else {
            throw PublicConfigurationPersistenceError.writeFailed
        }
        writes += 1
        value = .stored(snapshot)
    }

    func writeCount() -> Int { writes }
}

private actor GatedCancellationPublicConfigurationPersistence: PublicConfigurationPersisting {
    private var value: PublicConfigurationPersistenceRead = .empty
    private var writes = 0
    private let gate = PublicConfigurationPersistenceTestGate()

    func read() async -> PublicConfigurationPersistenceRead { value }

    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) async throws {
        await gate.enterAndWait()
        try Task.checkCancellation()
        writes += 1
        value = .stored(snapshot)
    }

    func waitUntilWriteEntered() async {
        await gate.waitUntilEntered()
    }

    func releaseWrite() async {
        await gate.release()
    }

    func writeCount() -> Int { writes }
}

private actor PublicConfigurationPersistenceTestGate {
    private var entered = false
    private var released = false
    private var entryWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []

    func enterAndWait() async {
        entered = true
        entryWaiters.forEach { $0.resume() }
        entryWaiters.removeAll()
        guard !released else { return }
        await withCheckedContinuation { continuation in
            releaseWaiters.append(continuation)
        }
    }

    func waitUntilEntered() async {
        guard !entered else { return }
        await withCheckedContinuation { continuation in
            entryWaiters.append(continuation)
        }
    }

    func release() {
        released = true
        releaseWaiters.forEach { $0.resume() }
        releaseWaiters.removeAll()
    }
}

private actor NoOpPublicConfigurationPersistence: PublicConfigurationPersisting {
    private var writes = 0

    func read() async -> PublicConfigurationPersistenceRead { .empty }

    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) async throws {
        _ = snapshot
        writes += 1
    }

    func writeCount() -> Int { writes }
}

/// Deliberately permits a higher-version write to overtake the lower write if the controller does
/// not serialize the complete acceptance transaction. The lower write waits briefly for that
/// unsafe overtake, making the stale-overwrite regression deterministic rather than scheduler-led.
private actor ReorderingPublicConfigurationPersistence: PublicConfigurationPersisting {
    private var value: PublicConfigurationPersistenceRead = .empty
    private var lowerWriteEntered = false
    private var higherWriteEntered = false
    private var lowerObservedHigher = false

    func read() async -> PublicConfigurationPersistenceRead { value }

    func write(_ snapshot: PublicConfigurationPersistenceSnapshot) async throws {
        if snapshot.highestAcceptedVersion == 1 {
            lowerWriteEntered = true
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .milliseconds(300))
            while !higherWriteEntered, clock.now < deadline, !Task.isCancelled {
                try? await clock.sleep(for: .milliseconds(5))
            }
            lowerObservedHigher = higherWriteEntered
        } else if snapshot.highestAcceptedVersion == 2 {
            higherWriteEntered = true
        }
        value = .stored(snapshot)
    }

    func waitForLowerWriteEntry() async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while !lowerWriteEntered, clock.now < deadline, !Task.isCancelled {
            try? await clock.sleep(for: .milliseconds(5))
        }
        return lowerWriteEntered
    }

    func lowerWriteObservedHigherWrite() -> Bool { lowerObservedHigher }
}
