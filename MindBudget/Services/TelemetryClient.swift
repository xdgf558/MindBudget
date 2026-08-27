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
            availability: .available
        )
    }

    func setCollectionEnabled(_ enabled: Bool, now: Date) async throws {
        await acquireStateMutation()
        defer { releaseStateMutation() }
        try Task.checkCancellation()
        guard var state = await loadState() else { throw TelemetryClientError.corruptPersistence }
        if enabled {
            pruneExpiredProofs(in: &state, now: now)
            state.collectionEnabled = true
            if state.identities.last?.deletionProofExpiresAt != nil || state.identities.isEmpty {
                try createIdentity(in: &state, now: now)
            }
        } else {
            // Missing state materializes only in memory. Repeating the default-off decision must
            // not create an encrypted file, Keychain key, identity, or persistence write.
            guard state.collectionEnabled else { return }
            try retireCurrentIdentityForOptOut(in: &state, now: now)
            state.collectionEnabled = false
            state.queuedEvents.removeAll()
            state.consecutiveFailures = 0
            state.retryNotBefore = nil
        }
        try await commit(state)
    }

    func capture(_ event: TelemetryEvent, at now: Date) async throws -> TelemetryCaptureResult {
        await acquireStateMutation()
        defer { releaseStateMutation() }
        try Task.checkCancellation()
        guard var state = await loadState() else { return .unavailable }
        guard state.collectionEnabled else { return .disabled }
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
            result = .accepted(events.count)
        case .rejected:
            current.queuedEvents.removeAll { eventIDs.contains($0.id) }
            current.consecutiveFailures = 0
            current.retryNotBefore = nil
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
        guard !state.identities.isEmpty else {
            do {
                try await persistence.delete()
                self.state = .disabled
                return .deletedLocally
            } catch {
                return .failed(nil)
            }
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
            state.consecutiveFailures += 1
            state.retryNotBefore = policy.retryDate(
                after: now,
                consecutiveFailures: state.consecutiveFailures
            )
            try? await commit(state)
            return .failed(state.retryNotBefore)
        }
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
