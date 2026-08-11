import Foundation
import Testing
@testable import MindBudget

struct CommercializationEntitlementTests {
    @Test
    func freeIsTheExactEmptyEntitlementSet() {
        #expect(EntitlementSet.free.isFree)
        #expect(EntitlementSet.free.isSuperset(of: .proSubscription) == false)
        #expect(EntitlementSet.union([EntitlementSet]()) == .free)
    }

    @Test(arguments: AcceptedSubscriptionFixture.allCases)
    func acceptedSubscriptionVocabularyFixturesUseTheSameDomainRight(
        fixture: AcceptedSubscriptionFixture
    ) {
        // This is a C1-01 domain-vocabulary fixture, not proof of StoreKit state mapping. COM-C2
        // owns the subscribed/grace/retry/expired/revoked/unverified/pending mapping matrix.
        #expect(fixture.entitlements == .proSubscription)
        #expect(fixture.entitlements.isSuperset(of: .proSubscription))
        #expect(fixture.entitlements.isFree == false)
    }

    @Test
    func supersetSemanticsDoNotMisclassifyPaidUsersAsFree() {
        #expect(EntitlementSet.proSubscription.isSuperset(of: .free))
        #expect(EntitlementSet.proSubscription.isFree == false)
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
        #expect(removed.isSuperset(of: .proSubscription) == false)
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
        #expect(
            EntitlementSet.union(EntitlementSet.reachablePaidEntitlements).version1Bits
                == EntitlementSet.version1KnownBits
        )
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

/// A domain vocabulary fixture only. Production StoreKit status mapping does not exist in C1-01.
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
