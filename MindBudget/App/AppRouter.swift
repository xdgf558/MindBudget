import SwiftUI

enum AppTab: Hashable {
    case dashboard
    case add
    case insights
    case wishlist
    case settings
}

@MainActor
final class AppSession: ObservableObject {
    let dataActor: DataActor
    private let notificationScheduler: any NotificationScheduling
    private let searchIndexCleaner: any SearchIndexDeleting
    private let privacyDeletionVerifier: any PrivacyDeletionVerifying

    @Published var revision = 0
    @Published var selectedTab: AppTab = .dashboard
    @Published var presentsAddExpense = false
    @Published private(set) var isPrepared = false
    @Published private(set) var preparationFailed = false
    @Published private(set) var notificationAuthorizationState: NotificationAuthorizationState = .notDetermined
    @Published private(set) var notificationOperationFailed = false
    @Published private(set) var notificationDataIntegrityWarning = false
    @Published private(set) var privacyDeletionState: PrivacyDeletionState = .idle

    init(
        dataActor: DataActor,
        notificationScheduler: any NotificationScheduling = NotificationScheduler(),
        searchIndexCleaner: any SearchIndexDeleting = CoreSpotlightIndexCleaner(),
        privacyDeletionVerifier: any PrivacyDeletionVerifying = ModelCountPrivacyDeletionVerifier()
    ) {
        self.dataActor = dataActor
        self.notificationScheduler = notificationScheduler
        self.searchIndexCleaner = searchIndexCleaner
        self.privacyDeletionVerifier = privacyDeletionVerifier
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
            notificationDataIntegrityWarning = false
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
        searchIndexCleaner: any SearchIndexDeleting = CoreSpotlightIndexCleaner()
    ) {
        _session = StateObject(
            wrappedValue: AppSession(
                dataActor: dataController.dataActor,
                notificationScheduler: notificationScheduler,
                searchIndexCleaner: searchIndexCleaner
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
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @State private var lastContentTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $session.selectedTab) {
            DashboardView(session: session)
                .tabItem { Label("tab.dashboard", systemImage: "chart.pie") }
                .tag(AppTab.dashboard)

            Color.clear
                .tabItem { Label("tab.add", systemImage: "plus.circle.fill") }
                .tag(AppTab.add)

            InsightsView(session: session)
                .tabItem { Label("tab.insights", systemImage: "chart.xyaxis.line") }
                .tag(AppTab.insights)

            WishlistView(session: session)
                .tabItem { Label("tab.wishlist", systemImage: "heart.text.square") }
                .tag(AppTab.wishlist)

            SettingsView(session: session)
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .onChange(of: session.selectedTab) { _, selectedTab in
            if selectedTab == .add {
                session.selectedTab = lastContentTab
                session.presentExpenseEntry()
            } else {
                lastContentTab = selectedTab
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                session.dataDidChange()
            }
        }
        .task(id: session.revision) {
            await session.reconcileNotifications(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
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
}
