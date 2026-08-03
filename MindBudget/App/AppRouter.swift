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

    @Published var revision = 0
    @Published var selectedTab: AppTab = .dashboard
    @Published var presentsAddExpense = false
    @Published private(set) var isPrepared = false
    @Published private(set) var preparationFailed = false

    init(dataActor: DataActor) {
        self.dataActor = dataActor
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
}

struct AppRouter: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var session: AppSession

    init(dataController: DataController) {
        _session = StateObject(wrappedValue: AppSession(dataActor: dataController.dataActor))
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
    @State private var lastContentTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $session.selectedTab) {
            DashboardView(session: session)
                .tabItem { Label("tab.dashboard", systemImage: "chart.pie") }
                .tag(AppTab.dashboard)

            Color.clear
                .tabItem { Label("tab.add", systemImage: "plus.circle.fill") }
                .tag(AppTab.add)

            InsightsView()
                .tabItem { Label("tab.insights", systemImage: "chart.xyaxis.line") }
                .tag(AppTab.insights)

            WishlistView()
                .tabItem { Label("tab.wishlist", systemImage: "heart.text.square") }
                .tag(AppTab.wishlist)

            SettingsView()
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
