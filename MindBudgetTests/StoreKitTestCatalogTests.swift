import Foundation
import StoreKitTest
import Testing

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
        #expect(annual.referenceName == "MindBudget Pro Annual")
        #expect(annual.recurringSubscriptionPeriod == "P1Y")

        for subscription in [monthly, annual] {
            #expect(subscription.type == "RecurringSubscription")
            #expect(subscription.subscriptionGroupID == group.id)
            #expect(subscription.groupNumber == 1)
            #expect(subscription.familyShareable == false)
            #expect(subscription.introductoryOffers.isEmpty)
            #expect(subscription.codeOffers.isEmpty)
            #expect(subscription.adHocOffers.isEmpty)
            #expect(subscription.winbackOffers.isEmpty)
            #expect(Set(subscription.localizations.map(\.locale)) == Set(["en_US", "zh_CN"]))
            #expect(
                subscription.localizations.allSatisfy {
                    $0.description.localizedCaseInsensitiveContains("test")
                        || $0.description.contains("测试")
                }
            )
        }
    }

    @Test
    func fixtureHasNoLifetimeOrFormalOfferMetadata() throws {
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
                    $0.introductoryOffers.isEmpty
                        && $0.codeOffers.isEmpty
                        && $0.adHocOffers.isEmpty
                        && $0.winbackOffers.isEmpty
                }
        )
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
}

private final class StoreKitTestCatalogBundleMarker {}

private struct StoreKitConfigurationCatalog: Decodable {
    let products: [IgnoredStoreKitItem]
    let nonRenewingSubscriptions: [IgnoredStoreKitItem]
    let subscriptionGroups: [StoreKitSubscriptionGroup]
}

private struct IgnoredStoreKitItem: Decodable {}

private struct StoreKitSubscriptionGroup: Decodable {
    let id: String
    let name: String
    let subscriptions: [StoreKitSubscription]
}

private struct StoreKitSubscription: Decodable {
    let adHocOffers: [IgnoredStoreKitItem]
    let codeOffers: [IgnoredStoreKitItem]
    let familyShareable: Bool
    let groupNumber: Int
    let introductoryOffers: [IgnoredStoreKitItem]
    let localizations: [StoreKitProductLocalization]
    let productID: String
    let recurringSubscriptionPeriod: String
    let referenceName: String
    let subscriptionGroupID: String
    let type: String
    let winbackOffers: [IgnoredStoreKitItem]
}

private struct StoreKitProductLocalization: Decodable {
    let description: String
    let locale: String
}
