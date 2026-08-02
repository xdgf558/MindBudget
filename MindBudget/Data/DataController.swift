import Foundation
import SwiftData

struct DataController: Sendable {
    let container: ModelContainer

    init(isStoredInMemoryOnly: Bool = false, storeURL: URL? = nil) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration: ModelConfiguration

        if let storeURL {
            configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
        } else if isStoredInMemoryOnly {
            configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            let applicationSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                url: applicationSupportURL.appendingPathComponent("MindBudget.store"),
                allowsSave: true
            )
        }

        container = try ModelContainer(
            for: schema,
            migrationPlan: MindBudgetMigrationPlan.self,
            configurations: [configuration]
        )
    }

    func makeDataActor() -> DataActor {
        DataActor(modelContainer: container)
    }
}
