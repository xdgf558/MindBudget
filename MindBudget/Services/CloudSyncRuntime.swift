import CloudKit
import CryptoKit
import Foundation

@MainActor
protocol CloudSyncServicing: AnyObject {
    var snapshot: CloudSyncSnapshot { get }
    var onSnapshotChange: (@MainActor @Sendable (CloudSyncSnapshot) -> Void)? { get set }

    func start() async
    func setEnabled(_ enabled: Bool) async
    func retry() async
    func sceneDidBecomeActive() async
    func stop() async
}

@MainActor
final class CloudSyncService: CloudSyncServicing {
    typealias AdapterFactory = @MainActor @Sendable (DataActor) -> any CloudSyncEngineAdapting

    private let dataActor: DataActor
    private let adapterFactory: AdapterFactory
    private var adapter: (any CloudSyncEngineAdapting)?
    private var adapterOperationTask: Task<Void, Never>?
    private var adapterOperationToken: UUID?
    private var localChangeTask: Task<Void, Never>?
    private var remoteApplicationTask: Task<Void, Never>?

    private(set) var snapshot: CloudSyncSnapshot = .disabled
    var onSnapshotChange: (@MainActor @Sendable (CloudSyncSnapshot) -> Void)?

    init(
        dataActor: DataActor,
        adapterFactory: @escaping AdapterFactory = { CKSyncEngineAdapter(dataActor: $0) }
    ) {
        self.dataActor = dataActor
        self.adapterFactory = adapterFactory
    }

    deinit {
        adapterOperationTask?.cancel()
        localChangeTask?.cancel()
        remoteApplicationTask?.cancel()
    }

    func start() async {
        await reloadSnapshot()
        guard snapshot.isEnabled else { return }
        installSignalObserversIfNeeded()
        await synchronizeAdapterIfPermitted()
    }

    func setEnabled(_ enabled: Bool) async {
        do {
            snapshot = try await dataActor.setCloudSyncEnabled(enabled)
            publishSnapshot()
            if snapshot.isEnabled {
                installSignalObserversIfNeeded()
                await synchronizeAdapterIfPermitted()
            } else {
                await stopAdapter()
            }
        } catch {
            await publishFailure(.localValidationFailed)
        }
    }

    func retry() async {
        await reloadSnapshot()
        await synchronizeAdapterIfPermitted()
    }

    func sceneDidBecomeActive() async {
        await reloadSnapshot()
        await synchronizeAdapterIfPermitted()
    }

    func stop() async {
        localChangeTask?.cancel()
        localChangeTask = nil
        remoteApplicationTask?.cancel()
        remoteApplicationTask = nil
        await stopAdapter()
    }

    private func synchronizeAdapterIfPermitted() async {
        guard snapshot.permitsCloudTransport else { return }
        if let adapterOperationTask {
            await adapterOperationTask.value
            return
        }
        let token = UUID()
        adapterOperationToken = token
        let operation = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }
            if self.adapter == nil {
                let created = self.adapterFactory(self.dataActor)
                created.onStatusChange = { [weak self] in
                    guard let self else { return }
                    await self.reloadSnapshot()
                }
                self.adapter = created
                await created.start()
            } else {
                await self.adapter?.synchronize()
            }
            guard !Task.isCancelled else { return }
            await self.reloadSnapshot()
        }
        adapterOperationTask = operation
        await operation.value
        if adapterOperationToken == token {
            adapterOperationTask = nil
            adapterOperationToken = nil
        }
    }

    private func stopAdapter() async {
        adapterOperationTask?.cancel()
        adapterOperationTask = nil
        adapterOperationToken = nil
        await adapter?.stop()
        adapter = nil
    }

    private func installSignalObserversIfNeeded() {
        if localChangeTask == nil {
            localChangeTask = Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(
                    named: CloudSyncLocalChangeSignal.notification
                ) {
                    guard !Task.isCancelled, let self else { return }
                    await self.reloadSnapshot()
                    await self.synchronizeAdapterIfPermitted()
                }
            }
        }
        if remoteApplicationTask == nil {
            remoteApplicationTask = Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(
                    named: CloudSyncRemoteApplicationSignal.notification
                ) {
                    guard !Task.isCancelled, let self else { return }
                    await self.reloadSnapshot()
                }
            }
        }
    }

    private func reloadSnapshot() async {
        do {
            snapshot = try await dataActor.cloudSyncSnapshot()
            publishSnapshot()
        } catch {
            snapshot = CloudSyncSnapshot(
                isEnabled: snapshot.isEnabled,
                status: .failed,
                reason: .localValidationFailed,
                pendingCount: snapshot.pendingCount,
                quarantinedCount: snapshot.quarantinedCount
            )
            publishSnapshot()
        }
    }

    private func publishFailure(_ reason: CloudSyncReasonCode) async {
        try? await dataActor.updateCloudSyncStatus(.failed, reason: reason)
        await reloadSnapshot()
    }

    private func publishSnapshot() {
        onSnapshotChange?(snapshot)
    }
}

private extension CloudSyncSnapshot {
    var permitsCloudTransport: Bool {
        guard isEnabled else { return false }
        switch status {
        case .pausedAccountChanged, .pausedEncryptedDataReset, .pausedRemoteZoneDeleted:
            return false
        case .disabled, .starting, .ready, .syncing, .waitingForNetwork,
             .accountUnavailable, .quotaExceeded, .failed:
            return true
        }
    }
}

@MainActor
protocol CloudSyncEngineAdapting: AnyObject {
    var onStatusChange: (@MainActor @Sendable () async -> Void)? { get set }
    func start() async
    func synchronize() async
    func stop() async
}

@available(iOS 17.0, *)
final class CKSyncEngineAdapter: NSObject, CloudSyncEngineAdapting, CKSyncEngineDelegate, @unchecked Sendable {
    nonisolated static let containerIdentifier = "iCloud.com.xdgf558.MindBudget"
    nonisolated static let zoneName = "MindBudget.Sync.v1"
    nonisolated static let recordType = "MindBudgetEnvelopeV1"
    nonisolated static let subscriptionID = "MindBudget.Sync.v1.subscription"
    nonisolated static let encryptedEnvelopeKey = "envelope"

    private let dataActor: DataActor
    private let container: CKContainer
    private let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    private let lifecycle = CKSyncEngineAdapterLifecycle()

    @MainActor var onStatusChange: (@MainActor @Sendable () async -> Void)?

    @MainActor
    init(dataActor: DataActor, container: CKContainer? = nil) {
        self.dataActor = dataActor
        self.container = container ?? CKContainer(identifier: Self.containerIdentifier)
        super.init()
    }

    @MainActor
    func start() async {
        guard await establishAccountAuthority() else { return }
        do {
            let serialization = try await dataActor.cloudSyncEngineStateData().flatMap {
                try JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: $0)
            }
            var configuration = CKSyncEngine.Configuration(
                database: container.privateCloudDatabase,
                stateSerialization: serialization,
                delegate: self
            )
            configuration.automaticallySync = false
            configuration.subscriptionID = Self.subscriptionID
            let engine = CKSyncEngine(configuration)
            await lifecycle.setEngine(engine)
            engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zoneID))])
            try await addPendingOutboxChanges(to: engine)
            try await dataActor.updateCloudSyncStatus(.syncing, reason: nil)
            await notifyStatusChange()
            // A new engine may still need to create its custom zone. Send database changes before
            // the first fetch so a zone-not-found response cannot prevent that creation forever.
            try await engine.sendChanges()
            try await engine.fetchChanges()
            try await dataActor.completeCloudSyncPass()
        } catch {
            await handle(error)
        }
        await notifyStatusChange()
    }

    @MainActor
    func synchronize() async {
        guard await establishAccountAuthority() else {
            if let engine = await lifecycle.engine { await engine.cancelOperations() }
            await lifecycle.setEngine(nil)
            return
        }
        guard let engine = await lifecycle.engine else {
            await start()
            return
        }
        do {
            try await addPendingOutboxChanges(to: engine)
            try await dataActor.updateCloudSyncStatus(.syncing, reason: nil)
            await notifyStatusChange()
            try await engine.fetchChanges()
            try await engine.sendChanges()
            try await dataActor.completeCloudSyncPass()
        } catch {
            await handle(error)
        }
        await notifyStatusChange()
    }

    @MainActor
    func stop() async {
        if let engine = await lifecycle.engine { await engine.cancelOperations() }
        await lifecycle.setEngine(nil)
    }

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        do {
            switch event {
            case .stateUpdate(let update):
                let data = try JSONEncoder().encode(update.stateSerialization)
                try await dataActor.saveCloudSyncEngineState(data)
            case .accountChange(let change):
                try await handleAccountChange(change, syncEngine: syncEngine)
            case .fetchedDatabaseChanges(let changes):
                let deletionReasons = changes.deletions
                    .filter { $0.zoneID == zoneID }
                    .map(\.reason)
                if let pause = Self.databaseDeletionPause(for: deletionReasons) {
                    try await dataActor.updateCloudSyncStatus(
                        pause.status,
                        reason: pause.reason
                    )
                    await syncEngine.cancelOperations()
                    await lifecycle.setEngine(nil)
                }
            case .fetchedRecordZoneChanges(let changes):
                try await ingest(changes)
            case .sentRecordZoneChanges(let changes):
                try await acknowledge(changes, syncEngine: syncEngine)
            case .sentDatabaseChanges(let changes):
                for failure in changes.failedZoneSaves {
                    await handle(failure.error)
                }
            case .didFetchRecordZoneChanges(let event):
                if let error = event.error { await handle(error) }
            case .willFetchChanges, .willFetchRecordZoneChanges, .didFetchChanges,
                 .willSendChanges, .didSendChanges:
                break
            @unknown default:
                try await dataActor.updateCloudSyncStatus(.failed, reason: .transportFailed)
            }
        } catch {
            await handle(error)
        }
        await notifyStatusChange()
    }

    /// A missing private zone is destructive external state, not an empty sync target. C4B-03
    /// owns any explicit cloud-delete/recovery choice; C4B-02 must never recreate and repopulate it
    /// automatically. Encrypted-key reset remains distinguishable because its recovery semantics
    /// are different even though both outcomes stop transport.
    nonisolated static func databaseDeletionPause(
        for reasons: [CKDatabase.DatabaseChange.Deletion.Reason]
    ) -> (status: CloudSyncStatus, reason: CloudSyncReasonCode)? {
        if reasons.contains(.encryptedDataReset) {
            return (.pausedEncryptedDataReset, .encryptedDataReset)
        }
        if reasons.contains(.deleted) || reasons.contains(.purged) {
            return (.pausedRemoteZoneDeleted, .remoteZoneDeleted)
        }
        return nil
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { [dataActor, zoneID] recordID in
            guard recordID.zoneID == zoneID,
                  let pending = try? await dataActor.pendingCloudSyncRecord(named: recordID.recordName) else {
                return nil
            }
            let record = Self.decodeSystemFields(pending.encodedSystemFields)
                ?? CKRecord(recordType: Self.recordType, recordID: recordID)
            guard record.recordID == recordID, record.recordType == Self.recordType else { return nil }
            record.encryptedValues[Self.encryptedEnvelopeKey] = pending.envelopeData as CKRecordValue
            return record
        }
    }

    func nextFetchChangesOptions(
        _ context: CKSyncEngine.FetchChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.FetchChangesOptions {
        var options = CKSyncEngine.FetchChangesOptions()
        options.scope = .zoneIDs([zoneID])
        return options
    }

    private func establishAccountAuthority() async -> Bool {
        do {
            guard try await container.accountStatus() == .available else {
                try await dataActor.updateCloudSyncStatus(.accountUnavailable, reason: .noAccount)
                await notifyStatusChange()
                return false
            }
            let userRecordID = try await container.userRecordID()
            let identifierHash = CloudSyncCodec.digestHex(Data(userRecordID.recordName.utf8))
            let accepted = try await dataActor.bindCloudSyncAccount(identifierHash: identifierHash)
            if !accepted { await notifyStatusChange() }
            return accepted
        } catch {
            await handle(error)
            return false
        }
    }

    private func addPendingOutboxChanges(to engine: CKSyncEngine) async throws {
        let names = try await dataActor.pendingCloudSyncRecordNames()
        let existing = Set(engine.state.pendingRecordZoneChanges.compactMap { change -> CKRecord.ID? in
            if case .saveRecord(let id) = change { return id }
            return nil
        })
        let additions = names.map { CKRecord.ID(recordName: $0, zoneID: zoneID) }
            .filter { !existing.contains($0) }
            .map(CKSyncEngine.PendingRecordZoneChange.saveRecord)
        if !additions.isEmpty { engine.state.add(pendingRecordZoneChanges: additions) }
    }

    private func ingest(_ event: CKSyncEngine.Event.FetchedRecordZoneChanges) async throws {
        var records: [CloudSyncRemoteRecord] = []
        for change in event.modifications {
            let record = change.record
            guard record.recordID.zoneID == zoneID,
                  record.recordType == Self.recordType,
                  let data = record.encryptedValues[Self.encryptedEnvelopeKey] as? Data else {
                records.append(
                    CloudSyncRemoteRecord(
                        recordName: record.recordID.recordName,
                        envelopeData: nil,
                        encodedSystemFields: Self.encodeSystemFields(record),
                        wasPhysicallyDeleted: false
                    )
                )
                continue
            }
            records.append(
                CloudSyncRemoteRecord(
                    recordName: record.recordID.recordName,
                    envelopeData: data,
                    encodedSystemFields: Self.encodeSystemFields(record),
                    wasPhysicallyDeleted: false
                )
            )
        }
        for deletion in event.deletions where deletion.recordID.zoneID == zoneID {
            records.append(
                CloudSyncRemoteRecord(
                    recordName: deletion.recordID.recordName,
                    envelopeData: nil,
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: true
                )
            )
        }
        if !records.isEmpty { try await dataActor.ingestCloudSyncRecords(records) }
    }

    private func acknowledge(
        _ event: CKSyncEngine.Event.SentRecordZoneChanges,
        syncEngine: CKSyncEngine
    ) async throws {
        for record in event.savedRecords where record.recordID.zoneID == zoneID {
            guard let fields = Self.encodeSystemFields(record) else { continue }
            try await dataActor.acknowledgeCloudSyncRecord(
                recordName: record.recordID.recordName,
                encodedSystemFields: fields
            )
        }
        for failure in event.failedRecordSaves where failure.record.recordID.zoneID == zoneID {
            if failure.error.code == .serverRecordChanged {
                syncEngine.state.remove(
                    pendingRecordZoneChanges: [.saveRecord(failure.record.recordID)]
                )
                try await quarantineServerRecordConflict(failure)
            } else {
                await handle(failure.error)
            }
        }
    }

    private func quarantineServerRecordConflict(
        _ failure: CKSyncEngine.Event.SentRecordZoneChanges.FailedRecordSave
    ) async throws {
        let recordName = failure.record.recordID.recordName
        try await dataActor.blockCloudSyncRecordAfterServerConflict(recordName: recordName)
        let server = failure.error.serverRecord
        let remote: CloudSyncRemoteRecord
        if let server,
           server.recordID.zoneID == zoneID,
           server.recordID.recordName == recordName,
           server.recordType == Self.recordType,
           let data = server.encryptedValues[Self.encryptedEnvelopeKey] as? Data {
            remote = CloudSyncRemoteRecord(
                recordName: recordName,
                envelopeData: data,
                encodedSystemFields: Self.encodeSystemFields(server),
                wasPhysicallyDeleted: false
            )
        } else {
            // Preserve a durable, content-free quarantine even if CloudKit did not provide a
            // usable server record. The local outbox remains blocked for explicit review.
            remote = CloudSyncRemoteRecord(
                recordName: recordName,
                envelopeData: nil,
                encodedSystemFields: nil,
                wasPhysicallyDeleted: false
            )
        }
        try await dataActor.ingestCloudSyncRecords([remote])
    }

    private func handleAccountChange(
        _ event: CKSyncEngine.Event.AccountChange,
        syncEngine: CKSyncEngine
    ) async throws {
        let accepted: Bool
        switch event.changeType {
        case .signIn(let currentUser):
            accepted = try await dataActor.bindCloudSyncAccount(
                identifierHash: CloudSyncCodec.digestHex(Data(currentUser.recordName.utf8))
            )
        case .signOut:
            try await dataActor.updateCloudSyncStatus(.accountUnavailable, reason: .noAccount)
            accepted = false
        case .switchAccounts(_, let currentUser):
            accepted = try await dataActor.bindCloudSyncAccount(
                identifierHash: CloudSyncCodec.digestHex(Data(currentUser.recordName.utf8))
            )
        @unknown default:
            try await dataActor.updateCloudSyncStatus(.failed, reason: .transportFailed)
            accepted = false
        }
        if !accepted {
            await syncEngine.cancelOperations()
            await lifecycle.setEngine(nil)
        }
    }

    private func handle(_ error: Error) async {
        let resolution = Self.statusResolution(for: error)
        try? await dataActor.updateCloudSyncStatus(resolution.status, reason: resolution.reason)
        if resolution.status.isStickyPause {
            if let engine = await lifecycle.engine { await engine.cancelOperations() }
            await lifecycle.setEngine(nil)
        }
    }

    /// CloudKit may report a destructive encrypted-key reset as `zoneNotFound` plus
    /// `CKErrorUserDidResetEncryptedDataKey`, rather than as a database-deletion event. Preserve
    /// that distinction and treat every other missing accepted zone as remote zone loss. Both
    /// outcomes are sticky and therefore cannot flow through the ordinary retry path.
    nonisolated static func statusResolution(
        for error: Error
    ) -> (status: CloudSyncStatus, reason: CloudSyncReasonCode) {
        guard let cloudError = error as? CKError else { return (.failed, .transportFailed) }
        let didResetEncryptedDataKey =
            (cloudError.userInfo[CKErrorUserDidResetEncryptedDataKey] as? NSNumber)?.boolValue == true
        return statusResolution(
            for: cloudError.code,
            userDidResetEncryptedDataKey: didResetEncryptedDataKey
        )
    }

    /// Closed non-content mapping used by the adapter and deterministic tests. Raw CloudKit
    /// messages never cross into UI or analytics.
    nonisolated static func statusResolution(
        for code: CKError.Code,
        userDidResetEncryptedDataKey: Bool = false
    ) -> (status: CloudSyncStatus, reason: CloudSyncReasonCode) {
        if code == .zoneNotFound {
            return userDidResetEncryptedDataKey
                ? (.pausedEncryptedDataReset, .encryptedDataReset)
                : (.pausedRemoteZoneDeleted, .remoteZoneDeleted)
        }
        switch code {
        case .notAuthenticated: return (.accountUnavailable, .noAccount)
        case .networkFailure, .networkUnavailable: return (.waitingForNetwork, .networkUnavailable)
        case .quotaExceeded: return (.quotaExceeded, .quotaExceeded)
        case .serviceUnavailable, .requestRateLimited: return (.waitingForNetwork, .serviceUnavailable)
        default: return (.failed, .transportFailed)
        }
    }

    private func notifyStatusChange() async {
        await onStatusChange?()
    }

    nonisolated private static func encodeSystemFields(_ record: CKRecord) -> Data? {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: archiver)
        archiver.finishEncoding()
        return archiver.encodedData
    }

    nonisolated private static func decodeSystemFields(_ data: Data?) -> CKRecord? {
        guard let data else { return nil }
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
            defer { unarchiver.finishDecoding() }
            return CKRecord(coder: unarchiver)
        } catch {
            return nil
        }
    }
}

private actor CKSyncEngineAdapterLifecycle {
    var engine: CKSyncEngine?

    func setEngine(_ engine: CKSyncEngine?) {
        self.engine = engine
    }
}
