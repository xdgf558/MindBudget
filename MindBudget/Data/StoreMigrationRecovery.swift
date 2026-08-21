import CryptoKit
import Foundation

/// App-owned pre-open checkpointing for a SwiftData store. It deliberately knows nothing about
/// SwiftData's private metadata: our durable marker is the only fast-path trust signal.
struct StoreMigrationRecoveryCoordinator: @unchecked Sendable {
    static let currentTarget = "mindbudget-schema-v6"

    enum RecoveryError: Error, Equatable, Sendable {
        case unreadableJournal
        case unreadableManifest
        case backupIntegrityMismatch
        case unsupportedJournalState
    }

    enum JournalState: String, Codable, Sendable {
        case prepared
        case migrating
        case validating
        case committed
        case restoring

        var isActive: Bool { self != .committed }
    }

    enum AnomalyReason: String, Codable, Sendable {
        case containerOpenFailed
        case inventoryRejected
        case restoreFailed
        case backupIntegrityMismatch
        case interruptedAttemptRestored
    }

    struct Attempt: Sendable {
        fileprivate let migrationID: UUID
    }

    private struct Marker: Codable {
        let formatVersion: Int
        let state: JournalState
        let target: String
    }

    private struct Artifact: Codable, Equatable {
        let name: String
        let isDirectory: Bool
        let byteCount: Int64
        let digest: Data
    }

    private struct Manifest: Codable {
        let formatVersion: Int
        let migrationID: UUID
        let artifacts: [Artifact]
    }

    private struct Journal: Codable {
        let formatVersion: Int
        let migrationID: UUID
        let sourceMarkerTarget: String?
        let target: String
        let backupDirectoryName: String
        let manifestFileName: String
        var state: JournalState
    }

    private let storeURL: URL
    private let fileManager: FileManager
    /// Internal deterministic fault seam for the C4A-03 recovery matrix. Production uses the
    /// default no-op; it exposes no user action and does not participate in recovery decisions.
    private let beforeRestoreArtifactCopy: @Sendable (String) throws -> Void

    init(
        storeURL: URL,
        fileManager: FileManager = .default,
        beforeRestoreArtifactCopy: @escaping @Sendable (String) throws -> Void = { _ in }
    ) {
        self.storeURL = storeURL
        self.fileManager = fileManager
        self.beforeRestoreArtifactCopy = beforeRestoreArtifactCopy
    }

    var hasExistingStore: Bool {
        fileManager.fileExists(atPath: storeURL.path)
    }

    /// Returns nil for a new store or a trusted committed marker. Every other existing-store
    /// state gets exactly one recoverable snapshot before opening the container.
    func prepareForOpen() throws -> Attempt? {
        try recoverInterruptedAttemptIfNeeded()
        try removeOrphanedBackups()
        guard fileManager.fileExists(atPath: storeURL.path) else { return nil }
        if try isTrustedCommittedMarker(for: Self.currentTarget) { return nil }

        let migrationID = UUID()
        let backupDirectory = recoveryRootURL.appendingPathComponent(migrationID.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        try applyProtection(to: backupDirectory)

        let artifacts = try snapshotLiveArtifacts(into: backupDirectory)
        let manifest = Manifest(formatVersion: 1, migrationID: migrationID, artifacts: artifacts)
        let manifestURL = backupDirectory.appendingPathComponent("manifest.json")
        try write(manifest, to: manifestURL)
        let journal = Journal(
            formatVersion: 1,
            migrationID: migrationID,
            sourceMarkerTarget: try committedMarkerTarget(),
            target: Self.currentTarget,
            backupDirectoryName: migrationID.uuidString,
            manifestFileName: "manifest.json",
            state: .prepared
        )
        try write(journal, to: journalURL)
        return Attempt(migrationID: migrationID)
    }

    func markMigrating(_ attempt: Attempt) throws {
        try transition(attempt, to: .migrating)
    }

    func markValidating(_ attempt: Attempt) throws {
        try transition(attempt, to: .validating)
    }

    func commit(_ attempt: Attempt) throws {
        let journal = try journal(for: attempt)
        guard journal.target == Self.currentTarget else { throw RecoveryError.unsupportedJournalState }
        try write(Marker(formatVersion: 1, state: .committed, target: Self.currentTarget), to: markerURL)
        try transition(attempt, to: .committed)
        // Once both durable records say committed, cleanup is no longer part of the migration
        // transaction. Treating a cleanup failure as a migration failure would make the caller
        // attempt to restore a backup that may already have been removed. A later cold start (or
        // Delete All) safely retries/removes these terminal artifacts.
        try? removeItemIfPresent(at: backupDirectory(for: journal))
        try? removeItemIfPresent(at: journalURL)
    }

    /// A genuinely new store has no source bytes to protect. It still receives the app-owned
    /// committed marker after its first successful open so later cold starts stay copy-free.
    func commitFreshOpen() throws {
        try write(Marker(formatVersion: 1, state: .committed, target: Self.currentTarget), to: markerURL)
    }

    /// Restores only a checksum-verified snapshot. A corrupt backup is never allowed to overwrite
    /// the current store; the caller receives a closed reason code instead.
    func restore(_ attempt: Attempt, reason: AnomalyReason) throws {
        do {
            try transition(attempt, to: .restoring)
            let journal = try journal(for: attempt)
            try restore(journal)
            try restoreSourceMarker(from: journal)
            try writeAnomaly(reason, migrationID: journal.migrationID)
            try removeItemIfPresent(at: journalURL)
            try removeItemIfPresent(at: backupDirectory(for: journal))
        } catch RecoveryError.backupIntegrityMismatch {
            try? writeAnomaly(.backupIntegrityMismatch, migrationID: attempt.migrationID)
            throw RecoveryError.backupIntegrityMismatch
        } catch {
            try? writeAnomaly(.restoreFailed, migrationID: attempt.migrationID)
            throw error
        }
    }

    /// Delete All needs this explicit boundary because a pending backup can contain the full local
    /// store even though it is outside SwiftData's normal model inventory.
    func deleteRecoveryArtifacts() throws {
        try removeItemIfPresent(at: recoveryRootURL)
    }

    private var recoveryRootURL: URL {
        storeURL.deletingLastPathComponent().appendingPathComponent("MindBudgetMigrationRecovery", isDirectory: true)
    }

    private var markerURL: URL { URL(fileURLWithPath: storeURL.path + ".migration-marker") }
    private var journalURL: URL { recoveryRootURL.appendingPathComponent("journal.json") }
    private var anomalyURL: URL { recoveryRootURL.appendingPathComponent("anomaly.json") }

    private func liveArtifacts() -> [(name: String, url: URL)] {
        [
            ("store", storeURL),
            ("wal", URL(fileURLWithPath: storeURL.path + "-wal")),
            ("shm", URL(fileURLWithPath: storeURL.path + "-shm")),
            ("journal", URL(fileURLWithPath: storeURL.path + "-journal")),
            ("support", URL(fileURLWithPath: storeURL.path + "_SUPPORT"))
        ]
    }

    private func recoverInterruptedAttemptIfNeeded() throws {
        guard fileManager.fileExists(atPath: journalURL.path) else { return }
        let journal = try validatedJournal(try read(Journal.self, from: journalURL))
        if journal.state == .committed {
            // This is terminal cleanup, not recovery. Failure to reclaim an already-committed
            // backup must not block the trusted current store or roll it back.
            try? removeItemIfPresent(at: backupDirectory(for: journal))
            try? removeItemIfPresent(at: journalURL)
            return
        }
        // A restart never guesses that an interrupted open or validation succeeded.
        try restore(journal)
        try restoreSourceMarker(from: journal)
        try writeAnomaly(.interruptedAttemptRestored, migrationID: journal.migrationID)
        try removeItemIfPresent(at: journalURL)
        try removeItemIfPresent(at: backupDirectory(for: journal))
    }

    private func isTrustedCommittedMarker(for target: String) throws -> Bool {
        guard let marker = try readableMarker(),
              marker.formatVersion == 1,
              marker.state == .committed,
              marker.target == target else { return false }
        guard !fileManager.fileExists(atPath: journalURL.path) else {
            let journal = try validatedJournal(try read(Journal.self, from: journalURL))
            return !journal.state.isActive
        }
        return true
    }

    private func readableMarker() throws -> Marker? {
        guard fileManager.fileExists(atPath: markerURL.path) else { return nil }
        return try? read(Marker.self, from: markerURL)
    }

    private func committedMarkerTarget() throws -> String? {
        guard let marker = try readableMarker(), marker.formatVersion == 1, marker.state == .committed else {
            return nil
        }
        return marker.target
    }

    private func removeOrphanedBackups() throws {
        guard fileManager.fileExists(atPath: recoveryRootURL.path) else { return }
        let protectedDirectoryName: String?
        if fileManager.fileExists(atPath: journalURL.path) {
            protectedDirectoryName = try? validatedJournal(read(Journal.self, from: journalURL)).backupDirectoryName
        } else {
            protectedDirectoryName = nil
        }
        for item in try fileManager.contentsOfDirectory(at: recoveryRootURL, includingPropertiesForKeys: [.isDirectoryKey]) {
            let values = try item.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true, item.lastPathComponent != protectedDirectoryName,
                  UUID(uuidString: item.lastPathComponent) != nil else { continue }
            try removeItemIfPresent(at: item)
        }
    }

    private func transition(_ attempt: Attempt, to state: JournalState) throws {
        var journal = try journal(for: attempt)
        journal.state = state
        try write(journal, to: journalURL)
    }

    private func journal(for attempt: Attempt) throws -> Journal {
        let journal = try validatedJournal(try read(Journal.self, from: journalURL))
        guard journal.migrationID == attempt.migrationID else { throw RecoveryError.unsupportedJournalState }
        return journal
    }

    private func backupDirectory(for journal: Journal) -> URL {
        recoveryRootURL.appendingPathComponent(journal.backupDirectoryName, isDirectory: true)
    }

    private func validatedJournal(_ journal: Journal) throws -> Journal {
        guard journal.formatVersion == 1,
              journal.target == Self.currentTarget,
              journal.backupDirectoryName == journal.migrationID.uuidString,
              journal.manifestFileName == "manifest.json" else {
            throw RecoveryError.unreadableJournal
        }
        return journal
    }

    private func snapshotLiveArtifacts(into backupDirectory: URL) throws -> [Artifact] {
        try liveArtifacts().compactMap { artifact in
            guard fileManager.fileExists(atPath: artifact.url.path) else { return nil }
            let destination = backupDirectory.appendingPathComponent(artifact.name)
            try fileManager.copyItem(at: artifact.url, to: destination)
            try applyProtection(to: destination)
            return try makeArtifact(name: artifact.name, url: destination)
        }
    }

    private func restore(_ journal: Journal) throws {
        let backupDirectory = backupDirectory(for: journal)
        let manifestURL = backupDirectory.appendingPathComponent(journal.manifestFileName)
        let manifest = try read(Manifest.self, from: manifestURL)
        guard manifest.formatVersion == 1, manifest.migrationID == journal.migrationID else {
            throw RecoveryError.unreadableManifest
        }
        let expectedArtifacts: [String: Bool] = [
            "store": false,
            "wal": false,
            "shm": false,
            "journal": false,
            "support": true,
        ]
        let allowedNames = Set(expectedArtifacts.keys)
        let manifestNames = manifest.artifacts.map(\.name)
        guard Set(manifestNames).count == manifestNames.count,
              Set(manifestNames).isSubset(of: allowedNames),
              manifestNames.contains("store"),
              manifest.artifacts.allSatisfy({ artifact in
                  guard let expectedIsDirectory = expectedArtifacts[artifact.name] else { return false }
                  return artifact.isDirectory == expectedIsDirectory
              }) else {
            throw RecoveryError.unreadableManifest
        }
        for artifact in manifest.artifacts {
            let url = backupDirectory.appendingPathComponent(artifact.name)
            guard try makeArtifact(name: artifact.name, url: url) == artifact else {
                throw RecoveryError.backupIntegrityMismatch
            }
        }
        for artifact in liveArtifacts() { try removeItemIfPresent(at: artifact.url) }
        for artifact in manifest.artifacts {
            let source = backupDirectory.appendingPathComponent(artifact.name)
            guard let destination = liveArtifacts().first(where: { $0.name == artifact.name })?.url else {
                throw RecoveryError.unreadableManifest
            }
            try beforeRestoreArtifactCopy(artifact.name)
            try fileManager.copyItem(at: source, to: destination)
            try applyProtection(to: destination)
        }
    }

    private func makeArtifact(name: String, url: URL) throws -> Artifact {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
        let isDirectory = values.isDirectory ?? false
        let data: Data
        let byteCount: Int64
        if isDirectory {
            let children = try fileManager.subpathsOfDirectory(atPath: url.path).sorted()
            struct DirectoryEntry: Codable {
                let path: String
                let byteCount: Int64
                let digest: Data
            }
            var entries: [DirectoryEntry] = []
            var total: Int64 = 0
            for child in children {
                let childURL = url.appendingPathComponent(child)
                var isChildDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: childURL.path, isDirectory: &isChildDirectory), !isChildDirectory.boolValue else { continue }
                let childData = try Data(contentsOf: childURL)
                entries.append(
                    DirectoryEntry(
                        path: child,
                        byteCount: Int64(childData.count),
                        digest: Data(SHA256.hash(data: childData))
                    )
                )
                total += Int64(childData.count)
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            data = try encoder.encode(entries)
            byteCount = total
        } else {
            data = try Data(contentsOf: url)
            byteCount = Int64(data.count)
        }
        return Artifact(name: name, isDirectory: isDirectory, byteCount: byteCount, digest: Data(SHA256.hash(data: data)))
    }

    private func writeAnomaly(_ reason: AnomalyReason, migrationID: UUID) throws {
        struct Anomaly: Codable { let formatVersion: Int; let reason: AnomalyReason; let migrationID: UUID; let recordedAt: Date }
        try fileManager.createDirectory(at: recoveryRootURL, withIntermediateDirectories: true)
        try applyProtection(to: recoveryRootURL)
        try write(Anomaly(formatVersion: 1, reason: reason, migrationID: migrationID, recordedAt: Date()), to: anomalyURL)
    }

    private func restoreSourceMarker(from journal: Journal) throws {
        if let sourceMarkerTarget = journal.sourceMarkerTarget {
            try write(Marker(formatVersion: 1, state: .committed, target: sourceMarkerTarget), to: markerURL)
        } else {
            try removeItemIfPresent(at: markerURL)
        }
    }

    private func read<Value: Decodable>(_ type: Value.Type, from url: URL) throws -> Value {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: Data(contentsOf: url))
    }

    private func write<Value: Encodable>(_ value: Value, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        try applyProtection(to: url)
    }

    private func applyProtection(to url: URL) throws {
        try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path)
    }

    private func removeItemIfPresent(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }
}

protocol MigrationRecoveryArtifactDeleting: Sendable {
    func deleteRecoveryArtifacts() async throws
}

struct NoopMigrationRecoveryArtifactDeleter: MigrationRecoveryArtifactDeleting {
    func deleteRecoveryArtifacts() async throws {}
}

struct StoreMigrationRecoveryArtifactDeleter: MigrationRecoveryArtifactDeleting {
    let coordinator: StoreMigrationRecoveryCoordinator

    func deleteRecoveryArtifacts() async throws {
        try coordinator.deleteRecoveryArtifacts()
    }
}
