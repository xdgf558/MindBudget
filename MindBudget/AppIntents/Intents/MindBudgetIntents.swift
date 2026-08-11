import AppIntents
import Foundation

struct AnalyzeEmotionalSpendingIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.emotion.title"
    static let description = IntentDescription("intent.emotion.description")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "intent.parameter.emotion") var emotion: EmotionTagEntity?
    @Dependency private var service: MindBudgetIntentService

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            var calendar = Calendar.autoupdatingCurrent
            calendar.timeZone = .autoupdatingCurrent
            let count = try await service.emotionalSpendingCount(
                tag: emotion?.tag,
                now: Date(),
                calendar: calendar
            )
            let text = LocalizedCatalog.format(
                "intent.emotion.result",
                locale: .autoupdatingCurrent,
                count
            )
            return .result(dialog: IntentDialog("\(text)"))
        } catch let error as IntentExecutionError {
            return .result(dialog: IntentDialog(error.dialogKey))
        } catch {
            return .result(dialog: IntentDialog("intent.error.data"))
        }
    }
}

struct CreateCoolingOffReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.cooling.title"
    static let description = IntentDescription("intent.cooling.description")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "intent.parameter.wishlistItem") var item: WishlistItemEntity
    @Parameter(title: "intent.parameter.durationHours", default: 24) var durationHours: Int
    @Dependency private var service: MindBudgetIntentService

    static var parameterSummary: some ParameterSummary {
        Summary("intent.cooling.summary \(\.$item) \(\.$durationHours)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            var calendar = Calendar.autoupdatingCurrent
            calendar.timeZone = .autoupdatingCurrent
            let result = try await service.createCoolingOff(
                wishItemID: item.id,
                durationHours: durationHours,
                now: Date(),
                calendar: calendar,
                locale: .autoupdatingCurrent
            )
            let key = result.notificationScheduled
                ? "intent.cooling.success.scheduled"
                : "intent.cooling.success.local"
            return .result(dialog: IntentDialog(LocalizedStringResource(stringLiteral: key)))
        } catch let error as IntentExecutionError {
            return .result(dialog: IntentDialog(error.dialogKey))
        } catch {
            return .result(dialog: IntentDialog("intent.error.data"))
        }
    }
}

struct SuggestAlternativeIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.alternative.title"
    static let description = IntentDescription("intent.alternative.description")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "intent.parameter.itemName") var candidateName: String?
    @Dependency private var service: MindBudgetIntentService

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            _ = try await service.validateEphemeralCandidateName(candidateName)
            return .result(dialog: IntentDialog("intent.alternative.result"))
        } catch let error as IntentExecutionError {
            return .result(dialog: IntentDialog(error.dialogKey))
        } catch {
            return .result(dialog: IntentDialog("intent.error.data"))
        }
    }
}

struct FindRecentSpendingPatternIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.pattern.title"
    static let description = IntentDescription("intent.pattern.description")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Dependency private var service: MindBudgetIntentService

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            var calendar = Calendar.autoupdatingCurrent
            calendar.timeZone = .autoupdatingCurrent
            guard let pattern = try await service.recentSpendingPattern(
                now: Date(),
                calendar: calendar
            ) else {
                return .result(dialog: IntentDialog("intent.pattern.none"))
            }
            let key = "entity.insight.\(pattern.rawValue)"
            let patternName = LocalizedCatalog.string(key, locale: .autoupdatingCurrent)
            let text = LocalizedCatalog.format(
                "intent.pattern.result",
                locale: .autoupdatingCurrent,
                patternName
            )
            return .result(dialog: IntentDialog("\(text)"))
        } catch let error as IntentExecutionError {
            return .result(dialog: IntentDialog(error.dialogKey))
        } catch {
            return .result(dialog: IntentDialog("intent.error.data"))
        }
    }
}

struct OpenWishlistItemIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.openWishlist.title"
    static let description = IntentDescription("intent.openWishlist.description")
    static let openAppWhenRun = true
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "intent.parameter.wishlistItem") var item: WishlistItemEntity
    @Dependency private var service: MindBudgetIntentService

    static var parameterSummary: some ParameterSummary {
        Summary("intent.openWishlist.summary \(\.$item)")
    }

    func perform() async throws -> some IntentResult {
        _ = try await service.requireAdvancedSiri()
        await service.navigationStore.submit(.wishlistItem(item.id))
        return .result()
    }
}

struct OpenBudgetDashboardIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.openDashboard.title"
    static let description = IntentDescription("intent.openDashboard.description")
    static let openAppWhenRun = true
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Dependency private var service: MindBudgetIntentService

    func perform() async throws -> some IntentResult {
        _ = try await service.requireSiri()
        await service.navigationStore.submit(.dashboard)
        return .result()
    }
}

struct MindBudgetShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordExpenseIntent(),
            phrases: [
                "Record an expense in \(.applicationName)",
                "Use \(.applicationName) to record spending",
            ],
            shortTitle: "shortcut.record",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: CheckBudgetImpactIntent(),
            phrases: [
                "Check a purchase with \(.applicationName)",
            ],
            shortTitle: "shortcut.impact",
            systemImageName: "scale.3d"
        )
        AppShortcut(
            intent: AddWishlistItemIntent(),
            phrases: [
                "Add to my \(.applicationName) wishlist",
            ],
            shortTitle: "shortcut.wishlist",
            systemImageName: "heart.text.square"
        )
        AppShortcut(
            intent: AnalyzeEmotionalSpendingIntent(),
            phrases: [
                "Review emotional spending in \(.applicationName)",
            ],
            shortTitle: "shortcut.emotion",
            systemImageName: "face.smiling"
        )
        AppShortcut(
            intent: FindRecentSpendingPatternIntent(),
            phrases: [
                "Find a recent pattern in \(.applicationName)",
            ],
            shortTitle: "shortcut.pattern",
            systemImageName: "chart.xyaxis.line"
        )
        AppShortcut(
            intent: OpenBudgetDashboardIntent(),
            phrases: [
                "Open my budget in \(.applicationName)",
            ],
            shortTitle: "shortcut.dashboard",
            systemImageName: "chart.pie"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .orange
}
