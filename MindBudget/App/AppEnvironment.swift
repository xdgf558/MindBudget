import Foundation

@MainActor
struct AppEnvironment {
    let dataController: DataController
    let settingsStore: SettingsStore
    let notificationScheduler: any NotificationScheduling
    let searchIndexCleaner: any SearchIndexDeleting
    let spotlightIndexer: any SpotlightIndexing
    let intentService: MindBudgetIntentService

    static func live() throws -> AppEnvironment {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") {
            let suiteName = "MindBudgetUITests"
            guard let defaults = UserDefaults(suiteName: suiteName) else {
                throw CocoaError(.fileReadUnknown)
            }
            defaults.removePersistentDomain(forName: suiteName)
            return try make(
                defaults: defaults,
                preferenceSuiteName: suiteName,
                isStoredInMemoryOnly: true
            )
        }
        #endif
        return try make(
            defaults: .standard,
            preferenceSuiteName: nil,
            isStoredInMemoryOnly: false
        )
    }

    private static func make(
        defaults: UserDefaults,
        preferenceSuiteName: String?,
        isStoredInMemoryOnly: Bool
    ) throws -> AppEnvironment {
        let dataController = try DataController(isStoredInMemoryOnly: isStoredInMemoryOnly)
        let notificationScheduler = NotificationScheduler()
        let navigationStore = MindBudgetNavigationRequestStore()
        let intentService = MindBudgetIntentService(
            dataActor: dataController.dataActor,
            preferencesProvider: UserDefaultsSystemIntegrationPreferencesProvider(
                suiteName: preferenceSuiteName
            ),
            notificationScheduler: notificationScheduler,
            navigationStore: navigationStore
        )
        return AppEnvironment(
            dataController: dataController,
            settingsStore: SettingsStore(defaults: defaults),
            notificationScheduler: notificationScheduler,
            searchIndexCleaner: CoreSpotlightIndexCleaner(),
            spotlightIndexer: SpotlightIndexingService(),
            intentService: intentService
        )
    }
}
