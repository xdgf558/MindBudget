import Foundation

@MainActor
struct AppEnvironment {
    let dataController: DataController
    let settingsStore: SettingsStore

    static func live() throws -> AppEnvironment {
        AppEnvironment(
            dataController: try DataController(),
            settingsStore: SettingsStore()
        )
    }
}
