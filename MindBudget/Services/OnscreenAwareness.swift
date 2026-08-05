import Foundation
import SwiftUI

#if canImport(AppIntents)
import AppIntents
#endif

/// A deliberately amount-free reference to an app-owned entity that may be onscreen.
enum OnscreenEntityReference: Equatable, Sendable {
    case expense(UUID)
    case budgetCurrent
    case wishlistItem(UUID)
    case spendingInsight(UUID)

    var activityType: String {
        let prefix = Bundle.main.bundleIdentifier ?? "MindBudget"
        return switch self {
        case .expense: "\(prefix).onscreen.expense"
        case .budgetCurrent: "\(prefix).onscreen.budget"
        case .wishlistItem: "\(prefix).onscreen.wishlist-item"
        case .spendingInsight: "\(prefix).onscreen.insight"
        }
    }

    #if canImport(AppIntents)
    @available(iOS 26.0, *)
    var entityIdentifier: EntityIdentifier {
        switch self {
        case let .expense(id):
            EntityIdentifier(for: ExpenseEntity.self, identifier: id)
        case .budgetCurrent:
            EntityIdentifier(for: BudgetSnapshotEntity.self, identifier: "current")
        case let .wishlistItem(id):
            EntityIdentifier(for: WishlistItemEntity.self, identifier: id)
        case let .spendingInsight(id):
            EntityIdentifier(for: SpendingInsightEntity.self, identifier: id)
        }
    }
    #endif
}

/// Xcode 26.6 / iOS 26.5 does not expose a public UserNotifications entity-
/// annotation property. The scheduler still carries a typed, gated association so
/// the public adapter can be filled in when the SDK ships it without changing policy.
enum NotificationEntityAssociationSupport {
    static let isAvailableInCurrentSDK = false
}

extension View {
    /// Associates one visible subject with an NSUserActivity only when every centralized
    /// product, SDK/runtime, and default-off Siri setting gate is open.
    func mindBudgetOnscreenEntity(
        _ reference: OnscreenEntityReference?,
        userEnabled: Bool,
        capability: SystemIntegrationCapability = SystemIntegrationCapability()
    ) -> some View {
        modifier(
            MindBudgetOnscreenEntityModifier(
                reference: reference,
                userEnabled: userEnabled,
                capability: capability
            )
        )
    }

    /// Current Xcode 26.6 has no public multi-object list selection annotation API.
    /// A list therefore publishes an entity only when it has an explicit selection;
    /// passing nil is the intentional, privacy-preserving fallback.
    func mindBudgetOnscreenListSelection(
        _ selectedReference: OnscreenEntityReference?,
        userEnabled: Bool,
        capability: SystemIntegrationCapability = SystemIntegrationCapability()
    ) -> some View {
        mindBudgetOnscreenEntity(
            selectedReference,
            userEnabled: userEnabled,
            capability: capability
        )
    }
}

private struct MindBudgetOnscreenEntityModifier: ViewModifier {
    let reference: OnscreenEntityReference?
    let userEnabled: Bool
    let capability: SystemIntegrationCapability

    @ViewBuilder
    func body(content: Content) -> some View {
        #if canImport(AppIntents)
        if #available(iOS 26.0, *),
           capability.onscreenAvailability(userEnabled: userEnabled).isAvailable,
           let reference {
            content.userActivity(reference.activityType) { activity in
                activity.appEntityIdentifier = reference.entityIdentifier
                // The activity exists only to describe what is onscreen. It must not
                // become a second searchable or cross-device data surface.
                activity.isEligibleForSearch = false
                activity.isEligibleForPrediction = false
                activity.isEligibleForHandoff = false
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}
