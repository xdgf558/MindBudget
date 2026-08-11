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

    @Test
    func fullFeatureAccessMatrixRequiresTheAcceptedSubscription() {
        let freeService = FeatureAccessService(entitlements: .free)
        let subscribedService = FeatureAccessService(entitlements: .proSubscription)

        for feature in PremiumFeature.allCases {
            #expect(freeService.decision(for: feature) == .requiresProSubscription)
            #expect(freeService.decision(for: feature).isAllowed == false)
            #expect(subscribedService.decision(for: feature) == .allowed)
            #expect(subscribedService.decision(for: feature).isAllowed)
        }
    }

    @Test
    func featureAccessDefaultsToExactFreeAndRemovalReturnsToTheSameMatrix() {
        let defaultService = FeatureAccessService()
        let granted = EntitlementSet.free.union(.proSubscription)
        let removed = granted.removing(.proSubscription)
        let removedService = FeatureAccessService(entitlements: removed)

        #expect(removed.isFree)
        for feature in PremiumFeature.allCases {
            #expect(defaultService.decision(for: feature) == .requiresProSubscription)
            #expect(removedService.decision(for: feature) == .requiresProSubscription)
        }
    }

    @Test
    func existingPremiumEntriesConsumeOnlyTheCentralAccessAuthority() {
        let freeEntries = ExistingPremiumEntryAccess(
            featureAccess: FeatureAccessService(entitlements: .free)
        )
        let subscribedEntries = ExistingPremiumEntryAccess(
            featureAccess: FeatureAccessService(entitlements: .proSubscription)
        )

        #expect(freeEntries.enablesAppleOnDeviceAI(userEnabled: true) == false)
        #expect(freeEntries.offersCustomCoolingOffDurations == false)
        #expect(freeEntries.permitsAdvancedSiri == false)

        #expect(subscribedEntries.enablesAppleOnDeviceAI(userEnabled: false) == false)
        #expect(subscribedEntries.enablesAppleOnDeviceAI(userEnabled: true))
        #expect(subscribedEntries.offersCustomCoolingOffDurations)
        #expect(subscribedEntries.permitsAdvancedSiri)
    }

    @Test
    func immutableFeatureAccessSnapshotIsConsistentAcrossConcurrentReads() async {
        let service: any FeatureAccessChecking = FeatureAccessService(
            entitlements: .proSubscription
        )

        let snapshots = await withTaskGroup(
            of: [FeatureAccessDecision].self,
            returning: [[FeatureAccessDecision]].self
        ) { group in
            for _ in 0..<128 {
                group.addTask {
                    PremiumFeature.allCases.map { feature in
                        service.decision(for: feature)
                    }
                }
            }

            var results: [[FeatureAccessDecision]] = []
            for await snapshot in group {
                results.append(snapshot)
            }
            return results
        }

        #expect(snapshots.count == 128)
        #expect(snapshots.allSatisfy { decisions in
            decisions.count == PremiumFeature.allCases.count
                && decisions.allSatisfy { $0 == .allowed }
        })
    }

    @MainActor
    @Test
    func appSessionOwnsOneInjectedAuthorityWithAFreeDefault() throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let freeSession = AppSession(dataActor: controller.dataActor)

        #expect(freeSession.existingPremiumEntryAccess.offersAppleOnDeviceAI == false)
        #expect(freeSession.existingPremiumEntryAccess.offersCustomCoolingOffDurations == false)
        #expect(freeSession.existingPremiumEntryAccess.permitsAdvancedSiri == false)

        #if DEBUG
        let debugSession = AppSession(
            dataActor: controller.dataActor,
            featureAccessService: DebugFeatureAccessProvider(
                entitlements: .proSubscription
            )
        )
        #expect(debugSession.existingPremiumEntryAccess.offersAppleOnDeviceAI)
        #expect(debugSession.existingPremiumEntryAccess.offersCustomCoolingOffDurations)
        #expect(debugSession.existingPremiumEntryAccess.permitsAdvancedSiri)
        #endif
    }

    #if DEBUG
    @Test
    func debugProviderAcceptsEveryValidReachableCombinationWithoutPersistence() {
        let combinations: [EntitlementSet] = [
            .free,
            .proSubscription,
            EntitlementSet.union([.free, .proSubscription, .proSubscription]),
        ]

        for entitlements in combinations {
            let provider = DebugFeatureAccessProvider(entitlements: entitlements)
            let expected: FeatureAccessDecision = entitlements.isFree
                ? .requiresProSubscription
                : .allowed
            for feature in PremiumFeature.allCases {
                #expect(provider.decision(for: feature) == expected)
            }
        }
    }
    #endif
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
