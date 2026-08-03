import Foundation
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
        let configuration = configuration(
            largePurchaseFloor: 100_000,
            largePurchaseRatio: 1
        )
        let drafts = detector.evaluatePotentialPurchase(
            candidate: candidate(amount: 75_000),
            expenses: [],
            snapshot: context.snapshot,
            categoryBudgets: [],
            historicalCycles: [],
            config: configuration,
            now: context.now,
            calendar: calendar
        )

        #expect(drafts.contains { $0.type == .safeToProceed })
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
    func insightUpsertDeduplicatesAndPreservesDismissal() async throws {
        let context = try makeContext()
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let draft = insightDraft(type: .safeToProceed, snapshot: context.snapshot, severity: .info)

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
    func fiveSequentialLargeExpenseSubmissionsPresentOnlyOneSheet() async throws {
        let context = try makeContext()
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.createBudgetPlan(
            BudgetPlanDraft(
                id: UUID(),
                cycleStart: context.snapshot.cycle.start,
                cycleEnd: context.snapshot.cycle.end,
                currencyCode: "USD",
                monthlyIncomeMinorUnits: 400_000,
                totalBudgetMinorUnits: 300_000,
                fixedExpensesMinorUnits: 100_000,
                savingGoalMinorUnits: 50_000,
                createdAt: context.now,
                updatedAt: context.now,
                categoryBudgets: []
            )
        )

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
            monthlyIncomeMinorUnits: 400_000,
            totalBudgetMinorUnits: 300_000,
            fixedExpensesMinorUnits: 100_000,
            savingGoalMinorUnits: 50_000,
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
        return InsightDraft(
            type: type,
            severity: severity,
            dedupeKey: "\(type.rawValue):test",
            payload: type == .highSinglePurchase
                ? ["amount": .money(Money(minorUnits: 30_000, currencyCode: "USD"))]
                : ["count": .integer(3)],
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
        stressCount: Int = 3,
        impulseHours: Int = 72,
        impulseCount: Int = 3,
        imageMultiplier: Decimal = Decimal(string: "1.4")!,
        baselineMonths: Int = 3,
        minimumBaseline: Int = 2
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
            stressWindowDays: 7,
            stressMinimumCount: stressCount,
            impulseWindowHours: impulseHours,
            impulseMinimumCount: impulseCount,
            imageIncreaseMultiplier: imageMultiplier,
            imageBaselineMonths: baselineMonths,
            minimumBaselineMonthsRequired: minimumBaseline,
            categoryWarningThresholdBasisPoints: 8_000
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
}
