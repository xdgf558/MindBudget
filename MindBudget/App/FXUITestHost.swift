#if DEBUG && targetEnvironment(simulator) && MINDBUDGET_FX_UI_TEST_HOST
import SwiftData
import SwiftUI

/// A different executable entry, not a branch inside AppBootstrap. It never constructs
/// AppEnvironment.live(), registers Intents, or starts StoreKit/network/system lifecycles.
@main
struct MindBudgetFXUITestApp: App {
    @StateObject private var host = FXUITestHost()

    var body: some Scene {
        WindowGroup {
            FXUITestRoot(host: host)
        }
    }
}

@MainActor
private final class FXUITestHost: ObservableObject {
    let controller: DataController
    let settings: SettingsStore
    let authority = LiveFeatureAccessAuthority()
    let session: AppSession
    @Published var saved: ExpenseSummary?
    @Published var accessRevision = 0
    @Published var saveFailed = false
    @Published var seeding = false

    init() {
        do {
            controller = try DataController(isStoredInMemoryOnly: true)
        } catch {
            fatalError("FX UI in-memory store failed: \(error)")
        }
        // Never touch the normal app's preferences or on-disk financial store.
        let suite = "MindBudget.FXUI.IsolatedPreferences"
        guard let defaults = UserDefaults(suiteName: suite) else {
            fatalError("FX UI isolated preferences unavailable")
        }
        defaults.removePersistentDomain(forName: suite)
        settings = SettingsStore(defaults: defaults)
        settings.currencyCode = "USD"
        settings.enableGentleReminders = false
        settings.enableLocalNotifications = false
        settings.enableAIEnhancement = false
        settings.enableSiriIntegration = false
        settings.enableSpotlightIndexing = false
        let chinese = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        settings.appLanguageRaw = chinese ? "zh-Hans" : "en"
        settings.appSkinRaw = chinese ? "neonPulse" : "warmBotanical"
        FXUIFixtureAccess.allow(authority)
        // No prepare(), commerce, notification, telemetry, sync, or index lifecycle is invoked.
        // This session only supplies the real detail view's DataActor and revision counter.
        session = AppSession(dataActor: controller.dataActor,
                             notificationScheduler: FXUINotificationStub(),
                             featureAccessService: authority)
    }

    func didSave() {
        Task {
            do {
                saved = try await controller.dataActor.fetchExpenseSummaries().first
                saveFailed = saved == nil
            } catch {
                saveFailed = true
            }
        }
    }

    func revoke() {
        FXUIFixtureAccess.revoke(authority)
        // Editing must still use the stored USD, not this changed setting.
        if saved != nil { settings.currencyCode = "JPY" }
        accessRevision += 1
    }

    func restoreFixture() {
        FXUIFixtureAccess.allow(authority)
        accessRevision += 1
    }

    func loadExistingFixture() {
        guard saved == nil, !seeding else { return }
        seeding = true
        Task {
            do {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: "UTC")!
                let date = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
                let foreign = try ExpenseForeignCurrency(
                    original: Money(minorUnits: 300, currencyCode: "EUR"),
                    rate: ForeignCurrencyRate(numerator: 2, denominator: 1),
                    selectedDate: date, calendar: calendar, source: .manualRate
                )
                let draft = ExpenseDraft(
                    id: UUID(), amount: Money(minorUnits: 600, currencyCode: "USD"), category: .food,
                    bucket: .discretionary, merchantName: nil, note: nil, spentAt: date,
                    spentTimeZoneIdentifier: calendar.timeZone.identifier, createdAt: date, updatedAt: date,
                    paymentMethod: nil, emotionTag: nil, purchaseReason: nil, isPlanned: false,
                    isRecurring: false, source: .manual, allowMerchantIndexing: false, foreignCurrency: foreign
                )
                saved = try await controller.dataActor.createExpense(draft, featureAccess: authority)
                revoke()
            } catch {
                saveFailed = true
            }
            seeding = false
        }
    }
}

private struct FXUINotificationStub: NotificationScheduling {
    func authorizationState() async -> NotificationAuthorizationState {
        fatalError("FX UI host must not start notification lifecycle")
    }
    func requestAuthorization() async throws -> NotificationAuthorizationState {
        fatalError("FX UI host must not request system authorization")
    }
    func reconcile(candidates: [CoolingNotificationCandidate], preferences: PreferencesSnapshot,
                   contextualEntitiesEnabled: Bool, now: Date, calendar: Calendar,
                   locale: Locale) async throws -> NotificationReconciliation {
        fatalError("FX UI host must not reconcile notifications")
    }
    func cancelAll() async throws {
        fatalError("FX UI host must not alter system notifications")
    }
}

@MainActor
private struct FXUITestRoot: View {
    @ObservedObject var host: FXUITestHost

    var body: some View {
        NavigationStack {
            Group {
                if let saved = host.saved {
                    ExpenseDetailView(expense: saved, session: host.session)
                } else {
                    AddExpenseView(
                        dataActor: host.controller.dataActor,
                        accountingCurrencyCode: "USD",
                        existingExpense: nil,
                        completed: host.didSave
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Text(verbatim: "FX-UI-IN-MEMORY")
                        .accessibilityIdentifier("fx.testHost")
                    Button(action: host.revoke) { Text(verbatim: "Free") }
                        .accessibilityIdentifier("fx.testHost.revoke")
                    Button(action: host.restoreFixture) { Text(verbatim: "Fixture") }
                        .accessibilityIdentifier("fx.testHost.restore")
                    if host.saved == nil {
                        Button(action: host.loadExistingFixture) { Text(verbatim: "Saved") }
                            .accessibilityIdentifier("fx.testHost.existing")
                            .disabled(host.seeding)
                    }
                }
                .font(.caption)
                .dynamicTypeSize(.medium)
                .padding(8)
                .background(.regularMaterial)
            }
        }
        .environmentObject(host.settings)
        .environment(\.locale, host.settings.selectedLocale)
        .environment(\.mindBudgetTheme, MindBudgetTheme(skin: host.settings.appSkin))
        .preferredColorScheme(MindBudgetTheme(skin: host.settings.appSkin).preferredColorScheme)
        .environment(\.existingPremiumEntryAccess,
                     ExistingPremiumEntryAccess(featureAccess: host.authority))
        .environment(\.featureAccessAuthority, host.authority)
        .accessibilityValue(host.saveFailed ? "FX-SAVE-FAILED" : "fixture-\(host.accessRevision)")
    }
}
#endif
