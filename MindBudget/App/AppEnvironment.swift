import Foundation
@preconcurrency import LocalAuthentication

enum FaceIDAvailability: Equatable, Sendable {
    case available
    case unavailable
}

enum AppLockState: Equatable, Sendable {
    case unlocked
    case locked
    case authenticating
}

enum AppLockOperationError: Equatable, Sendable {
    case faceIDUnavailable
    case authenticationFailed
}

protocol AppLockAuthenticating: Sendable {
    @MainActor
    func faceIDAvailability() -> FaceIDAvailability

    /// Uses Face ID when enrolled and lets iOS offer the device passcode as the
    /// recovery path. A biometric change must never permanently lock the owner out.
    @MainActor
    func authenticate(localizedReason: String) async -> Bool
}

struct LocalAppLockAuthenticator: AppLockAuthenticating {
    @MainActor
    func faceIDAvailability() -> FaceIDAvailability {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ), context.biometryType == .faceID else {
            return .unavailable
        }
        return .available
    }

    @MainActor
    func authenticate(localizedReason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = LocalizedCatalog.string(
            "common.cancel",
            locale: .current
        )
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: localizedReason
            )
        } catch {
            return false
        }
    }
}

@MainActor
struct AppEnvironment {
    let dataController: DataController
    let settingsStore: SettingsStore
    let notificationScheduler: any NotificationScheduling
    let searchIndexCleaner: any SearchIndexDeleting
    let spotlightIndexer: any SpotlightIndexing
    let intentService: MindBudgetIntentService
    let appLockAuthenticator: any AppLockAuthenticating
    let featureAccessService: any FeatureAccessChecking
    let storeCatalog: StoreCatalog
    let entitlementStore: EntitlementStore
    let trialLifecycleScheduler: any TrialLifecycleScheduling
    let publicConfigurationService: any PublicConfigurationServicing
    let cloudSyncService: any CloudSyncServicing
    let receiptImageLifecycle: any ReceiptImageLifecycleHandling

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
        let featureAccessAuthority = LiveFeatureAccessAuthority()
        let featureAccessService: any FeatureAccessChecking = featureAccessAuthority
        let storeCatalog = StoreCatalog(
            presentationCache: UserDefaultsStorePresentationCache(
                suiteName: preferenceSuiteName
            )
        )
        let entitlementStore = EntitlementStore(
            featureAccessAuthority: featureAccessAuthority
        )
        let trialLifecycleScheduler = TrialLifecycleScheduler()
        let publicConfigurationService = PublicConfigurationServiceFactory.live()
        let cloudSyncService = CloudSyncService(dataActor: dataController.dataActor)
        let receiptImageLifecycle = ReceiptImageLifecycle()
        let intentService = MindBudgetIntentService(
            dataActor: dataController.dataActor,
            preferencesProvider: UserDefaultsSystemIntegrationPreferencesProvider(
                suiteName: preferenceSuiteName
            ),
            notificationScheduler: notificationScheduler,
            navigationStore: navigationStore,
            featureAccessService: featureAccessService
        )
        return AppEnvironment(
            dataController: dataController,
            settingsStore: SettingsStore(defaults: defaults),
            notificationScheduler: notificationScheduler,
            searchIndexCleaner: CoreSpotlightIndexCleaner(),
            spotlightIndexer: SpotlightIndexingService(),
            intentService: intentService,
            appLockAuthenticator: LocalAppLockAuthenticator(),
            featureAccessService: featureAccessService,
            storeCatalog: storeCatalog,
            entitlementStore: entitlementStore,
            trialLifecycleScheduler: trialLifecycleScheduler,
            publicConfigurationService: publicConfigurationService,
            cloudSyncService: cloudSyncService,
            receiptImageLifecycle: receiptImageLifecycle
        )
    }
}
