import Foundation
import SwiftUI
@preconcurrency import CoreSpotlight

private struct ExistingPremiumEntryAccessEnvironmentKey: EnvironmentKey {
    static let defaultValue = ExistingPremiumEntryAccess()
}

extension EnvironmentValues {
    var existingPremiumEntryAccess: ExistingPremiumEntryAccess {
        get { self[ExistingPremiumEntryAccessEnvironmentKey.self] }
        set { self[ExistingPremiumEntryAccessEnvironmentKey.self] = newValue }
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
    private let systemIntegrationCapability: SystemIntegrationCapability
    private let appLockAuthenticator: any AppLockAuthenticating
    let existingPremiumEntryAccess: ExistingPremiumEntryAccess

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
    private var invalidCoolingOffPlanIDs: Set<UUID> = []

    var notificationDataIntegrityWarning: Bool {
        invalidCoolingOffRecordCount > 0
    }

    init(
        dataActor: DataActor,
        notificationScheduler: any NotificationScheduling = NotificationScheduler(),
        searchIndexCleaner: any SearchIndexDeleting = CoreSpotlightIndexCleaner(),
        spotlightIndexer: any SpotlightIndexing = SpotlightIndexingService(),
        navigationStore: MindBudgetNavigationRequestStore = MindBudgetNavigationRequestStore(),
        privacyDeletionVerifier: any PrivacyDeletionVerifying = ModelCountPrivacyDeletionVerifier(),
        systemIntegrationCapability: SystemIntegrationCapability = SystemIntegrationCapability(),
        appLockAuthenticator: any AppLockAuthenticating = LocalAppLockAuthenticator(),
        featureAccessService: any FeatureAccessChecking = FeatureAccessService(),
        appLockInitiallyEnabled: Bool = false
    ) {
        self.dataActor = dataActor
        self.notificationScheduler = notificationScheduler
        self.searchIndexCleaner = searchIndexCleaner
        self.spotlightIndexer = spotlightIndexer
        self.navigationStore = navigationStore
        self.privacyDeletionVerifier = privacyDeletionVerifier
        self.systemIntegrationCapability = systemIntegrationCapability
        self.appLockAuthenticator = appLockAuthenticator
        existingPremiumEntryAccess = ExistingPremiumEntryAccess(featureAccess: featureAccessService)
        appLockState = appLockInitiallyEnabled ? .locked : .unlocked
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

        privacyDeletionState = .inProgress(.deletingLocalData)
        do {
            try await dataActor.deleteAllUserData()
            guard try await privacyDeletionVerifier.isDeletionComplete(in: dataActor) else {
                privacyDeletionState = .failed(.deletingLocalData)
                return false
            }
        } catch {
            privacyDeletionState = .failed(.deletingLocalData)
            return false
        }

        privacyDeletionState = .inProgress(.resettingPreferences)
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
        appLockInitiallyEnabled: Bool = false
    ) {
        _session = StateObject(
            wrappedValue: AppSession(
                dataActor: dataController.dataActor,
                notificationScheduler: notificationScheduler,
                searchIndexCleaner: searchIndexCleaner,
                spotlightIndexer: spotlightIndexer,
                navigationStore: navigationStore,
                appLockAuthenticator: appLockAuthenticator,
                featureAccessService: featureAccessService,
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
        .environment(\.mindBudgetTheme, MindBudgetTheme(skin: settings.appSkin))
        .preferredColorScheme(MindBudgetTheme(skin: settings.appSkin).preferredColorScheme)
        .task {
            await session.unlockAppIfNeeded(
                settings: settings,
                localizedReason: appLockReason
            )
            await session.prepare(settings: settings, calendar: calendar)
            await session.observeIntentNavigation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await session.unlockAppIfNeeded(
                        settings: settings,
                        localizedReason: appLockReason
                    )
                }
            case .inactive, .background:
                session.lockAppIfNeeded(settings: settings)
            @unknown default:
                session.lockAppIfNeeded(settings: settings)
            }
        }
        .onChange(of: settings.requireFaceID) { _, _ in
            session.synchronizeAppLock(settings: settings)
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
