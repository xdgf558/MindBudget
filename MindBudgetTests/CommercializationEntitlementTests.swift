import Foundation
import Testing
@testable import MindBudget

struct CommercializationEntitlementTests {
    @Test
    func freeIsTheExactEmptyEntitlementSet() {
        #expect(EntitlementSet.free.isFree)
        #expect(EntitlementSet.free.contains(.proSubscription) == false)
        #expect(EntitlementSet.union([EntitlementSet]()) == .free)
    }

    @Test(arguments: AcceptedSubscriptionFixture.allCases)
    func subscribedAndGraceFixturesProduceTheSameReachableRight(
        fixture: AcceptedSubscriptionFixture
    ) {
        #expect(fixture.entitlements == .proSubscription)
        #expect(fixture.entitlements.contains(.proSubscription))
        #expect(fixture.entitlements.isFree == false)
    }

    @Test
    func unionIsIdempotentCommutativeAndIgnoresDuplicateInput() {
        let duplicateUnion = EntitlementSet.union([
            .proSubscription,
            .proSubscription,
            .free,
        ])

        #expect(duplicateUnion == .proSubscription)
        #expect(duplicateUnion.union(.proSubscription) == duplicateUnion)
        #expect(EntitlementSet.free.union(.proSubscription) == .proSubscription.union(.free))
    }

    @Test
    func removingSubscriptionReturnsExactFreeWithoutResidualRights() {
        let granted = EntitlementSet.free.union(.proSubscription)
        let removed = granted.removing(.proSubscription)

        #expect(removed == .free)
        #expect(removed.isFree)
        #expect(removed.contains(.proSubscription) == false)
    }

    @Test
    func versionOneRepresentationRoundTripsSubscriptionAndFree() throws {
        for original in [EntitlementSet.free, .proSubscription] {
            let representation = EntitlementSetMigrator.representation(for: original)
            let encoded = try JSONEncoder().encode(representation)
            let decoded = try JSONDecoder().decode(
                EntitlementSetRepresentation.self,
                from: encoded
            )

            #expect(representation.version == EntitlementSetMigrator.currentVersion)
            #expect(try EntitlementSetMigrator.migrate(decoded) == original)
        }
    }

    @Test
    func unknownAndDeferredBitsFailClosedToExactFree() {
        let unknownBit: UInt64 = 1 << 1
        let representation = EntitlementSetRepresentation(
            version: EntitlementSetMigrator.currentVersion,
            rawBits: unknownBit
        )

        #expect(throws: EntitlementSetMigrationError.unknownEntitlementBits(unknownBit)) {
            try EntitlementSetMigrator.migrate(representation)
        }
        #expect(EntitlementSetMigrator.resolveFailClosed(representation) == .free)
    }

    @Test
    func unsupportedRepresentationVersionFailsClosedToExactFree() {
        let futureVersion = EntitlementSetMigrator.currentVersion + 1
        let representation = EntitlementSetRepresentation(
            version: futureVersion,
            rawBits: 1
        )

        #expect(throws: EntitlementSetMigrationError.unsupportedVersion(futureVersion)) {
            try EntitlementSetMigrator.migrate(representation)
        }
        #expect(EntitlementSetMigrator.resolveFailClosed(representation) == .free)
    }

    @Test(arguments: FreeCoreFeature.allCases)
    func freeTrustCapabilitiesCannotBeConstructedAsPremium(feature: FreeCoreFeature) {
        #expect(PremiumFeature(rawValue: feature.rawValue) == nil)
    }

    @Test
    func currentReleaseExposesOnlyTheAcceptedSubscriptionRight() {
        #expect(EntitlementSet.reachablePaidEntitlements == [.proSubscription])
    }

    @Test
    func premiumVocabularyContainsOnlyOwnerApprovedReachableSeams() {
        #expect(Set(PremiumFeature.allCases) == Set([
            .unlimitedCategoryBudgets,
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
            .appleWatchCompanion,
        ]))
    }
}

enum AcceptedSubscriptionFixture: CaseIterable, Sendable {
    case subscribed
    case gracePeriod

    var entitlements: EntitlementSet {
        switch self {
        case .subscribed, .gracePeriod:
            .proSubscription
        }
    }
}
