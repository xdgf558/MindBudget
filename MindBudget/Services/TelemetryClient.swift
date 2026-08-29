import CryptoKit
import Foundation
import Security

enum TelemetryPersistenceRead: Equatable, Sendable {
    case missing
    case valid(TelemetryPersistedState)
    case invalid
}

protocol TelemetryPersisting: Sendable {
    func read() async -> TelemetryPersistenceRead
    func write(_ state: TelemetryPersistedState) async throws
    func delete() async throws
}

protocol TelemetryAtRestKeyProviding: Sendable {
    func read() throws -> Data?
    func createIfMissing() throws -> Data
    func delete() throws
}

struct KeychainTelemetryAtRestKeyProvider: TelemetryAtRestKeyProviding {
    private let service: String
    private let account: String

    init(
        service: String = "com.xdgf558.mindbudget.telemetry",
        account: String = "encrypted-queue-key-v1"
    ) {
        self.service = service
        self.account = account
    }

    func read() throws -> Data? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data, data.count == 32 else {
            throw TelemetryPersistenceError.keychain(status)
        }
        return data
    }

    func createIfMissing() throws -> Data {
        if let existing = try read() { return existing }
        let keyByteCount = 32
        var data = Data(count: keyByteCount)
        let status = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, keyByteCount, bytes.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw TelemetryPersistenceError.keychain(status)
        }
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus == errSecDuplicateItem, let existing = try read() {
            return existing
        }
        guard addStatus == errSecSuccess else {
            throw TelemetryPersistenceError.keychain(addStatus)
        }
        return data
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TelemetryPersistenceError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum TelemetryPersistenceError: Error, Equatable, Sendable {
    case invalidKey
    case invalidState
    case keychain(OSStatus)
    case oversized
    case readBackFailed
}

actor EncryptedFileTelemetryPersistence: TelemetryPersisting {
    private static let header = Data("MBTEL1".utf8)

    private let fileURL: URL
    private let keyProvider: any TelemetryAtRestKeyProviding
    private let fileManager: FileManager

    init(
        fileURL: URL,
        keyProvider: any TelemetryAtRestKeyProviding = KeychainTelemetryAtRestKeyProvider(),
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.keyProvider = keyProvider
        self.fileManager = fileManager
    }

    func read() -> TelemetryPersistenceRead {
        guard fileManager.fileExists(atPath: fileURL.path) else { return .missing }
        do {
            let encrypted = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
            guard encrypted.count <= TelemetryPolicy.maximumPersistenceBytes,
                  encrypted.starts(with: Self.header),
                  let keyData = try keyProvider.read(),
                  keyData.count == 32 else {
                return .invalid
            }
            let combined = encrypted.dropFirst(Self.header.count)
            let box = try AES.GCM.SealedBox(combined: combined)
            let plaintext = try AES.GCM.open(box, using: SymmetricKey(data: keyData))
            let state = try Self.decoder.decode(TelemetryPersistedState.self, from: plaintext)
            return Self.isStructurallyValid(state) ? .valid(state) : .invalid
        } catch {
            return .invalid
        }
    }

    func write(_ state: TelemetryPersistedState) throws {
        try Task.checkCancellation()
        guard Self.isStructurallyValid(state) else {
            throw TelemetryPersistenceError.invalidState
        }
        let plaintext = try Self.encoder.encode(state)
        guard plaintext.count <= TelemetryPolicy.maximumPersistenceBytes else {
            throw TelemetryPersistenceError.oversized
        }
        let keyData = try keyProvider.createIfMissing()
        guard keyData.count == 32 else { throw TelemetryPersistenceError.invalidKey }
        let box = try AES.GCM.seal(plaintext, using: SymmetricKey(data: keyData))
        guard let combined = box.combined else { throw TelemetryPersistenceError.invalidKey }
        let encrypted = Self.header + combined
        guard encrypted.count <= TelemetryPolicy.maximumPersistenceBytes else {
            throw TelemetryPersistenceError.oversized
        }

        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDirectory = directory
        try mutableDirectory.setResourceValues(values)
        try Task.checkCancellation()
        try encrypted.write(
            to: fileURL,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
        var mutableFile = fileURL
        try mutableFile.setResourceValues(values)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )

        guard case let .valid(readBack) = read(), readBack == state else {
            throw TelemetryPersistenceError.readBackFailed
        }
    }

    func delete() throws {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        try keyProvider.delete()
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    private static func isStructurallyValid(_ state: TelemetryPersistedState) -> Bool {
        guard state.queuedEvents.count <= TelemetryPolicy.maximumQueuedEvents,
              state.identities.count <= TelemetryPolicy.maximumIdentityGenerations,
              state.consecutiveFailures >= 0,
              state.identities.allSatisfy({ $0.deletionSecret.count == 32 }),
              Set(state.identities.map(\.identifier)).count == state.identities.count,
              Set(state.queuedEvents.map(\.id)).count == state.queuedEvents.count else {
            return false
        }
        let activeIdentityIndexes = state.identities.indices.filter {
            state.identities[$0].deletionProofExpiresAt == nil
        }
        if state.collectionEnabled {
            guard let currentIndex = state.identities.indices.last,
                  activeIdentityIndexes == [currentIndex] else {
                return false
            }
        } else if !activeIdentityIndexes.isEmpty {
            return false
        }
        let identityIDs = Set(state.identities.map(\.identifier))
        return state.queuedEvents.allSatisfy { identityIDs.contains($0.identityIdentifier) }
    }
}

enum TelemetryClientError: Error, Equatable, Sendable {
    case corruptPersistence
    case identityCapacityReached
    case invalidClock
    case unresolvedDeletion
}

actor TelemetryClient {
    private let persistence: any TelemetryPersisting
    private let transport: any TelemetryTransporting
    private let environment: TelemetryEnvironment
    private let appVersion: TelemetryAppVersion
    private let policy: TelemetryPolicy

    private var state: TelemetryPersistedState?
    private var persistenceIsCorrupt = false
    private var stateMutationInProgress = false
    private var stateMutationWaiters: [CheckedContinuation<Void, Never>] = []
    private var transportOperationInProgress = false
    private var transportOperationWaiters: [CheckedContinuation<Void, Never>] = []

    init(
        persistence: any TelemetryPersisting,
        transport: any TelemetryTransporting = UnavailableTelemetryTransport(),
        environment: TelemetryEnvironment,
        appVersion: TelemetryAppVersion,
        policy: TelemetryPolicy = TelemetryPolicy()
    ) {
        self.persistence = persistence
        self.transport = transport
        self.environment = environment
        self.appVersion = appVersion
        self.policy = policy
    }

    func snapshot() async -> TelemetryClientSnapshot {
        guard let state = await loadState() else { return .corrupt }
        return TelemetryClientSnapshot(
            collectionEnabled: state.collectionEnabled,
            queuedEventCount: state.queuedEvents.count,
            retainedIdentityCount: state.identities.count,
            retryNotBefore: state.retryNotBefore,
            availability: .available,
            terminalTransportFailure: state.terminalTransportFailure
        )
    }

    func setCollectionEnabled(_ enabled: Bool, now: Date) async throws {
        await acquireStateMutation()
        defer { releaseStateMutation() }
        try Task.checkCancellation()
        guard var state = await loadState() else { throw TelemetryClientError.corruptPersistence }
        if enabled {
            // A terminal failure on disabled state came from proof-authenticated Delete. Do not
            // create another identity or restart capture until the customer repeats Delete and
            // every recoverable proof has been removed.
            guard state.terminalTransportFailure == nil else {
                throw TelemetryClientError.unresolvedDeletion
            }
            pruneExpiredProofs(in: &state, now: now)
            state.collectionEnabled = true
            if state.identities.last?.deletionProofExpiresAt != nil || state.identities.isEmpty {
                try createIdentity(in: &state, now: now)
            }
        } else {
            // Missing state materializes only in memory. Repeating the default-off decision must
            // not create an encrypted file, Keychain key, identity, or persistence write.
            guard state.collectionEnabled else { return }
            // Opt-out asks the fixed transport to cancel an active request. Cancellation is
            // necessarily best-effort: an edge acceptance that won the race remains subject to
            // server TTL and explicit proof deletion, never a false recall claim.
            await transport.cancelInFlightUpload()
            try retireCurrentIdentityForOptOut(in: &state, now: now)
            state.collectionEnabled = false
            state.queuedEvents.removeAll()
            state.consecutiveFailures = 0
            state.retryNotBefore = nil
            state.terminalTransportFailure = nil
        }
        try await commit(state)
    }

    func capture(_ event: TelemetryEvent, at now: Date) async throws -> TelemetryCaptureResult {
        await acquireStateMutation()
        defer { releaseStateMutation() }
        try Task.checkCancellation()
        guard var state = await loadState() else { return .unavailable }
        guard state.collectionEnabled else { return .disabled }
        guard state.terminalTransportFailure == nil else { return .unavailable }
        try rotateIdentityIfNeeded(in: &state, now: now)
        guard let identity = state.identities.last else {
            throw TelemetryClientError.invalidClock
        }

        let droppedOldest = state.queuedEvents.count == TelemetryPolicy.maximumQueuedEvents
        if droppedOldest {
            state.queuedEvents.removeFirst()
        }
        state.queuedEvents.append(
            TelemetryQueuedEvent(
                id: UUID(),
                identityIdentifier: identity.identifier,
                occurredAt: now,
                event: event
            )
        )
        try await commit(state)
        return droppedOldest ? .queuedAfterDroppingOldest : .queued
    }

    func resetPseudonymousIdentity(now: Date) async throws {
        await acquireStateMutation()
        defer { releaseStateMutation() }
        try Task.checkCancellation()
        guard var state = await loadState() else { throw TelemetryClientError.corruptPersistence }
        guard state.collectionEnabled else { return }
        try retireCurrentIdentity(in: &state, now: now)
        try createIdentity(in: &state, now: now)
        try await commit(state)
    }

    func flush(now: Date) async -> TelemetryFlushResult {
        await acquireTransportOperation()
        defer { releaseTransportOperation() }
        await acquireStateMutation()
        if Task.isCancelled {
            releaseStateMutation()
            return .failed(nil)
        }
        guard let state = await loadState() else {
            releaseStateMutation()
            return .unavailable
        }
        guard state.collectionEnabled else {
            releaseStateMutation()
            return .disabled
        }
        if let failure = state.terminalTransportFailure {
            releaseStateMutation()
            return .terminalFailure(failure)
        }
        if let retryNotBefore = state.retryNotBefore, now < retryNotBefore {
            releaseStateMutation()
            return .deferred(retryNotBefore)
        }
        guard let first = state.queuedEvents.first,
              let identity = state.identities.first(where: {
                  $0.identifier == first.identityIdentifier
              }) else {
            releaseStateMutation()
            return .empty
        }

        let events = Array(
            state.queuedEvents
                .prefix { $0.identityIdentifier == identity.identifier }
                .prefix(TelemetryPolicy.maximumBatchEvents)
        )
        let batch = TelemetryUploadBatch(
            schemaVersion: TelemetryPolicy.schemaVersion,
            environment: environment,
            appVersion: appVersion,
            pseudonymousIdentifier: identity.identifier,
            deletionHandle: identity.deletionHandle,
            events: events
        )
        releaseStateMutation()

        let resolution: TelemetryTransportUploadResolution
        do {
            resolution = try await transport.upload(batch)
            try Task.checkCancellation()
        } catch is CancellationError {
            return .failed(nil)
        } catch {
            if let terminalFailure = (error as? any TelemetryTerminalFailureProviding)?
                .telemetryTerminalFailure {
                return await recordTerminalTransportFailure(terminalFailure)
            }
            return await recordTransportFailure(now: now)
        }

        await acquireStateMutation()
        defer { releaseStateMutation() }
        guard var current = self.state, current.collectionEnabled else { return .disabled }
        let eventIDs = Set(events.map(\.id))
        let result: TelemetryFlushResult
        switch resolution {
        case .accepted:
            current.queuedEvents.removeAll { eventIDs.contains($0.id) }
            current.consecutiveFailures = 0
            current.retryNotBefore = nil
            current.terminalTransportFailure = nil
            result = .accepted(events.count)
        case .rejected:
            current.queuedEvents.removeAll { eventIDs.contains($0.id) }
            current.consecutiveFailures = 0
            current.retryNotBefore = nil
            current.terminalTransportFailure = nil
            result = .rejected(events.count)
        case let .retryAfter(seconds):
            current.consecutiveFailures += 1
            let bounded = min(max(seconds, 60), TelemetryPolicy.maximumRetryDelaySeconds)
            current.retryNotBefore = policy.calendar.date(
                byAdding: .second,
                value: bounded,
                to: now
            )
            result = .failed(current.retryNotBefore)
        }
        do {
            try await commit(current)
            return result
        } catch is CancellationError {
            return .failed(nil)
        } catch {
            // The transport resolution happened, but local acknowledgement/backoff did not
            // commit. Do not relabel this as a network failure or persist a transport retry.
            return .persistenceFailed
        }
    }

    func deleteAllTelemetry(now: Date) async -> TelemetryDeletionResult {
        await acquireTransportOperation()
        defer { releaseTransportOperation() }
        await acquireStateMutation()
        defer { releaseStateMutation() }
        if Task.isCancelled { return .failed(nil) }
        guard var state = await loadState() else {
            // Collection and mutation remain sticky fail-closed after corrupt persistence, but
            // local deletion must stay available. The unreadable file cannot supply authenticated
            // remote proofs, so this result deliberately makes no remote-deletion claim.
            do {
                try await persistence.delete()
                self.state = .disabled
                persistenceIsCorrupt = false
                return .deletedLocallyWithoutRemoteProofs
            } catch {
                return .failed(nil)
            }
        }

        // Delete is also an immediate opt-out. Persist that privacy-safe state before making the
        // remote request so cancellation, termination, or a transport failure cannot resume
        // capture or preserve an unsent event. Every remaining identity is retained only as a
        // bounded deletion proof until the remote delete is confirmed.
        do {
            try retireCurrentIdentityForOptOut(in: &state, now: now)
        } catch {
            return .failed(nil)
        }
        state.collectionEnabled = false
        state.queuedEvents.removeAll()
        state.consecutiveFailures = 0
        state.retryNotBefore = nil
        state.terminalTransportFailure = nil
        pruneExpiredProofs(in: &state, now: now)

        guard !state.identities.isEmpty else {
            do {
                try await persistence.delete()
                self.state = .disabled
                return .deletedLocally
            } catch {
                return .failed(nil)
            }
        }
        do {
            try await commit(state)
        } catch {
            return .failed(nil)
        }
        let request = TelemetryDeletionRequest(
            schemaVersion: TelemetryPolicy.schemaVersion,
            environment: environment,
            proofs: state.identities.map {
                TelemetryDeletionProof(
                    pseudonymousIdentifier: $0.identifier,
                    deletionSecret: $0.deletionSecret
                )
            }
        )
        do {
            try await transport.delete(request)
            try Task.checkCancellation()
            try await persistence.delete()
            self.state = .disabled
            return .deletedRemotely
        } catch is CancellationError {
            return .failed(nil)
        } catch {
            if let terminalFailure = (error as? any TelemetryTerminalFailureProviding)?
                .telemetryTerminalFailure {
                state.terminalTransportFailure = terminalFailure
                state.retryNotBefore = nil
                state.consecutiveFailures = 0
                do {
                    try await commit(state)
                    return .terminalFailure(terminalFailure)
                } catch {
                    // A sticky terminal result is truthful only after it is durable. Preserve
                    // the in-memory and persisted proofs and report an unclassified failure when
                    // that commit cannot be established.
                    return .failed(nil)
                }
            }
            state.consecutiveFailures += 1
            state.retryNotBefore = policy.retryDate(
                after: now,
                consecutiveFailures: state.consecutiveFailures
            )
            try? await commit(state)
            return .failed(state.retryNotBefore)
        }
    }

    /// A customer retry is the only operation that clears a sticky upload-policy failure.
    /// A failed Delete remains disabled and is retried through the explicit Delete action so the
    /// client never confuses an upload retry with proof-authenticated deletion.
    func retryTerminalTransport(now: Date) async -> TelemetryFlushResult {
        await acquireStateMutation()
        guard var state = await loadState() else {
            releaseStateMutation()
            return .unavailable
        }
        guard state.collectionEnabled else {
            releaseStateMutation()
            return .disabled
        }
        state.terminalTransportFailure = nil
        state.retryNotBefore = nil
        state.consecutiveFailures = 0
        do {
            try await commit(state)
        } catch {
            releaseStateMutation()
            return .persistenceFailed
        }
        releaseStateMutation()
        return await flush(now: now)
    }

    private func loadState() async -> TelemetryPersistedState? {
        if persistenceIsCorrupt { return nil }
        if let state { return state }
        switch await persistence.read() {
        case .missing:
            state = .disabled
        case let .valid(stored):
            state = stored
        case .invalid:
            persistenceIsCorrupt = true
            return nil
        }
        return state
    }

    private func recordTransportFailure(now: Date) async -> TelemetryFlushResult {
        await acquireStateMutation()
        defer { releaseStateMutation() }
        guard var current = self.state, current.collectionEnabled else { return .disabled }
        current.consecutiveFailures += 1
        current.retryNotBefore = policy.retryDate(
            after: now,
            consecutiveFailures: current.consecutiveFailures
        )
        do {
            try await commit(current)
            return .failed(current.retryNotBefore)
        } catch is CancellationError {
            return .failed(nil)
        } catch {
            return .persistenceFailed
        }
    }

    private func recordTerminalTransportFailure(
        _ failure: TelemetryTerminalFailure
    ) async -> TelemetryFlushResult {
        await acquireStateMutation()
        defer { releaseStateMutation() }
        guard var current = self.state, current.collectionEnabled else { return .disabled }
        current.terminalTransportFailure = failure
        current.consecutiveFailures = 0
        current.retryNotBefore = nil
        do {
            try await commit(current)
            return .terminalFailure(failure)
        } catch is CancellationError {
            return .failed(nil)
        } catch {
            return .persistenceFailed
        }
    }

    private func commit(_ state: TelemetryPersistedState) async throws {
        guard !persistenceIsCorrupt else { throw TelemetryClientError.corruptPersistence }
        try await persistence.write(state)
        self.state = state
    }

    /// Serializes each local read/modify/write transaction while still allowing capture to proceed
    /// during an in-flight network upload. This is the combined state-machine invariant: no two
    /// mutations may derive from the same persisted generation and overwrite one another.
    private func acquireStateMutation() async {
        if !stateMutationInProgress {
            stateMutationInProgress = true
            return
        }
        await withCheckedContinuation { continuation in
            stateMutationWaiters.append(continuation)
        }
    }

    private func releaseStateMutation() {
        guard !stateMutationWaiters.isEmpty else {
            stateMutationInProgress = false
            return
        }
        stateMutationWaiters.removeFirst().resume()
    }

    /// Allows capture to continue during upload while preventing duplicate concurrent flushes and
    /// ensuring remote deletion is ordered after every older upload. Without this independent
    /// transport lane, a late upload could recreate data after a deletion request had succeeded.
    private func acquireTransportOperation() async {
        if !transportOperationInProgress {
            transportOperationInProgress = true
            return
        }
        await withCheckedContinuation { continuation in
            transportOperationWaiters.append(continuation)
        }
    }

    private func releaseTransportOperation() {
        guard !transportOperationWaiters.isEmpty else {
            transportOperationInProgress = false
            return
        }
        transportOperationWaiters.removeFirst().resume()
    }

    private func rotateIdentityIfNeeded(
        in state: inout TelemetryPersistedState,
        now: Date
    ) throws {
        guard let current = state.identities.last else {
            try createIdentity(in: &state, now: now)
            return
        }
        guard now >= current.rotatesAt else { return }
        try retireCurrentIdentity(in: &state, now: now)
        try createIdentity(in: &state, now: now)
    }

    private func retireCurrentIdentity(
        in state: inout TelemetryPersistedState,
        now: Date
    ) throws {
        pruneExpiredProofs(in: &state, now: now)
        guard !state.identities.isEmpty else { return }
        guard let expiration = policy.deletionProofExpirationDate(after: now) else {
            throw TelemetryClientError.invalidClock
        }
        state.identities[state.identities.count - 1].deletionProofExpiresAt = expiration
    }

    private func retireCurrentIdentityForOptOut(
        in state: inout TelemetryPersistedState,
        now: Date
    ) throws {
        pruneExpiredProofs(in: &state, now: now)
        guard let current = state.identities.last,
              current.deletionProofExpiresAt == nil else { return }
        guard let expiration = policy.deletionProofExpirationDate(after: now) else {
            throw TelemetryClientError.invalidClock
        }
        state.identities[state.identities.count - 1].deletionProofExpiresAt = expiration
    }

    private func createIdentity(
        in state: inout TelemetryPersistedState,
        now: Date
    ) throws {
        guard state.identities.count < TelemetryPolicy.maximumIdentityGenerations else {
            throw TelemetryClientError.identityCapacityReached
        }
        guard let rotatesAt = policy.identityRotationDate(after: now) else {
            throw TelemetryClientError.invalidClock
        }
        let secretByteCount = 32
        var secret = Data(count: secretByteCount)
        let status = secret.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, secretByteCount, bytes.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw TelemetryPersistenceError.keychain(status)
        }
        state.identities.append(
            TelemetryIdentityGeneration(
                identifier: UUID(),
                createdAt: now,
                rotatesAt: rotatesAt,
                deletionSecret: secret,
                deletionProofExpiresAt: nil
            )
        )
    }

    private func pruneExpiredProofs(
        in state: inout TelemetryPersistedState,
        now: Date
    ) {
        let queuedIdentityIDs = Set(state.queuedEvents.map(\.identityIdentifier))
        state.identities.removeAll { identity in
            guard let expiresAt = identity.deletionProofExpiresAt else { return false }
            return expiresAt <= now && !queuedIdentityIDs.contains(identity.identifier)
        }
    }
}

@MainActor
protocol TelemetryServicing: AnyObject, Sendable {
    var snapshot: TelemetryClientSnapshot { get }
    var onSnapshotChange: (@MainActor @Sendable (TelemetryClientSnapshot) -> Void)? { get set }

    func start() async
    func setCollectionEnabled(_ enabled: Bool) async -> Bool
    func capture(_ event: TelemetryEvent) async -> TelemetryCaptureResult
    func retryTerminalFailure() async
    func sceneDidBecomeActive() async
    func deleteAllTelemetry() async -> TelemetryDeletionResult
    func stop()
}

@MainActor
final class TelemetryService: TelemetryServicing {
    private let client: TelemetryClient
    private var hasStarted = false
    private var drainTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?

    private(set) var snapshot = TelemetryClientSnapshot(
        collectionEnabled: false,
        queuedEventCount: 0,
        retainedIdentityCount: 0,
        retryNotBefore: nil,
        availability: .available
    )
    var onSnapshotChange: (@MainActor @Sendable (TelemetryClientSnapshot) -> Void)?

    init(client: TelemetryClient) {
        self.client = client
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        defer {
            if Task.isCancelled {
                hasStarted = false
            }
        }
        await publishSnapshot()
        guard !Task.isCancelled else { return }
        guard snapshot.collectionEnabled else { return }
        _ = await capture(.appSessionStarted)
    }

    func setCollectionEnabled(_ enabled: Bool) async -> Bool {
        do {
            try await client.setCollectionEnabled(enabled, now: Date())
            if !enabled {
                drainTask?.cancel()
                retryTask?.cancel()
            }
            await publishSnapshot()
            if enabled {
                _ = await capture(.appSessionStarted)
            }
            return true
        } catch {
            await publishSnapshot()
            return false
        }
    }

    func capture(_ event: TelemetryEvent) async -> TelemetryCaptureResult {
        do {
            let result = try await client.capture(event, at: Date())
            await publishSnapshot()
            if result == .queued || result == .queuedAfterDroppingOldest {
                beginDrain()
            }
            return result
        } catch {
            await publishSnapshot()
            return .unavailable
        }
    }

    func retryTerminalFailure() async {
        drainTask?.cancel()
        retryTask?.cancel()
        let result = await client.retryTerminalTransport(now: Date())
        await publishSnapshot()
        await handleFlushResult(result)
    }

    func sceneDidBecomeActive() async {
        await publishSnapshot()
        guard snapshot.collectionEnabled,
              snapshot.terminalTransportFailure == nil else { return }
        beginDrain()
    }

    func deleteAllTelemetry() async -> TelemetryDeletionResult {
        drainTask?.cancel()
        retryTask?.cancel()
        let result = await client.deleteAllTelemetry(now: Date())
        await publishSnapshot()
        return result
    }

    func stop() {
        drainTask?.cancel()
        retryTask?.cancel()
        drainTask = nil
        retryTask = nil
    }

    private func beginDrain() {
        guard drainTask == nil else { return }
        drainTask = Task { [weak self] in
            await self?.drainQueuedEvents()
        }
    }

    private func drainQueuedEvents() async {
        defer { drainTask = nil }
        // The persisted queue is bounded at 256 and batches at 20. Fourteen passes drain any
        // reachable snapshot while preventing an accidental unbounded network loop.
        for _ in 0..<14 {
            guard !Task.isCancelled else { return }
            let result = await client.flush(now: Date())
            await publishSnapshot()
            switch result {
            case .accepted, .rejected:
                continue
            default:
                await handleFlushResult(result)
                return
            }
        }
    }

    private func handleFlushResult(_ result: TelemetryFlushResult) async {
        let retryDate: Date?
        switch result {
        case let .deferred(date), let .failed(date?):
            retryDate = date
        default:
            retryDate = nil
        }
        guard let retryDate else { return }
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            do {
                let delay = max(0, retryDate.timeIntervalSinceNow)
                try await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                self?.beginDrain()
            } catch {
                // Disable, deletion, replacement, and shutdown deliberately cancel retry.
            }
        }
    }

    private func publishSnapshot() async {
        snapshot = await client.snapshot()
        onSnapshotChange?(snapshot)
    }
}

@MainActor
final class UnavailableTelemetryService: TelemetryServicing {
    private(set) var snapshot = TelemetryClientSnapshot.unavailable
    var onSnapshotChange: (@MainActor @Sendable (TelemetryClientSnapshot) -> Void)?

    func start() async { onSnapshotChange?(snapshot) }
    func setCollectionEnabled(_ enabled: Bool) async -> Bool { false }
    func capture(_ event: TelemetryEvent) async -> TelemetryCaptureResult { .unavailable }
    func retryTerminalFailure() async {}
    func sceneDidBecomeActive() async { onSnapshotChange?(snapshot) }
    func deleteAllTelemetry() async -> TelemetryDeletionResult { .unavailable }
    func stop() {}
}

enum TelemetryServiceFactory {
    @MainActor
    static func live(
        applicationSupportURL: URL? = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first,
        rawVersion: String? = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
    ) -> any TelemetryServicing {
        guard let applicationSupportURL,
              let rawVersion,
              let appVersion = try? TelemetryAppVersion(rawVersion) else {
            // Optional telemetry construction can fail closed without ever preventing the local
            // budgeting app from launching. App-wide deletion still refuses to claim telemetry
            // cleanup while this unavailable state cannot authenticate any possible proofs.
            return UnavailableTelemetryService()
        }
        let environment = TelemetryEnvironment.current()
        let persistence = EncryptedFileTelemetryPersistence(
            fileURL: applicationSupportURL
                .appendingPathComponent("MindBudget/Telemetry", isDirectory: true)
                .appendingPathComponent("queue.v1", isDirectory: false)
        )
        let client = TelemetryClient(
            persistence: persistence,
            transport: FixedTelemetryTransport(environment: environment),
            environment: environment,
            appVersion: appVersion
        )
        return TelemetryService(client: client)
    }
}
