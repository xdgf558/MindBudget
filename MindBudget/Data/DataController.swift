import Foundation
import SwiftData

struct DataController: Sendable {
    let container: ModelContainer
    let dataActor: DataActor
    let migrationRecoveryArtifactDeleter: any MigrationRecoveryArtifactDeleting

    init(isStoredInMemoryOnly: Bool = false, storeURL: URL? = nil) throws {
        let schema = Schema(versionedSchema: SchemaV5.self)
        let configuration: ModelConfiguration
        let recoveryCoordinator: StoreMigrationRecoveryCoordinator?

        if let storeURL {
            configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
            recoveryCoordinator = StoreMigrationRecoveryCoordinator(storeURL: storeURL)
        } else if isStoredInMemoryOnly {
            configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            recoveryCoordinator = nil
        } else {
            let applicationSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let storeURL = applicationSupportURL.appendingPathComponent("MindBudget.store")
            configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
            recoveryCoordinator = StoreMigrationRecoveryCoordinator(storeURL: storeURL)
        }

        let attempt = try recoveryCoordinator?.prepareForOpen()
        // An interrupted attempt can restore a store that was absent when this process began.
        // Decide the new-store marker path only after the recovery envelope has settled.
        let opensExistingStore = recoveryCoordinator?.hasExistingStore ?? false
        let openedContainer: ModelContainer
        do {
            if let recoveryCoordinator, let attempt {
                try recoveryCoordinator.markMigrating(attempt)
            }
            openedContainer = try Self.openValidateAndCommit(
                schema: schema,
                configuration: configuration,
                recoveryCoordinator: recoveryCoordinator,
                attempt: attempt,
                requiresInitialValidation: recoveryCoordinator != nil && !opensExistingStore
            )
            if let recoveryCoordinator, !opensExistingStore {
                try recoveryCoordinator.commitFreshOpen()
            }
        } catch {
            if let recoveryCoordinator, let attempt {
                let reason: StoreMigrationRecoveryCoordinator.AnomalyReason
                if error is InventoryFailure {
                    reason = .inventoryRejected
                } else {
                    reason = .containerOpenFailed
                }
                try recoveryCoordinator.restore(attempt, reason: reason)
            }
            throw error
        }
        self.container = openedContainer
        dataActor = DataActor(modelContainer: openedContainer)
        migrationRecoveryArtifactDeleter = recoveryCoordinator.map(StoreMigrationRecoveryArtifactDeleter.init)
            ?? NoopMigrationRecoveryArtifactDeleter()
    }

    func makeDataActor() -> DataActor {
        dataActor
    }

    private struct InventoryFailure: Error {}

    private static func openValidateAndCommit(
        schema: Schema,
        configuration: ModelConfiguration,
        recoveryCoordinator: StoreMigrationRecoveryCoordinator?,
        attempt: StoreMigrationRecoveryCoordinator.Attempt?,
        requiresInitialValidation: Bool
    ) throws -> ModelContainer {
        let container = try ModelContainer(
            for: schema,
            migrationPlan: MindBudgetMigrationPlan.self,
            configurations: [configuration]
        )
        if requiresInitialValidation || attempt != nil {
            if let recoveryCoordinator, let attempt {
                try recoveryCoordinator.markValidating(attempt)
            }
            do {
                try MigrationIntegrityInventory.validateAndRepair(in: container)
            } catch {
                // Let the local container leave this helper before its caller overwrites any
                // SQLite artifacts during restore.
                throw InventoryFailure()
            }
            if let recoveryCoordinator, let attempt {
                try recoveryCoordinator.commit(attempt)
            }
        }
        return container
    }
}
