import SwiftUI
@preconcurrency import CoreSpotlight

enum AppTab: Hashable {
    case dashboard
    case list
    case insights
    case wishlist
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

    @Published var revision = 0
    @Published var selectedTab: AppTab = .dashboard
    @Published var presentsAddExpense = false
    @Published var wishlistNavigationPath: [UUID] = []
    @Published private(set) var isPrepared = false
    @Published private(set) var preparationFailed = false
    @Published private(set) var notificationAuthorizationState: NotificationAuthorizationState = .notDetermined
    @Published private(set) var notificationOperationFailed = false
    @Published private(set) var notificationDataIntegrityWarning = false
    @Published private(set) var spotlightResult: SpotlightReconciliationResult?
    @Published private(set) var privacyDeletionState: PrivacyDeletionState = .idle

    init(
        dataActor: DataActor,
        notificationScheduler: any NotificationScheduling = NotificationScheduler(),
        searchIndexCleaner: any SearchIndexDeleting = CoreSpotlightIndexCleaner(),
        spotlightIndexer: any SpotlightIndexing = SpotlightIndexingService(),
        navigationStore: MindBudgetNavigationRequestStore = MindBudgetNavigationRequestStore(),
        privacyDeletionVerifier: any PrivacyDeletionVerifying = ModelCountPrivacyDeletionVerifier(),
        systemIntegrationCapability: SystemIntegrationCapability = SystemIntegrationCapability()
    ) {
        self.dataActor = dataActor
        self.notificationScheduler = notificationScheduler
        self.searchIndexCleaner = searchIndexCleaner
        self.spotlightIndexer = spotlightIndexer
        self.navigationStore = navigationStore
        self.privacyDeletionVerifier = privacyDeletionVerifier
        self.systemIntegrationCapability = systemIntegrationCapability
    }

    func prepare(settings: SettingsStore, force: Bool = false) async {
        guard !isPrepared || force else { return }
        isPrepared = false
        do {
            if let existingPlan = try await dataActor.fetchBudgetPlanSummaries().first {
                settings.currencyCode = existingPlan.currencyCode
                settings.firstLaunchCompleted = true
            }
            preparationFailed = false
        } catch {
            preparationFailed = true
        }
        isPrepared = true
    }

    func dataDidChange() {
        revision &+= 1
    }

    func presentExpenseEntry() {
        presentsAddExpense = true
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
            notificationDataIntegrityWarning = candidateBatch.containsInvalidData
            return true
        } catch {
            notificationOperationFailed = true
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
    @StateObject private var session: AppSession

    init(
        dataController: DataController,
        notificationScheduler: any NotificationScheduling = NotificationScheduler(),
        searchIndexCleaner: any SearchIndexDeleting = CoreSpotlightIndexCleaner(),
        spotlightIndexer: any SpotlightIndexing = SpotlightIndexingService(),
        navigationStore: MindBudgetNavigationRequestStore = MindBudgetNavigationRequestStore()
    ) {
        _session = StateObject(
            wrappedValue: AppSession(
                dataActor: dataController.dataActor,
                notificationScheduler: notificationScheduler,
                searchIndexCleaner: searchIndexCleaner,
                spotlightIndexer: spotlightIndexer,
                navigationStore: navigationStore
            )
        )
    }

    var body: some View {
        Group {
            if !session.isPrepared {
                ProgressView()
                    .accessibilityLabel("common.loading")
            } else if session.preparationFailed {
                ErrorStateView(messageKey: "error.data.load") {
                    Task { await session.prepare(settings: settings, force: true) }
                }
            } else if !settings.firstLaunchCompleted {
                OnboardingView(dataActor: session.dataActor) {
                    session.dataDidChange()
                }
            } else {
                MainTabView(session: session)
            }
        }
        .task {
            await session.prepare(settings: settings)
            await session.observeIntentNavigation()
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier]
                    as? String else { return }
            session.openSearchResult(identifier: identifier)
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

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
        .tint(Color.mbAccent)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                session.dataDidChange()
            }
        }
        .task(id: session.revision) {
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
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(.dashboard, title: "tab.dashboard", symbol: "circle.dotted", identifier: "tab.dashboard")
            tabButton(.list, title: "tab.log", symbol: "list.bullet", identifier: "tab.log")
            Button {
                session.presentExpenseEntry()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(Color.mbAccent, in: Circle())
                    .shadow(color: Color.mbAccent.opacity(0.30), radius: 8, y: 5)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .offset(y: -18)
            .accessibilityLabel("expense.quickAdd")
            .accessibilityIdentifier("dashboard.quickAdd")
            tabButton(.insights, title: "tab.insights", symbol: "chart.bar", identifier: "tab.insights")
            tabButton(.wishlist, title: "tab.wishlist", symbol: "bookmark", identifier: "tab.wishlist")
        }
        .frame(height: 64)
        .padding(.top, 2)
        .background(Color.mbSurface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.mbHairline).frame(height: 1)
        }
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
            }
            .foregroundStyle(session.selectedTab == tab ? Color.mbAccent : Color.mbInkTertiary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
