import Foundation
import Testing
@testable import MindBudget

@Suite(.serialized)
struct StoreRuntimeTests {
    @Test
    func verifiedAppIdentityIsTheOnlyAuthorityForAStoreEnvironment() async {
        let policy = StoreAppIdentityPolicy(expectedBundleID: "com.xdgf558.MindBudget")

        for environment in [
            StoreRuntimeEnvironment.xcode,
            .sandbox,
            .production,
        ] {
            #expect(
                policy.acceptedEnvironment(
                    for: StoreAppIdentity(
                        bundleID: "com.xdgf558.MindBudget",
                        environment: environment
                    )
                ) == environment
            )
        }
        #expect(
            policy.acceptedEnvironment(
                for: StoreAppIdentity(
                    bundleID: "com.example.other-app",
                    environment: .production
                )
            ) == nil
        )
        #expect(
            policy.acceptedEnvironment(
                for: StoreAppIdentity(
                    bundleID: "com.xdgf558.MindBudget",
                    environment: StoreRuntimeEnvironment(rawValue: "Unknown")
                )
            ) == nil
        )
        #expect(
            StoreAppIdentityPolicy(expectedBundleID: "").acceptedEnvironment(
                for: StoreAppIdentity(
                    bundleID: "",
                    environment: .sandbox
                )
            ) == nil
        )

        let contextProvider = StoreKitCatalogContextProvider(
            expectedBundleID: "com.xdgf558.MindBudget",
            appEnvironmentProvider: FixedStoreAppEnvironmentProvider(environment: .sandbox)
        )
        #expect((await contextProvider.currentContext()).environment == .sandbox)

        let unavailableContextProvider = StoreKitCatalogContextProvider(
            expectedBundleID: "com.xdgf558.MindBudget",
            appEnvironmentProvider: FixedStoreAppEnvironmentProvider(environment: nil)
        )
        #expect(
            (await unavailableContextProvider.currentContext()).environment
                == StoreRuntimeEnvironment(rawValue: "Unknown")
        )
    }

    @Test
    func entitlementAuthorityRejectsEveryCrossEnvironmentOrBundleMismatch() {
        let mapper = SubscriptionStatusMapper()

        for environment in [
            StoreRuntimeEnvironment.xcode,
            .sandbox,
            .production,
        ] {
            let exact = mapper.resolve(
                StoreEntitlementRead(
                    transactions: [verifiedTransaction(environment: environment)],
                    unverifiedCount: 0,
                    appEnvironment: environment
                )
            )
            #expect(exact.isActionable)
            #expect(exact.hasActiveSubscription)
            #expect(exact.environment == environment)
        }

        let mismatches: [(StoreRuntimeEnvironment, StoreRuntimeEnvironment)] = [
            (StoreRuntimeEnvironment.xcode, .sandbox),
            (.sandbox, .production),
            (.production, .sandbox),
        ]
        for (transactionEnvironment, appEnvironment) in mismatches {
            #expect(
                mapper.resolve(
                    StoreEntitlementRead(
                        transactions: [
                            verifiedTransaction(environment: transactionEnvironment)
                        ],
                        unverifiedCount: 0,
                        appEnvironment: appEnvironment
                    )
                ) == .failedClosed
            )
        }

        #expect(
            mapper.resolve(
                StoreEntitlementRead(
                    transactions: [verifiedTransaction(environment: .production)],
                    unverifiedCount: 0,
                    appEnvironment: nil
                )
            ) == .failedClosed
        )
        #expect(
            mapper.resolve(
                StoreEntitlementRead(
                    transactions: [
                        verifiedTransaction(
                            environment: .production,
                            hasVerifiedAppBundle: false
                        )
                    ],
                    unverifiedCount: 0,
                    appEnvironment: .production
                )
            ) == .failedClosed
        )
    }

    @Test
    func readMergerRejectsConflictingAppEnvironmentAuthorities() {
        let current = paidRead(environment: .sandbox)
        let supplemental = paidRead(environment: .production)
        let merged = StoreEntitlementReadMerger().merge(
            current: current,
            supplemental: supplemental
        )

        #expect(merged.isComplete == false)
        #expect(merged.appEnvironment == nil)
        #expect(SubscriptionStatusMapper().resolve(merged) == .failedClosed)
    }

    @Test
    func productFailureUsesOnlyAnExactEnvironmentAndStorefrontPresentationCache() async {
        let china = StoreCatalogContext(environment: .xcode, storefrontCountryCode: "CHN")
        let usa = StoreCatalogContext(environment: .xcode, storefrontCountryCode: "USA")
        let sandboxChina = StoreCatalogContext(environment: .sandbox, storefrontCountryCode: "CHN")
        let cache = TestStorePresentationCache()
        let liveCatalog = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: china),
            productLoader: TestStoreProductLoader(result: .success(validRecords())),
            presentationCache: cache
        )

        let live = await liveCatalog.refresh()
        #expect(live.snapshot?.context == china)
        #expect(live.snapshot?.products.count == 2)
        #expect(
            live.snapshot?.products.allSatisfy(\.isEligibleForIntroductoryOffer) == true
        )

        let failedSameContext = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: china),
            productLoader: TestStoreProductLoader(result: .failure(.loadFailed)),
            presentationCache: cache
        )
        guard case let .cached(cached) = await failedSameContext.refresh() else {
            Issue.record("An exact-context presentation cache should soften a product-load failure")
            return
        }
        #expect(cached.context == china)
        #expect(
            cached.products.allSatisfy { !$0.isEligibleForIntroductoryOffer }
        )

        let failedOtherStorefront = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: usa),
            productLoader: TestStoreProductLoader(result: .failure(.loadFailed)),
            presentationCache: cache
        )
        #expect(await failedOtherStorefront.refresh() == .unavailable)

        let failedOtherEnvironment = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: sandboxChina),
            productLoader: TestStoreProductLoader(result: .failure(.loadFailed)),
            presentationCache: cache
        )
        #expect(await failedOtherEnvironment.refresh() == .unavailable)

        await liveCatalog.clearPresentationCache()
        #expect(await cache.load(for: china) == nil)
    }

    @Test
    func catalogRejectsPartialOrMalformedProductsInsteadOfInventingTerms() async {
        let context = StoreCatalogContext(environment: .xcode, storefrontCountryCode: "CHN")
        let cache = TestStorePresentationCache()
        let partial = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: context),
            productLoader: TestStoreProductLoader(
                result: .success(Array(validRecords().prefix(1)))
            ),
            presentationCache: cache
        )
        #expect(await partial.refresh() == .unavailable)

        var malformed = validRecords()
        malformed[0] = StoreProductRecord(
            id: malformed[0].id,
            displayName: malformed[0].displayName,
            description: malformed[0].description,
            displayPrice: malformed[0].displayPrice,
            isAutoRenewable: true,
            isFamilyShareable: true,
            subscriptionGroupID: malformed[0].subscriptionGroupID,
            subscriptionPeriod: malformed[0].subscriptionPeriod,
            introductoryOffer: malformed[0].introductoryOffer,
            isEligibleForIntroductoryOffer: malformed[0].isEligibleForIntroductoryOffer
        )
        let familyShared = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: context),
            productLoader: TestStoreProductLoader(result: .success(malformed)),
            presentationCache: cache
        )
        #expect(await familyShared.refresh() == .unavailable)
    }

    @Test
    func catalogContractRequiresTheExactMonthlyAnnualPairInOneSubscriptionGroup() throws {
        let valid = validRecords()
        let validated = try StoreCatalogContract.validate(valid)

        #expect(Set(validated.keys) == Set(StoreProductID.allCases))
        #expect(validated[.proMonthly]?.subscriptionPeriod == .init(value: 1, unit: .month))
        #expect(validated[.proAnnual]?.subscriptionPeriod == .init(value: 1, unit: .year))
        #expect(
            try StoreCatalogContract.validatedRecord(for: .proAnnual, in: valid).id
                == StoreProductID.proAnnual.rawValue
        )

        #expect(throws: StoreCatalogValidationError.productSetMismatch) {
            _ = try StoreCatalogContract.validate(Array(valid.prefix(1)))
        }
        #expect(throws: StoreCatalogValidationError.productSetMismatch) {
            _ = try StoreCatalogContract.validate(valid + [valid[0]])
        }
        let unapproved = StoreProductRecord(
            id: "unapproved.product",
            displayName: "Unapproved",
            description: "Unapproved",
            displayPrice: "CN¥0.01",
            isAutoRenewable: true,
            isFamilyShareable: false,
            subscriptionGroupID: "mindbudget-pro-group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryOffer: testFreeTrialTerms,
            isEligibleForIntroductoryOffer: true
        )
        #expect(throws: StoreCatalogValidationError.productSetMismatch) {
            _ = try StoreCatalogContract.validate(valid + [unapproved])
        }

        var wrongGroup = valid
        wrongGroup[1] = replacing(wrongGroup[1], subscriptionGroupID: "different-group")
        #expect(throws: StoreCatalogValidationError.subscriptionGroupMismatch) {
            _ = try StoreCatalogContract.validate(wrongGroup)
        }

        var missingGroup = valid
        missingGroup[0] = StoreProductRecord(
            id: missingGroup[0].id,
            displayName: missingGroup[0].displayName,
            description: missingGroup[0].description,
            displayPrice: missingGroup[0].displayPrice,
            isAutoRenewable: missingGroup[0].isAutoRenewable,
            isFamilyShareable: missingGroup[0].isFamilyShareable,
            subscriptionGroupID: nil,
            subscriptionPeriod: missingGroup[0].subscriptionPeriod,
            introductoryOffer: missingGroup[0].introductoryOffer,
            isEligibleForIntroductoryOffer: missingGroup[0].isEligibleForIntroductoryOffer
        )
        #expect(throws: StoreCatalogValidationError.subscriptionGroupMismatch) {
            _ = try StoreCatalogContract.validate(missingGroup)
        }
    }

    @Test
    func catalogContractRejectsMalformedSubscriptionsButTreatsOffersAsOptionalPresentation() throws {
        let valid = validRecords()
        let monthlyID = StoreProductID.proMonthly.rawValue

        var notRenewing = valid
        notRenewing[0] = replacing(notRenewing[0], isAutoRenewable: false)
        #expect(throws: StoreCatalogValidationError.invalidSubscription(monthlyID)) {
            _ = try StoreCatalogContract.validate(notRenewing)
        }

        var familyShared = valid
        familyShared[0] = replacing(familyShared[0], isFamilyShareable: true)
        #expect(throws: StoreCatalogValidationError.invalidSubscription(monthlyID)) {
            _ = try StoreCatalogContract.validate(familyShared)
        }

        var wrongPeriod = valid
        wrongPeriod[0] = replacing(
            wrongPeriod[0],
            subscriptionPeriod: .init(value: 1, unit: .year)
        )
        #expect(throws: StoreCatalogValidationError.invalidSubscription(monthlyID)) {
            _ = try StoreCatalogContract.validate(wrongPeriod)
        }

        var missingTrial = valid
        missingTrial[0] = replacing(missingTrial[0], removesIntroductoryOffer: true)
        #expect(try StoreCatalogContract.validate(missingTrial)[.proMonthly]?.introductoryOffer == nil)

        var changedTrial = valid
        changedTrial[0] = replacing(
            changedTrial[0],
            introductoryOffer: StoreIntroductoryOfferTerms(
                period: .init(value: 2, unit: .week),
                periodCount: 1,
                displayPrice: "FREE_TRIAL_PRICE_TOKEN",
                paymentMode: .freeTrial
            )
        )
        #expect(
            try StoreCatalogContract.validate(changedTrial)[.proMonthly]?.introductoryOffer
                == changedTrial[0].introductoryOffer
        )
    }

    @Test
    func proCommerceNoticesCoverEveryTypedPurchaseAndRestoreOutcome() {
        #expect(ProCommerceNotice(purchaseOutcome: .purchased) == .purchased)
        #expect(ProCommerceNotice(purchaseOutcome: .pending) == .pending)
        #expect(ProCommerceNotice(purchaseOutcome: .cancelled) == .cancelled)
        #expect(ProCommerceNotice(restoreOutcome: .restored) == .restored)
        #expect(
            ProCommerceNotice(restoreOutcome: .noActiveSubscription)
                == .noActiveSubscription
        )

        let failures: [(StoreOperationFailure, ProCommerceNotice)] = [
            (.operationInProgress, .operationInProgress),
            (.productUnavailable, .productUnavailable),
            (.unsupportedIntroductoryOffer, .unsupportedIntroductoryOffer),
            (.purchasesNotAllowed, .purchasesNotAllowed),
            (.verificationFailed, .verificationFailed),
            (.invalidStoreState, .invalidStoreState),
            (.unavailable, .unavailable),
        ]
        for (failure, expectedNotice) in failures {
            #expect(
                ProCommerceNotice(purchaseOutcome: .failed(failure)) == expectedNotice
            )
            #expect(
                ProCommerceNotice(restoreOutcome: .failed(failure)) == expectedNotice
            )
            #expect(expectedNotice.isFailure)
        }

        #expect(!ProCommerceNotice.pending.isFailure)
        #expect(!ProCommerceNotice.cancelled.isFailure)
        #expect(!ProCommerceNotice.noActiveSubscription.isFailure)
    }

    @Test
    func renewalDisclosureUsesStoreKitOfferAndExplicitApplicationLocale() {
        let priceToken = "STOREKIT_PRICE_TOKEN_731"
        let eligibleProduct = StoreProductPresentation(
            id: .proAnnual,
            displayName: "Annual",
            description: "Annual",
            displayPrice: priceToken,
            subscriptionPeriod: .init(value: 1, unit: .year),
            introductoryOffer: testFreeTrialTerms,
            isEligibleForIntroductoryOffer: true
        )
        let ineligibleProduct = StoreProductPresentation(
            id: .proAnnual,
            displayName: "Annual",
            description: "Annual",
            displayPrice: priceToken,
            subscriptionPeriod: .init(value: 1, unit: .year),
            introductoryOffer: testFreeTrialTerms,
            isEligibleForIntroductoryOffer: false
        )

        let englishTrial = ProCommerceCopy.renewalDisclosure(
            for: eligibleProduct,
            locale: Locale(identifier: "en")
        )
        let chineseTrial = ProCommerceCopy.renewalDisclosure(
            for: eligibleProduct,
            locale: Locale(identifier: "zh-Hans")
        )
        let standardDisclosure = ProCommerceCopy.renewalDisclosure(
            for: ineligibleProduct,
            locale: Locale(identifier: "en")
        )
        #expect(englishTrial.contains(priceToken))
        #expect(englishTrial.localizedCaseInsensitiveContains("free"))
        #expect(chineseTrial.contains(priceToken))
        #expect(chineseTrial.contains("免费"))
        #expect(englishTrial != chineseTrial)
        #expect(englishTrial != standardDisclosure)
    }

    @Test
    func unavailableSubscriptionAuthorityNeverPermitsThePurchaseSurface() {
        #expect(ProCommercePurchaseGate.hasConfirmedAuthority(.none))
        #expect(ProCommercePurchaseGate.hasConfirmedAuthority(.expired))
        #expect(ProCommercePurchaseGate.hasConfirmedAuthority(.revoked))
        #expect(!ProCommercePurchaseGate.hasConfirmedAuthority(.unavailable))
    }

    @Test
    func eligiblePayAsYouGoOfferRetainsItsPriceAndPausesPurchase() {
        let payAsYouGo = StoreProductPresentation(
            id: .proMonthly,
            displayName: "Monthly",
            description: "Monthly",
            displayPrice: "STANDARD_MONTHLY_PRICE",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryOffer: StoreIntroductoryOfferTerms(
                period: .init(value: 1, unit: .month),
                periodCount: 3,
                displayPrice: "INSTALLMENT_OFFER_PRICE",
                paymentMode: .payAsYouGo
            ),
            isEligibleForIntroductoryOffer: true
        )
        #expect(payAsYouGo.introductoryOffer?.displayPrice == "INSTALLMENT_OFFER_PRICE")
        #expect(payAsYouGo.introductoryOffer?.paymentMode == .payAsYouGo)
        #expect(!ProCommercePurchaseGate.supportsIntroductoryOffer(payAsYouGo))
    }

    @Test
    func eligiblePayUpFrontOfferRetainsItsPriceAndPausesPurchase() {
        let payUpFront = StoreProductPresentation(
            id: .proAnnual,
            displayName: "Annual",
            description: "Annual",
            displayPrice: "STANDARD_ANNUAL_PRICE",
            subscriptionPeriod: .init(value: 1, unit: .year),
            introductoryOffer: StoreIntroductoryOfferTerms(
                period: .init(value: 3, unit: .month),
                periodCount: 1,
                displayPrice: "UPFRONT_OFFER_PRICE",
                paymentMode: .payUpFront
            ),
            isEligibleForIntroductoryOffer: true
        )

        #expect(payUpFront.introductoryOffer?.displayPrice == "UPFRONT_OFFER_PRICE")
        #expect(payUpFront.introductoryOffer?.paymentMode == .payUpFront)
        #expect(!ProCommercePurchaseGate.supportsIntroductoryOffer(payUpFront))
    }

    @Test
    func ineligibleOrUnknownIntroductoryOffersCannotBeMisrepresented() {
        let paidButIneligible = StoreProductPresentation(
            id: .proMonthly,
            displayName: "Monthly",
            description: "Monthly",
            displayPrice: "STANDARD_PRICE",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryOffer: StoreIntroductoryOfferTerms(
                period: .init(value: 1, unit: .month),
                periodCount: 2,
                displayPrice: "PAID_OFFER_PRICE",
                paymentMode: .payAsYouGo
            ),
            isEligibleForIntroductoryOffer: false
        )
        let unknownEligibleMode = StoreProductPresentation(
            id: .proMonthly,
            displayName: "Monthly",
            description: "Monthly",
            displayPrice: "STANDARD_PRICE",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryOffer: StoreIntroductoryOfferTerms(
                period: .init(value: 1, unit: .month),
                periodCount: 1,
                displayPrice: "UNKNOWN_OFFER_PRICE",
                paymentMode: .init(rawValue: "futureStoreKitMode")
            ),
            isEligibleForIntroductoryOffer: true
        )

        #expect(ProCommercePurchaseGate.supportsIntroductoryOffer(paidButIneligible))
        #expect(!ProCommercePurchaseGate.supportsIntroductoryOffer(unknownEligibleMode))
        #expect(!ProCommerceCopy.hasPresentableFreeTrial(unknownEligibleMode))
    }

    @Test
    func launchReconciliationUsesVerifiedCurrentStateAndNeverThePresentationCache() async {
        let authority = LiveFeatureAccessAuthority()
        let source = TestStoreEntitlementSource(
            read: paidRead(environment: .xcode)
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await store.start()
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect((await store.currentSnapshot()).environment == .xcode)
        await store.stop()
    }

    @Test
    func concurrentStartsOwnOneListenerAndUpdatesReconcileFromCurrentState() async {
        let authority = LiveFeatureAccessAuthority()
        let source = TestStoreEntitlementSource(
            read: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<24 {
                group.addTask { await store.start() }
            }
        }
        await waitUntil { await source.listenerStartCount() == 1 }
        #expect(await source.listenerStartCount() == 1)
        #expect(authority.decision(for: .appleOnDeviceAI) == .requiresProSubscription)

        await source.setRead(paidRead(environment: .sandbox))
        source.sendUpdate()
        await waitUntil {
            authority.decision(for: .appleOnDeviceAI) == .allowed
        }
        #expect(authority.decision(for: .appleOnDeviceAI) == .allowed)
        #expect((await store.currentSnapshot()).environment == .sandbox)
        await store.stop()
    }

    @Test
    func mixedOrUnverifiedRuntimeStateFailsClosed() async {
        let authority = LiveFeatureAccessAuthority()
        let mixed = StoreEntitlementRead(
            transactions: [
                verifiedTransaction(environment: .sandbox),
                verifiedTransaction(environment: .production),
            ],
            unverifiedCount: 1,
            appEnvironment: .sandbox
        )
        let source = TestStoreEntitlementSource(read: mixed)
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).environment == nil)
        #expect((await store.currentSnapshot()).unverifiedCount == 1)
        await store.stop()
    }

    @Test
    func unknownProductOrEnvironmentCannotHideBesideAnAcceptedTransaction() async {
        let authority = LiveFeatureAccessAuthority()
        let accepted = verifiedTransaction(environment: .production)
        let unknownProduct = VerifiedStoreTransaction(
            transactionID: 9_001,
            productID: "unapproved.product",
            environment: .production,
            isPurchased: true,
            isRevoked: false,
            expirationDate: nil,
            subscriptionState: .subscribed,
            hasVerifiedStatusTransaction: true,
            hasVerifiedRenewalInfo: true,
            hasVerifiedAppBundle: true
        )
        let source = TestStoreEntitlementSource(
            read: StoreEntitlementRead(
                transactions: [accepted, unknownProduct],
                unverifiedCount: 0,
                appEnvironment: .production
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)

        let unknownEnvironment = VerifiedStoreTransaction(
            transactionID: 9_002,
            productID: StoreProductID.proMonthly.rawValue,
            environment: StoreRuntimeEnvironment(rawValue: "Unknown"),
            isPurchased: true,
            isRevoked: false,
            expirationDate: nil,
            subscriptionState: .subscribed,
            hasVerifiedStatusTransaction: true,
            hasVerifiedRenewalInfo: true,
            hasVerifiedAppBundle: true
        )
        await source.setRead(
            StoreEntitlementRead(
                transactions: [accepted, unknownEnvironment],
                unverifiedCount: 0,
                appEnvironment: .production
            )
        )
        source.sendUpdate()
        await waitUntil {
            (await store.currentSnapshot()).environment == nil
        }
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await store.stop()
    }

    @Test
    func anOlderSuspendedReadCannotOverwriteANewerEntitlementSnapshot() async {
        let authority = LiveFeatureAccessAuthority()
        let source = OutOfOrderStoreEntitlementSource(
            firstRead: paidRead(environment: .sandbox),
            laterRead: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        let startup = Task { await store.start() }
        await waitUntil {
            let reads = await source.readCount()
            let listeners = await source.listenerStartCount()
            return reads == 1 && listeners == 1
        }
        source.sendUpdate()
        await waitUntil { await source.readCount() == 2 }
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)

        await source.releaseFirstRead()
        await startup.value
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).environment == nil)
        await store.stop()
    }

    @Test
    func verifiedBillingGraceGrantsAccessDespitePastExpiration() async {
        let authority = LiveFeatureAccessAuthority()
        let graceCandidate = VerifiedStoreTransaction(
            transactionID: 9_003,
            productID: StoreProductID.proMonthly.rawValue,
            environment: .sandbox,
            isPurchased: true,
            isRevoked: false,
            expirationDate: Date(timeIntervalSince1970: 1),
            subscriptionState: .inGracePeriod,
            hasVerifiedStatusTransaction: true,
            hasVerifiedRenewalInfo: true,
            hasVerifiedAppBundle: true
        )
        let source = TestStoreEntitlementSource(
            read: StoreEntitlementRead(
                transactions: [graceCandidate],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()

        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect((await store.currentSnapshot()).environment == .sandbox)
        await store.stop()
    }

    @Test
    func revokedCurrentEntitlementStillFailsClosed() async {
        let authority = LiveFeatureAccessAuthority()
        let revoked = VerifiedStoreTransaction(
            transactionID: 9_004,
            productID: StoreProductID.proMonthly.rawValue,
            environment: .sandbox,
            isPurchased: true,
            isRevoked: true,
            expirationDate: Date.distantFuture,
            subscriptionState: .revoked,
            hasVerifiedStatusTransaction: true,
            hasVerifiedRenewalInfo: true,
            hasVerifiedAppBundle: true
        )
        let source = TestStoreEntitlementSource(
            read: StoreEntitlementRead(
                transactions: [revoked],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()

        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).environment == nil)
        await store.stop()
    }

    @MainActor
    @Test
    func appSessionPublishesPaidAccessAndItsRevocationToSwiftUIConsumers() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let authority = LiveFeatureAccessAuthority()
        let source = TestStoreEntitlementSource(read: paidRead(environment: .sandbox))
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: authority
        )
        let session = AppSession(
            dataActor: controller.dataActor,
            featureAccessService: authority,
            entitlementStore: store
        )

        #expect(session.existingPremiumEntryAccess.offersAppleOnDeviceAI == false)
        await session.startCommerceLifecycle()
        #expect(session.existingPremiumEntryAccess.offersAppleOnDeviceAI)
        #expect(session.existingPremiumEntryAccess.offersCustomCoolingOffDurations)
        #expect(session.existingPremiumEntryAccess.permitsAdvancedSiri)

        await source.setRead(
            StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            )
        )
        await session.refreshCommerceEntitlements()
        await waitUntil {
            await MainActor.run {
                session.existingPremiumEntryAccess.offersAppleOnDeviceAI == false
            }
        }

        #expect(session.existingPremiumEntryAccess.offersAppleOnDeviceAI == false)
        #expect(session.existingPremiumEntryAccess.offersCustomCoolingOffDurations == false)
        #expect(session.existingPremiumEntryAccess.permitsAdvancedSiri == false)
        await store.stop()
    }

    @Test
    func synchronousFeatureReadsRemainWholeDuringConcurrentReplacement() async {
        let authority = LiveFeatureAccessAuthority()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<200 {
                group.addTask {
                    authority.replaceEntitlements(index.isMultiple(of: 2) ? .free : .proSubscription)
                }
                group.addTask {
                    let result = authority.decision(for: .cloudCoach)
                    #expect(result == .allowed || result == .requiresProSubscription)
                }
            }
        }
    }

    private func validRecords() -> [StoreProductRecord] {
        [
            StoreProductRecord(
                id: StoreProductID.proMonthly.rawValue,
                displayName: "花有数 Pro 月付（本地测试）",
                description: "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
                displayPrice: "US$1.99",
                isAutoRenewable: true,
                isFamilyShareable: false,
                subscriptionGroupID: "mindbudget-pro-group",
                subscriptionPeriod: StoreSubscriptionPeriod(value: 1, unit: .month),
                introductoryOffer: testFreeTrialTerms,
                isEligibleForIntroductoryOffer: true
            ),
            StoreProductRecord(
                id: StoreProductID.proAnnual.rawValue,
                displayName: "花有数 Pro 年付（本地测试）",
                description: "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
                displayPrice: "US$19.99",
                isAutoRenewable: true,
                isFamilyShareable: false,
                subscriptionGroupID: "mindbudget-pro-group",
                subscriptionPeriod: StoreSubscriptionPeriod(value: 1, unit: .year),
                introductoryOffer: testFreeTrialTerms,
                isEligibleForIntroductoryOffer: true
            ),
        ]
    }

    private func replacing(
        _ record: StoreProductRecord,
        isAutoRenewable: Bool? = nil,
        isFamilyShareable: Bool? = nil,
        subscriptionGroupID: String? = nil,
        subscriptionPeriod: StoreSubscriptionPeriod? = nil,
        introductoryOffer: StoreIntroductoryOfferTerms? = nil,
        removesIntroductoryOffer: Bool = false
    ) -> StoreProductRecord {
        StoreProductRecord(
            id: record.id,
            displayName: record.displayName,
            description: record.description,
            displayPrice: record.displayPrice,
            isAutoRenewable: isAutoRenewable ?? record.isAutoRenewable,
            isFamilyShareable: isFamilyShareable ?? record.isFamilyShareable,
            subscriptionGroupID: subscriptionGroupID ?? record.subscriptionGroupID,
            subscriptionPeriod: subscriptionPeriod ?? record.subscriptionPeriod,
            introductoryOffer: removesIntroductoryOffer
                ? nil
                : (introductoryOffer ?? record.introductoryOffer),
            isEligibleForIntroductoryOffer: record.isEligibleForIntroductoryOffer
        )
    }

    private var testFreeTrialTerms: StoreIntroductoryOfferTerms {
        StoreIntroductoryOfferTerms(
            period: StoreSubscriptionPeriod(value: 1, unit: .week),
            periodCount: 1,
            displayPrice: "FREE_TRIAL_PRICE_TOKEN",
            paymentMode: .freeTrial
        )
    }

    private func paidRead(environment: StoreRuntimeEnvironment) -> StoreEntitlementRead {
        StoreEntitlementRead(
            transactions: [verifiedTransaction(environment: environment)],
            unverifiedCount: 0,
            appEnvironment: environment
        )
    }

    private func verifiedTransaction(
        environment: StoreRuntimeEnvironment,
        transactionID: UInt64 = 1,
        state: StoreSubscriptionState = .subscribed,
        hasVerifiedAppBundle: Bool = true
    ) -> VerifiedStoreTransaction {
        VerifiedStoreTransaction(
            transactionID: transactionID,
            productID: StoreProductID.proMonthly.rawValue,
            environment: environment,
            isPurchased: true,
            isRevoked: false,
            expirationDate: nil,
            subscriptionState: state,
            hasVerifiedStatusTransaction: true,
            hasVerifiedRenewalInfo: true,
            hasVerifiedAppBundle: hasVerifiedAppBundle
        )
    }

    private func waitUntil(
        _ predicate: @escaping @Sendable () async -> Bool
    ) async {
        for _ in 0..<200 {
            if await predicate() { return }
            await Task.yield()
        }
    }
}

private struct FixedStoreContextProvider: StoreCatalogContextProviding {
    let context: StoreCatalogContext

    func currentContext() async -> StoreCatalogContext { context }
}

private struct FixedStoreAppEnvironmentProvider: StoreAppEnvironmentProviding {
    let environment: StoreRuntimeEnvironment?

    func currentEnvironment() async -> StoreRuntimeEnvironment? { environment }
}

private enum TestStoreFailure: Error, Sendable {
    case loadFailed
}

private struct TestStoreProductLoader: StoreProductLoading {
    let result: Result<[StoreProductRecord], TestStoreFailure>

    func loadProducts(identifiedBy identifiers: Set<String>) async throws -> [StoreProductRecord] {
        try result.get()
    }
}

private actor TestStorePresentationCache: StorePresentationCaching {
    private var snapshots: [StoreCatalogContext: StoreCatalogSnapshot] = [:]

    func load(for context: StoreCatalogContext) -> StoreCatalogSnapshot? {
        snapshots[context]
    }

    func save(_ snapshot: StoreCatalogSnapshot) {
        snapshots[snapshot.context] = snapshot
    }

    func clear() {
        snapshots = [:]
    }
}

private final class TestUpdateChannel: @unchecked Sendable {
    let stream: AsyncStream<StoreTransactionSignal>
    let continuation: AsyncStream<StoreTransactionSignal>.Continuation

    init() {
        var captured: AsyncStream<StoreTransactionSignal>.Continuation?
        stream = AsyncStream { captured = $0 }
        continuation = captured!
    }
}

private struct TestStoreEntitlementSource: StoreEntitlementSourcing {
    private let state: TestEntitlementState
    private let channel = TestUpdateChannel()

    init(read: StoreEntitlementRead) {
        state = TestEntitlementState(read: read)
    }

    func currentAppEnvironment() async -> StoreRuntimeEnvironment? {
        await state.appEnvironment()
    }

    func currentEntitlements() async -> StoreEntitlementRead {
        await state.currentRead()
    }

    func unfinishedTransactions() async -> StoreUnfinishedTransactionRead {
        StoreUnfinishedTransactionRead(transactions: [], unverifiedCount: 0)
    }

    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async {
        await state.listenerStarted()
        for await signal in channel.stream {
            guard !Task.isCancelled else { return }
            await handler(signal)
        }
    }

    func setRead(_ read: StoreEntitlementRead) async {
        await state.setRead(read)
    }

    @MainActor
    func purchase(_ productID: StoreProductID) async throws -> StorePurchaseResult {
        .userCancelled
    }

    func synchronizePurchases() async throws {}

    func listenerStartCount() async -> Int {
        await state.startCount()
    }

    func sendUpdate() {
        channel.continuation.yield(.changed)
    }
}

private actor TestEntitlementState {
    private var read: StoreEntitlementRead
    private var listeners = 0

    init(read: StoreEntitlementRead) {
        self.read = read
    }

    func currentRead() -> StoreEntitlementRead { read }
    func appEnvironment() -> StoreRuntimeEnvironment? { read.appEnvironment }
    func setRead(_ read: StoreEntitlementRead) { self.read = read }
    func listenerStarted() { listeners += 1 }
    func startCount() -> Int { listeners }
}

private final class OutOfOrderStoreEntitlementSource: StoreEntitlementSourcing, @unchecked Sendable {
    private let state: OutOfOrderEntitlementState
    private let channel = TestUpdateChannel()

    init(firstRead: StoreEntitlementRead, laterRead: StoreEntitlementRead) {
        state = OutOfOrderEntitlementState(firstRead: firstRead, laterRead: laterRead)
    }

    func currentAppEnvironment() async -> StoreRuntimeEnvironment? {
        await state.appEnvironment()
    }

    func currentEntitlements() async -> StoreEntitlementRead {
        await state.read()
    }

    func unfinishedTransactions() async -> StoreUnfinishedTransactionRead {
        StoreUnfinishedTransactionRead(transactions: [], unverifiedCount: 0)
    }

    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async {
        await state.listenerStarted()
        for await signal in channel.stream {
            guard !Task.isCancelled else { return }
            await handler(signal)
        }
    }

    func readCount() async -> Int { await state.readCount() }
    func listenerStartCount() async -> Int { await state.listenerStartCount() }
    func releaseFirstRead() async { await state.releaseFirstRead() }
    func sendUpdate() { channel.continuation.yield(.changed) }

    @MainActor
    func purchase(_ productID: StoreProductID) async throws -> StorePurchaseResult {
        .userCancelled
    }

    func synchronizePurchases() async throws {}
}

private actor OutOfOrderEntitlementState {
    private let firstRead: StoreEntitlementRead
    private let laterRead: StoreEntitlementRead
    private var reads = 0
    private var listeners = 0
    private var firstReadContinuation: CheckedContinuation<StoreEntitlementRead, Never>?

    init(firstRead: StoreEntitlementRead, laterRead: StoreEntitlementRead) {
        self.firstRead = firstRead
        self.laterRead = laterRead
    }

    func read() async -> StoreEntitlementRead {
        reads += 1
        guard reads == 1 else { return laterRead }
        return await withCheckedContinuation { continuation in
            firstReadContinuation = continuation
        }
    }

    func appEnvironment() -> StoreRuntimeEnvironment? { laterRead.appEnvironment }

    func listenerStarted() { listeners += 1 }
    func readCount() -> Int { reads }
    func listenerStartCount() -> Int { listeners }

    func releaseFirstRead() {
        firstReadContinuation?.resume(returning: firstRead)
        firstReadContinuation = nil
    }
}
