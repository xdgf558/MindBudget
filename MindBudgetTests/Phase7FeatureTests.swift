import Foundation
import Testing
@testable import MindBudget

struct Phase7FeatureTests {
    @Test
    func classifierCoversEverySupportedIntentInEnglishAndChinese() {
        let classifier = IntentClassifier()
        let examples: [(String, AskIntentKey)] = [
            ("Can I afford this?", .canIAfford),
            ("这个周期还剩多少？", .remainingBudget),
            ("Any stress pattern?", .stressPattern),
            ("最近有冲动消费吗？", .impulsePattern),
            ("Which category increased?", .categoryChange),
            ("有什么便宜的替代？", .alternative),
            ("Wishlist cooling status", .wishlistStatus),
            ("Should I buy this stock?", .outOfScope),
            ("Hello there", .unknown)
        ]

        for (question, expected) in examples {
            #expect(classifier.classify(question) == expected)
        }
    }

    @Test
    func aiOffStillReturnsCompleteTemplatesForAllSevenAskIntents() async {
        let questions: [(String, AskIntentKey)] = [
            ("Can I afford this?", .canIAfford),
            ("Any stress pattern?", .stressPattern),
            ("Any impulse pattern?", .impulsePattern),
            ("Which category increased?", .categoryChange),
            ("How much is left?", .remainingBudget),
            ("Any cheaper alternative?", .alternative),
            ("Wishlist status", .wishlistStatus)
        ]
        for (question, expected) in questions {
            let response = await service(model: MockAI(mode: .safe)).answer(
                request(question: question, enhancementEnabled: false)
            )
            #expect(response.intent == expected)
            #expect(!response.answer.title.isEmpty)
            #expect(!response.answer.body.isEmpty)
            #expect((2...4).contains(response.answer.actionIdentifiers.count))
            #expect(response.source == .modelUnavailableFallback)
        }
    }

    @Test
    func rawQuestionNeverEntersTheModelContext() async throws {
        let recorder = AIContextRecorder()
        let sensitiveQuestion = "Can I afford SECRET-RAW-QUESTION?"
        let response = await service(model: MockAI(mode: .capturing(recorder))).answer(
            request(
                question: sensitiveQuestion,
                amount: Money(minorUnits: 2_500, currencyCode: "USD"),
                category: .coffee,
                enhancementEnabled: true
            )
        )
        let context = try #require(await recorder.context)

        #expect(response.source == .model)
        #expect(!context.promptData.contains("SECRET-RAW-QUESTION"))
        #expect(context.budgetFactsFormatted.keys.contains("candidateAmount"))
    }

    @Test
    func unknownAndOutOfScopeQuestionsNeverCallTheModel() async {
        let recorder = AIContextRecorder()
        let ask = service(model: MockAI(mode: .capturing(recorder)))

        let unknown = await ask.answer(
            request(question: "Hello there", enhancementEnabled: true)
        )
        let refused = await ask.answer(
            request(question: "Give me tax advice", enhancementEnabled: true)
        )

        #expect(unknown.intent == .unknown)
        #expect(refused.intent == .outOfScope)
        #expect(unknown.source == .template)
        #expect(refused.source == .template)
        #expect(await recorder.callCount == 0)
    }

    @Test
    func affordabilityNeverGuessesMissingAmountOrCategory() async {
        let response = await service(model: MockAI(mode: .safe)).answer(
            request(question: "Can I afford this?", enhancementEnabled: false)
        )

        #expect(response.intent == .canIAfford)
        #expect(response.answer.body.contains("without guessing"))
        #expect(!response.answer.body.contains("$"))
    }

    @Test
    func validatorRejectsFabricatedNumbersAndUnknownActions() throws {
        let context = askContext(
            facts: ["remaining": "$1,234.56"],
            actions: [.reviewRecentSpending, .adjustBudget]
        )
        let fabricated = GeneratedAnswer(
            title: "Budget check",
            body: "You have 999 left.",
            actionIdentifiers: [
                SuggestedAction.reviewRecentSpending.rawValue,
                SuggestedAction.adjustBudget.rawValue
            ]
        )
        let unknownAction = GeneratedAnswer(
            title: "Budget check",
            body: "Review the recorded facts.",
            actionIdentifiers: ["sendMoney", SuggestedAction.adjustBudget.rawValue]
        )

        #expect(throws: AdviceSafetyViolation.fabricatedNumber) {
            try AdviceSafetyValidator().validate(answer: fabricated, context: context)
        }
        #expect(throws: AdviceSafetyViolation.unknownAction) {
            try AdviceSafetyValidator().validate(answer: unknownAction, context: context)
        }
    }

    @Test
    func purchaseAdviceRequiresAContinueAction() throws {
        let context = PrivacyRedactor().redactAdvice(
            AdviceAggregateInput(
                localeIdentifier: "en_US",
                currencyCode: "USD",
                purchaseCategory: .coffee,
                purchaseAmountFormatted: "$25.00",
                remainingFreeAfterFormatted: "$100.00",
                freeBudgetImpactPercent: 25,
                daysOfBudgetConsumed: 2,
                categoryBudgetUsedPercent: nil,
                recentStressPurchaseCount7d: 0,
                recentImpulsePurchaseCount72h: 0,
                allowedActions: [.addToWishlist, .continuePurchase],
                tone: .soft,
                maxTitleLength: 24,
                maxBodyLength: 80
            )
        )
        let advice = GeneratedAdvice(
            title: "A pause is available",
            body: "You can review this choice.",
            actionIdentifiers: [
                SuggestedAction.addToWishlist.rawValue,
                SuggestedAction.addToWishlist.rawValue
            ],
            severity: .caution
        )

        #expect(throws: AdviceSafetyViolation.invalidActionCount) {
            try AdviceSafetyValidator().validate(advice: advice, context: context)
        }

        let noContinue = GeneratedAdvice(
            title: "A pause is available",
            body: "You can review this choice.",
            actionIdentifiers: [
                SuggestedAction.addToWishlist.rawValue,
                SuggestedAction.reviewRecentSpending.rawValue
            ],
            severity: .caution
        )
        let expandedContext = PrivacyRedactor().redactAdvice(
            AdviceAggregateInput(
                localeIdentifier: "en_US",
                currencyCode: "USD",
                purchaseCategory: .coffee,
                purchaseAmountFormatted: "$25.00",
                remainingFreeAfterFormatted: "$100.00",
                freeBudgetImpactPercent: 25,
                daysOfBudgetConsumed: 2,
                categoryBudgetUsedPercent: nil,
                recentStressPurchaseCount7d: 0,
                recentImpulsePurchaseCount72h: 0,
                allowedActions: [.addToWishlist, .reviewRecentSpending, .continuePurchase],
                tone: .soft,
                maxTitleLength: 24,
                maxBodyLength: 80
            )
        )
        #expect(throws: AdviceSafetyViolation.missingContinuePurchase) {
            try AdviceSafetyValidator().validate(advice: noContinue, context: expandedContext)
        }
    }

    @Test
    func compositeFallsBackForUnsafeFailureAndTimeout() async {
        let context = askContext(
            facts: [:],
            actions: [.reviewRecentSpending, .adjustBudget]
        )
        let available = AIEnhancementCapability(
            userEnabled: true,
            runtimeAvailability: { .available }
        )

        let unsafe = await CompositeAdviceGenerator(
            model: MockAI(mode: .fabricated),
            capability: available
        ).answer(intent: .remainingBudget, context: context, locale: Locale(identifier: "en"))
        let failed = await CompositeAdviceGenerator(
            model: MockAI(mode: .failure),
            capability: available
        ).answer(intent: .remainingBudget, context: context, locale: Locale(identifier: "en"))
        let timedOut = await CompositeAdviceGenerator(
            model: MockAI(mode: .slow),
            capability: available,
            timeoutNanoseconds: 1_000_000
        ).answer(intent: .remainingBudget, context: context, locale: Locale(identifier: "en"))

        #expect(unsafe.source == .modelValidatedFallback)
        #expect(failed.source == .modelValidatedFallback)
        #expect(timedOut.source == .modelTimedOutFallback)
        #expect(!unsafe.answer.body.isEmpty)
        #expect(!failed.answer.body.isEmpty)
        #expect(!timedOut.answer.body.isEmpty)
    }

    @Test
    func aggregateContextsContainNoDetailOrRawTimestampFields() {
        let ask = askContext(
            facts: ["remaining": "$10.00"],
            actions: [.reviewRecentSpending, .adjustBudget]
        )
        let summary = PrivacyRedactor().redactSummary(
            SummaryAggregateInput(
                localeIdentifier: "en_US",
                cycleLabel: "currentCycle",
                topCategories: [.food],
                categoryChangeDirections: [.food: "up"],
                totalUsedPercent: 40,
                emotionCounts: [.neutral: 2],
                coolingOffSkippedCount: 1,
                coolingOffPurchasedCount: 0,
                tone: .soft
            )
        )

        for prompt in [ask.promptData, summary.promptData] {
            #expect(!prompt.contains("note"))
            #expect(!prompt.contains("merchant"))
            #expect(!prompt.contains("startedAt"))
            #expect(!prompt.contains("reviewAt"))
            #expect(!prompt.contains("outcomeRecordedAt"))
        }
    }

    @Test
    func validatorRejectsLengthShameDiagnosisAdviceAndCommands() {
        let context = askContext(
            facts: [:],
            actions: [.reviewRecentSpending, .adjustBudget]
        )
        let actions = context.allowedActionIdentifiers
        let samples: [(GeneratedAnswer, AdviceSafetyViolation)] = [
            (
                GeneratedAnswer(
                    title: String(repeating: "a", count: 25),
                    body: "Review the facts.",
                    actionIdentifiers: actions
                ),
                .titleTooLong
            ),
            (
                GeneratedAnswer(
                    title: "Budget check",
                    body: String(repeating: "a", count: 121),
                    actionIdentifiers: actions
                ),
                .bodyTooLong
            ),
            (
                GeneratedAnswer(
                    title: "Budget check",
                    body: "That is wasteful.",
                    actionIdentifiers: actions
                ),
                .bannedPhrase
            ),
            (
                GeneratedAnswer(
                    title: "Budget check",
                    body: "You are addicted.",
                    actionIdentifiers: actions
                ),
                .diagnosis
            ),
            (
                GeneratedAnswer(
                    title: "Budget check",
                    body: "This is financial advice.",
                    actionIdentifiers: actions
                ),
                .financialAdvice
            ),
            (
                GeneratedAnswer(
                    title: "Budget check",
                    body: "Do not buy this.",
                    actionIdentifiers: actions
                ),
                .imperativeProhibition
            )
        ]

        for (answer, violation) in samples {
            #expect(throws: violation) {
                try AdviceSafetyValidator().validate(answer: answer, context: context)
            }
        }
    }

    @Test
    func validatorAcceptsLocalizedAllowedNumbers() throws {
        let context = askContext(
            facts: ["remaining": "US$1,234.56"],
            actions: [.reviewRecentSpending, .adjustBudget]
        )
        let answer = GeneratedAnswer(
            title: "Budget check",
            body: "The recorded remaining amount is 1,234.56.",
            actionIdentifiers: context.allowedActionIdentifiers
        )

        try AdviceSafetyValidator().validate(answer: answer, context: context)
    }

    @Test
    func numericValidationPreservesTheDecimalPointMeaning() {
        let context = askContext(
            facts: ["remaining": "US$1,234.56"],
            actions: [.reviewRecentSpending, .adjustBudget]
        )
        let fabricated = GeneratedAnswer(
            title: "Budget check",
            body: "The recorded remaining amount is 123456.",
            actionIdentifiers: context.allowedActionIdentifiers
        )

        #expect(throws: AdviceSafetyViolation.fabricatedNumber) {
            try AdviceSafetyValidator().validate(answer: fabricated, context: context)
        }
    }

    @Test
    func numericValidationPreservesNegativeAmountMeaning() throws {
        let context = askContext(
            facts: ["remaining": "-US$10.00"],
            actions: [.reviewRecentSpending]
        )
        let positive = GeneratedAnswer(
            title: "Budget check",
            body: "The recorded remaining amount is 10.00.",
            actionIdentifiers: []
        )
        let negative = GeneratedAnswer(
            title: "Budget check",
            body: "The recorded remaining amount is -10.00.",
            actionIdentifiers: []
        )

        #expect(throws: AdviceSafetyViolation.fabricatedNumber) {
            try AdviceSafetyValidator().validate(answer: positive, context: context)
        }
        try AdviceSafetyValidator().validate(answer: negative, context: context)
    }

    @Test
    func askPurchaseDecisionRequiresContinueButInformationalOutputMayHaveNoAction() throws {
        let purchaseContext = PrivacyRedactor().redactAsk(
            AskAggregateInput(
                localeIdentifier: "en_US",
                currencyCode: "USD",
                intent: .canIAfford,
                budgetFactsFormatted: [
                    "candidateAmount": "$25.00",
                    "templateBody": "Review the recorded facts."
                ],
                relevantInsightKeys: [],
                allowedActions: [.addToWishlist, .reviewRecentSpending, .continuePurchase],
                tone: .soft
            )
        )
        let missingContinue = GeneratedAnswer(
            title: "Budget check",
            body: "Review the recorded facts.",
            actionIdentifiers: [
                SuggestedAction.addToWishlist.rawValue,
                SuggestedAction.reviewRecentSpending.rawValue
            ]
        )
        #expect(throws: AdviceSafetyViolation.missingContinuePurchase) {
            try AdviceSafetyValidator().validate(answer: missingContinue, context: purchaseContext)
        }

        let informational = GeneratedAnswer(
            title: "Budget check",
            body: "Review the recorded facts.",
            actionIdentifiers: []
        )
        try AdviceSafetyValidator().validate(
            answer: informational,
            context: askContext(facts: [:], actions: [])
        )
    }

    @Test
    func cycleSummaryCountsOnlyOutcomesRecordedInsideTheCycle() async throws {
        let recorder = SummaryContextRecorder()
        let configured = snapshot()
        let calendar = TestFixtures.utcCalendar
        let inside = try #require(
            calendar.date(byAdding: .hour, value: 1, to: configured.cycle.start)
        )
        let outside = try #require(
            calendar.date(byAdding: .month, value: -1, to: configured.cycle.start)
        )
        let summaries = [
            coolingSummary(outcome: .skipped, recordedAt: inside),
            coolingSummary(outcome: .purchased, recordedAt: outside)
        ]

        let result = await CycleSummaryService(
            model: MockAI(mode: .capturingSummary(recorder)),
            runtimeAvailability: { .available }
        ).generate(
            snapshot: .configured(configured),
            expenses: [],
            coolingOffPlans: summaries,
            locale: Locale(identifier: "en_US"),
            calendar: calendar,
            tone: .soft,
            enhancementEnabled: true
        )
        let context = try #require(await recorder.context)

        #expect(result.source == .model)
        #expect(context.coolingOffSkippedCount == 1)
        #expect(context.coolingOffPurchasedCount == 0)
        #expect(context.cycleLabel != "currentCycle")
        #expect(!context.promptData.contains("outcomeRecordedAt"))
    }

    @Test
    func centralizedCapabilityFailsClosedBeforeRuntimeWhenDisabled() async {
        let probe = GateProbe()
        let userDisabled = await AIEnhancementCapability(
            productScopeEnabled: true,
            userEnabled: false,
            runtimeAvailability: {
                await probe.recordCall()
                return .available
            }
        ).availability
        let buildDisabled = await AIEnhancementCapability(
            productScopeEnabled: false,
            userEnabled: true,
            runtimeAvailability: {
                await probe.recordCall()
                return .available
            }
        ).availability

        #expect(userDisabled == .unavailable(.userDisabled))
        #expect(buildDisabled == .unavailable(.buildUnsupported))
        #expect(await probe.callCount == 0)
    }

    @Test
    func reminderAndCycleSummaryUseMocksAndValidatedModelSources() async throws {
        let mock = MockAI(mode: .safe)
        let configured = snapshot()
        let draft = InsightDraft(
            type: .highSinglePurchase,
            severity: .caution,
            dedupeKey: "phase7:test",
            payload: ["amount": .money(Money(minorUnits: 2_500, currencyCode: "USD"))],
            throttleMetadata: ReminderThrottleMetadata(
                scopeKey: "highSinglePurchase:global",
                categoryRiskBasisPoints: nil
            ),
            relatedCategory: .coffee,
            relatedEmotionTag: nil,
            periodStart: configured.cycle.start,
            periodEnd: configured.cycle.end
        )
        let engine = ReminderEngine(
            aiEnhancementEnabled: true,
            aiGenerator: mock,
            aiRuntimeAvailability: { .available }
        )
        let context = engine.buildContext(
            candidate: PurchaseCandidate(
                name: "Never enters the redactor",
                amount: Money(minorUnits: 2_500, currencyCode: "USD"),
                category: .coffee,
                bucket: .discretionary,
                reason: nil,
                emotionTag: nil
            ),
            impact: nil,
            snapshot: .configured(configured),
            drafts: [draft],
            tone: .soft
        )
        let reminder = try #require(
            await engine.generateReminder(
                context: context,
                channel: .sheet,
                locale: Locale(identifier: "en_US")
            )
        )
        let summary = await CycleSummaryService(
            model: mock,
            runtimeAvailability: { .available }
        ).generate(
            snapshot: .configured(configured),
            expenses: [],
            coolingOffPlans: [],
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            tone: .soft,
            enhancementEnabled: true
        )

        #expect(reminder.source == .model)
        #expect(reminder.actions.contains(.continuePurchase))
        #expect(summary.source == .model)
    }

    private func service(model: MockAI) -> AskMindBudgetService {
        AskMindBudgetService(
            modelFactory: { _ in model },
            runtimeAvailability: { .available }
        )
    }

    private func request(
        question: String,
        amount: Money? = nil,
        category: ExpenseCategory? = nil,
        enhancementEnabled: Bool
    ) -> AskMindBudgetRequest {
        AskMindBudgetRequest(
            question: question,
            purchaseAmount: amount,
            purchaseCategory: category,
            purchaseBucket: category?.defaultBucket,
            snapshot: snapshot(),
            expenses: [],
            wishItems: [],
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            tone: .soft,
            enhancementEnabled: enhancementEnabled
        )
    }

    private func snapshot() -> ConfiguredBudgetSnapshot {
        let start = Date(timeIntervalSince1970: 1_784_764_800)
        let end = Date(timeIntervalSince1970: 1_785_715_200)
        return ConfiguredBudgetSnapshot(
            cycle: DateInterval(start: start, end: end),
            currencyCode: "USD",
            totalBudget: Money(minorUnits: 300_000, currencyCode: "USD"),
            fixedForecast: Money(minorUnits: 100_000, currencyCode: "USD"),
            savingGoal: Money(minorUnits: 50_000, currencyCode: "USD"),
            freeBudget: Money(minorUnits: 150_000, currencyCode: "USD"),
            spentTotal: Money(minorUnits: 40_000, currencyCode: "USD"),
            fixedSpent: Money(minorUnits: 0, currencyCode: "USD"),
            discretionarySpent: Money(minorUnits: 40_000, currencyCode: "USD"),
            savedSoFar: Money(minorUnits: 0, currencyCode: "USD"),
            spentByCategory: [:],
            remainingTotal: Money(minorUnits: 260_000, currencyCode: "USD"),
            remainingFree: Money(minorUnits: 110_000, currencyCode: "USD"),
            pendingFixed: Money(minorUnits: 100_000, currencyCode: "USD"),
            pendingSaving: Money(minorUnits: 50_000, currencyCode: "USD"),
            availableRightNow: Money(minorUnits: 110_000, currencyCode: "USD"),
            safeDailySpend: Money(minorUnits: 10_000, currencyCode: "USD"),
            daysRemaining: 11
        )
    }

    private func askContext(
        facts: [String: String],
        actions: [SuggestedAction]
    ) -> RedactedAskContext {
        PrivacyRedactor().redactAsk(
            AskAggregateInput(
                localeIdentifier: "en_US",
                currencyCode: "USD",
                intent: .remainingBudget,
                budgetFactsFormatted: facts.merging([
                    "templateBody": "Review the recorded budget facts."
                ]) { first, _ in first },
                relevantInsightKeys: [],
                allowedActions: actions,
                tone: .soft
            )
        )
    }

    private func coolingSummary(
        outcome: CoolingOffOutcome,
        recordedAt: Date
    ) -> CoolingOffPlanSummary {
        CoolingOffPlanSummary(
            id: UUID(),
            wishItemId: UUID(),
            startedAt: recordedAt,
            reviewAt: recordedAt,
            durationHours: 24,
            status: .completed,
            notificationIdentifier: nil,
            completedAt: recordedAt,
            outcome: outcome,
            outcomeRecordedAt: recordedAt
        )
    }
}

private actor AIContextRecorder {
    private(set) var context: RedactedAskContext?
    private(set) var callCount = 0

    func record(_ context: RedactedAskContext) {
        self.context = context
        callCount += 1
    }
}

private actor GateProbe {
    private(set) var callCount = 0

    func recordCall() {
        callCount += 1
    }
}

private actor SummaryContextRecorder {
    private(set) var context: RedactedSummaryContext?

    func record(_ context: RedactedSummaryContext) {
        self.context = context
    }
}

private enum MockAIError: Error, Sendable {
    case failed
}

private struct MockAI: AIAdviceGenerating, Sendable {
    enum Mode: Sendable {
        case safe
        case capturing(AIContextRecorder)
        case capturingSummary(SummaryContextRecorder)
        case fabricated
        case failure
        case slow
    }

    let mode: Mode
    var availability: AIAvailability { get async { .available } }

    func generateReminder(from context: RedactedAdviceContext) async throws -> GeneratedAdvice {
        GeneratedAdvice(
            title: "A gentle check",
            body: "Review the recorded facts.",
            actionIdentifiers: context.allowedActionIdentifiers,
            severity: .caution
        )
    }

    func generateCycleSummary(from context: RedactedSummaryContext) async throws -> GeneratedSummary {
        if case let .capturingSummary(recorder) = mode {
            await recorder.record(context)
        }
        return GeneratedSummary(
            title: "Cycle snapshot",
            body: "Review the recorded pattern.",
            actionIdentifiers: context.allowedActionIdentifiers
        )
    }

    func answerQuestion(
        intent: AskIntentKey,
        context: RedactedAskContext
    ) async throws -> GeneratedAnswer {
        switch mode {
        case .safe:
            break
        case let .capturing(recorder):
            await recorder.record(context)
        case .capturingSummary:
            break
        case .fabricated:
            return GeneratedAnswer(
                title: "Budget check",
                body: "You have 999 left.",
                actionIdentifiers: context.allowedActionIdentifiers
            )
        case .failure:
            throw MockAIError.failed
        case .slow:
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        return GeneratedAnswer(
            title: "Budget check",
            body: "Review the recorded facts.",
            actionIdentifiers: context.allowedActionIdentifiers
        )
    }
}
