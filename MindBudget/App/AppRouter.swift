import Foundation
import SwiftUI
import UIKit
@preconcurrency import CoreSpotlight

private struct ExistingPremiumEntryAccessEnvironmentKey: EnvironmentKey {
    static let defaultValue = ExistingPremiumEntryAccess()
}

private struct ReceiptImageLifecycleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any ReceiptImageLifecycleHandling = NoopReceiptImageLifecycle()
}

struct TelemetryEventRecorder: Sendable {
    private let handler: @MainActor @Sendable (TelemetryEvent) -> Void

    init(handler: @MainActor @Sendable @escaping (TelemetryEvent) -> Void = { _ in }) {
        self.handler = handler
    }

    @MainActor
    func capture(_ event: TelemetryEvent) {
        handler(event)
    }
}

private struct TelemetryEventRecorderEnvironmentKey: EnvironmentKey {
    static let defaultValue = TelemetryEventRecorder()
}

extension EnvironmentValues {
    var existingPremiumEntryAccess: ExistingPremiumEntryAccess {
        get { self[ExistingPremiumEntryAccessEnvironmentKey.self] }
        set { self[ExistingPremiumEntryAccessEnvironmentKey.self] = newValue }
    }

    var receiptImageLifecycle: any ReceiptImageLifecycleHandling {
        get { self[ReceiptImageLifecycleEnvironmentKey.self] }
        set { self[ReceiptImageLifecycleEnvironmentKey.self] = newValue }
    }

    var telemetryEventRecorder: TelemetryEventRecorder {
        get { self[TelemetryEventRecorderEnvironmentKey.self] }
        set { self[TelemetryEventRecorderEnvironmentKey.self] = newValue }
    }
}

enum AppTab: Hashable, CaseIterable {
    case dashboard
    case list
    case insights
    case wishlist

    var accessibilityPosition: Int {
        guard let index = Self.allCases.firstIndex(of: self) else {
            preconditionFailure("Every app tab must appear in CaseIterable order")
        }
        return index + 1
    }
}

enum CoolingOffRepairState: Equatable {
    case idle
    case repairing
    case completed(Int)
    case failed
}

@MainActor
final class AppSession: ObservableObject {
    let dataActor: DataActor
    private let notificationScheduler: any NotificationScheduling
    private let searchIndexCleaner: any SearchIndexDeleting
    private let spotlightIndexer: any SpotlightIndexing
    private let navigationStore: MindBudgetNavigationRequestStore
    private let privacyDeletionVerifier: any PrivacyDeletionVerifying
    private let migrationRecoveryArtifactDeleter: any MigrationRecoveryArtifactDeleting
    private let systemIntegrationCapability: SystemIntegrationCapability
    private let appLockAuthenticator: any AppLockAuthenticating
    private let storeCatalog: StoreCatalog?
    private let entitlementStore: EntitlementStore?
    private let trialLifecycleScheduler: any TrialLifecycleScheduling
    private let publicConfigurationService: (any PublicConfigurationServicing)?
    private let publicConfigurationExpirationScheduler: any PublicConfigurationExpirationScheduling
    private let cloudSyncService: (any CloudSyncServicing)?
    private let telemetryService: (any TelemetryServicing)?
    let receiptImageLifecycle: any ReceiptImageLifecycleHandling

    @Published var revision = 0
    @Published var selectedTab: AppTab = .dashboard
    @Published var presentsAddExpense = false
    @Published var presentsAddIncome = false
    @Published var presentsEntryChooser = false
    @Published var wishlistNavigationPath: [UUID] = []
    @Published private(set) var isPrepared = false
    @Published private(set) var preparationFailed = false
    @Published private(set) var notificationAuthorizationState: NotificationAuthorizationState = .notDetermined
    @Published private(set) var notificationOperationFailed = false
    @Published private(set) var invalidCoolingOffRecordCount = 0
    @Published private(set) var coolingOffRepairState: CoolingOffRepairState = .idle
    @Published private(set) var spotlightResult: SpotlightReconciliationResult?
    @Published private(set) var privacyDeletionState: PrivacyDeletionState = .idle
    @Published private(set) var appLockState: AppLockState
    @Published private(set) var appLockOperationError: AppLockOperationError?
    @Published private(set) var recurringExpenseReconciliationFailed = false
    @Published private(set) var recurringExpenseReconciliationHasMore = false
    @Published private(set) var existingPremiumEntryAccess: ExistingPremiumEntryAccess
    @Published private(set) var storeCatalogAvailability: StoreCatalogAvailability = .unavailable
    @Published private(set) var commerceSubscriptionState: EffectiveStoreSubscriptionState = .unavailable
    @Published private(set) var commerceSubscriptionAuthorityIsActionable = false
    @Published private(set) var trialLifecycle: TrialLifecycleProjection?
    @Published private(set) var trialRenewalReminder = TrialRenewalReminderReconciliation.inactive
    @Published private(set) var trialRenewalReminderFailed = false
    @Published private(set) var publicConfigurationPresentation =
        PublicConfigurationPresentation.conservativeDefault
    @Published private(set) var cloudSyncSnapshot = CloudSyncSnapshot.disabled
    @Published private(set) var telemetrySnapshot = TelemetryClientSnapshot(
        collectionEnabled: false,
        queuedEventCount: 0,
        retainedIdentityCount: 0,
        retryNotBefore: nil,
        availability: .available
    )
    private var invalidCoolingOffPlanIDs: Set<UUID> = []
    private var hasStartedCommerceLifecycle = false
    private var trialLifecycleReconciliationGeneration = 0
    private var hasStartedPublicConfigurationLifecycle = false
    private var publicConfigurationExpiresAt: Date?
    private var publicConfigurationRefreshTask: Task<Void, Never>?
    private var publicConfigurationExpiryTask: Task<Void, Never>?
    private var telemetryCaptureTail: Task<Void, Never>?

    var notificationDataIntegrityWarning: Bool {
        invalidCoolingOffRecordCount > 0
    }

    /// The only signed-configuration presentation consumer. It may hide or show this voluntary
    /// entry, but it cannot alter access and never suppresses the permanent Settings Pro entry.
    var offersAppleOnDeviceAIProValueTrigger: Bool {
        publicConfigurationPresentation.proValueTriggersEnabled
            && commerceSubscriptionAuthorityIsActionable
            && commerceSubscriptionState == .none
            && !existingPremiumEntryAccess.offersAppleOnDeviceAI
    }

    /// Feature views consume this already-matched presentation value and never inspect a
    /// StoreKit Product ID. Cached/unavailable catalog state intentionally returns nil.
    var trialRenewalDisplayPrice: String? {
        guard let trialLifecycle,
              case .live = storeCatalogAvailability else { return nil }
        return TrialLifecyclePresentation.liveDisplayPrice(
            for: trialLifecycle,
            catalog: storeCatalogAvailability
        )
    }

    init(
        dataActor: DataActor,
        notificationScheduler: any NotificationScheduling = NotificationScheduler(),
        searchIndexCleaner: any SearchIndexDeleting = CoreSpotlightIndexCleaner(),
        spotlightIndexer: any SpotlightIndexing = SpotlightIndexingService(),
        navigationStore: MindBudgetNavigationRequestStore = MindBudgetNavigationRequestStore(),
        privacyDeletionVerifier: any PrivacyDeletionVerifying = ModelCountPrivacyDeletionVerifier(),
        migrationRecoveryArtifactDeleter: any MigrationRecoveryArtifactDeleting = NoopMigrationRecoveryArtifactDeleter(),
        systemIntegrationCapability: SystemIntegrationCapability = SystemIntegrationCapability(),
        appLockAuthenticator: any AppLockAuthenticating = LocalAppLockAuthenticator(),
        featureAccessService: any FeatureAccessChecking = FeatureAccessService(),
        storeCatalog: StoreCatalog? = nil,
        entitlementStore: EntitlementStore? = nil,
        trialLifecycleScheduler: any TrialLifecycleScheduling = NoopTrialLifecycleScheduler(),
        publicConfigurationService: (any PublicConfigurationServicing)? = nil,
        publicConfigurationExpirationScheduler: any PublicConfigurationExpirationScheduling =
            SystemPublicConfigurationExpirationScheduler(),
        cloudSyncService: (any CloudSyncServicing)? = nil,
        receiptImageLifecycle: any ReceiptImageLifecycleHandling = NoopReceiptImageLifecycle(),
        telemetryService: (any TelemetryServicing)? = nil,
        appLockInitiallyEnabled: Bool = false
    ) {
        self.dataActor = dataActor
        self.notificationScheduler = notificationScheduler
        self.searchIndexCleaner = searchIndexCleaner
        self.spotlightIndexer = spotlightIndexer
        self.navigationStore = navigationStore
        self.privacyDeletionVerifier = privacyDeletionVerifier
        self.migrationRecoveryArtifactDeleter = migrationRecoveryArtifactDeleter
        self.systemIntegrationCapability = systemIntegrationCapability
        self.appLockAuthenticator = appLockAuthenticator
        self.storeCatalog = storeCatalog
        self.entitlementStore = entitlementStore
        self.trialLifecycleScheduler = trialLifecycleScheduler
        self.publicConfigurationService = publicConfigurationService
        self.publicConfigurationExpirationScheduler = publicConfigurationExpirationScheduler
        self.cloudSyncService = cloudSyncService
        self.receiptImageLifecycle = receiptImageLifecycle
        self.telemetryService = telemetryService
        existingPremiumEntryAccess = ExistingPremiumEntryAccess(featureAccess: featureAccessService)
        appLockState = appLockInitiallyEnabled ? .locked : .unlocked
        if let cloudSyncService {
            cloudSyncSnapshot = cloudSyncService.snapshot
            cloudSyncService.onSnapshotChange = { [weak self] snapshot in
                self?.cloudSyncSnapshot = snapshot
            }
        }
        if let telemetryService {
            telemetrySnapshot = telemetryService.snapshot
            telemetryService.onSnapshotChange = { [weak self] snapshot in
                self?.telemetrySnapshot = snapshot
            }
        }
    }

    deinit {
        publicConfigurationRefreshTask?.cancel()
        publicConfigurationExpiryTask?.cancel()
        telemetryCaptureTail?.cancel()
        let telemetryService = telemetryService
        Task { @MainActor in telemetryService?.stop() }
        let receiptImageLifecycle = receiptImageLifecycle
        Task { await receiptImageLifecycle.discardTemporaryImage() }
    }

    func startCommerceLifecycle() async {
        guard !hasStartedCommerceLifecycle else { return }
        hasStartedCommerceLifecycle = true
        if let entitlementStore {
            await entitlementStore.start { [weak self] snapshot in
                self?.existingPremiumEntryAccess = snapshot.premiumEntryAccess
                self?.commerceSubscriptionState = snapshot.effectiveState
                self?.commerceSubscriptionAuthorityIsActionable = snapshot.isActionable
                self?.trialLifecycle = snapshot.trialLifecycle
            }
        }
        if storeCatalog != nil {
            Task { [weak self] in await self?.refreshCommerceCatalog() }
        }
    }

    func startPublicConfigurationLifecycle() async {
        guard !hasStartedPublicConfigurationLifecycle else { return }
        hasStartedPublicConfigurationLifecycle = true
        defer {
            // A SwiftUI task can be recreated after its view disappears. Cancellation ends only
            // this attempt; it must not poison the one-time guard and suppress that later retry.
            if Task.isCancelled {
                hasStartedPublicConfigurationLifecycle = false
            }
        }
        guard let publicConfigurationService else { return }

        let cacheNow = Date()
        let cachedResolution = await publicConfigurationService.resolveCached(now: cacheNow)
        guard !Task.isCancelled else { return }
        applyPublicConfiguration(cachedResolution, now: cacheNow)
        // Remain structured under the owning SwiftUI `.task`: if that task disappears or is
        // canceled, cancellation reaches the service instead of leaving a detached refresh.
        await refreshPublicConfiguration()
    }

    func refreshPublicConfiguration() async {
        guard let publicConfigurationService else { return }
        do {
            let resolution = try await publicConfigurationService.refresh()
            try Task.checkCancellation()
            applyPublicConfiguration(resolution, now: Date())
        } catch {
            // Retain the currently scheduled verified value; its independent expiry task still
            // clears it at the signed instant.
        }
    }

    /// Scene activation owns one explicitly retained refresh. A later activation replaces it,
    /// while inactive/background and deinitialization cancel it through the service boundary.
    func beginScenePublicConfigurationRefresh() {
        publicConfigurationRefreshTask?.cancel()
        guard let service = publicConfigurationService else { return }
        publicConfigurationRefreshTask = Task { [weak self] in
            do {
                let resolution = try await service.refresh()
                try Task.checkCancellation()
                self?.applyPublicConfiguration(resolution, now: Date())
            } catch {
                // Scene cancellation retains the verified nonexpired cache/current presentation.
            }
        }
    }

    func cancelScenePublicConfigurationRefresh() {
        publicConfigurationRefreshTask?.cancel()
        publicConfigurationRefreshTask = nil
    }

    private func applyPublicConfiguration(
        _ resolution: PublicConfigurationResolution,
        now: Date
    ) {
        publicConfigurationExpiryTask?.cancel()
        publicConfigurationExpiryTask = nil
        publicConfigurationExpiresAt = nil

        guard let expiresAt = resolution.expiresAt, expiresAt > now else {
            publicConfigurationPresentation = .conservativeDefault
            return
        }

        publicConfigurationPresentation = resolution.presentation
        publicConfigurationExpiresAt = expiresAt
        let expirationScheduler = publicConfigurationExpirationScheduler
        publicConfigurationExpiryTask = Task { [weak self] in
            do {
                try await expirationScheduler.wait(until: expiresAt)
                try Task.checkCancellation()
                self?.expirePublicConfiguration(expectedExpiration: expiresAt)
            } catch {
                // A replacement configuration cancels this task and owns the next expiry.
            }
        }
    }

    private func expirePublicConfiguration(expectedExpiration: Date) {
        guard publicConfigurationExpiresAt == expectedExpiration else { return }
        publicConfigurationExpiresAt = nil
        publicConfigurationExpiryTask = nil
        publicConfigurationPresentation = .conservativeDefault
    }

    /// Typed commerce seams owned by the voluntary C3 purchase presentation. Views never call
    /// StoreKit directly, and none of these operations runs without an explicit user action.
    func purchasePro(_ product: StoreProductID) async -> StorePurchaseOutcome {
        guard let entitlementStore else {
            recordTelemetry(.subscription(.purchase, .unavailable))
            return .failed(.unavailable)
        }
        let outcome = await entitlementStore.purchase(product)
        if outcome == .purchased {
            await refreshCommerceCatalog()
        }
        recordTelemetry(.subscription(.purchase, telemetryOutcome(for: outcome)))
        return outcome
    }

    func restoreProPurchases() async -> StoreRestoreOutcome {
        guard let entitlementStore else {
            recordTelemetry(.subscription(.restore, .unavailable))
            return .failed(.unavailable)
        }
        let outcome = await entitlementStore.restorePurchases()
        if outcome == .restored {
            await refreshCommerceCatalog()
        }
        recordTelemetry(.subscription(.restore, telemetryOutcome(for: outcome)))
        return outcome
    }

    func recordManageSubscriptionsPresented() {
        recordTelemetry(.subscription(.manage, .completed))
    }

    func recordTelemetry(_ event: TelemetryEvent) {
        guard let telemetryService else { return }
        let predecessor = telemetryCaptureTail
        telemetryCaptureTail = Task {
            _ = await predecessor?.value
            guard !Task.isCancelled else { return }
            _ = await telemetryService.capture(event)
        }
    }

    func startTelemetryLifecycle() async {
        await telemetryService?.start()
    }

    func setTelemetryCollectionEnabled(_ enabled: Bool) async -> Bool {
        await telemetryService?.setCollectionEnabled(enabled) ?? false
    }

    func retryTelemetryTransport() async {
        await telemetryService?.retryTerminalFailure()
    }

    func deleteTelemetryData() async -> TelemetryDeletionResult {
        await telemetryService?.deleteAllTelemetry() ?? .unavailable
    }

    func refreshTelemetryOnSceneActivation() async {
        await telemetryService?.sceneDidBecomeActive()
    }

    func refreshCommerceCatalog() async {
        guard let storeCatalog else {
            storeCatalogAvailability = .unavailable
            return
        }
        storeCatalogAvailability = await storeCatalog.refresh()
    }

    func refreshCommerceEntitlements() async {
        await entitlementStore?.refreshCurrentEntitlements()
    }

    func startCloudSyncLifecycle() async {
        await cloudSyncService?.start()
    }

    func startReceiptImageLifecycle() async {
        await receiptImageLifecycle.start()
    }

    func setCloudSyncEnabled(_ enabled: Bool) async {
        await cloudSyncService?.setEnabled(enabled)
        let succeeded = cloudSyncSnapshot.isEnabled == enabled
        recordTelemetry(.cloudSync(
            enabled ? .enable : .disable,
            succeeded ? .completed : .failed
        ))
    }

    func setCloudSyncEnabled(_ enabled: Bool, reimportConfirmed: Bool) async {
        await cloudSyncService?.setEnabled(enabled, reimportConfirmed: reimportConfirmed)
        let succeeded = cloudSyncSnapshot.isEnabled == enabled
        recordTelemetry(.cloudSync(
            enabled ? .enable : .disable,
            succeeded ? .completed : .failed
        ))
    }

    func retryCloudSync() async {
        await cloudSyncService?.retry()
    }

    func refreshCloudSyncOnSceneActivation() async {
        await cloudSyncService?.sceneDidBecomeActive()
    }

    func discardReceiptImageWork() async {
        await receiptImageLifecycle.discardTemporaryImage()
    }

    func cloudSyncConflicts() async -> [CloudSyncConflictSummary] {
        await cloudSyncService?.conflicts() ?? []
    }

    func resolveCloudSyncConflict(
        recordName: String,
        resolution: CloudSyncConflictResolution
    ) async -> Bool {
        let resolved = await cloudSyncService?.resolveConflict(
            recordName: recordName,
            resolution: resolution
        ) ?? false
        recordTelemetry(.cloudSync(
            .resolveConflict,
            resolved ? .completed : .failed
        ))
        return resolved
    }

    func deleteCloudSyncData() async -> CloudSyncCloudDeletionOutcome {
        let outcome = await cloudSyncService?.deleteCloudData() ?? .failed(.transportFailed)
        recordTelemetry(.cloudSync(
            .deleteCloudCopy,
            outcome == .deleted ? .completed : .failed
        ))
        return outcome
    }

    private func telemetryOutcome(for outcome: StorePurchaseOutcome) -> TelemetryOutcome {
        switch outcome {
        case .purchased: .completed
        case .cancelled: .cancelled
        case .pending: .unavailable
        case .failed: .failed
        }
    }

    private func telemetryOutcome(for outcome: StoreRestoreOutcome) -> TelemetryOutcome {
        switch outcome {
        case .restored: .completed
        case .noActiveSubscription: .unavailable
        case .failed: .failed
        }
    }

    func recoverCloudSyncFromLocalData() async -> Bool {
        await cloudSyncService?.recoverFromTrustBoundary(.rebuildCloudFromLocal) ?? false
    }

    @discardableResult
    func reconcileTrialLifecycle(
        settings: SettingsStore,
        locale: Locale,
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> Bool {
        trialLifecycleReconciliationGeneration += 1
        let generation = trialLifecycleReconciliationGeneration
        do {
            let reconciliation = try await trialLifecycleScheduler.reconcile(
                trial: trialLifecycle,
                notificationsEnabled: settings.enableLocalNotifications,
                now: now,
                calendar: calendar,
                locale: locale
            )
            guard generation == trialLifecycleReconciliationGeneration else { return true }
            trialRenewalReminder = reconciliation
            trialRenewalReminderFailed = false
            return true
        } catch {
            guard generation == trialLifecycleReconciliationGeneration else { return false }
            trialRenewalReminderFailed = true
            return false
        }
    }

    func faceIDAvailability() -> FaceIDAvailability {
        appLockAuthenticator.faceIDAvailability()
    }

    func setAppLockProtection(
        enabled: Bool,
        settings: SettingsStore,
        localizedReason: String
    ) async -> Bool {
        guard enabled != settings.requireFaceID else { return true }
        if enabled, appLockAuthenticator.faceIDAvailability() != .available {
            appLockOperationError = .faceIDUnavailable
            return false
        }

        let previousState = appLockState
        appLockState = .authenticating
        let authenticated = await appLockAuthenticator.authenticate(
            localizedReason: localizedReason
        )
        guard authenticated else {
            appLockState = settings.requireFaceID ? .locked : previousState
            appLockOperationError = .authenticationFailed
            return false
        }

        settings.requireFaceID = enabled
        appLockState = .unlocked
        appLockOperationError = nil
        return true
    }

    func lockAppIfNeeded(settings: SettingsStore) {
        guard settings.requireFaceID else {
            appLockState = .unlocked
            return
        }
        appLockState = .locked
        appLockOperationError = nil
    }

    func unlockAppIfNeeded(
        settings: SettingsStore,
        localizedReason: String
    ) async {
        guard settings.requireFaceID else {
            appLockState = .unlocked
            appLockOperationError = nil
            return
        }
        guard appLockState == .locked else { return }

        appLockState = .authenticating
        let authenticated = await appLockAuthenticator.authenticate(
            localizedReason: localizedReason
        )
        if authenticated {
            appLockState = .unlocked
            appLockOperationError = nil
        } else {
            appLockState = .locked
            appLockOperationError = .authenticationFailed
        }
    }

    func synchronizeAppLock(settings: SettingsStore) {
        if !settings.requireFaceID {
            appLockState = .unlocked
            appLockOperationError = nil
        }
    }

    func prepare(
        settings: SettingsStore,
        force: Bool = false,
        calendar: Calendar = .current,
        now: Date = Date()
    ) async {
        guard !isPrepared || force else { return }
        isPrepared = false
        do {
            if let existingPlan = try await dataActor.fetchBudgetPlanSummaries().first {
                settings.currencyCode = existingPlan.currencyCode
                settings.firstLaunchCompleted = true
            }
            _ = await reconcileRecurringExpenses(calendar: calendar, now: now)
            preparationFailed = false
        } catch {
            preparationFailed = true
        }
        isPrepared = true
    }

    @discardableResult
    func reconcileRecurringExpenses(
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> RecurringExpenseReconciliationResult {
        do {
            let result = try await dataActor.reconcileRecurringFixedExpenses(
                through: now,
                calendar: calendar
            )
            recurringExpenseReconciliationFailed = false
            recurringExpenseReconciliationHasMore = result.hasMore
            if result.insertedCount > 0 { dataDidChange() }
            return result
        } catch {
            recurringExpenseReconciliationFailed = true
            recurringExpenseReconciliationHasMore = false
            return .empty
        }
    }

    func dataDidChange() {
        revision &+= 1
    }

    func presentExpenseEntry() {
        presentsAddExpense = true
    }

    func presentIncomeEntry() {
        presentsAddIncome = true
    }

    func presentEntryChooser() {
        presentsEntryChooser = true
    }

    func observeIntentNavigation() async {
        let requests = await navigationStore.requests()
        for await request in requests {
            guard !Task.isCancelled else { return }
            applyNavigation(request)
        }
    }

    func openSearchResult(identifier: String) {
        guard let request = MindBudgetSearchIdentifier.navigationRequest(for: identifier) else {
            return
        }
        applyNavigation(request)
    }

    @discardableResult
    func reconcileSpotlight(
        settings: SettingsStore,
        locale: Locale,
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> SpotlightReconciliationResult {
        let result = await spotlightIndexer.reconcile(
            dataActor: dataActor,
            preferences: settings.systemIntegrationPreferencesSnapshot,
            now: now,
            calendar: calendar,
            locale: locale
        )
        spotlightResult = result
        return result
    }

    private func applyNavigation(_ request: MindBudgetNavigationRequest) {
        switch request {
        case .dashboard:
            selectedTab = .dashboard
        case .expenses:
            selectedTab = .list
        case .wishlist:
            selectedTab = .wishlist
            wishlistNavigationPath = []
        case let .wishlistItem(id):
            selectedTab = .wishlist
            wishlistNavigationPath = [id]
        case .insights:
            selectedTab = .insights
        }
    }

    @discardableResult
    func requestNotificationAuthorization(
        settings: SettingsStore,
        locale: Locale,
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> NotificationAuthorizationState {
        do {
            var state = await notificationScheduler.authorizationState()
            if state == .notDetermined {
                state = try await notificationScheduler.requestAuthorization()
            }
            notificationAuthorizationState = state
            settings.enableLocalNotifications = state.permitsScheduling
            notificationOperationFailed = false
            _ = await reconcileNotifications(
                settings: settings,
                locale: locale,
                calendar: calendar,
                now: now
            )
            return state
        } catch {
            settings.enableLocalNotifications = false
            notificationOperationFailed = true
            return notificationAuthorizationState
        }
    }

    func disableNotifications(
        settings: SettingsStore,
        locale: Locale,
        calendar: Calendar = .current,
        now: Date = Date()
    ) async {
        settings.enableLocalNotifications = false
        _ = await reconcileNotifications(
            settings: settings,
            locale: locale,
            calendar: calendar,
            now: now
        )
    }

    @discardableResult
    func reconcileNotifications(
        settings: SettingsStore,
        locale: Locale,
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> Bool {
        do {
            let candidateBatch = try await dataActor.fetchCoolingNotificationCandidates()
            let result = try await notificationScheduler.reconcile(
                candidates: candidateBatch.candidates,
                preferences: settings.preferencesSnapshot,
                contextualEntitiesEnabled: systemIntegrationCapability
                    .onscreenAvailability(userEnabled: settings.enableSiriIntegration)
                    .isAvailable,
                now: now,
                calendar: calendar,
                locale: locale
            )
            let invalidIdentifierUpdates = candidateBatch.invalidPlanIDs.map {
                CoolingNotificationIdentifierUpdate(planID: $0, identifier: nil)
            }
            try await dataActor.updateCoolingNotificationIdentifiers(
                result.identifierUpdates + invalidIdentifierUpdates
            )
            for delivered in result.deliveredNotifications {
                _ = try? await dataActor.recordDeliveredCoolingNotification(
                    planID: delivered.planID,
                    deliveredAt: delivered.deliveredAt
                )
            }
            notificationAuthorizationState = result.authorizationState
            notificationOperationFailed = false
            invalidCoolingOffPlanIDs = Set(candidateBatch.invalidPlanIDs)
            invalidCoolingOffRecordCount = invalidCoolingOffPlanIDs.count
            return true
        } catch {
            notificationOperationFailed = true
            return false
        }
    }

    /// Called only after the user confirms the count shown in Settings. The actor
    /// revalidates every identifier so this cannot remove a record that became readable.
    @discardableResult
    func repairInvalidCoolingOffRecords(
        settings: SettingsStore,
        locale: Locale,
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> Bool {
        let identifiedPlanIDs = Array(invalidCoolingOffPlanIDs)
        guard !identifiedPlanIDs.isEmpty else { return true }

        coolingOffRepairState = .repairing
        do {
            let repairedCount = try await dataActor.repairInvalidCoolingOffPlans(
                identifiedBy: identifiedPlanIDs
            )
            // Every cached identifier was either deleted while still invalid or preserved
            // because it became readable. Do not leave a stale integrity warning visible if
            // the best-effort notification reconciliation below independently fails.
            invalidCoolingOffPlanIDs.subtract(identifiedPlanIDs)
            invalidCoolingOffRecordCount = invalidCoolingOffPlanIDs.count
            coolingOffRepairState = .completed(repairedCount)
            _ = await reconcileNotifications(
                settings: settings,
                locale: locale,
                calendar: calendar,
                now: now
            )
            dataDidChange()
            return true
        } catch {
            coolingOffRepairState = .failed
            return false
        }
    }

    @discardableResult
    func deleteAllData(settings: SettingsStore) async -> Bool {
        await receiptImageLifecycle.discardTemporaryImage()
        await cloudSyncService?.stop()
        telemetryCaptureTail?.cancel()
        telemetryCaptureTail = nil
        telemetryService?.stop()
        privacyDeletionState = .inProgress(.cancellingNotifications)
        do {
            try await notificationScheduler.cancelAll()
        } catch {
            privacyDeletionState = .failed(.cancellingNotifications)
            return false
        }

        privacyDeletionState = .inProgress(.clearingSearchIndex)
        do {
            try await searchIndexCleaner.deleteAll()
        } catch {
            privacyDeletionState = .failed(.clearingSearchIndex)
            return false
        }

        privacyDeletionState = .inProgress(.deletingTelemetry)
        if let telemetryService {
            switch await telemetryService.deleteAllTelemetry() {
            case .deletedLocally, .deletedLocallyWithoutRemoteProofs, .deletedRemotely:
                break
            case .failed, .terminalFailure, .unavailable:
                privacyDeletionState = .failed(.deletingTelemetry)
                return false
            }
        }

        privacyDeletionState = .inProgress(.deletingLocalData)
        do {
            try await dataActor.deleteAllUserData()
            if let cloudSyncService {
                await cloudSyncService.refreshAfterLocalDataDeletion()
            } else {
                cloudSyncSnapshot = .disabled
            }
            try await migrationRecoveryArtifactDeleter.deleteRecoveryArtifacts()
            guard try await privacyDeletionVerifier.isDeletionComplete(in: dataActor) else {
                privacyDeletionState = .failed(.deletingLocalData)
                return false
            }
        } catch {
            privacyDeletionState = .failed(.deletingLocalData)
            return false
        }

        privacyDeletionState = .inProgress(.resettingPreferences)
        if let storeCatalog {
            await storeCatalog.clearPresentationCache()
            storeCatalogAvailability = .unavailable
        }
        settings.resetAfterDataDeletion()
        selectedTab = .dashboard
        presentsAddExpense = false
        presentsAddIncome = false
        presentsEntryChooser = false
        wishlistNavigationPath = []
        dataDidChange()
        privacyDeletionState = .completed
        return true
    }

    func clearPrivacyDeletionFailure() {
        if case .failed = privacyDeletionState {
            privacyDeletionState = .idle
        }
    }
}

struct AppRouter: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @StateObject private var session: AppSession
    @State private var showsLaunchAnimation = true

    init(
        dataController: DataController,
        notificationScheduler: any NotificationScheduling = NotificationScheduler(),
        searchIndexCleaner: any SearchIndexDeleting = CoreSpotlightIndexCleaner(),
        spotlightIndexer: any SpotlightIndexing = SpotlightIndexingService(),
        navigationStore: MindBudgetNavigationRequestStore = MindBudgetNavigationRequestStore(),
        appLockAuthenticator: any AppLockAuthenticating = LocalAppLockAuthenticator(),
        featureAccessService: any FeatureAccessChecking = FeatureAccessService(),
        storeCatalog: StoreCatalog? = nil,
        entitlementStore: EntitlementStore? = nil,
        trialLifecycleScheduler: any TrialLifecycleScheduling = NoopTrialLifecycleScheduler(),
        publicConfigurationService: (any PublicConfigurationServicing)? = nil,
        cloudSyncService: (any CloudSyncServicing)? = nil,
        receiptImageLifecycle: any ReceiptImageLifecycleHandling = NoopReceiptImageLifecycle(),
        telemetryService: (any TelemetryServicing)? = nil,
        appLockInitiallyEnabled: Bool = false
    ) {
        _session = StateObject(
            wrappedValue: AppSession(
                dataActor: dataController.dataActor,
                notificationScheduler: notificationScheduler,
                searchIndexCleaner: searchIndexCleaner,
                spotlightIndexer: spotlightIndexer,
                navigationStore: navigationStore,
                migrationRecoveryArtifactDeleter: dataController.migrationRecoveryArtifactDeleter,
                appLockAuthenticator: appLockAuthenticator,
                featureAccessService: featureAccessService,
                storeCatalog: storeCatalog,
                entitlementStore: entitlementStore,
                trialLifecycleScheduler: trialLifecycleScheduler,
                publicConfigurationService: publicConfigurationService,
                cloudSyncService: cloudSyncService,
                receiptImageLifecycle: receiptImageLifecycle,
                telemetryService: telemetryService,
                appLockInitiallyEnabled: appLockInitiallyEnabled
            )
        )
    }

    var body: some View {
        ZStack {
            ZStack {
                Group {
                    if !session.isPrepared {
                        ProgressView()
                            .accessibilityLabel("common.loading")
                    } else if session.preparationFailed {
                        ErrorStateView(messageKey: "error.data.load") {
                            Task {
                                await session.prepare(
                                    settings: settings,
                                    force: true,
                                    calendar: calendar
                                )
                            }
                        }
                    } else if !settings.firstLaunchCompleted {
                        OnboardingView(dataActor: session.dataActor) {
                            session.dataDidChange()
                        }
                    } else {
                        MainTabView(session: session)
                    }
                }
            }
            .accessibilityHidden(session.appLockState != .unlocked)
            if showsLaunchAnimation {
                MindBudgetLaunchAnimation(
                    holdsForUITesting: holdsLaunchAnimationForUITesting
                ) {
                    showsLaunchAnimation = false
                }
                .allowsHitTesting(false)
                .zIndex(1)
            }
            if session.appLockState != .unlocked {
                AppLockView(
                    state: session.appLockState,
                    error: session.appLockOperationError
                ) {
                    Task {
                        await session.unlockAppIfNeeded(
                            settings: settings,
                            localizedReason: appLockReason
                        )
                    }
                }
                .zIndex(2)
            }
        }
        .environment(\.existingPremiumEntryAccess, session.existingPremiumEntryAccess)
        .environment(\.receiptImageLifecycle, session.receiptImageLifecycle)
        .environment(
            \.telemetryEventRecorder,
            TelemetryEventRecorder { [weak session] event in
                session?.recordTelemetry(event)
            }
        )
        .environment(\.mindBudgetTheme, MindBudgetTheme(skin: settings.appSkin))
        .preferredColorScheme(MindBudgetTheme(skin: settings.appSkin).preferredColorScheme)
        .task {
            // Kept separate from local app preparation so network latency cannot delay startup,
            // while SwiftUI still owns and cancels this refresh with the view lifecycle.
            await session.startPublicConfigurationLifecycle()
        }
        .task {
            // The service reads the durable default-off switch first. No CKContainer or
            // CKSyncEngine is created until the owner has explicitly accepted the disclosure.
            await session.startCloudSyncLifecycle()
        }
        .task {
            // Missing/default-off telemetry state stays memory-only and creates no identifier,
            // encrypted file, Keychain key, or request until the customer explicitly opts in.
            await session.startTelemetryLifecycle()
        }
        .task {
            // Clears only crash-orphaned C4C-02 temporary bytes. The actor is idempotent so a
            // SwiftUI task recreation cannot erase a later active import.
            await session.startReceiptImageLifecycle()
        }
        .task {
            await session.startCommerceLifecycle()
            await session.reconcileTrialLifecycle(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
            await session.unlockAppIfNeeded(
                settings: settings,
                localizedReason: appLockReason
            )
            await session.prepare(settings: settings, calendar: calendar)
            await session.observeIntentNavigation()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didReceiveMemoryWarningNotification
        )) { _ in
            Task { await session.discardReceiptImageWork() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                session.beginScenePublicConfigurationRefresh()
                Task {
                    await session.refreshCloudSyncOnSceneActivation()
                    await session.refreshTelemetryOnSceneActivation()
                    await session.refreshCommerceEntitlements()
                    await session.reconcileTrialLifecycle(
                        settings: settings,
                        locale: locale,
                        calendar: calendar
                    )
                    await session.unlockAppIfNeeded(
                        settings: settings,
                        localizedReason: appLockReason
                    )
                }
            case .inactive:
                session.cancelScenePublicConfigurationRefresh()
                session.lockAppIfNeeded(settings: settings)
            case .background:
                session.cancelScenePublicConfigurationRefresh()
                session.lockAppIfNeeded(settings: settings)
                Task { await session.discardReceiptImageWork() }
            @unknown default:
                session.cancelScenePublicConfigurationRefresh()
                session.lockAppIfNeeded(settings: settings)
                Task { await session.discardReceiptImageWork() }
            }
        }
        .onChange(of: settings.requireFaceID) { _, _ in
            session.synchronizeAppLock(settings: settings)
        }
        .onChange(of: session.trialLifecycle) { _, _ in
            Task {
                await session.reconcileTrialLifecycle(
                    settings: settings,
                    locale: locale,
                    calendar: calendar
                )
            }
        }
        .onChange(of: settings.enableLocalNotifications) { _, _ in
            Task {
                await session.reconcileTrialLifecycle(
                    settings: settings,
                    locale: locale,
                    calendar: calendar
                )
            }
        }
        .onChange(of: settings.appLanguageRaw) { _, _ in
            Task {
                await session.reconcileTrialLifecycle(
                    settings: settings,
                    locale: settings.selectedLocale,
                    calendar: calendar
                )
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier]
                    as? String else { return }
            session.openSearchResult(identifier: identifier)
        }
    }

    private var holdsLaunchAnimationForUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-testing-hold-launch-animation")
        #else
        false
        #endif
    }

    private var appLockReason: String {
        LocalizedCatalog.string("appLock.authentication.reason", locale: locale)
    }
}

private struct AppLockView: View {
    @Environment(\.mindBudgetTheme) private var theme
    let state: AppLockState
    let error: AppLockOperationError?
    let retry: () -> Void

    var body: some View {
        ZStack {
            MindBudgetThemeBackground()
            theme.canvas.opacity(0.72)

            VStack(spacing: 18) {
                Image(systemName: "faceid")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .accessibilityHidden(true)
                Text("appLock.title")
                    .font(.title2.bold())
                    .foregroundStyle(theme.ink)
                Text("appLock.message")
                    .font(.subheadline)
                    .foregroundStyle(theme.inkSecondary)
                    .multilineTextAlignment(.center)

                if state == .authenticating {
                    ProgressView()
                        .tint(theme.accent)
                        .accessibilityLabel("appLock.authenticating")
                } else {
                    Button("appLock.unlock", action: retry)
                        .buttonStyle(MindBudgetPrimaryButtonStyle())
                        .accessibilityIdentifier("appLock.unlock")
                }

                if error == .authenticationFailed {
                    Text("appLock.error.authenticationFailed")
                        .font(.footnote)
                        .foregroundStyle(theme.attentionText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
            .frame(maxWidth: 420)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appLock.view")
    }
}

private struct MainTabView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.mindBudgetTheme) private var theme

    var body: some View {
        TabView(selection: $session.selectedTab) {
            DashboardView(session: session)
                .tag(AppTab.dashboard)

            NavigationStack {
                ExpenseListView(session: session)
            }
            .tag(AppTab.list)

            InsightsView(session: session)
                .tag(AppTab.insights)

            WishlistView(session: session)
                .tag(AppTab.wishlist)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .tint(theme.accent)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    _ = await session.reconcileRecurringExpenses(calendar: calendar)
                    session.dataDidChange()
                }
            }
        }
        .task(id: "\(session.revision)|\(locale.identifier)") {
            async let notifications: Bool = session.reconcileNotifications(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
            async let spotlight: SpotlightReconciliationResult = session.reconcileSpotlight(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
            _ = await (notifications, spotlight)
        }
        .sheet(isPresented: $session.presentsAddExpense) {
            NavigationStack {
                AddExpenseView(
                    dataActor: session.dataActor,
                    accountingCurrencyCode: settings.currencyCode,
                    existingExpense: nil
                ) {
                    session.dataDidChange()
                    session.presentsAddExpense = false
                }
            }
        }
        .sheet(isPresented: $session.presentsAddIncome) {
            NavigationStack {
                AddIncomeView(
                    dataActor: session.dataActor,
                    accountingCurrencyCode: settings.currencyCode,
                    existingIncome: nil
                ) {
                    session.dataDidChange()
                    session.presentsAddIncome = false
                }
            }
        }
        .confirmationDialog(
            "entry.type.title",
            isPresented: $session.presentsEntryChooser,
            titleVisibility: .visible
        ) {
            Button("entry.expense") { session.presentExpenseEntry() }
                .accessibilityIdentifier("entry.add.expense")
            Button("entry.income") { session.presentIncomeEntry() }
                .accessibilityIdentifier("entry.add.income")
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("entry.type.message")
        }
    }

    private var customTabBar: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabButton(
                    .dashboard,
                    title: "tab.dashboard",
                    symbol: "circle.dotted",
                    identifier: "tab.dashboard"
                )
                tabButton(
                    .list,
                    title: "tab.log",
                    symbol: "list.bullet",
                    identifier: "tab.log"
                )
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .accessibilityHidden(true)
                tabButton(
                    .insights,
                    title: "tab.insights",
                    symbol: "chart.bar",
                    identifier: "tab.insights"
                )
                tabButton(
                    .wishlist,
                    title: "tab.wishlist",
                    symbol: "bookmark",
                    identifier: "tab.wishlist"
                )
            }
            .padding(.top, 18)
            .padding(.bottom, 6)

            Button {
                session.presentEntryChooser()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(theme.accentGradient, in: Circle())
                    .shadow(color: theme.accent.opacity(0.30), radius: 8, y: 5)
            }
            .buttonStyle(.plain)
            .frame(width: 64, height: 64)
            .accessibilityLabel("entry.quickAdd")
            .accessibilitySortPriority(3)
            .accessibilityIdentifier("dashboard.quickAdd")
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(
            theme.surface
                .opacity(theme.skin == .warmBotanical ? 0.98 : 0.92)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        )
    }

    private func tabButton(
        _ tab: AppTab,
        title: LocalizedStringKey,
        symbol: String,
        identifier: String
    ) -> some View {
        Button {
            session.selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: session.selectedTab == tab ? .semibold : .regular))
                Text(title)
                    .font(.caption2.weight(session.selectedTab == tab ? .semibold : .regular))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(session.selectedTab == tab ? theme.accent : theme.inkTertiary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityValue(
            "tab.position \(tab.accessibilityPosition) \(AppTab.allCases.count)"
        )
        .accessibilityAddTraits(session.selectedTab == tab ? .isSelected : [])
        .mindBudgetNavigationSortPriority(for: tab)
        .accessibilityIdentifier(identifier)
    }
}

private extension View {
    @ViewBuilder
    func mindBudgetNavigationSortPriority(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            accessibilitySortPriority(5)
        case .list:
            accessibilitySortPriority(4)
        case .insights:
            accessibilitySortPriority(2)
        case .wishlist:
            accessibilitySortPriority(1)
        }
    }
}
