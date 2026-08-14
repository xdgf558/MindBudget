import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import MindBudget

@Suite(.serialized)
struct StoreKitTestCatalogTests {
    @Test
    func xcodeStoreKitTestAcceptsTheCommittedConfiguration() throws {
        let session = try SKTestSession(contentsOf: try configurationURL())
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()

        #expect(session.allTransactions().isEmpty)
    }

    @Test
    func configurationContainsOnlyTheAcceptedMonthlyAndAnnualSubscriptions() throws {
        let catalog = try decodedCatalog()

        #expect(catalog.settings.storefront == "USA")
        #expect(catalog.settings.locale == "en_US")
        #expect(catalog.products.isEmpty)
        #expect(catalog.nonRenewingSubscriptions.isEmpty)
        #expect(catalog.subscriptionGroups.count == 1)

        let group = try #require(catalog.subscriptionGroups.first)
        #expect(group.name == "MindBudget Pro")
        #expect(group.subscriptions.count == 2)

        let subscriptionsByID = Dictionary(
            grouping: group.subscriptions,
            by: \.productID
        )
        #expect(Set(subscriptionsByID.keys) == Set([
            "com.xdgf558.mindbudget.pro.monthly",
            "com.xdgf558.mindbudget.pro.annual",
        ]))
        #expect(subscriptionsByID.values.allSatisfy { $0.count == 1 })

        let monthly = try #require(
            subscriptionsByID["com.xdgf558.mindbudget.pro.monthly"]?.first
        )
        let annual = try #require(
            subscriptionsByID["com.xdgf558.mindbudget.pro.annual"]?.first
        )

        #expect(monthly.referenceName == "MindBudget Pro Monthly")
        #expect(monthly.recurringSubscriptionPeriod == "P1M")
        #expect(monthly.displayPrice == "1.99")
        #expect(annual.referenceName == "MindBudget Pro Annual")
        #expect(annual.recurringSubscriptionPeriod == "P1Y")
        #expect(annual.displayPrice == "19.99")

        for subscription in [monthly, annual] {
            #expect(subscription.type == "RecurringSubscription")
            #expect(subscription.subscriptionGroupID == group.id)
            #expect(subscription.groupNumber == 1)
            #expect(subscription.familyShareable == false)
            #expect(subscription.introductoryOffers.count == 1)
            let trial = try #require(subscription.introductoryOffers.first)
            #expect(trial.billingPlanType == "BILLED_UPFRONT")
            #expect(trial.numberOfPeriods == 1)
            #expect(trial.paymentMode == "free")
            #expect(trial.subscriptionPeriod == "P1W")
            #expect(subscription.codeOffers.isEmpty)
            #expect(subscription.adHocOffers.isEmpty)
            #expect(subscription.winbackOffers.isEmpty)
            #expect(Set(subscription.localizations.map(\.locale)) == Set(["en_US", "zh_CN"]))
            #expect(subscription.billingPlans.count == 1)
            let billingPlan = try #require(subscription.billingPlans.first)
            #expect(billingPlan.billingPlanType == "BILLED_UPFRONT")
            #expect(billingPlan.displayPrice == subscription.displayPrice)
            #expect(billingPlan.commitmentDisplayPrice == subscription.displayPrice)
            #expect(billingPlan.isEnabled)
        }

        #expect(
            Dictionary(uniqueKeysWithValues: monthly.localizations.map {
                ($0.locale, [$0.displayName, $0.description])
            }) == [
                "en_US": [
                    "MindBudget Pro Monthly (Local Test)",
                    "Local StoreKit test configuration fixture only. Not a customer offer.",
                ],
                "zh_CN": [
                    "花有数 Pro 月付（本地测试）",
                    "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
                ],
            ]
        )
        #expect(
            Dictionary(uniqueKeysWithValues: annual.localizations.map {
                ($0.locale, [$0.displayName, $0.description])
            }) == [
                "en_US": [
                    "MindBudget Pro Annual (Local Test)",
                    "Local StoreKit test configuration fixture only. Not a customer offer.",
                ],
                "zh_CN": [
                    "花有数 Pro 年付（本地测试）",
                    "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
                ],
            ]
        )
    }

    @Test
    func fixtureHasOnlyTheAcceptedTrialAndNoLifetimeOrOtherOffers() throws {
        let data = try Data(contentsOf: try configurationURL())
        let text = try #require(String(data: data, encoding: .utf8))
        let catalog = try decodedCatalog()

        #expect(text.localizedCaseInsensitiveContains("lifetime") == false)
        #expect(
            catalog.subscriptionGroups
                .flatMap(\.subscriptions)
                .allSatisfy { $0.familyShareable == false }
        )
        #expect(
            catalog.subscriptionGroups
                .flatMap(\.subscriptions)
                .allSatisfy {
                    $0.introductoryOffers.count == 1
                        && $0.codeOffers.isEmpty
                        && $0.adHocOffers.isEmpty
                        && $0.winbackOffers.isEmpty
                }
        )
    }

    @Test(.enabled(if: Self.runsLocalStoreKitRuntimeTests))
    func runtimeCatalogLoadsForHongKong() async throws {
        try await exerciseRuntimeCatalog(storefront: "HKG", locale: "en_HK")
    }

    @Test(.enabled(if: Self.runsLocalStoreKitRuntimeTests))
    func runtimeCatalogLoadsForUnitedStates() async throws {
        try await exerciseRuntimeCatalog(storefront: "USA", locale: "en_US")
    }

    @Test(.enabled(if: Self.runsLocalStoreKitRuntimeTests))
    func runtimeCatalogLoadsForSingapore() async throws {
        try await exerciseRuntimeCatalog(storefront: "SGP", locale: "en_SG")
    }

    @Test(.enabled(if: Self.runsLocalStoreKitRuntimeTests))
    func runtimeCatalogLoadsForTaiwan() async throws {
        try await exerciseRuntimeCatalog(storefront: "TWN", locale: "en_TW")
    }

    @Test(.enabled(if: Self.runsLocalStoreKitRuntimeTests))
    func runtimeMonthlyPurchaseIsVerifiedGrantedAndFinished() async throws {
        try await exerciseVerifiedPurchaseAndFinish(.proMonthly)
    }

    @Test(.enabled(if: Self.runsLocalStoreKitRuntimeTests))
    func runtimeAnnualPurchaseIsVerifiedGrantedAndFinished() async throws {
        try await exerciseVerifiedPurchaseAndFinish(.proAnnual)
    }

    private func decodedCatalog() throws -> StoreKitConfigurationCatalog {
        let data = try Data(contentsOf: try configurationURL())
        return try JSONDecoder().decode(StoreKitConfigurationCatalog.self, from: data)
    }

    private func configurationURL() throws -> URL {
        let bundle = Bundle(for: StoreKitTestCatalogBundleMarker.self)
        return try #require(
            bundle.url(forResource: "MindBudgetPro", withExtension: "storekit")
        )
    }

    private func preparedRuntimeSession() throws -> SKTestSession {
        let session = try SKTestSession(contentsOf: try configurationURL())
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        session.storefront = "USA"
        session.locale = Locale(identifier: "en_US")
        return session
    }

    private func exerciseRuntimeCatalog(
        storefront: String,
        locale: String
    ) async throws {
        let session = try SKTestSession(contentsOf: try configurationURL())
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        session.storefront = storefront
        session.locale = Locale(identifier: locale)

        let records = try await StoreKitProductLoader().loadProducts(
            identifiedBy: Set(StoreProductID.allCases.map(\.rawValue))
        )
        #expect(Set(records.map(\.id)) == Set(StoreProductID.allCases.map(\.rawValue)))
        #expect(records.allSatisfy { $0.isAutoRenewable })
        #expect(records.allSatisfy { !$0.isFamilyShareable })
        #expect(records.allSatisfy { !$0.displayPrice.isEmpty })
        // Exact fixture JSON owns its USD literal. Runtime StoreKit owns the localized zero-price
        // rendering, which legitimately differs across HKG/USA/SGP/TWN.
        #expect(
            records.allSatisfy { record in
                record.introductoryOffer?.period
                    == StoreSubscriptionPeriod(value: 1, unit: .week)
                    && record.introductoryOffer?.periodCount == 1
                    && record.introductoryOffer?.paymentMode == .freeTrial
                    && record.introductoryOffer?.displayPrice.isEmpty == false
            }
        )
    }

    private func exerciseVerifiedPurchaseAndFinish(
        _ productID: StoreProductID
    ) async throws {
        let session = try preparedRuntimeSession()
        // A unit-test host has no purchase-confirmation UI anchor. Seed the real StoreKit
        // transaction here; the presented `Product.purchase()` path belongs to the later
        // purchase UI packet. This test owns the production verification, authority, and
        // acknowledgement boundary after StoreKit has created a transaction.
        try await session.buyProduct(identifier: productID.rawValue)

        let source = StoreKitEntitlementSource()
        let beforeStart = await source.unfinishedTransactions()
        #expect(beforeStart.unverifiedCount == 0)
        #expect(beforeStart.transactions.count == 1)
        #expect(beforeStart.transactions.first?.facts.productID == productID.rawValue)

        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: authority
        )
        await store.start()

        #expect(authority.decision(for: .advancedSiri) == .allowed)
        let lifecycleSnapshot = await store.currentSnapshot()
        #expect(lifecycleSnapshot.effectiveState == .subscribed)
        #expect(lifecycleSnapshot.trialLifecycle?.productID == productID)
        #expect(lifecycleSnapshot.trialLifecycle?.renewalDate != nil)
        #expect(lifecycleSnapshot.trialLifecycle?.willAutoRenew == true)
        #expect(
            session.allTransactions().filter {
                $0.productIdentifier == productID.rawValue
            }.count == 1
        )

        let unfinished = await source.unfinishedTransactions()
        #expect(unfinished.transactions.isEmpty)
        #expect(unfinished.unverifiedCount == 0)

        await store.stop()
    }

    private static var runsLocalStoreKitRuntimeTests: Bool {
        ProcessInfo.processInfo.environment["MINDBUDGET_LOCAL_STOREKIT_RUNTIME_TESTS"] == "1"
    }
}

private final class StoreKitTestCatalogBundleMarker {}

private struct StoreKitConfigurationCatalog: Decodable {
    let settings: StoreKitConfigurationSettings
    let products: [IgnoredStoreKitItem]
    let nonRenewingSubscriptions: [IgnoredStoreKitItem]
    let subscriptionGroups: [StoreKitSubscriptionGroup]
}

private struct StoreKitConfigurationSettings: Decodable {
    let storefront: String
    let locale: String

    enum CodingKeys: String, CodingKey {
        case storefront = "_storefront"
        case locale = "_locale"
    }
}

private struct IgnoredStoreKitItem: Decodable {}

private struct StoreKitSubscriptionGroup: Decodable {
    let id: String
    let name: String
    let subscriptions: [StoreKitSubscription]
}

private struct StoreKitSubscription: Decodable {
    let adHocOffers: [IgnoredStoreKitItem]
    let billingPlans: [StoreKitBillingPlan]
    let codeOffers: [IgnoredStoreKitItem]
    let displayPrice: String
    let familyShareable: Bool
    let groupNumber: Int
    let introductoryOffers: [StoreKitIntroductoryOffer]
    let localizations: [StoreKitProductLocalization]
    let productID: String
    let recurringSubscriptionPeriod: String
    let referenceName: String
    let subscriptionGroupID: String
    let type: String
    let winbackOffers: [IgnoredStoreKitItem]
}

private struct StoreKitIntroductoryOffer: Decodable {
    let billingPlanType: String
    let numberOfPeriods: Int
    let paymentMode: String
    let subscriptionPeriod: String
}

private struct StoreKitBillingPlan: Decodable {
    let billingPlanType: String
    let commitmentDisplayPrice: String
    let displayPrice: String
    let isEnabled: Bool
}

private struct StoreKitProductLocalization: Decodable {
    let description: String
    let displayName: String
    let locale: String
}
