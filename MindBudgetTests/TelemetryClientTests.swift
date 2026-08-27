import CryptoKit
import Foundation
import Testing
@testable import MindBudget

@Suite("C5-01 typed telemetry client")
struct TelemetryClientTests {
    @Test
    func collectionIsDefaultOffAndDoesNotCreatePersistence() async throws {
        let persistence = MemoryTelemetryPersistence()
        let client = try makeClient(persistence: persistence)

        #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .disabled)
        #expect(await client.snapshot() == TelemetryClientSnapshot(
            collectionEnabled: false,
            queuedEventCount: 0,
            retainedIdentityCount: 0,
            retryNotBefore: nil,
            availability: .available
        ))
        try await client.setCollectionEnabled(false, now: referenceDate)
        #expect(await persistence.writeCount == 0)
    }

    @Test
    func disablingANeverEnabledEncryptedClientCreatesNoFileOrKey() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudget-Telemetry-Disabled-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("queue.v1")
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyProvider = TrackingTelemetryKeyProvider(startingKey: nil)
        let persistence = EncryptedFileTelemetryPersistence(
            fileURL: fileURL,
            keyProvider: keyProvider
        )
        let client = try makeClient(persistence: persistence)

        try await client.setCollectionEnabled(false, now: referenceDate)

        #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
        #expect(keyProvider.containsKey() == false)
        #expect(await client.snapshot().collectionEnabled == false)
    }

    @Test
    func fixedVocabularyEncodesOnlyClosedKeysAndValues() throws {
        let event = TelemetryEvent.receipt(.reviewed, .completed)
        let data = try JSONEncoder().encode(event)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect(object == [
            "name": "receipt_flow",
            "action": "reviewed",
            "outcome": "completed"
        ])
        #expect(throws: TelemetryAppVersionError.invalid) {
            try TelemetryAppVersion("1.0 beta")
        }
        #expect(try TelemetryAppVersion("1.0.9").value == "1.0.9")
    }

    @Test
    func policyUsesTheInjectedUserCalendarAcrossDaylightSavingTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let start = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 1,
            hour: 12
        )))
        let policy = TelemetryPolicy(calendar: calendar)

        let rotation = try #require(policy.identityRotationDate(after: start))
        let expiration = try #require(policy.deletionProofExpirationDate(after: start))

        #expect(rotation == calendar.date(byAdding: .day, value: 30, to: start))
        #expect(expiration == calendar.date(byAdding: .day, value: 90, to: start))
        #expect(rotation.timeIntervalSince(start) != TimeInterval(30 * 24 * 60 * 60))
    }

    @Test
    func optOutClearsUnsentEventsAndReenableCannotReuseThePriorPseudonym() async throws {
        let persistence = MemoryTelemetryPersistence()
        let client = try makeClient(persistence: persistence)

        try await client.setCollectionEnabled(true, now: referenceDate)
        #expect(try await client.capture(.proSurface(.presented), at: referenceDate) == .queued)
        let firstIdentity = try #require(await persistence.currentState?.identities.last)
        try await client.setCollectionEnabled(false, now: laterDate(days: 1))

        let snapshot = await client.snapshot()
        #expect(snapshot.collectionEnabled == false)
        #expect(snapshot.queuedEventCount == 0)
        #expect(snapshot.retainedIdentityCount == 1)
        #expect(await persistence.currentState?.identities.last?.deletionProofExpiresAt != nil)

        try await client.setCollectionEnabled(true, now: laterDate(days: 2))
        let identities = try #require(await persistence.currentState?.identities)
        #expect(identities.count == 2)
        #expect(identities.last?.identifier != firstIdentity.identifier)
    }

    @Test
    func identityCapacityFailsClosedWithoutDiscardingDeletionProofs() async throws {
        let persistence = MemoryTelemetryPersistence()
        let client = try makeClient(persistence: persistence)

        for generation in 0..<TelemetryPolicy.maximumIdentityGenerations {
            try await client.setCollectionEnabled(true, now: laterDate(days: generation * 2))
            try await client.setCollectionEnabled(false, now: laterDate(days: generation * 2 + 1))
        }

        #expect(
            await client.snapshot().retainedIdentityCount
                == TelemetryPolicy.maximumIdentityGenerations
        )
        await #expect(throws: TelemetryClientError.identityCapacityReached) {
            try await client.setCollectionEnabled(
                true,
                now: laterDate(days: TelemetryPolicy.maximumIdentityGenerations * 2)
            )
        }
        let snapshot = await client.snapshot()
        #expect(snapshot.collectionEnabled == false)
        #expect(snapshot.retainedIdentityCount == TelemetryPolicy.maximumIdentityGenerations)
    }

    @Test
    func concurrentCapturesSerializeReadModifyWriteWithoutLosingAnEvent() async throws {
        let persistence = GatedWriteTelemetryPersistence()
        let client = try makeClient(persistence: persistence)
        try await client.setCollectionEnabled(true, now: referenceDate)
        await persistence.suspendNextWrite()

        let first = Task {
            try await client.capture(.appSessionStarted, at: referenceDate)
        }
        await persistence.waitUntilWriteStarts()
        let second = Task {
            try await client.capture(.proSurface(.presented), at: referenceDate)
        }
        await persistence.releaseWrite()

        #expect(try await first.value == .queued)
        #expect(try await second.value == .queued)
        #expect(await client.snapshot().queuedEventCount == 2)
        #expect(await persistence.currentState?.queuedEvents.count == 2)
    }

    @Test
    func boundedQueueDropsOnlyTheOldestUnsentEvent() async throws {
        let persistence = MemoryTelemetryPersistence()
        let client = try makeClient(persistence: persistence)
        try await client.setCollectionEnabled(true, now: referenceDate)

        for index in 0..<TelemetryPolicy.maximumQueuedEvents {
            #expect(try await client.capture(
                .proSurface(index.isMultiple(of: 2) ? .presented : .dismissed),
                at: referenceDate.addingTimeInterval(TimeInterval(index))
            ) == .queued)
        }
        #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .queuedAfterDroppingOldest)

        let stored = try #require(await persistence.currentState)
        #expect(stored.queuedEvents.count == TelemetryPolicy.maximumQueuedEvents)
        #expect(stored.queuedEvents.last?.event == .appSessionStarted)
    }

    @Test
    func resetRotatesPseudonymButRetainsDeletionProof() async throws {
        let persistence = MemoryTelemetryPersistence()
        let client = try makeClient(persistence: persistence)
        try await client.setCollectionEnabled(true, now: referenceDate)
        let first = try #require(await persistence.currentState?.identities.last)

        try await client.resetPseudonymousIdentity(now: laterDate(days: 1))

        let identities = try #require(await persistence.currentState?.identities)
        #expect(identities.count == 2)
        #expect(identities[0].identifier == first.identifier)
        #expect(identities[0].deletionProofExpiresAt != nil)
        #expect(identities[1].identifier != first.identifier)
        #expect(identities.allSatisfy { $0.deletionHandle.count == 64 })
    }

    @Test
    func automaticRotationUsesCalendarDaysAndPreservesQueuedGeneration() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = RecordingTelemetryTransport()
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)
        #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .queued)
        #expect(try await client.capture(.proSurface(.presented), at: laterDate(days: 31)) == .queued)

        let stored = try #require(await persistence.currentState)
        #expect(stored.identities.count == 2)
        #expect(stored.queuedEvents[0].identityIdentifier != stored.queuedEvents[1].identityIdentifier)

        #expect(await client.flush(now: laterDate(days: 31)) == .accepted(1))
        let firstBatch = try #require(await transport.uploads.first)
        #expect(firstBatch.events.count == 1)
        #expect(firstBatch.pseudonymousIdentifier == stored.identities[0].identifier)
    }

    @Test
    func uploadIsBoundedAndAcceptedIDsDoNotRemoveConcurrentCapture() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = GatedTelemetryTransport()
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)
        for _ in 0..<TelemetryPolicy.maximumBatchEvents {
            #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .queued)
        }

        let flush = Task { await client.flush(now: referenceDate) }
        await transport.waitUntilUploadStarts()
        #expect(try await client.capture(.receipt(.opened, .completed), at: referenceDate) == .queued)
        await transport.releaseUpload()

        #expect(await flush.value == .accepted(TelemetryPolicy.maximumBatchEvents))
        #expect(await client.snapshot().queuedEventCount == 1)
    }

    @Test
    func concurrentFlushesShareOneTransportLaneAndCannotDuplicateABatch() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = GatedTelemetryTransport()
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)
        #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .queued)

        let first = Task { await client.flush(now: referenceDate) }
        await transport.waitUntilUploadStarts()
        let second = Task { await client.flush(now: referenceDate) }
        await transport.releaseUpload()

        #expect(await first.value == .accepted(1))
        #expect(await second.value == .empty)
        #expect(await transport.uploadCount == 1)
    }

    @Test
    func retryBackoffPreservesQueueAndDoesNotAffectCapture() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = RecordingTelemetryTransport(uploadResolution: .retryAfter(seconds: 5))
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)
        #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .queued)

        let first = await client.flush(now: referenceDate)
        guard case let .failed(retryDate?) = first else {
            Issue.record("Expected a bounded retry")
            return
        }
        #expect(retryDate == laterDate(seconds: 60))
        #expect(await client.flush(now: laterDate(seconds: 30)) == .deferred(retryDate))
        #expect(
            try await client.capture(.receipt(.opened, .completed), at: laterDate(seconds: 30))
                == .queued
        )
        #expect(await client.snapshot().queuedEventCount == 2)
        #expect(await transport.uploads.count == 1)
    }

    @Test
    func acceptedUploadWithLocalCommitFailureIsNotClassifiedAsTransportFailure() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = RecordingTelemetryTransport()
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)
        #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .queued)
        await persistence.failNextWrite()

        #expect(await client.flush(now: referenceDate) == .persistenceFailed)
        let snapshot = await client.snapshot()
        #expect(snapshot.queuedEventCount == 1)
        #expect(snapshot.retryNotBefore == nil)
        #expect(await transport.uploads.count == 1)
    }

    @Test
    func remoteDeleteFailureRetainsProofsAndSuccessDestroysLocalState() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = RecordingTelemetryTransport(deleteFailuresRemaining: 1)
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)

        guard case .failed = await client.deleteAllTelemetry(now: referenceDate) else {
            Issue.record("Expected first deletion to fail closed")
            return
        }
        #expect(await client.snapshot().retainedIdentityCount == 1)

        #expect(await client.deleteAllTelemetry(now: laterDate(seconds: 60)) == .deletedRemotely)
        #expect(await persistence.deleteCount == 1)
        #expect(await client.snapshot().retainedIdentityCount == 0)
        let request = try #require(await transport.deletions.first)
        #expect(request.proofs.count == 1)
        #expect(request.proofs[0].deletionSecret.count == 32)
    }

    @Test
    func remoteDeleteCanRetryTheSameProofAfterLocalCleanupFails() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = RecordingTelemetryTransport()
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)
        await persistence.failNextDelete()

        guard case .failed = await client.deleteAllTelemetry(now: referenceDate) else {
            Issue.record("Expected local cleanup failure after remote deletion")
            return
        }
        #expect(await client.snapshot().retainedIdentityCount == 1)
        #expect(await client.deleteAllTelemetry(now: laterDate(seconds: 60)) == .deletedRemotely)
        let requests = await transport.deletions
        #expect(requests.count == 2)
        #expect(requests[0] == requests[1])
    }

    @Test
    func deletionRequestExplicitlyGroupsEveryRetainedGenerationForCompleteDeletion() async throws {
        let persistence = MemoryTelemetryPersistence()
        let transport = RecordingTelemetryTransport()
        let client = try makeClient(persistence: persistence, transport: transport)
        try await client.setCollectionEnabled(true, now: referenceDate)
        try await client.resetPseudonymousIdentity(now: laterDate(days: 1))
        try await client.setCollectionEnabled(false, now: laterDate(days: 2))
        let expectedIdentifiers = Set(try #require(await persistence.currentState).identities.map(\.identifier))

        #expect(await client.deleteAllTelemetry(now: laterDate(days: 3)) == .deletedRemotely)
        let request = try #require(await transport.deletions.first)
        #expect(request.proofs.count == 2)
        #expect(Set(request.proofs.map(\.pseudonymousIdentifier)) == expectedIdentifiers)
    }

    @Test
    func corruptPersistenceIsStickyAndNeverOverwritten() async throws {
        let persistence = MemoryTelemetryPersistence(readResult: .invalid)
        let client = try makeClient(persistence: persistence)

        #expect(await client.snapshot() == .corrupt)
        #expect(try await client.capture(.appSessionStarted, at: referenceDate) == .unavailable)
        await #expect(throws: TelemetryClientError.corruptPersistence) {
            try await client.setCollectionEnabled(true, now: referenceDate)
        }
        #expect(await persistence.writeCount == 0)
    }

    @Test
    func corruptPersistenceCanBeDeletedLocallyWithoutClaimingRemoteDeletion() async throws {
        let persistence = MemoryTelemetryPersistence(readResult: .invalid)
        let client = try makeClient(persistence: persistence)

        #expect(await client.snapshot() == .corrupt)
        #expect(
            await client.deleteAllTelemetry(now: referenceDate)
                == .deletedLocallyWithoutRemoteProofs
        )
        #expect(await persistence.deleteCount == 1)
        #expect(await client.snapshot() == TelemetryClientSnapshot(
            collectionEnabled: false,
            queuedEventCount: 0,
            retainedIdentityCount: 0,
            retryNotBefore: nil,
            availability: .available
        ))

        let restartedClient = try makeClient(persistence: persistence)
        #expect(await restartedClient.snapshot().availability == .available)
    }

    @Test
    func encryptedCorruptPersistenceDeletesFileAndKeyWithoutRemoteClaim() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudget-Telemetry-Delete-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("queue.v1")
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyProvider = TrackingTelemetryKeyProvider()
        let persistence = EncryptedFileTelemetryPersistence(
            fileURL: fileURL,
            keyProvider: keyProvider
        )
        let state = makePersistedTelemetryState()
        try await persistence.write(state)
        var corrupt = try Data(contentsOf: fileURL)
        corrupt[corrupt.index(before: corrupt.endIndex)] ^= 0x01
        try corrupt.write(to: fileURL, options: .atomic)
        let client = try makeClient(persistence: persistence)

        #expect(await client.snapshot() == .corrupt)
        #expect(
            await client.deleteAllTelemetry(now: referenceDate)
                == .deletedLocallyWithoutRemoteProofs
        )
        #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
        #expect(keyProvider.containsKey() == false)
    }

    @Test
    func encryptedFileRoundTripsWithoutPlaintextAndCorruptionFailsClosed() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudget-Telemetry-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("queue.v1")
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = EncryptedFileTelemetryPersistence(
            fileURL: fileURL,
            keyProvider: FixedTelemetryKeyProvider()
        )
        let state = makePersistedTelemetryState()
        let identity = try #require(state.identities.first)

        try await persistence.write(state)
        #expect(await persistence.read() == .valid(state))
        let encrypted = try Data(contentsOf: fileURL)
        #expect(String(decoding: encrypted, as: UTF8.self).contains("receipt_flow") == false)

        let impossibleDisabledState = TelemetryPersistedState(
            collectionEnabled: false,
            identities: [identity],
            queuedEvents: [],
            consecutiveFailures: 0,
            retryNotBefore: nil
        )
        await #expect(throws: TelemetryPersistenceError.invalidState) {
            try await persistence.write(impossibleDisabledState)
        }
        #expect(await persistence.read() == .valid(state))

        var corrupt = encrypted
        corrupt[corrupt.index(before: corrupt.endIndex)] ^= 0x01
        try corrupt.write(to: fileURL, options: .atomic)
        #expect(await persistence.read() == .invalid)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_800_000_000)
    }

    private func laterDate(days: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(byAdding: .day, value: days, to: referenceDate)!
    }

    private func laterDate(seconds: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            byAdding: .second,
            value: seconds,
            to: referenceDate
        )!
    }

    private func makeClient(
        persistence: any TelemetryPersisting,
        transport: any TelemetryTransporting = UnavailableTelemetryTransport()
    ) throws -> TelemetryClient {
        TelemetryClient(
            persistence: persistence,
            transport: transport,
            environment: .development,
            appVersion: try TelemetryAppVersion("1.0.0"),
            policy: TelemetryPolicy(calendar: testCalendar)
        )
    }

    private var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makePersistedTelemetryState() -> TelemetryPersistedState {
        let identity = TelemetryIdentityGeneration(
            identifier: UUID(),
            createdAt: referenceDate,
            rotatesAt: laterDate(days: 30),
            deletionSecret: Data(repeating: 7, count: 32),
            deletionProofExpiresAt: nil
        )
        return TelemetryPersistedState(
            collectionEnabled: true,
            identities: [identity],
            queuedEvents: [
                TelemetryQueuedEvent(
                    id: UUID(),
                    identityIdentifier: identity.identifier,
                    occurredAt: referenceDate,
                    event: .receipt(.saved, .completed)
                )
            ],
            consecutiveFailures: 0,
            retryNotBefore: nil
        )
    }
}

private actor MemoryTelemetryPersistence: TelemetryPersisting {
    private(set) var currentState: TelemetryPersistedState?
    private(set) var writeCount = 0
    private(set) var deleteCount = 0
    private var readResult: TelemetryPersistenceRead?
    private var shouldFailNextWrite = false
    private var shouldFailNextDelete = false

    init(readResult: TelemetryPersistenceRead? = nil) {
        self.readResult = readResult
    }

    func read() -> TelemetryPersistenceRead {
        readResult ?? currentState.map(TelemetryPersistenceRead.valid) ?? .missing
    }

    func write(_ state: TelemetryPersistedState) throws {
        if shouldFailNextWrite {
            shouldFailNextWrite = false
            throw StubPersistenceError.failed
        }
        currentState = state
        writeCount += 1
    }

    func delete() throws {
        if shouldFailNextDelete {
            shouldFailNextDelete = false
            throw StubPersistenceError.failed
        }
        currentState = nil
        readResult = nil
        deleteCount += 1
    }

    func failNextWrite() {
        shouldFailNextWrite = true
    }

    func failNextDelete() {
        shouldFailNextDelete = true
    }
}

private actor GatedWriteTelemetryPersistence: TelemetryPersisting {
    private(set) var currentState: TelemetryPersistedState?
    private var shouldSuspendNextWrite = false
    private var writeStarted = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func read() -> TelemetryPersistenceRead {
        currentState.map(TelemetryPersistenceRead.valid) ?? .missing
    }

    func write(_ state: TelemetryPersistedState) async {
        if shouldSuspendNextWrite {
            shouldSuspendNextWrite = false
            writeStarted = true
            let waiters = startWaiters
            startWaiters.removeAll()
            waiters.forEach { $0.resume() }
            await withCheckedContinuation { continuation in
                releaseContinuation = continuation
            }
        }
        currentState = state
    }

    func delete() {
        currentState = nil
    }

    func suspendNextWrite() {
        shouldSuspendNextWrite = true
        writeStarted = false
    }

    func waitUntilWriteStarts() async {
        if writeStarted { return }
        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    func releaseWrite() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

private actor RecordingTelemetryTransport: TelemetryTransporting {
    private let uploadResolution: TelemetryTransportUploadResolution
    private var deleteFailuresRemaining: Int
    private(set) var uploads: [TelemetryUploadBatch] = []
    private(set) var deletions: [TelemetryDeletionRequest] = []

    init(
        uploadResolution: TelemetryTransportUploadResolution = .accepted,
        deleteFailuresRemaining: Int = 0
    ) {
        self.uploadResolution = uploadResolution
        self.deleteFailuresRemaining = deleteFailuresRemaining
    }

    func upload(_ batch: TelemetryUploadBatch) -> TelemetryTransportUploadResolution {
        uploads.append(batch)
        return uploadResolution
    }

    func delete(_ request: TelemetryDeletionRequest) throws {
        deletions.append(request)
        if deleteFailuresRemaining > 0 {
            deleteFailuresRemaining -= 1
            throw StubTransportError.failed
        }
    }
}

private actor GatedTelemetryTransport: TelemetryTransporting {
    private var entered = false
    private var entryWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?
    private(set) var uploadCount = 0

    func upload(_ batch: TelemetryUploadBatch) async -> TelemetryTransportUploadResolution {
        uploadCount += 1
        entered = true
        let waiters = entryWaiters
        entryWaiters.removeAll()
        waiters.forEach { $0.resume() }
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
        return .accepted
    }

    func delete(_ request: TelemetryDeletionRequest) {}

    func waitUntilUploadStarts() async {
        if entered { return }
        await withCheckedContinuation { continuation in
            entryWaiters.append(continuation)
        }
    }

    func releaseUpload() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

private struct FixedTelemetryKeyProvider: TelemetryAtRestKeyProviding {
    private let key = Data(SHA256.hash(data: Data("test-key".utf8)))

    func read() -> Data? { key }
    func createIfMissing() -> Data { key }
    func delete() {}
}

private final class TrackingTelemetryKeyProvider: TelemetryAtRestKeyProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var key: Data?

    init(
        startingKey: Data? = Data(SHA256.hash(data: Data("test-delete-key".utf8)))
    ) {
        key = startingKey
    }

    func read() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return key
    }

    func createIfMissing() -> Data {
        lock.lock()
        defer { lock.unlock() }
        if let key { return key }
        let replacement = Data(SHA256.hash(data: Data("replacement-delete-key".utf8)))
        key = replacement
        return replacement
    }

    func delete() {
        lock.lock()
        defer { lock.unlock() }
        key = nil
    }

    func containsKey() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return key != nil
    }
}

private enum StubTransportError: Error {
    case failed
}

private enum StubPersistenceError: Error {
    case failed
}
