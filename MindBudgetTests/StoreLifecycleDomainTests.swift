import Foundation
import Testing
@testable import MindBudget

@Suite(.serialized)
struct StoreLifecycleDomainTests {
    @Test
    func subscriptionStateMatrixGrantsOnlySubscribedAndVerifiedGrace() {
        let cases = [
            SubscriptionCase(
                state: .subscribed,
                isRevoked: false,
                expectsAccess: true,
                expectedState: .subscribed
            ),
            SubscriptionCase(
                state: .inGracePeriod,
                isRevoked: false,
                expectsAccess: true,
                expectedState: .inGracePeriod
            ),
            SubscriptionCase(
                state: .inBillingRetryPeriod,
                isRevoked: false,
                expectsAccess: false,
                expectedState: .inBillingRetryPeriod
            ),
            SubscriptionCase(
                state: .expired,
                isRevoked: false,
                expectsAccess: false,
                expectedState: .expired
            ),
            SubscriptionCase(
                state: .revoked,
                isRevoked: true,
                expectsAccess: false,
                expectedState: .revoked
            ),
        ]

        for (index, testCase) in cases.enumerated() {
            let facts = transactionFacts(
                id: UInt64(100 + index),
                state: testCase.state,
                isRevoked: testCase.isRevoked,
                // Expiration alone must never invent or preempt StoreKit's verified state.
                expirationDate: .distantPast
            )
            let resolution = SubscriptionStatusMapper().resolve(
                StoreEntitlementRead(
                    transactions: [facts],
                    unverifiedCount: 0,
                    appEnvironment: facts.environment
                )
            )

            #expect(resolution.isActionable)
            #expect(resolution.hasActiveSubscription == testCase.expectsAccess)
            #expect(resolution.effectiveState == testCase.expectedState)
            #expect(
                resolution.environment == (testCase.expectsAccess ? .sandbox : nil)
            )
        }

        let empty = SubscriptionStatusMapper().resolve(
            StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            )
        )
        #expect(empty.isActionable)
        #expect(empty.hasActiveSubscription == false)
        #expect(empty.effectiveState == .none)

        let incompletePaid = SubscriptionStatusMapper().resolve(
            StoreEntitlementRead(
                transactions: [transactionFacts(id: 199, state: .subscribed)],
                unverifiedCount: 0,
                isComplete: false,
                appEnvironment: .sandbox
            )
        )
        // Actionable means safe to use, not that every Product/catalog input was complete.
        // A separately verified active subscription survives a supplemental catalog failure.
        #expect(incompletePaid.isActionable)
        #expect(incompletePaid.hasActiveSubscription)

        let incompleteFree = SubscriptionStatusMapper().resolve(
            StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                isComplete: false,
                appEnvironment: .sandbox
            )
        )
        #expect(incompleteFree == .failedClosed)
    }

    @Test
    func unknownOrUnverifiedSubscriptionFactsFailClosedAsOneAuthoritySnapshot() {
        let accepted = transactionFacts(id: 200, state: .subscribed)
        let invalidFacts = [
            transactionFacts(
                id: 201,
                state: .subscribed,
                hasVerifiedStatusTransaction: false
            ),
            transactionFacts(
                id: 202,
                state: .subscribed,
                hasVerifiedRenewalInfo: false
            ),
            transactionFacts(id: 203, state: .unknown),
            transactionFacts(id: 204, state: .subscribed, isPurchased: false),
        ]

        for facts in invalidFacts {
            let resolution = SubscriptionStatusMapper().resolve(
                StoreEntitlementRead(
                    transactions: [accepted, facts],
                    unverifiedCount: 0,
                    appEnvironment: .sandbox
                )
            )
            #expect(resolution == .failedClosed)
        }

        let unverifiedTransaction = SubscriptionStatusMapper().resolve(
            StoreEntitlementRead(
                transactions: [accepted],
                unverifiedCount: 1,
                appEnvironment: .sandbox
            )
        )
        #expect(unverifiedTransaction == .failedClosed)
    }

    @Test
    func conflictingCurrentAndSupplementalReadsFailClosedInsteadOfChoosingAStaleFact() {
        let subscribed = transactionFacts(id: 205, state: .subscribed)
        let retry = transactionFacts(
            id: 205,
            state: .inBillingRetryPeriod,
            expirationDate: .distantPast
        )

        let conflicting = StoreEntitlementReadMerger().merge(
            current: entitlementRead(subscribed),
            supplemental: entitlementRead(retry)
        )
        #expect(conflicting.transactions.isEmpty)
        #expect(conflicting.isComplete == false)
        #expect(SubscriptionStatusMapper().resolve(conflicting) == .failedClosed)

        let stable = StoreEntitlementReadMerger().merge(
            current: entitlementRead(subscribed),
            supplemental: entitlementRead(subscribed)
        )
        #expect(stable.transactions == [subscribed])
        #expect(stable.isComplete)
        #expect(SubscriptionStatusMapper().resolve(stable).hasActiveSubscription)

        let conflictingProduct = transactionFacts(
            id: 205,
            state: .subscribed,
            productID: .proAnnual
        )
        let productConflict = StoreEntitlementReadMerger().merge(
            current: entitlementRead(subscribed),
            supplemental: entitlementRead(conflictingProduct)
        )
        #expect(productConflict.transactions.isEmpty)
        #expect(productConflict.isComplete == false)
        #expect(SubscriptionStatusMapper().resolve(productConflict) == .failedClosed)
    }

    @Test
    func verifiedPurchasePublishesAccessBeforeFinishingExactlyOnce() async {
        let recorder = FinishRecorder()
        let authority = LiveFeatureAccessAuthority()
        let purchased = finishableTransaction(
            facts: transactionFacts(id: 300, state: .subscribed),
            recorder: recorder,
            accessAuthority: authority
        )
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(.verified(purchased))
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        let outcome = await store.purchase(.proMonthly)

        #expect(outcome == .purchased)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect(await recorder.count(for: 300) == 1)
        #expect(await recorder.observedAllowedAccess(for: 300) == [true])
        #expect(await source.purchasedProductIDs() == [.proMonthly])
    }

    @Test
    func concurrentPurchaseAndUpdateForTheSameTransactionFinishExactlyOnce() async {
        let recorder = FinishRecorder()
        let finishGate = AsyncTestGate()
        let batchWaitObserver = TransactionBatchWaitObserver()
        let authority = LiveFeatureAccessAuthority()
        let facts = transactionFacts(id: 301, state: .subscribed)
        let purchaseTransaction = gatedFinishableTransaction(
            facts: facts,
            recorder: recorder,
            gate: finishGate,
            accessAuthority: authority
        )
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(.verified(purchaseTransaction))
        )
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: authority,
            transactionBatchWaitHandler: { ids in
                await batchWaitObserver.record(ids)
            }
        )
        await store.start()

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await finishGate.entryCount() == 1 })

        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await batchWaitObserver.count(for: 301) == 1 })
        await finishGate.release()

        let purchaseOutcome = await purchase.value
        #expect(purchaseOutcome == .purchased)
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect(await recorder.count(for: 301) == 1)
        #expect(await recorder.observedAllowedAccess(for: 301) == [true])
        await store.stop()
    }

    @Test
    func updateThatFinishesFirstStillLetsTheMatchingPurchaseReportSuccess() async {
        let recorder = FinishRecorder()
        let authority = LiveFeatureAccessAuthority()
        let facts = transactionFacts(id: 307, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(
                .verified(finishableTransaction(facts: facts, recorder: recorder))
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(await recorder.count(for: 307) == 1)
        #expect(authority.decision(for: .advancedSiri) == .allowed)

        #expect(await store.purchase(.proMonthly) == .purchased)
        #expect(await recorder.count(for: 307) == 1)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        await store.stop()
    }

    @Test
    func failedActiveFinishCannotBePromotedToSuccessByAWaitingDuplicate() async {
        let recorder = FinishRecorder()
        let finishGate = AsyncTestGate()
        let batchWaitObserver = TransactionBatchWaitObserver()
        let authority = LiveFeatureAccessAuthority()
        let facts = transactionFacts(id: 302, state: .subscribed)
        let failingPurchaseTransaction = gatedFinishableTransaction(
            facts: facts,
            recorder: recorder,
            gate: finishGate,
            succeeds: false,
            accessAuthority: authority
        )
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(.verified(failingPurchaseTransaction))
        )
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: authority,
            transactionBatchWaitHandler: { ids in
                await batchWaitObserver.record(ids)
            }
        )
        await store.start()

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await finishGate.entryCount() == 1 })

        // This duplicate advertises a successful finish, but it must inherit the active batch's
        // failure instead of running its own closure and treating the transaction as handled.
        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await batchWaitObserver.count(for: 302) == 1 })
        await finishGate.release()

        #expect(await purchase.value == .failed(.invalidStoreState))
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(await recorder.count(for: 302) == 1)

        // Because neither path marked the acknowledgement as finished, a later delivery retries.
        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await source.handledSignalCount() == 2 })
        #expect(await recorder.count(for: 302) == 2)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        await store.stop()
    }

    @Test
    func changedFactsForAnActiveAcknowledgementInvalidateTheOlderPurchaseBatch() async {
        let recorder = FinishRecorder()
        let finishGate = AsyncTestGate()
        let authority = LiveFeatureAccessAuthority()
        let subscribed = transactionFacts(id: 303, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(
                .verified(
                    gatedFinishableTransaction(
                        facts: subscribed,
                        recorder: recorder,
                        gate: finishGate
                    )
                )
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await finishGate.entryCount() == 1 })

        source.send(
            .verified(
                finishableTransaction(
                    facts: transactionFacts(
                        id: 303,
                        state: .inBillingRetryPeriod,
                        expirationDate: .distantPast
                    ),
                    recorder: recorder
                )
            )
        )
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)

        await finishGate.release()

        #expect(await purchase.value == .failed(.invalidStoreState))
        #expect(await recorder.count(for: 303) == 1)
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).effectiveState == .unavailable)
        await store.stop()
    }

    @Test
    func unverifiedUpdateDuringFinishPreventsTheOlderPurchaseFromReportingSuccess() async {
        let recorder = FinishRecorder()
        let finishGate = AsyncTestGate()
        let authority = LiveFeatureAccessAuthority()
        let facts = transactionFacts(id: 304, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(
                .verified(
                    gatedFinishableTransaction(
                        facts: facts,
                        recorder: recorder,
                        gate: finishGate
                    )
                )
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await finishGate.entryCount() == 1 })

        source.send(.unverified)
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)

        await finishGate.release()

        #expect(await purchase.value == .failed(.invalidStoreState))
        #expect(await recorder.count(for: 304) == 1)
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await store.stop()
    }

    @Test
    func verifiedStatusRefreshDuringFinishKeepsTheValidPurchaseSuccessful() async {
        let recorder = FinishRecorder()
        let finishGate = AsyncTestGate()
        let authority = LiveFeatureAccessAuthority()
        let facts = transactionFacts(id: 313, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            currentRead: entitlementRead(facts),
            purchasePlan: .result(
                .verified(
                    gatedFinishableTransaction(
                        facts: facts,
                        recorder: recorder,
                        gate: finishGate
                    )
                )
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await finishGate.entryCount() == 1 })

        // A successful purchase commonly causes StoreKit's status stream to refresh while the
        // transaction acknowledgement is still suspended. The newer whole snapshot still
        // contains this active transaction, so the purchase must not be misreported as failed.
        source.send(.changed)
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        await finishGate.release()

        #expect(await purchase.value == .purchased)
        #expect(await recorder.count(for: 313) == 1)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        await store.stop()
    }

    @Test
    func changeHandlerInvalidationBeforeReturnPreventsFinishAndPurchaseSuccess() async {
        let recorder = FinishRecorder()
        let snapshotGate = AsyncTestGate()
        let authority = LiveFeatureAccessAuthority()
        let facts = transactionFacts(id: 310, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(
                .verified(finishableTransaction(facts: facts, recorder: recorder))
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start { snapshot in
            guard snapshot.premiumEntryAccess.permitsAdvancedSiri else { return }
            await snapshotGate.enterAndWait()
        }

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await snapshotGate.entryCount() == 1 })

        source.send(.unverified)
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await snapshotGate.release()

        #expect(await purchase.value == .failed(.invalidStoreState))
        #expect(await recorder.count(for: 310) == 0)
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await store.stop()
    }

    @Test
    func unrelatedTransactionContinuesAfterAnActiveBatchFailsToFinish() async {
        let recorder = FinishRecorder()
        let finishGate = AsyncTestGate()
        let batchWaitObserver = TransactionBatchWaitObserver()
        let authority = LiveFeatureAccessAuthority()
        let failingFacts = transactionFacts(id: 305, state: .subscribed)
        let succeedingFacts = transactionFacts(
            id: 306,
            state: .subscribed,
            productID: .proAnnual
        )
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(
                .verified(
                    gatedFinishableTransaction(
                        facts: failingFacts,
                        recorder: recorder,
                        gate: finishGate,
                        succeeds: false
                    )
                )
            )
        )
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: authority,
            transactionBatchWaitHandler: { ids in
                await batchWaitObserver.record(ids)
            }
        )
        await store.start()

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await finishGate.entryCount() == 1 })

        source.send(
            .verified(
                finishableTransaction(facts: succeedingFacts, recorder: recorder)
            )
        )
        #expect(await eventually { await batchWaitObserver.count(for: 306) == 1 })
        await finishGate.release()

        #expect(await purchase.value == .failed(.invalidStoreState))
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(await recorder.count(for: 305) == 1)
        #expect(await recorder.count(for: 306) == 1)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        await store.stop()
    }

    @Test
    func finishedDifferentTransactionFactsAreReconciledAfterWaitingForAnActiveBatch() async {
        let recorder = FinishRecorder()
        let finishGate = AsyncTestGate()
        let batchWaitObserver = TransactionBatchWaitObserver()
        let authority = LiveFeatureAccessAuthority()
        let previouslyFinished = transactionFacts(id: 308, state: .subscribed)
        let activePurchase = transactionFacts(
            id: 309,
            state: .subscribed,
            productID: .proAnnual
        )
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(
                .verified(
                    gatedFinishableTransaction(
                        facts: activePurchase,
                        recorder: recorder,
                        gate: finishGate,
                        acknowledgementProductID: .proAnnual
                    )
                )
            )
        )
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: authority,
            transactionBatchWaitHandler: { ids in
                await batchWaitObserver.record(ids)
            }
        )
        await store.start()

        source.send(
            .verified(finishableTransaction(facts: previouslyFinished, recorder: recorder))
        )
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(await recorder.count(for: 308) == 1)

        let purchase = Task { await store.purchase(.proAnnual) }
        #expect(await eventually { await finishGate.entryCount() == 1 })

        source.send(
            .verified(
                finishableTransaction(
                    facts: transactionFacts(id: 308, state: .revoked, isRevoked: true),
                    recorder: recorder
                )
            )
        )
        #expect(await eventually { await batchWaitObserver.count(for: 308) == 1 })
        await finishGate.release()

        let purchaseOutcome = await purchase.value
        #expect(purchaseOutcome == .purchased)
        #expect(await eventually { await source.handledSignalCount() == 2 })
        let snapshot = await store.currentSnapshot()
        #expect(snapshot.observedStates.contains(.subscribed))
        #expect(snapshot.observedStates.contains(.revoked))
        #expect(await recorder.count(for: 308) == 1)
        #expect(await recorder.count(for: 309) == 1)
        await store.stop()
    }

    @Test
    func conflictingFinishedFactWaitsForThePendingBatchThenFailsClosed() async {
        let recorder = FinishRecorder()
        let pendingFinishGate = AsyncTestGate()
        let batchWaitObserver = TransactionBatchWaitObserver()
        let authority = LiveFeatureAccessAuthority()
        let finishedMonthly = transactionFacts(id: 311, state: .subscribed)
        let pendingAnnual = transactionFacts(
            id: 312,
            state: .subscribed,
            productID: .proAnnual
        )
        let source = ProgrammableStoreEntitlementSource(
            unfinishedRead: StoreUnfinishedTransactionRead(
                transactions: [
                    finishableTransaction(facts: finishedMonthly, recorder: recorder),
                    gatedFinishableTransaction(
                        facts: pendingAnnual,
                        recorder: recorder,
                        gate: pendingFinishGate,
                        acknowledgementProductID: .proAnnual
                    ),
                ],
                unverifiedCount: 0
            ),
            purchasePlan: .result(
                .verified(
                    finishableTransaction(facts: finishedMonthly, recorder: recorder)
                )
            )
        )
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: authority,
            transactionBatchWaitHandler: { ids in
                await batchWaitObserver.record(ids)
            }
        )

        // Finish A before startup. The startup batch then contains the finished duplicate A and
        // pending B, but only B may be advertised as the active acknowledgement identity.
        #expect(await store.purchase(.proMonthly) == .purchased)
        #expect(await recorder.count(for: 311) == 1)

        let startup = Task { await store.start() }
        #expect(await eventually { await pendingFinishGate.entryCount() == 1 })

        source.send(
            .verified(
                finishableTransaction(
                    facts: transactionFacts(id: 311, state: .revoked, isRevoked: true),
                    recorder: recorder
                )
            )
        )
        #expect(await eventually { await batchWaitObserver.count(for: 311) == 1 })
        await pendingFinishGate.release()

        await startup.value
        #expect(await eventually { await source.handledSignalCount() == 1 })
        let snapshot = await store.currentSnapshot()
        #expect(snapshot.effectiveState == .unavailable)
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect(await recorder.count(for: 311) == 1)
        #expect(await recorder.count(for: 312) == 1)
        await store.stop()
    }

    @Test
    func nonSuccessfulPurchaseResultsNeverFinishOrGrantAccess() async {
        let cases = [
            PurchaseCase(result: .pending, expected: .pending),
            PurchaseCase(result: .userCancelled, expected: .cancelled),
            PurchaseCase(result: .unverified, expected: .failed(.verificationFailed)),
        ]

        for testCase in cases {
            let authority = LiveFeatureAccessAuthority()
            let source = ProgrammableStoreEntitlementSource(
                purchasePlan: .result(testCase.result)
            )
            let store = EntitlementStore(source: source, featureAccessAuthority: authority)

            #expect(await store.purchase(.proMonthly) == testCase.expected)
            #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        }
    }

    @Test
    func purchaseSourceErrorsMapToStableFailClosedOutcomes() async {
        let cases = [
            PurchaseFailureCase(
                plan: .invalidProduct,
                expected: .failed(.productUnavailable)
            ),
            PurchaseFailureCase(
                plan: .purchasesNotAllowed,
                expected: .failed(.purchasesNotAllowed)
            ),
            PurchaseFailureCase(
                plan: .unavailable,
                expected: .failed(.unavailable)
            ),
        ]

        for testCase in cases {
            let authority = LiveFeatureAccessAuthority()
            let source = ProgrammableStoreEntitlementSource(purchasePlan: testCase.plan)
            let store = EntitlementStore(source: source, featureAccessAuthority: authority)

            #expect(await store.purchase(.proAnnual) == testCase.expected)
            #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        }
    }

    @Test
    func purchaseDoesNotFinishWhenTheCombinedStoreStateIsNotActionable() async {
        let recorder = FinishRecorder()
        let purchased = finishableTransaction(
            facts: transactionFacts(id: 350, state: .subscribed),
            recorder: recorder
        )
        let source = ProgrammableStoreEntitlementSource(
            currentRead: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 1,
                appEnvironment: .sandbox
            ),
            purchasePlan: .result(.verified(purchased))
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        #expect(await store.purchase(.proMonthly) == .failed(.invalidStoreState))
        #expect(await recorder.count(for: 350) == 0)
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
    }

    @Test
    func anExistingSubscriptionCannotMakeAMismatchedPurchaseLookSuccessful() async {
        let recorder = FinishRecorder()
        let existingMonthly = transactionFacts(id: 360, state: .subscribed)
        let mismatchedMonthly = finishableTransaction(
            facts: transactionFacts(id: 361, state: .subscribed),
            recorder: recorder
        )
        let source = ProgrammableStoreEntitlementSource(
            currentRead: entitlementRead(existingMonthly),
            purchasePlan: .result(.verified(mismatchedMonthly))
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        #expect(await store.purchase(.proAnnual) == .failed(.invalidStoreState))
        #expect(await recorder.count(for: 361) == 0)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        await store.stop()
    }

    @Test
    func verifiedDeferredCrossgradesAcceptTheRequestedAcknowledgementProduct() async {
        let cases: [(current: StoreProductID, requested: StoreProductID, id: UInt64)] = [
            (.proMonthly, .proAnnual, 362),
            (.proAnnual, .proMonthly, 363),
        ]

        for testCase in cases {
            let recorder = FinishRecorder()
            let activeFacts = transactionFacts(
                id: testCase.id,
                state: .subscribed,
                productID: testCase.current
            )
            let deferredCrossgrade = finishableTransaction(
                acknowledgementProductID: testCase.requested,
                facts: activeFacts,
                recorder: recorder
            )
            let source = ProgrammableStoreEntitlementSource(
                currentRead: entitlementRead(activeFacts),
                purchasePlan: .result(.verified(deferredCrossgrade))
            )
            let authority = LiveFeatureAccessAuthority()
            let store = EntitlementStore(source: source, featureAccessAuthority: authority)
            await store.start()

            #expect(await store.purchase(testCase.requested) == .purchased)
            #expect(await recorder.count(for: testCase.id) == 1)
            #expect(authority.decision(for: .advancedSiri) == .allowed)
            await store.stop()
        }
    }

    @Test
    func anExistingSubscriptionCannotMakeThisInactivePurchaseLookSuccessful() async {
        let recorder = FinishRecorder()
        let existingAnnual = transactionFacts(
            id: 370,
            state: .subscribed,
            productID: .proAnnual
        )
        let inactiveMonthly = finishableTransaction(
            facts: transactionFacts(
                id: 371,
                state: .inBillingRetryPeriod,
                expirationDate: .distantPast
            ),
            recorder: recorder
        )
        let source = ProgrammableStoreEntitlementSource(
            currentRead: entitlementRead(existingAnnual),
            purchasePlan: .result(.verified(inactiveMonthly))
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        #expect(await store.purchase(.proMonthly) == .failed(.invalidStoreState))
        #expect(await recorder.count(for: 371) == 0)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        await store.stop()
    }

    @Test
    func restoreDistinguishesRestoredNoPurchaseAndSourceFailure() async {
        let recorder = FinishRecorder()
        let paidFacts = transactionFacts(id: 400, state: .subscribed)
        let paidSource = ProgrammableStoreEntitlementSource(
            currentRead: entitlementRead(paidFacts),
            unfinishedRead: StoreUnfinishedTransactionRead(
                transactions: [
                    finishableTransaction(facts: paidFacts, recorder: recorder),
                    finishableTransaction(facts: paidFacts, recorder: recorder),
                ],
                unverifiedCount: 0
            )
        )
        let paidStore = EntitlementStore(
            source: paidSource,
            featureAccessAuthority: LiveFeatureAccessAuthority()
        )
        #expect(await paidStore.restorePurchases() == .restored)
        #expect(await paidSource.synchronizationCount() == 1)
        #expect(await recorder.count(for: 400) == 1)

        let freeSource = ProgrammableStoreEntitlementSource()
        let freeStore = EntitlementStore(
            source: freeSource,
            featureAccessAuthority: LiveFeatureAccessAuthority()
        )
        #expect(await freeStore.restorePurchases() == .noActiveSubscription)
        #expect(await freeSource.synchronizationCount() == 1)

        let failedSource = ProgrammableStoreEntitlementSource(syncPlan: .unavailable)
        let failedStore = EntitlementStore(
            source: failedSource,
            featureAccessAuthority: LiveFeatureAccessAuthority()
        )
        #expect(await failedStore.restorePurchases() == .failed(.unavailable))
        #expect(await failedSource.synchronizationCount() == 1)
    }

    @Test
    func restoreUsesVerifiedUnfinishedResolutionWhileCurrentEntitlementsCatchUp() async {
        let recorder = FinishRecorder()
        let facts = transactionFacts(id: 401, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            currentRead: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            ),
            unfinishedRead: StoreUnfinishedTransactionRead(
                transactions: [finishableTransaction(facts: facts, recorder: recorder)],
                unverifiedCount: 0
            )
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        #expect(await store.restorePurchases() == .restored)
        #expect(await recorder.count(for: 401) == 1)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
    }

    @Test
    func restoreUsesTheVerifiedUpdateHandledWhileSynchronizationWasSuspended() async {
        let recorder = FinishRecorder()
        let synchronizationGate = AsyncTestGate()
        let facts = transactionFacts(id: 402, state: .subscribed)
        let authority = LiveFeatureAccessAuthority()
        let source = ProgrammableStoreEntitlementSource(
            currentRead: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            ),
            synchronizationGate: synchronizationGate
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        let restore = Task { await store.restorePurchases() }
        #expect(await eventually { await synchronizationGate.entryCount() == 1 })

        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(await recorder.count(for: 402) == 1)
        #expect(authority.decision(for: .advancedSiri) == .allowed)

        await synchronizationGate.release()
        #expect(await restore.value == .restored)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect(await source.synchronizationCount() == 1)
        await store.stop()
    }

    @Test
    func restoreIgnoresAnOrdinaryRefreshPublishedWhileSynchronizationWasSuspended() async {
        let synchronizationGate = AsyncTestGate()
        let restoredFacts = transactionFacts(id: 403, state: .subscribed)
        let authority = LiveFeatureAccessAuthority()
        let source = ProgrammableStoreEntitlementSource(
            currentRead: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            ),
            synchronizationGate: synchronizationGate
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        let restore = Task { await store.restorePurchases() }
        #expect(await eventually { await synchronizationGate.entryCount() == 1 })

        // This is an ordinary status/foreground reconciliation, not a restored transaction.
        source.send(.changed)
        #expect(await eventually { await source.handledSignalCount() == 1 })
        await source.setCurrentRead(entitlementRead(restoredFacts))
        await synchronizationGate.release()

        #expect(await restore.value == .restored)
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect(await source.synchronizationCount() == 1)
        await store.stop()
    }

    @Test
    func restoreCannotReuseASubscribedSignalRejectedByNewerRevocationAuthority() async {
        let recorder = FinishRecorder()
        let synchronizationGate = AsyncTestGate()
        let finishGate = AsyncTestGate()
        let subscribed = transactionFacts(id: 404, state: .subscribed)
        let revoked = transactionFacts(id: 404, state: .revoked, isRevoked: true)
        let authority = LiveFeatureAccessAuthority()
        let source = ProgrammableStoreEntitlementSource(
            currentRead: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            ),
            synchronizationGate: synchronizationGate
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        let restore = Task { await store.restorePurchases() }
        #expect(await eventually { await synchronizationGate.entryCount() == 1 })

        source.send(
            .verified(
                gatedFinishableTransaction(
                    facts: subscribed,
                    recorder: recorder,
                    gate: finishGate
                )
            )
        )
        #expect(await eventually { await finishGate.entryCount() == 1 })

        await source.setCurrentRead(entitlementRead(revoked))
        await store.refreshCurrentEntitlements()
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await source.setCurrentRead(
            StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: .sandbox
            )
        )
        await finishGate.release()
        #expect(await eventually { await source.handledSignalCount() == 1 })
        await synchronizationGate.release()

        #expect(await restore.value == .noActiveSubscription)
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect(await recorder.count(for: 404) == 1)
        await store.stop()
    }

    @Test
    func restoreRejectsAnUnverifiedUnfinishedTransaction() async {
        let source = ProgrammableStoreEntitlementSource(
            unfinishedRead: StoreUnfinishedTransactionRead(
                transactions: [],
                unverifiedCount: 1
            )
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        #expect(await store.restorePurchases() == .failed(.verificationFailed))
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
    }

    @Test
    func startupProcessesDuplicateUnfinishedTransactionIDOnlyOnce() async {
        let recorder = FinishRecorder()
        let facts = transactionFacts(id: 500, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            unfinishedRead: StoreUnfinishedTransactionRead(
                transactions: [
                    finishableTransaction(facts: facts, recorder: recorder),
                    finishableTransaction(facts: facts, recorder: recorder),
                ],
                unverifiedCount: 0
            )
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()

        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect(await recorder.count(for: 500) == 1)
        await store.stop()
    }

    @Test
    func conflictingFactsForOneStatusTransactionFailTheUnfinishedBatchClosed() async {
        let recorder = FinishRecorder()
        let subscribed = transactionFacts(id: 499, state: .subscribed)
        let revoked = transactionFacts(id: 499, state: .revoked, isRevoked: true)
        let source = ProgrammableStoreEntitlementSource(
            unfinishedRead: StoreUnfinishedTransactionRead(
                transactions: [
                    finishableTransaction(
                        acknowledgementID: 700,
                        facts: subscribed,
                        recorder: recorder
                    ),
                    finishableTransaction(
                        acknowledgementID: 701,
                        facts: revoked,
                        recorder: recorder
                    ),
                ],
                unverifiedCount: 0
            )
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()

        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).effectiveState == .unavailable)
        #expect(await recorder.count(for: 499) == 0)
        await store.stop()
    }

    @Test
    func aFailedFinishIsRetriedWhenTheSameTransactionArrivesAgain() async {
        let recorder = FinishRecorder()
        let facts = transactionFacts(id: 501, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource(
            unfinishedRead: StoreUnfinishedTransactionRead(
                transactions: [
                    finishableTransaction(
                        facts: facts,
                        recorder: recorder,
                        succeeds: false
                    ),
                ],
                unverifiedCount: 0
            )
        )
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: LiveFeatureAccessAuthority()
        )

        await store.start()
        #expect(await recorder.count(for: 501) == 1)

        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(await recorder.count(for: 501) == 2)
        await store.stop()
    }

    @Test
    func verifiedAndChangedUpdatesRefreshAuthorityWhileDuplicateIDsStayFinished() async {
        let recorder = FinishRecorder()
        let facts = transactionFacts(id: 600, state: .subscribed)
        let source = ProgrammableStoreEntitlementSource()
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)

        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect(await recorder.count(for: 600) == 1)

        source.send(
            .verified(finishableTransaction(facts: facts, recorder: recorder))
        )
        #expect(await eventually { await source.handledSignalCount() == 2 })
        #expect(await recorder.count(for: 600) == 1)
        #expect(authority.decision(for: .advancedSiri) == .allowed)

        await source.setCurrentRead(
            entitlementRead(
                transactionFacts(
                    id: 600,
                    state: .inBillingRetryPeriod,
                    expirationDate: .distantPast
                )
            )
        )
        source.send(.changed)
        #expect(await eventually { await source.handledSignalCount() == 3 })
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).effectiveState == .inBillingRetryPeriod)

        source.send(.unverified)
        #expect(await eventually { await source.handledSignalCount() == 4 })
        #expect((await store.currentSnapshot()).effectiveState == .unavailable)
        #expect((await store.currentSnapshot()).unverifiedCount == 1)
        await store.stop()
    }

    @Test
    func incompleteCurrentReadStaysFailClosedWhenAFreeStateUpdateArrives() async {
        let recorder = FinishRecorder()
        let source = ProgrammableStoreEntitlementSource(
            currentRead: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                isComplete: false,
                appEnvironment: .sandbox
            )
        )
        let authority = LiveFeatureAccessAuthority()
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)
        await store.start()

        source.send(
            .verified(
                finishableTransaction(
                    facts: transactionFacts(
                        id: 610,
                        state: .inBillingRetryPeriod,
                        expirationDate: .distantPast
                    ),
                    recorder: recorder
                )
            )
        )

        #expect(await eventually { await source.handledSignalCount() == 1 })
        #expect(await recorder.count(for: 610) == 0)
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).effectiveState == .unavailable)
        await store.stop()
    }

    @Test
    func purchaseAndRestoreShareOneInFlightCommerceOperation() async {
        let source = ProgrammableStoreEntitlementSource(
            purchasePlan: .result(.pending),
            pausesPurchase: true
        )
        let store = EntitlementStore(
            source: source,
            featureAccessAuthority: LiveFeatureAccessAuthority()
        )

        let purchase = Task { await store.purchase(.proMonthly) }
        #expect(await eventually { await source.purchaseCallCount() == 1 })

        #expect(await store.restorePurchases() == .failed(.operationInProgress))
        #expect(await source.synchronizationCount() == 0)

        await source.resumePurchase()
        #expect(await purchase.value == .pending)
    }
}

private struct SubscriptionCase {
    let state: StoreSubscriptionState
    let isRevoked: Bool
    let expectsAccess: Bool
    let expectedState: EffectiveStoreSubscriptionState
}

private struct PurchaseCase {
    let result: StorePurchaseResult
    let expected: StorePurchaseOutcome
}

private struct PurchaseFailureCase {
    let plan: TestPurchasePlan
    let expected: StorePurchaseOutcome
}

private func transactionFacts(
    id: UInt64,
    state: StoreSubscriptionState,
    productID: StoreProductID = .proMonthly,
    isRevoked: Bool = false,
    expirationDate: Date? = nil,
    isPurchased: Bool = true,
    hasVerifiedStatusTransaction: Bool = true,
    hasVerifiedRenewalInfo: Bool = true
) -> VerifiedStoreTransaction {
    VerifiedStoreTransaction(
        transactionID: id,
        productID: productID.rawValue,
        environment: .sandbox,
        isPurchased: isPurchased,
        isRevoked: isRevoked,
        expirationDate: expirationDate,
        subscriptionState: state,
        hasVerifiedStatusTransaction: hasVerifiedStatusTransaction,
        hasVerifiedRenewalInfo: hasVerifiedRenewalInfo,
        hasVerifiedAppBundle: true
    )
}

private func entitlementRead(
    _ transaction: VerifiedStoreTransaction
) -> StoreEntitlementRead {
    StoreEntitlementRead(
        transactions: [transaction],
        unverifiedCount: 0,
        appEnvironment: transaction.environment
    )
}

private func finishableTransaction(
    acknowledgementID: UInt64? = nil,
    acknowledgementProductID: StoreProductID? = nil,
    facts: VerifiedStoreTransaction,
    recorder: FinishRecorder,
    succeeds: Bool = true,
    accessAuthority: LiveFeatureAccessAuthority? = nil
) -> FinishableStoreTransaction {
    FinishableStoreTransaction(
        acknowledgementID: acknowledgementID,
        acknowledgementProductID: acknowledgementProductID?.rawValue,
        facts: facts
    ) {
        let observedAllowedAccess = accessAuthority.map {
            $0.decision(for: .advancedSiri) == .allowed
        }
        return await recorder.record(
            transactionID: facts.transactionID,
            succeeds: succeeds,
            observedAllowedAccess: observedAllowedAccess
        )
    }
}

private func gatedFinishableTransaction(
    facts: VerifiedStoreTransaction,
    recorder: FinishRecorder,
    gate: AsyncTestGate,
    acknowledgementProductID: StoreProductID? = nil,
    succeeds: Bool = true,
    accessAuthority: LiveFeatureAccessAuthority? = nil
) -> FinishableStoreTransaction {
    FinishableStoreTransaction(
        acknowledgementProductID: acknowledgementProductID?.rawValue,
        facts: facts
    ) {
        await gate.enterAndWait()
        let observedAllowedAccess = accessAuthority.map {
            $0.decision(for: .advancedSiri) == .allowed
        }
        return await recorder.record(
            transactionID: facts.transactionID,
            succeeds: succeeds,
            observedAllowedAccess: observedAllowedAccess
        )
    }
}

private actor AsyncTestGate {
    private var entries = 0
    private var isReleased = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func enterAndWait() async {
        entries += 1
        guard !isReleased else { return }
        await withCheckedContinuation { continuation in
            if isReleased {
                continuation.resume()
            } else {
                waiters.append(continuation)
            }
        }
    }

    func entryCount() -> Int {
        entries
    }

    func release() {
        guard !isReleased else { return }
        isReleased = true
        let pending = waiters
        waiters.removeAll()
        for waiter in pending {
            waiter.resume()
        }
    }
}

private actor TransactionBatchWaitObserver {
    private var counts: [UInt64: Int] = [:]

    func record(_ transactionIDs: Set<UInt64>) {
        for transactionID in transactionIDs {
            counts[transactionID, default: 0] += 1
        }
    }

    func count(for transactionID: UInt64) -> Int {
        counts[transactionID, default: 0]
    }
}

private actor FinishRecorder {
    private var counts: [UInt64: Int] = [:]
    private var accessObservations: [UInt64: [Bool]] = [:]

    func record(
        transactionID: UInt64,
        succeeds: Bool,
        observedAllowedAccess: Bool?
    ) -> Bool {
        counts[transactionID, default: 0] += 1
        if let observedAllowedAccess {
            accessObservations[transactionID, default: []].append(observedAllowedAccess)
        }
        return succeeds
    }

    func count(for transactionID: UInt64) -> Int {
        counts[transactionID, default: 0]
    }

    func observedAllowedAccess(for transactionID: UInt64) -> [Bool] {
        accessObservations[transactionID, default: []]
    }
}

private enum TestPurchasePlan: Sendable {
    case result(StorePurchaseResult)
    case invalidProduct
    case purchasesNotAllowed
    case unavailable
}

private enum TestSynchronizationPlan: Equatable, Sendable {
    case success
    case unavailable
}

private enum ProgrammableStoreError: Error, Sendable {
    case unavailable
}

private final class LifecycleUpdateChannel: @unchecked Sendable {
    let stream: AsyncStream<StoreTransactionSignal>
    let continuation: AsyncStream<StoreTransactionSignal>.Continuation

    init() {
        var captured: AsyncStream<StoreTransactionSignal>.Continuation?
        stream = AsyncStream { captured = $0 }
        continuation = captured!
    }
}

private struct ProgrammableStoreEntitlementSource: StoreEntitlementSourcing {
    private let state: ProgrammableStoreState
    private let channel = LifecycleUpdateChannel()

    init(
        currentRead: StoreEntitlementRead = StoreEntitlementRead(
            transactions: [],
            unverifiedCount: 0,
            appEnvironment: .sandbox
        ),
        unfinishedRead: StoreUnfinishedTransactionRead = StoreUnfinishedTransactionRead(
            transactions: [],
            unverifiedCount: 0
        ),
        purchasePlan: TestPurchasePlan = .result(.userCancelled),
        syncPlan: TestSynchronizationPlan = .success,
        pausesPurchase: Bool = false,
        synchronizationGate: AsyncTestGate? = nil
    ) {
        state = ProgrammableStoreState(
            currentRead: currentRead,
            unfinishedRead: unfinishedRead,
            purchasePlan: purchasePlan,
            syncPlan: syncPlan,
            pausesPurchase: pausesPurchase,
            synchronizationGate: synchronizationGate
        )
    }

    func currentEntitlements() async -> StoreEntitlementRead {
        await state.currentEntitlements()
    }

    func unfinishedTransactions() async -> StoreUnfinishedTransactionRead {
        await state.unfinishedTransactions()
    }

    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async {
        for await signal in channel.stream {
            guard !Task.isCancelled else { return }
            await state.signalStarted()
            await handler(signal)
            await state.signalHandled()
        }
    }

    @MainActor
    func purchase(_ productID: StoreProductID) async throws -> StorePurchaseResult {
        try await state.purchase(productID)
    }

    func synchronizePurchases() async throws {
        try await state.synchronizePurchases()
    }

    func setCurrentRead(_ read: StoreEntitlementRead) async {
        await state.setCurrentRead(read)
    }

    func purchasedProductIDs() async -> [StoreProductID] {
        await state.purchasedProductIDs()
    }

    func purchaseCallCount() async -> Int {
        await state.purchaseCallCount()
    }

    func synchronizationCount() async -> Int {
        await state.synchronizationCount()
    }

    func handledSignalCount() async -> Int {
        await state.handledSignalCount()
    }

    func startedSignalCount() async -> Int {
        await state.startedSignalCount()
    }

    func resumePurchase() async {
        await state.resumePurchase()
    }

    func send(_ signal: StoreTransactionSignal) {
        channel.continuation.yield(signal)
    }
}

private actor ProgrammableStoreState {
    private var currentRead: StoreEntitlementRead
    private var unfinishedRead: StoreUnfinishedTransactionRead
    private let purchasePlan: TestPurchasePlan
    private let syncPlan: TestSynchronizationPlan
    private let pausesPurchase: Bool
    private let synchronizationGate: AsyncTestGate?
    private var purchaseContinuation: CheckedContinuation<Void, Never>?
    private var purchasedProducts: [StoreProductID] = []
    private var syncCalls = 0
    private var startedSignals = 0
    private var handledSignals = 0

    init(
        currentRead: StoreEntitlementRead,
        unfinishedRead: StoreUnfinishedTransactionRead,
        purchasePlan: TestPurchasePlan,
        syncPlan: TestSynchronizationPlan,
        pausesPurchase: Bool,
        synchronizationGate: AsyncTestGate?
    ) {
        self.currentRead = currentRead
        self.unfinishedRead = unfinishedRead
        self.purchasePlan = purchasePlan
        self.syncPlan = syncPlan
        self.pausesPurchase = pausesPurchase
        self.synchronizationGate = synchronizationGate
    }

    func currentEntitlements() -> StoreEntitlementRead {
        currentRead
    }

    func unfinishedTransactions() -> StoreUnfinishedTransactionRead {
        unfinishedRead
    }

    func setCurrentRead(_ read: StoreEntitlementRead) {
        currentRead = read
    }

    func purchase(_ productID: StoreProductID) async throws -> StorePurchaseResult {
        purchasedProducts.append(productID)
        if pausesPurchase {
            await withCheckedContinuation { continuation in
                purchaseContinuation = continuation
            }
        }

        switch purchasePlan {
        case let .result(result):
            return result
        case .invalidProduct:
            throw StoreCommerceSourceError.invalidProduct
        case .purchasesNotAllowed:
            throw StoreCommerceSourceError.purchasesNotAllowed
        case .unavailable:
            throw ProgrammableStoreError.unavailable
        }
    }

    func synchronizePurchases() async throws {
        syncCalls += 1
        await synchronizationGate?.enterAndWait()
        if syncPlan == .unavailable {
            throw ProgrammableStoreError.unavailable
        }
    }

    func purchasedProductIDs() -> [StoreProductID] {
        purchasedProducts
    }

    func purchaseCallCount() -> Int {
        purchasedProducts.count
    }

    func synchronizationCount() -> Int {
        syncCalls
    }

    func signalHandled() {
        handledSignals += 1
    }

    func signalStarted() {
        startedSignals += 1
    }

    func startedSignalCount() -> Int {
        startedSignals
    }

    func handledSignalCount() -> Int {
        handledSignals
    }

    func resumePurchase() {
        purchaseContinuation?.resume()
        purchaseContinuation = nil
    }
}

private func eventually(
    _ predicate: @escaping @Sendable () async -> Bool
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(5))
    while clock.now < deadline {
        if Task.isCancelled { return false }
        if await predicate() { return true }
        do {
            try await clock.sleep(for: .milliseconds(10))
        } catch {
            return false
        }
    }
    return await predicate()
}
