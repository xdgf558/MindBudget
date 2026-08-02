import SwiftData
import SwiftUI

@main
struct MindBudgetApp: App {
    private let environment: AppEnvironment

    init() {
        do {
            environment = try AppEnvironment.live()
        } catch {
            fatalError("Unable to initialize the local MindBudget store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .modelContainer(environment.dataController.container)
                .environmentObject(environment.settingsStore)
        }
    }
}
