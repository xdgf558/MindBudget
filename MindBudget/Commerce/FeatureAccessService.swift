import Foundation

/// The complete outcome of a paid-feature access check.
///
/// This deliberately does not mention StoreKit products, prices, trials, or billing state.
/// Consumers may present an accepted product experience only in later owning phases.
enum FeatureAccessDecision: Equatable, Sendable {
    case allowed
    case requiresProSubscription

    var isAllowed: Bool {
        self == .allowed
    }
}

/// The only feature-facing commercial access boundary.
///
/// Implementations must be deterministic and `Sendable`. Feature consumers ask this protocol
/// about a `PremiumFeature`; they never inspect entitlement bits, products, or billing state.
protocol FeatureAccessChecking: Sendable {
    func decision(for feature: PremiumFeature) -> FeatureAccessDecision
}

/// A pure immutable access evaluator for one entitlement snapshot.
///
/// The default snapshot is exact Free. Every current premium feature requires the sole Release-
/// reachable paid right. The exhaustive switch makes a future vocabulary addition choose its
/// requirement explicitly instead of inheriting a permissive default.
struct FeatureAccessService: FeatureAccessChecking, Sendable {
    private let entitlements: EntitlementSet

    init(entitlements: EntitlementSet = .free) {
        self.entitlements = entitlements
    }

    func decision(for feature: PremiumFeature) -> FeatureAccessDecision {
        let requiredEntitlement: EntitlementSet = switch feature {
        case .unlimitedCategoryBudgets,
             .advancedLocalInsights,
             .appleOnDeviceAI,
             .cloudCoach,
             .unlimitedWishlist,
             .customCoolingOffPeriod,
             .purchasePreflight,
             .postPurchaseReview,
             .receiptScan,
             .receiptImport,
             .shareExtension,
             .advancedSiri,
             .longRangeReports,
             .appleWatchCompanion:
            .proSubscription
        }

        return entitlements.isSuperset(of: requiredEntitlement)
            ? .allowed
            : .requiresProSubscription
    }
}

/// The process-local bridge from the actor-owned StoreKit lifecycle to existing synchronous
/// feature consumers.
///
/// Only an immutable `FeatureAccessService` snapshot crosses the lock. Nothing is persisted, and
/// the default remains exact Free until `EntitlementStore` completes verified reconciliation.
final class LiveFeatureAccessAuthority: FeatureAccessChecking, @unchecked Sendable {
    private let lock = NSLock()
    private var service = FeatureAccessService()

    func decision(for feature: PremiumFeature) -> FeatureAccessDecision {
        lock.lock()
        defer { lock.unlock() }
        return service.decision(for: feature)
    }

    func replaceEntitlements(_ entitlements: EntitlementSet) {
        lock.lock()
        service = FeatureAccessService(entitlements: entitlements)
        lock.unlock()
    }
}

/// Immutable decisions for the advanced entry points that already exist in the app.
///
/// Feature code receives this value instead of entitlement bits, products, or billing state.
/// The no-argument initializer is exact Free; the only way to create an allowed snapshot is an
/// injected `FeatureAccessChecking` authority owned by Commerce.
struct ExistingPremiumEntryAccess: Equatable, Sendable {
    private let appleOnDeviceAIDecision: FeatureAccessDecision
    private let customCoolingOffDecision: FeatureAccessDecision
    private let advancedSiriDecision: FeatureAccessDecision

    init(featureAccess: any FeatureAccessChecking = FeatureAccessService()) {
        appleOnDeviceAIDecision = featureAccess.decision(for: .appleOnDeviceAI)
        customCoolingOffDecision = featureAccess.decision(for: .customCoolingOffPeriod)
        advancedSiriDecision = featureAccess.decision(for: .advancedSiri)
    }

    func enablesAppleOnDeviceAI(userEnabled: Bool) -> Bool {
        userEnabled && appleOnDeviceAIDecision.isAllowed
    }

    var offersAppleOnDeviceAI: Bool {
        appleOnDeviceAIDecision.isAllowed
    }

    var offersCustomCoolingOffDurations: Bool {
        customCoolingOffDecision.isAllowed
    }

    var permitsAdvancedSiri: Bool {
        advancedSiriDecision.isAllowed
    }
}

#if DEBUG
/// Development/test injection for any entitlement combination constructible by the domain.
///
/// The provider is immutable, has no UserDefaults or other persistence path, and is absent from
/// Release compilation. Production `AppEnvironment.live()` never consults process arguments or
/// local storage to select commercial rights.
struct DebugFeatureAccessProvider: FeatureAccessChecking, Sendable {
    private let service: FeatureAccessService

    init(entitlements: EntitlementSet) {
        service = FeatureAccessService(entitlements: entitlements)
    }

    func decision(for feature: PremiumFeature) -> FeatureAccessDecision {
        service.decision(for: feature)
    }
}
#endif
