#if DEBUG && targetEnvironment(simulator) && MINDBUDGET_FX_UI_TEST_HOST
import SwiftData
import SwiftUI
import UIKit
import OSLog

// TEMPORARY PR #117 hosted diagnostic, not a corrective control or release candidate.
// This entire executable is excluded from ordinary Debug and every Release build.
// Observe public dispatch only: forward exactly once, add no gesture/action/retry.
private enum FX117TouchDiagnostic {
    static let logger = Logger(subsystem: "MindBudget.FX117Diagnostic", category: "touch")
    @MainActor static var installed = false

    @MainActor static func install() {
        guard !installed else { return }
        guard let event = class_getInstanceMethod(UIApplication.self, #selector(UIApplication.sendEvent(_:))),
              let observedEvent = class_getInstanceMethod(UIApplication.self, #selector(UIApplication.fx117_sendEvent(_:))),
              let action = class_getInstanceMethod(UIControl.self, #selector(UIControl.sendAction(_:to:for:))),
              let observedAction = class_getInstanceMethod(UIControl.self, #selector(UIControl.fx117_sendAction(_:to:for:))) else {
            fatalError("FX117 diagnostic could not observe public dispatch")
        }
        installed = true
        method_exchangeImplementations(event, observedEvent)
        method_exchangeImplementations(action, observedAction)
    }

    @MainActor static func describe(_ touch: UITouch, stage: String) {
        var view = touch.view
        var chain: [String] = []
        while let current = view {
            let recognizers = (current.gestureRecognizers ?? []).map {
                "\(type(of: $0)):\($0.state.rawValue):enabled=\($0.isEnabled):delaysBegan=\($0.delaysTouchesBegan):delaysEnded=\($0.delaysTouchesEnded):cancels=\($0.cancelsTouchesInView)"
            }.joined(separator: ",")
            let control = current as? UIControl
            let toggle = current as? UISwitch
            chain.append("\(type(of: current)) frame=\(current.convert(current.bounds, to: touch.window)) enabled=\(String(describing: control?.isEnabled)) on=\(String(describing: toggle?.isOn)) gestures=[\(recognizers)]")
            view = current.superview
        }
        // Synthetic fixture geometry/state only; no labels, text input or user data.
        let text = "\(stage) phase=\(touch.phase.rawValue) time=\(touch.timestamp) point=\(touch.location(in: touch.window)) targetChain=\(chain.joined(separator: " -> "))"
        logger.notice("\(text, privacy: .public)")
    }
}

private extension UIApplication {
    @objc func fx117_sendEvent(_ event: UIEvent) {
        let touches = event.allTouches ?? []
        for touch in touches { FX117TouchDiagnostic.describe(touch, stage: "before") }
        fx117_sendEvent(event)
        for touch in touches { FX117TouchDiagnostic.describe(touch, stage: "after") }
    }
}

private extension UIControl {
    @objc func fx117_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        let text = "ACTION \(type(of: self)) selector=\(action) enabled=\(isEnabled) on=\(String(describing: (self as? UISwitch)?.isOn))"
        FX117TouchDiagnostic.logger.notice("\(text, privacy: .public)")
        fx117_sendAction(action, to: target, for: event)
    }
}

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
        FX117TouchDiagnostic.install()
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
