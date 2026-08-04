import Foundation

@MainActor
struct AppEnvironment {
    let dataController: DataController
    let settingsStore: SettingsStore
    let notificationScheduler: any NotificationScheduling
    let searchIndexCleaner: any SearchIndexDeleting

    static func live() throws -> AppEnvironment {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") {
            let suiteName = "MindBudgetUITests"
            guard let defaults = UserDefaults(suiteName: suiteName) else {
                throw CocoaError(.fileReadUnknown)
            }
            defaults.removePersistentDomain(forName: suiteName)
            return AppEnvironment(
                dataController: try DataController(isStoredInMemoryOnly: true),
                settingsStore: SettingsStore(defaults: defaults),
                notificationScheduler: NotificationScheduler(),
                searchIndexCleaner: CoreSpotlightIndexCleaner()
            )
        }
        #endif
        return AppEnvironment(
            dataController: try DataController(),
            settingsStore: SettingsStore(),
            notificationScheduler: NotificationScheduler(),
            searchIndexCleaner: CoreSpotlightIndexCleaner()
        )
    }
}
