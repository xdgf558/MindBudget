import Foundation
import SwiftData
import Testing
@testable import MindBudget

struct Phase5FeatureTests {
    private let detector = SpendingPatternDetector()
    private let calendar = TestFixtures.utcCalendar

    @Test
    func largePurchaseUsesTheGreaterOfFloorAndFreeBudgetRatio() throws {
        let context = try makeContext()
        let atBoundary = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 22_500),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let belowBoundary = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 22_499),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let aboveBoundary = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 30_000),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(atBoundary.contains { $0.type == .highSinglePurchase })
        #expect(!belowBoundary.contains { $0.type == .highSinglePurchase })
        #expect(aboveBoundary.contains { $0.type == .highSinglePurchase })
    }

    @Test
    func lateNightRuleNeedsThreeRecordsAndAQualifyingCandidate() throws {
        let context = try makeContext(nowHour: 23)
        let expenses = [
            expense(amount: 500, at: try shifted(context.now, hours: -24), localHour: 23),
            expense(amount: 500, at: try shifted(context.now, hours: -48), localHour: 23)
        ]
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 7_500),
            expenses: expenses,
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let withOnlyOnePrior = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 7_500),
            expenses: Array(expenses.prefix(1)),
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let belowAmountBoundary = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 7_499),
            expenses: expenses,
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(drafts.contains { $0.type == .lateNightSpending })
        #expect(!withOnlyOnePrior.contains { $0.type == .lateNightSpending })
        #expect(!belowAmountBoundary.contains { $0.type == .lateNightSpending })
    }

    @Test
    func stressRuleWorksWithoutAConfiguredBudget() throws {
        let context = try makeContext()
        let expenses = [
            expense(amount: 300, at: try shifted(context.now, days: -2), emotion: .stressed),
            expense(amount: 400, at: try shifted(context.now, days: -1), reason: .stressRelief)
        ]
        let snapshot = BudgetSnapshot.unconfigured(
            cycle: context.snapshot.cycle,
            currencyCode: "USD"
        )
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 500, emotion: .stressed),
            expenses: expenses,
            snapshot: snapshot,
            categoryBudgets: [],
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(drafts.contains { $0.type == .repeatedStressSpending })
        #expect(!drafts.contains { $0.type == .highSinglePurchase })
        #expect(!drafts.contains { $0.type == .safeToProceed })
    }

    @Test
    func stressRuleUsesTheConfiguredCountBoundary() throws {
        let context = try makeContext()
        let oneStored = [
            expense(amount: 300, at: try shifted(context.now, days: -1), emotion: .stressed)
        ]
        let below = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 300, emotion: .stressed),
            expenses: oneStored,
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let boundary = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 300, emotion: .stressed),
            expenses: oneStored + [
                expense(amount: 300, at: try shifted(context.now, days: -2), reason: .stressRelief)
            ],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(!below.contains { $0.type == .repeatedStressSpending })
        #expect(boundary.contains { $0.type == .repeatedStressSpending })
    }

    @Test
    func impulseRuleIncludesTheCandidateInTheSeventyTwoHourWindow() throws {
        let context = try makeContext()
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 300, reason: .impulse),
            expenses: [
                expense(amount: 200, at: try shifted(context.now, hours: -71), emotion: .impulse),
                expense(amount: 200, at: try shifted(context.now, hours: -24), reason: .impulse)
            ],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(drafts.first { $0.type == .impulseCluster }?.severity == .caution)
    }

    @Test
    func impulseRuleDoesNotTriggerBelowItsCountBoundary() throws {
        let context = try makeContext()
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 300, reason: .impulse),
            expenses: [
                expense(amount: 200, at: try shifted(context.now, hours: -24), emotion: .impulse)
            ],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(!drafts.contains { $0.type == .impulseCluster })
    }

    @Test
    func imageRuleRequiresARealHistoricalBaseline() throws {
        let context = try makeContext()
        let histories = [
            CycleAggregate(
                periodStart: try shifted(context.start, days: -62),
                periodEnd: try shifted(context.start, days: -31),
                currencyCode: "USD",
                totalMinorUnits: 10_000,
                imageRelatedMinorUnits: 10_000
            ),
            CycleAggregate(
                periodStart: try shifted(context.start, days: -31),
                periodEnd: context.start,
                currencyCode: "USD",
                totalMinorUnits: 10_000,
                imageRelatedMinorUnits: 10_000
            )
        ]
        let imageCandidate = candidate(amount: 15_000, reason: .imageUpgrade)
        let withBaseline = detector.evaluatePotentialPurchase(
            candidate: imageCandidate,
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: histories,
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let newUser = detector.evaluatePotentialPurchase(
            candidate: imageCandidate,
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: Array(histories.prefix(1)),
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let exactMultiplier = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 14_000, reason: .imageUpgrade),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: histories,
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(withBaseline.contains { $0.type == .imageRelatedIncrease })
        #expect(!newUser.contains { $0.type == .imageRelatedIncrease })
        #expect(!exactMultiplier.contains { $0.type == .imageRelatedIncrease })
    }

    @Test
    func categoryRiskUsesItsConfiguredBoundaryAndSeverity() throws {
        let context = try makeContext(
            storedExpenses: [
                expense(amount: 70_000, category: .food, at: try date(2026, 1, 10))
            ]
        )
        let approaching = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 10_000, category: .food),
            expenses: [
                expense(amount: 70_000, category: .food, at: try date(2026, 1, 10))
            ],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let atLimit = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 30_000, category: .food),
            expenses: [
                expense(amount: 70_000, category: .food, at: try date(2026, 1, 10))
            ],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let belowWarning = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 9_999, category: .food),
            expenses: [
                expense(amount: 70_000, category: .food, at: try date(2026, 1, 10))
            ],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(approaching.first { $0.type == .categoryBudgetRisk }?.severity == .gentle)
        #expect(atLimit.first { $0.type == .categoryBudgetRisk }?.severity == .caution)
        #expect(!belowWarning.contains { $0.type == .categoryBudgetRisk })
    }

    @Test
    func coolingOffSuccessUsesTheDecisionTimestamp() throws {
        let context = try makeContext()
        let drafts = detector.detectPatterns(
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            coolingOffOutcomes: [
                CoolingOffOutcomeSummary(
                    outcome: .skipped,
                    outcomeRecordedAt: try shifted(context.start, hours: 2)
                ),
                CoolingOffOutcomeSummary(
                    outcome: .skipped,
                    outcomeRecordedAt: try shifted(context.start, days: -1)
                ),
                CoolingOffOutcomeSummary(
                    outcome: .purchased,
                    outcomeRecordedAt: try shifted(context.start, hours: 3)
                )
            ],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        let success = try #require(drafts.first { $0.type == .coolingOffSuccess })
        #expect(success.payload["count"] == .integer(1))
        #expect(success.severity == .info)
    }

    @Test
    func storedPatternDetectionProducesEverySupportedRecurringSignal() throws {
        let reference = try makeContext(nowHour: 23)
        let expenses = [
            expense(
                amount: 30_000,
                category: .food,
                at: reference.now,
                localHour: 23,
                emotion: .stressed,
                reason: .impulse
            ),
            expense(
                amount: 30_000,
                category: .food,
                at: try shifted(reference.now, days: -1),
                localHour: 23,
                emotion: .stressed,
                reason: .impulse
            ),
            expense(
                amount: 30_000,
                category: .food,
                at: try shifted(reference.now, days: -2),
                localHour: 23,
                emotion: .stressed,
                reason: .impulse
            ),
            expense(
                amount: 20_000,
                category: .electronics,
                at: try shifted(reference.now, days: -3),
                reason: .imageUpgrade
            )
        ]
        let context = try makeContext(nowHour: 23, storedExpenses: expenses)
        let histories = [
            CycleAggregate(
                periodStart: try date(2025, 11, 1),
                periodEnd: try date(2025, 12, 1),
                currencyCode: "USD",
                totalMinorUnits: 5_000,
                imageRelatedMinorUnits: 5_000
            ),
            CycleAggregate(
                periodStart: try date(2025, 12, 1),
                periodEnd: context.start,
                currencyCode: "USD",
                totalMinorUnits: 5_000,
                imageRelatedMinorUnits: 5_000
            )
        ]

        let drafts = detector.detectPatterns(
            expenses: expenses,
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: histories,
            coolingOffOutcomes: [
                CoolingOffOutcomeSummary(
                    outcome: .skipped,
                    outcomeRecordedAt: context.now
                )
            ],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let types = Set(drafts.map(\.type))

        #expect(types.contains(.highSinglePurchase))
        #expect(types.contains(.lateNightSpending))
        #expect(types.contains(.categoryBudgetRisk))
        #expect(types.contains(.repeatedStressSpending))
        #expect(types.contains(.impulseCluster))
        #expect(types.contains(.imageRelatedIncrease))
        #expect(types.contains(.coolingOffSuccess))
    }

    @Test
    func safeToProceedAppearsOnlyWhenNoWarningRuleMatches() throws {
        let context = try makeContext()
        let safe = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 100),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let warning = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 22_500),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(safe.contains { $0.type == .safeToProceed })
        #expect(!warning.contains { $0.type == .safeToProceed })
    }

    @Test
    func safeToProceedIncludesTheExactBufferBoundary() throws {
        let context = try makeContext()
        let baseConfiguration = configuration(
            largePurchaseFloor: 100_000,
            largePurchaseRatio: 1
        )
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 75_000),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [],
            config: baseConfiguration,
            now: context.now,
            calendar: calendar
        )
        let stricterBuffer = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 75_000),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [],
            config: configuration(
                largePurchaseFloor: 100_000,
                largePurchaseRatio: 1,
                safeBufferBasisPoints: 6_000
            ),
            now: context.now,
            calendar: calendar
        )

        #expect(drafts.contains { $0.type == .safeToProceed })
        #expect(!stricterBuffer.contains { $0.type == .safeToProceed })
    }

    @Test
    func lateNightWindowAndMinimumCountComeFromConfiguration() throws {
        let context = try makeContext(nowHour: 23)
        let recentLateExpenses = [
            expense(
                amount: 1_000,
                at: try shifted(context.now, hours: -1),
                localHour: 23
            ),
            expense(
                amount: 1_000,
                at: try shifted(context.now, days: -1),
                localHour: 23
            ),
            expense(
                amount: 1_000,
                at: try shifted(context.now, days: -5),
                localHour: 23
            )
        ]
        let configuration = configuration(
            largePurchaseFloor: 100_000,
            largePurchaseRatio: 1,
            lateRatio: Decimal(string: "0.01")!,
            lateWindowDays: 2,
            lateMinimumCount: 4
        )
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 1_500),
            expenses: recentLateExpenses,
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [],
            config: configuration,
            now: context.now,
            calendar: calendar
        )

        #expect(!drafts.contains { $0.type == .lateNightSpending })
    }

    @Test
    func imagePatternMinimumIsIndependentFromTheLargePurchaseFloor() throws {
        let context = try makeContext()
        let configuration = configuration(
            largePurchaseFloor: 50_000,
            largePurchaseRatio: 1,
            imageMultiplier: 2,
            imageMinimumAmount: 1_000,
            baselineMonths: 1,
            minimumBaseline: 1
        )
        let history = CycleAggregate(
            periodStart: try shifted(context.start, days: -31),
            periodEnd: context.start,
            currencyCode: "USD",
            totalMinorUnits: 500,
            imageRelatedMinorUnits: 500
        )
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 1_001, reason: .imageUpgrade),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [history],
            config: configuration,
            now: context.now,
            calendar: calendar
        )

        #expect(drafts.contains { $0.type == .imageRelatedIncrease })
        #expect(!drafts.contains { $0.type == .highSinglePurchase })
    }

    @Test
    func cycleAggregateOverflowRejectsTheWholeBuildInsteadOfSkippingACycle() throws {
        let start = try date(2025, 12, 1)
        let end = try date(2026, 1, 1)
        let plan = BudgetPlanSummary(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 0,
            totalBudgetMinorUnits: 0,
            fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0,
            authority: .incomeBased,
            categoryBudgets: []
        )
        let expenses = [
            expense(amount: Int64.max, at: try shifted(start, hours: 1)),
            expense(amount: 1, at: try shifted(start, hours: 2))
        ]

        #expect(throws: CycleAggregateBuildError.self) {
            try CycleAggregateBuilder().build(
                plans: [plan],
                expenses: expenses,
                before: end
            )
        }
    }

    @Test
    func nonDefaultConfigurationControlsPatternBoundaries() throws {
        let context = try makeContext(nowHour: 20)
        let configuration = configuration(
            largePurchaseFloor: 50_000,
            largePurchaseRatio: Decimal(string: "0.5")!,
            lateStart: 20,
            lateEnd: 21,
            lateRatio: Decimal(string: "0.01")!,
            stressCount: 2,
            impulseHours: 24,
            impulseCount: 2,
            imageMultiplier: 2,
            baselineMonths: 1,
            minimumBaseline: 1
        )
        let expenses = [
            expense(amount: 200, at: try shifted(context.now, hours: -1), emotion: .stressed),
            expense(amount: 200, at: try shifted(context.now, hours: -1), reason: .impulse),
            expense(amount: 200, at: try shifted(context.now, hours: -1), localHour: 20),
            expense(amount: 200, at: try shifted(context.now, days: -1), localHour: 20)
        ]
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 1_500, reason: .impulse, emotion: .stressed),
            expenses: expenses,
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [],
            config: configuration,
            now: context.now,
            calendar: calendar
        )

        #expect(drafts.contains { $0.type == .lateNightSpending })
        #expect(drafts.contains { $0.type == .repeatedStressSpending })
        #expect(drafts.contains { $0.type == .impulseCluster })
        #expect(!drafts.contains { $0.type == .highSinglePurchase })

        let history = CycleAggregate(
            periodStart: try shifted(context.start, days: -31),
            periodEnd: context.start,
            currencyCode: "USD",
            totalMinorUnits: 25_000,
            imageRelatedMinorUnits: 25_000
        )
        let exactImageBoundary = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 50_000, reason: .imageUpgrade),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [history],
            config: configuration,
            now: context.now,
            calendar: calendar
        )
        let aboveImageBoundary = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 50_001, reason: .imageUpgrade),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [history],
            config: configuration,
            now: context.now,
            calendar: calendar
        )
        #expect(!exactImageBoundary.contains { $0.type == .imageRelatedIncrease })
        #expect(aboveImageBoundary.contains { $0.type == .imageRelatedIncrease })
    }

    @Test
    func detectorIsDeterministicForIdenticalInputs() throws {
        let context = try makeContext()
        let arguments = [
            expense(amount: 200, at: try shifted(context.now, hours: -2), emotion: .impulse),
            expense(amount: 300, at: try shifted(context.now, hours: -1), reason: .impulse)
        ]
        let first = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 400, emotion: .impulse),
            expenses: arguments,
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )
        let second = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 400, emotion: .impulse),
            expenses: arguments,
            snapshot: context.snapshot,
            categoryBudgets: context.categoryBudgets,
            historicalCycles: [],
            config: context.config,
            now: context.now,
            calendar: calendar
        )

        #expect(first == second)
        for _ in 0..<100 {
            let repeated = detector.evaluatePotentialPurchase(
                candidate: candidate(amount: 400, emotion: .impulse),
                expenses: arguments,
                snapshot: context.snapshot,
                categoryBudgets: context.categoryBudgets,
                historicalCycles: [],
                config: context.config,
                now: context.now,
                calendar: calendar
            )
            #expect(repeated == first)
        }
    }

    @Test
    func reminderThrottleHonorsUserDisableAndDuplicateCooldown() throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let request = ReminderRequest(
            kind: .behavioralInsight,
            draft: draft,
            requestedChannel: nil,
            requestedDeliveryDate: nil
        )
        let disabled = ReminderThrottle().decide(
            for: request,
            history: [],
            preferences: preferences(enabled: false),
            now: context.now,
            calendar: calendar
        )
        let duplicate = ReminderThrottle().decide(
            for: request,
            history: [event(type: draft.type, scope: draft.throttleMetadata.scopeKey, at: try shifted(context.now, hours: -1))],
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(disabled.suppressionReason == .userDisabledReminders)
        #expect(duplicate.suppressionReason == .duplicateWithinCooldown)
    }

    @Test
    func categoryCanInterruptAgainWhenItFirstCrossesOneHundredPercent() throws {
        let context = try makeContext()
        let draft = insightDraft(
            type: .categoryBudgetRisk,
            snapshot: context.snapshot,
            riskBasisPoints: 10_000
        )
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(kind: .behavioralInsight, draft: draft, requestedChannel: nil, requestedDeliveryDate: nil),
            history: [
                event(
                    type: .categoryBudgetRisk,
                    scope: draft.throttleMetadata.scopeKey,
                    at: try shifted(context.now, hours: -1),
                    riskBasisPoints: 9_000
                )
            ],
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.shouldShowNow)
        #expect(decision.channel == .sheet)
    }

    @Test
    func threeRecentDismissalsDowngradeAnInterruptionToACard() throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let history = try (2...4).map { days in
            event(
                type: draft.type,
                scope: draft.throttleMetadata.scopeKey,
                at: try shifted(context.now, days: -days),
                response: .dismissed
            )
        }
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(kind: .behavioralInsight, draft: draft, requestedChannel: nil, requestedDeliveryDate: nil),
            history: history,
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.channel == .card)
        #expect(decision.shouldShowNow)
    }

    @Test
    func dismissalStreakUsesTheMostRecentResponseForTheFourteenDayWindow() throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let history = [
            event(
                type: draft.type,
                scope: draft.throttleMetadata.scopeKey,
                at: try shifted(context.now, days: -2),
                response: .dismissed
            ),
            event(
                type: draft.type,
                scope: draft.throttleMetadata.scopeKey,
                at: try shifted(context.now, days: -20),
                response: .ignored
            ),
            event(
                type: draft.type,
                scope: draft.throttleMetadata.scopeKey,
                at: try shifted(context.now, days: -30),
                response: .dismissed
            )
        ]
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(kind: .behavioralInsight, draft: draft, requestedChannel: nil, requestedDeliveryDate: nil),
            history: history,
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.channel == .card)
    }

    @Test
    func AnActedResponseResetsTheDismissalStreak() throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let responses: [ReminderResponse] = [.dismissed, .acted, .dismissed]
        let history = try responses.enumerated().map { index, response in
            event(
                type: draft.type,
                scope: draft.throttleMetadata.scopeKey,
                at: try shifted(context.now, days: -(index + 2)),
                response: response
            )
        }
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(kind: .behavioralInsight, draft: draft, requestedChannel: nil, requestedDeliveryDate: nil),
            history: history,
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.channel == .sheet)
    }

    @Test
    func dailyCapAndMinimalToneRemoveBlockingSheets() throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let request = ReminderRequest(kind: .behavioralInsight, draft: draft, requestedChannel: nil, requestedDeliveryDate: nil)
        let capped = ReminderThrottle().decide(
            for: request,
            history: [event(type: .impulseCluster, scope: "other", at: try shifted(context.now, hours: -1), interrupting: true)],
            preferences: preferences(maxDaily: 1),
            now: context.now,
            calendar: calendar
        )
        let minimal = ReminderThrottle().decide(
            for: request,
            history: [],
            preferences: preferences(tone: .minimal),
            now: context.now,
            calendar: calendar
        )

        #expect(capped.channel == .inline)
        #expect(minimal.channel == .inline)
    }

    @Test
    func unavailableDayBoundaryFailsClosedToANoninterruptingChannel() throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let decision = ReminderThrottle(dayInterval: { _, _ in nil }).decide(
            for: ReminderRequest(
                kind: .behavioralInsight,
                draft: draft,
                requestedChannel: nil,
                requestedDeliveryDate: nil
            ),
            history: [],
            preferences: preferences(maxDaily: 2),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.shouldShowNow)
        #expect(decision.channel == .inline)
    }

    @Test
    func missingBehavioralDraftIsReportedAsAnInvalidRequest() throws {
        let context = try makeContext()
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(
                kind: .behavioralInsight,
                draft: nil,
                requestedChannel: nil,
                requestedDeliveryDate: nil
            ),
            history: [],
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.suppressionReason == .invalidRequest)
    }

    @Test
    func informationalInsightUsesACard() throws {
        let context = try makeContext()
        let draft = insightDraft(type: .safeToProceed, snapshot: context.snapshot, severity: .info)
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(kind: .behavioralInsight, draft: draft, requestedChannel: nil, requestedDeliveryDate: nil),
            history: [],
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.channel == .card)
    }

    @Test
    func coolingNotificationDefersUntilQuietHoursEnd() throws {
        let context = try makeContext(nowHour: 23)
        let quietHours = try QuietHours(startHour: 21, endHour: 9)
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(
                kind: .coolingOffDue,
                draft: nil,
                requestedChannel: .notification,
                requestedDeliveryDate: context.now
            ),
            history: [],
            preferences: PreferencesSnapshot(
                reminderTone: .soft,
                gentleRemindersEnabled: true,
                notificationsEnabled: true,
                quietHours: quietHours,
                maxDailyInterruptions: 2
            ),
            now: context.now,
            calendar: calendar
        )

        #expect(!decision.shouldShowNow)
        #expect(decision.channel == .notification)
        #expect(calendar.component(.hour, from: try #require(decision.deferredUntil)) == 9)
    }

    @Test
    func coolingNotificationRequiresAuthorization() throws {
        let context = try makeContext()
        let decision = ReminderThrottle().decide(
            for: ReminderRequest(kind: .coolingOffDue, draft: nil, requestedChannel: nil, requestedDeliveryDate: context.now),
            history: [],
            preferences: preferences(),
            now: context.now,
            calendar: calendar
        )

        #expect(decision.suppressionReason == .notificationsNotAuthorized)
    }

    @Test
    func reminderEngineKeepsContinuePurchaseAndUsesHighestSeverity() async throws {
        let context = try makeContext()
        let gentle = insightDraft(type: .lateNightSpending, snapshot: context.snapshot, severity: .gentle)
        let caution = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let engine = ReminderEngine()
        let reminderContext = engine.buildContext(
            candidate: candidate(amount: 30_000),
            impact: nil,
            snapshot: context.snapshot,
            drafts: [gentle, caution],
            tone: .soft
        )
        let message = try #require(
            await engine.generateReminder(
                context: reminderContext,
                channel: .sheet,
                locale: Locale(identifier: "en")
            )
        )

        #expect(reminderContext.drafts.first?.type == .highSinglePurchase)
        #expect(message.supportingDetails.count == 1)
        #expect(message.actions.contains(.continuePurchase))
        #expect((2...4).contains(message.actions.count))
        #expect(message.source == .template)
    }

    @Test
    func invalidEnhancedWordingFallsBackToTheLocalTemplate() async throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let engine = ReminderEngine(enhancer: UnsafeEnhancer())
        let reminderContext = engine.buildContext(
            candidate: candidate(amount: 30_000),
            impact: nil,
            snapshot: context.snapshot,
            drafts: [draft],
            tone: .direct
        )
        let message = try #require(
            await engine.generateReminder(
                context: reminderContext,
                channel: .sheet,
                locale: Locale(identifier: "en")
            )
        )

        #expect(message.source == .modelValidatedFallback)
        #expect(message.title.count <= 24)
        #expect(message.body.count <= 40)
        #expect(!message.body.contains("!"))
    }

    @Test
    func everyInsightFamilyHasSafeTemplateAndPresentationCopy() throws {
        let context = try makeContext()
        let locale = Locale(identifier: "en_US")

        for type in SpendingInsightType.allCases {
            let draft = insightDraft(type: type, snapshot: context.snapshot)
            for tone in ReminderTone.allCases {
                let wording = AdviceTemplateGenerator().wording(
                    for: draft,
                    tone: tone,
                    locale: locale
                )
                #expect(!wording.title.isEmpty)
                #expect(!wording.body.isEmpty)
                #expect(!wording.title.contains("!"))
                #expect(!wording.body.contains("!"))
            }

            let insight = SpendingInsightSummary(
                id: UUID(),
                dedupeKey: draft.dedupeKey,
                type: type,
                severity: draft.severity,
                titleKey: draft.titleKey,
                bodyKey: draft.bodyKey,
                payload: draft.payload,
                relatedCategory: draft.relatedCategory,
                relatedEmotionTag: draft.relatedEmotionTag,
                periodStart: draft.periodStart,
                periodEnd: draft.periodEnd,
                isDismissed: false,
                dismissedAt: nil
            )
            let wording = InsightPresentationFormatter().wording(
                for: insight,
                locale: locale
            )
            #expect(!wording.title.isEmpty)
            #expect(!wording.body.isEmpty)
        }
    }

    @Test
    func reminderActionNormalizationIsUniqueBoundedAndKeepsContinuePurchase() async throws {
        let context = try makeContext()
        let draft = insightDraft(type: .highSinglePurchase, snapshot: context.snapshot)
        let engine = ReminderEngine()
        let tooMany = ReminderContext(
            candidate: nil,
            impact: nil,
            snapshot: context.snapshot,
            drafts: [draft],
            suggestedActions: [
                .addToWishlist,
                .addToWishlist,
                .startCoolingOff24h,
                .waitUntilNextCycle,
                .adjustBudget,
                .reviewRecentSpending
            ],
            tone: .soft
        )
        let empty = ReminderContext(
            candidate: nil,
            impact: nil,
            snapshot: context.snapshot,
            drafts: [draft],
            suggestedActions: [],
            tone: .soft
        )

        let bounded = try #require(
            await engine.generateReminder(
                context: tooMany,
                channel: .sheet,
                locale: Locale(identifier: "en_US")
            )
        )
        let filled = try #require(
            await engine.generateReminder(
                context: empty,
                channel: .sheet,
                locale: Locale(identifier: "en_US")
            )
        )

        #expect(bounded.actions.count == 4)
        #expect(Set(bounded.actions.map(\.rawValue)).count == bounded.actions.count)
        #expect(bounded.actions.contains(.continuePurchase))
        #expect(filled.actions == [.addToWishlist, .continuePurchase])
    }

    @Test
    func insightUpsertDeduplicatesAndPreservesDismissal() async throws {
        let context = try makeContext()
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let draft = insightDraft(
            type: .coolingOffSuccess,
            snapshot: context.snapshot,
            severity: .info
        )

        let first = try await actor.upsertSpendingInsights([draft, draft], createdAt: context.now)
        let stored = try await actor.fetchSpendingInsightSummaries()
        try await actor.dismissSpendingInsight(id: try #require(stored.first?.id), at: context.now)
        _ = try await actor.upsertSpendingInsights([draft], createdAt: context.now)
        let active = try await actor.fetchSpendingInsightSummaries()
        let all = try await actor.fetchSpendingInsightSummaries(includeDismissed: true)

        #expect(first.count == 1)
        #expect(stored.count == 1)
        #expect(active.isEmpty)
        #expect(all.count == 1)
        #expect(all.first?.isDismissed == true)
    }

    @Test
    func pointInTimeSafeCheckIsNotPersistedAsACurrentReviewInsight() async throws {
        let context = try makeContext()
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let draft = insightDraft(
            type: .safeToProceed,
            snapshot: context.snapshot,
            severity: .info
        )

        let inserted = try await actor.upsertSpendingInsights([draft], createdAt: context.now)
        let stored = try await actor.fetchSpendingInsightSummaries(includeDismissed: true)

        #expect(inserted.isEmpty)
        #expect(stored.isEmpty)
    }

    @Test
    func legacyPointInTimeSafeCheckIsHiddenWithoutHidingDurableInsights() async throws {
        let context = try makeContext()
        let controller = try DataController(isStoredInMemoryOnly: true)
        try await Phase5LegacyInsightSeeder(modelContainer: controller.container)
            .insertSafeAndDurableInsights(at: context.now)

        let stored = try await controller.makeDataActor()
            .fetchSpendingInsightSummaries(includeDismissed: true)

        #expect(stored.map(\.type) == [.coolingOffSuccess])
    }

    @Test
    func reminderResponseIsPersistedOnTheShownEvent() async throws {
        let context = try makeContext()
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let id = UUID()
        _ = try await actor.createReminderEvent(
            ReminderEventDraft(
                id: id,
                insightType: .highSinglePurchase,
                scopeKey: "highSinglePurchase:global",
                channel: .sheet,
                shownAt: context.now,
                categoryRiskBasisPoints: nil,
                isInterrupting: true,
                response: nil,
                respondedAt: nil
            )
        )
        let updated = try await actor.updateReminderEventResponse(
            id: id,
            response: .acted,
            at: try shifted(context.now, hours: 1)
        )

        let expectedResponseDate = try shifted(context.now, hours: 1)
        #expect(updated.response == .acted)
        #expect(updated.respondedAt == expectedResponseDate)
    }

    @Test @MainActor
    func reminderEventCreationFailureDoesNotBlockExpenseSaving() async throws {
        let context = try makeContext()
        let actor = try await configuredActor(for: context)
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: context.now,
            reminderEventWriter: reminderWriter(failCreate: true)
        )
        viewModel.amountText = "300"
        await loadContext(for: viewModel, actor: actor, context: context)

        let result = await submit(viewModel, actor: actor, context: context)
        let expenses = try await actor.fetchExpenseSummaries()
        let events = try await actor.fetchReminderEventSummaries()

        if case .saved = result {
            // Expected: advisory history is best effort, while the expense is authoritative.
        } else {
            Issue.record("Reminder history failure must fall back to saving the expense")
        }
        #expect(expenses.count == 1)
        #expect(events.isEmpty)
        #expect(viewModel.error == nil)
    }

    @Test @MainActor
    func reminderResponseFailureDoesNotBlockContinuePurchase() async throws {
        let context = try makeContext()
        let actor = try await configuredActor(for: context)
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: context.now,
            reminderEventWriter: reminderWriter(failUpdate: true)
        )
        viewModel.amountText = "300"
        await loadContext(for: viewModel, actor: actor, context: context)

        let result = await submit(viewModel, actor: actor, context: context)
        guard case let .reminder(presentation) = result else {
            Issue.record("Expected a reminder before continuing the purchase")
            return
        }
        let saved = await viewModel.continueAfterReminder(
            eventID: presentation.id,
            dataActor: actor,
            currencyCode: "USD",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: context.now,
            timeZone: TimeZone(identifier: "UTC")!,
            cycleStartDay: 1,
            calendar: calendar
        )
        let expenses = try await actor.fetchExpenseSummaries()
        let events = try await actor.fetchReminderEventSummaries()

        #expect(saved)
        #expect(expenses.count == 1)
        #expect(events.count == 1)
        #expect(events.first?.response == nil)
        #expect(viewModel.error == nil)
    }

    @Test @MainActor
    func fiveSequentialLargeExpenseSubmissionsPresentOnlyOneSheet() async throws {
        let context = try makeContext()
        let actor = try await configuredActor(for: context)

        var reminderCount = 0
        var savedCount = 0
        for _ in 0..<5 {
            let viewModel = ExpenseFormViewModel(existingExpense: nil, now: context.now)
            viewModel.amountText = "300"
            await viewModel.loadContext(
                dataActor: actor,
                currencyCode: "USD",
                cycleStartDay: 1,
                calendar: calendar,
                referenceDate: context.now,
                locale: Locale(identifier: "en_US"),
                ruleConfiguration: context.config,
                preferences: preferences()
            )
            let result = await viewModel.submit(
                dataActor: actor,
                currencyCode: "USD",
                bucket: .discretionary,
                locale: Locale(identifier: "en_US"),
                now: context.now,
                timeZone: TimeZone(identifier: "UTC")!,
                cycleStartDay: 1,
                calendar: calendar
            )
            switch result {
            case .reminder:
                reminderCount += 1
            case .saved:
                savedCount += 1
            case .failed:
                Issue.record("Large expense submission unexpectedly failed")
            }
        }
        let events = try await actor.fetchReminderEventSummaries()
        let insights = try await actor.fetchSpendingInsightSummaries()

        #expect(reminderCount == 1)
        #expect(savedCount == 4)
        #expect(events.count == 1)
        #expect(insights.contains { $0.type == .highSinglePurchase })
    }

    @MainActor
    private func configuredActor(for context: Context) async throws -> DataActor {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.createBudgetPlan(
            BudgetPlanDraft(
                id: UUID(),
                cycleStart: context.snapshot.cycle.start,
                cycleEnd: context.snapshot.cycle.end,
                currencyCode: "USD",
                monthlyIncomeMinorUnits: 300_000,
                totalBudgetMinorUnits: 300_000,
                fixedExpensesMinorUnits: 0,
                savingGoalMinorUnits: 150_000,
                createdAt: context.now,
                updatedAt: context.now,
                categoryBudgets: []
            )
        )
        return actor
    }

    @MainActor
    private func loadContext(
        for viewModel: ExpenseFormViewModel,
        actor: DataActor,
        context: Context
    ) async {
        await viewModel.loadContext(
            dataActor: actor,
            currencyCode: "USD",
            cycleStartDay: 1,
            calendar: calendar,
            referenceDate: context.now,
            locale: Locale(identifier: "en_US"),
            ruleConfiguration: context.config,
            preferences: preferences()
        )
    }

    @MainActor
    private func submit(
        _ viewModel: ExpenseFormViewModel,
        actor: DataActor,
        context: Context
    ) async -> ExpenseSubmitResult {
        await viewModel.submit(
            dataActor: actor,
            currencyCode: "USD",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: context.now,
            timeZone: TimeZone(identifier: "UTC")!,
            cycleStartDay: 1,
            calendar: calendar
        )
    }

    private func reminderWriter(
        failCreate: Bool = false,
        failUpdate: Bool = false
    ) -> ReminderEventWriter {
        let live = ReminderEventWriter.live
        return ReminderEventWriter(
            create: { actor, draft in
                if failCreate { throw ForcedReminderWriterError.failure }
                return try await live.create(actor, draft)
            },
            updateResponse: { actor, id, response, date in
                if failUpdate { throw ForcedReminderWriterError.failure }
                return try await live.updateResponse(actor, id, response, date)
            }
        )
    }

    private func makeContext(
        nowHour: Int = 12,
        storedExpenses: [ExpenseSummary] = []
    ) throws -> Context {
        let start = try date(2026, 1, 1)
        let end = try date(2026, 2, 1)
        let now = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 20, hour: nowHour))
        )
        let categoryBudget = CategoryBudgetSummary(
            id: UUID(),
            category: .food,
            limitMinorUnits: 100_000,
            warningThresholdBasisPoints: 8_000
        )
        let plan = BudgetPlanSummary(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 300_000,
            totalBudgetMinorUnits: 300_000,
            fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 150_000,
            authority: .incomeBased,
            categoryBudgets: [categoryBudget]
        )
        let snapshot = try BudgetEngine().snapshot(
            cycle: DateInterval(start: start, end: end),
            currencyCode: "USD",
            expenses: storedExpenses,
            plan: plan,
            now: now,
            calendar: calendar
        )
        return Context(
            start: start,
            now: now,
            snapshot: snapshot,
            categoryBudgets: [categoryBudget],
            config: RuleConfiguration.defaults(currencyCode: "USD")
        )
    }

    private func candidate(
        amount: Int64,
        category: ExpenseCategory = .coffee,
        reason: PurchaseReason? = nil,
        emotion: EmotionTag? = nil
    ) -> PurchaseCandidate {
        PurchaseCandidate(
            name: nil,
            amount: Money(minorUnits: amount, currencyCode: "USD"),
            category: category,
            bucket: .discretionary,
            reason: reason,
            emotionTag: emotion
        )
    }

    private func expense(
        amount: Int64,
        category: ExpenseCategory = .coffee,
        at date: Date,
        localHour: Int? = nil,
        emotion: EmotionTag? = nil,
        reason: PurchaseReason? = nil
    ) -> ExpenseSummary {
        let spentAt: Date
        if let localHour {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            spentAt = calendar.date(from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: localHour
            )) ?? date
        } else {
            spentAt = date
        }
        return ExpenseSummary(
            id: UUID(),
            amount: Money(minorUnits: amount, currencyCode: "USD"),
            category: category,
            bucket: .discretionary,
            merchantName: nil,
            spentAt: spentAt,
            spentTimeZoneIdentifier: "UTC",
            createdAt: spentAt,
            updatedAt: spentAt,
            paymentMethod: nil,
            emotionTag: emotion,
            purchaseReason: reason,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func insightDraft(
        type: SpendingInsightType,
        snapshot: BudgetSnapshot,
        severity: InsightSeverity = .caution,
        riskBasisPoints: Int? = nil
    ) -> InsightDraft {
        let category = type == .categoryBudgetRisk ? ExpenseCategory.food : nil
        let payload: [String: InsightValue] = switch type {
        case .highSinglePurchase:
            ["amount": .money(Money(minorUnits: 30_000, currencyCode: "USD"))]
        case .categoryBudgetRisk:
            [
                "category": .category(.food),
                "risk": .basisPoints(riskBasisPoints ?? 8_500)
            ]
        case .imageRelatedIncrease:
            [
                "current": .money(Money(minorUnits: 30_000, currencyCode: "USD")),
                "change": .basisPoints(15_000)
            ]
        case .safeToProceed:
            [
                "remainingFreeAfter": .money(
                    Money(minorUnits: 90_000, currencyCode: "USD")
                )
            ]
        case .lateNightSpending, .repeatedStressSpending, .impulseCluster,
             .wishlistCoolingOff, .coolingOffSuccess, .monthlySummary:
            ["count": .integer(3)]
        }
        return InsightDraft(
            type: type,
            severity: severity,
            dedupeKey: "\(type.rawValue):test",
            payload: payload,
            throttleMetadata: ReminderThrottleMetadata(
                scopeKey: category.map { "categoryBudgetRisk:\($0.rawValue)" }
                    ?? "\(type.rawValue):global",
                categoryRiskBasisPoints: riskBasisPoints
            ),
            relatedCategory: category,
            relatedEmotionTag: nil,
            periodStart: snapshot.cycle.start,
            periodEnd: snapshot.cycle.end
        )
    }

    private func event(
        type: SpendingInsightType,
        scope: String,
        at date: Date,
        riskBasisPoints: Int? = nil,
        response: ReminderResponse? = nil,
        interrupting: Bool = false
    ) -> ReminderEventSummary {
        ReminderEventSummary(
            id: UUID(),
            insightType: type,
            scopeKey: scope,
            channel: interrupting ? .sheet : .card,
            shownAt: date,
            categoryRiskBasisPoints: riskBasisPoints,
            isInterrupting: interrupting,
            response: response,
            respondedAt: response == nil ? nil : date
        )
    }

    private func preferences(
        enabled: Bool = true,
        tone: ReminderTone = .soft,
        maxDaily: Int = 2
    ) -> PreferencesSnapshot {
        PreferencesSnapshot(
            reminderTone: tone,
            gentleRemindersEnabled: enabled,
            notificationsEnabled: false,
            quietHours: nil,
            maxDailyInterruptions: maxDaily
        )
    }

    private func configuration(
        largePurchaseFloor: Int64,
        largePurchaseRatio: Decimal,
        lateStart: Int = 22,
        lateEnd: Int = 5,
        lateRatio: Decimal = Decimal(string: "0.05")!,
        lateWindowDays: Int = 30,
        lateMinimumCount: Int = 3,
        stressCount: Int = 3,
        impulseHours: Int = 72,
        impulseCount: Int = 3,
        imageMultiplier: Decimal = Decimal(string: "1.4")!,
        imageMinimumAmount: Int64? = nil,
        baselineMonths: Int = 3,
        minimumBaseline: Int = 2,
        safeBufferBasisPoints: Int = 5_000
    ) -> RuleConfiguration {
        RuleConfiguration(
            largePurchaseFloor: Money(
                minorUnits: largePurchaseFloor,
                currencyCode: "USD"
            ),
            largePurchaseFreeBudgetRatio: largePurchaseRatio,
            lateNightStartHour: lateStart,
            lateNightEndHour: lateEnd,
            lateNightMinimumRatio: lateRatio,
            lateNightWindowDays: lateWindowDays,
            lateNightMinimumCount: lateMinimumCount,
            stressWindowDays: 7,
            stressMinimumCount: stressCount,
            impulseWindowHours: impulseHours,
            impulseMinimumCount: impulseCount,
            imageIncreaseMultiplier: imageMultiplier,
            imageRelatedMinimumAmount: Money(
                minorUnits: imageMinimumAmount ?? largePurchaseFloor,
                currencyCode: "USD"
            ),
            imageBaselineMonths: baselineMonths,
            minimumBaselineMonthsRequired: minimumBaseline,
            categoryWarningThresholdBasisPoints: 8_000,
            safeProceedBufferBasisPoints: safeBufferBasisPoints
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func shifted(_ date: Date, days: Int) throws -> Date {
        try #require(calendar.date(byAdding: .day, value: days, to: date))
    }

    private func shifted(_ date: Date, hours: Int) throws -> Date {
        try #require(calendar.date(byAdding: .hour, value: hours, to: date))
    }

    private struct Context {
        let start: Date
        let now: Date
        let snapshot: BudgetSnapshot
        let categoryBudgets: [CategoryBudgetSummary]
        let config: RuleConfiguration
    }

    private struct UnsafeEnhancer: ReminderWordingEnhancing {
        func enhance(
            template: ReminderWording,
            tone: ReminderTone,
            localeIdentifier: String
        ) async throws -> ReminderWording {
            ReminderWording(
                title: "You must stop!",
                body: "This wording is intentionally far too long and judgmental for the selected reminder tone!"
            )
        }
    }

    private enum ForcedReminderWriterError: Error {
        case failure
    }
}

@ModelActor
private actor Phase5LegacyInsightSeeder {
    func insertSafeAndDurableInsights(at date: Date) throws {
        modelContext.insert(insight(type: .safeToProceed, at: date))
        modelContext.insert(insight(type: .coolingOffSuccess, at: date.addingTimeInterval(-1)))
        try modelContext.save()
    }

    private func insight(type: SpendingInsightType, at date: Date) -> SpendingInsight {
        SpendingInsight(
            id: UUID(),
            dedupeKey: "legacy:\(type.rawValue)",
            typeRaw: type.rawValue,
            severityRaw: InsightSeverity.info.rawValue,
            titleKey: "insight.\(type.rawValue).title",
            bodyKey: "insight.\(type.rawValue).body",
            payloadJSON: "{}",
            relatedCategoryRaw: nil,
            relatedEmotionTagRaw: nil,
            createdAt: date,
            periodStart: date.addingTimeInterval(-1),
            periodEnd: date,
            isDismissed: false,
            dismissedAt: nil
        )
    }
}
