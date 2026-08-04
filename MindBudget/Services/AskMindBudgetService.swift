import Foundation

struct AskMindBudgetRequest: Sendable {
    let question: String
    let purchaseAmount: Money?
    let purchaseCategory: ExpenseCategory?
    let purchaseBucket: BudgetBucket?
    let snapshot: ConfiguredBudgetSnapshot
    let expenses: [ExpenseSummary]
    let wishItems: [WishItemSummary]
    let locale: Locale
    let calendar: Calendar
    let tone: ReminderTone
    let enhancementEnabled: Bool
}

struct AskMindBudgetResponse: Equatable, Sendable {
    let intent: AskIntentKey
    let answer: GeneratedAnswer
    let source: AdviceGenerationSource
}

struct AskMindBudgetService: Sendable {
    private let classifier: IntentClassifier
    private let redactor: PrivacyRedactor
    private let modelFactory: @Sendable (Bool) -> any AIAdviceGenerating
    private let runtimeAvailability: @Sendable () async -> AIAvailability

    init(
        classifier: IntentClassifier = IntentClassifier(),
        redactor: PrivacyRedactor = PrivacyRedactor(),
        modelFactory: @escaping @Sendable (Bool) -> any AIAdviceGenerating = { _ in
            FoundationModelsAdviceGenerator()
        },
        runtimeAvailability: @escaping @Sendable () async -> AIAvailability = {
            await FoundationModelsAdviceGenerator.runtimeAvailability()
        }
    ) {
        self.classifier = classifier
        self.redactor = redactor
        self.modelFactory = modelFactory
        self.runtimeAvailability = runtimeAvailability
    }

    func answer(_ request: AskMindBudgetRequest) async -> AskMindBudgetResponse {
        // The raw question remains a local, ephemeral classifier input and is never
        // included in an aggregate context or sent to a language model.
        let intent = classifier.classify(request.question, locale: request.locale)
        let input = aggregateInput(intent: intent, request: request)
        let context = redactor.redactAsk(input)
        let capability = AIEnhancementCapability(
            userEnabled: request.enhancementEnabled,
            runtimeAvailability: runtimeAvailability
        )
        let result = await CompositeAdviceGenerator(
            model: modelFactory(request.enhancementEnabled),
            capability: capability
        ).answer(intent: intent, context: context, locale: request.locale)
        return AskMindBudgetResponse(intent: intent, answer: result.answer, source: result.source)
    }

    private func aggregateInput(
        intent: AskIntentKey,
        request: AskMindBudgetRequest
    ) -> AskAggregateInput {
        let formatter = CurrencyFormatterService()
        let currentExpenses = request.expenses.filter {
            request.snapshot.cycle.start <= $0.spentAt
                && $0.spentAt < request.snapshot.cycle.end
        }
        var facts: [String: String] = [:]
        var insightKeys: [String] = []
        var actions: [SuggestedAction] = [.reviewRecentSpending, .adjustBudget]

        switch intent {
        case .canIAfford:
            guard let amount = request.purchaseAmount,
                  let category = request.purchaseCategory,
                  let bucket = request.purchaseBucket else {
                facts["templateBody"] = LocalizedCatalog.string(
                    "ask.answer.canIAfford.clarify",
                    locale: request.locale
                )
                facts["requiresDetails"] = "true"
                actions = [.addToWishlist, .reviewRecentSpending]
                break
            }
            let impact = try? BudgetEngine().impact(
                of: amount,
                category: category,
                bucket: bucket,
                snapshot: request.snapshot,
                categoryBudgets: []
            )
            let affordable = impact.map {
                !$0.willExceedTotalBudget && !$0.willExceedFreeBudget
                    && amount.minorUnits <= request.snapshot.availableRightNow.minorUnits
            } ?? false
            let amountText = formatter.string(from: amount, locale: request.locale)
            let availableText = formatter.string(
                from: request.snapshot.availableRightNow,
                locale: request.locale
            )
            facts["candidateAmount"] = amountText
            facts["availableRightNow"] = availableText
            facts["affordability"] = affordable ? "within" : "outside"
            facts["templateBody"] = LocalizedCatalog.format(
                affordable ? "ask.answer.canIAfford.within" : "ask.answer.canIAfford.outside",
                locale: request.locale,
                amountText,
                availableText
            )
            actions = affordable
                ? [.reviewRecentSpending, .continuePurchase]
                : [.addToWishlist, .adjustBudget, .continuePurchase]
        case .remainingBudget:
            let remaining = formatter.string(
                from: request.snapshot.remainingFree,
                locale: request.locale
            )
            let daily = formatter.string(
                from: request.snapshot.safeDailySpend,
                locale: request.locale
            )
            facts["remainingFree"] = remaining
            facts["safeDailySpend"] = daily
            facts["daysRemaining"] = String(request.snapshot.daysRemaining)
            facts["templateBody"] = LocalizedCatalog.format(
                "ask.answer.remainingBudget.body",
                locale: request.locale,
                remaining,
                daily,
                request.snapshot.daysRemaining
            )
        case .stressPattern:
            let count = currentExpenses.filter {
                $0.emotionTag == .stressed || $0.emotionTag == .anxious
                    || $0.purchaseReason == .stressRelief
            }.count
            facts["count"] = String(count)
            facts["templateBody"] = LocalizedCatalog.format(
                count == 0 ? "ask.answer.stress.none" : "ask.answer.stress.body",
                locale: request.locale,
                count
            )
            insightKeys = count == 0 ? [] : [SpendingInsightType.repeatedStressSpending.rawValue]
        case .impulsePattern:
            let count = currentExpenses.filter {
                $0.emotionTag == .impulse || $0.purchaseReason == .impulse
            }.count
            facts["count"] = String(count)
            facts["templateBody"] = LocalizedCatalog.format(
                count == 0 ? "ask.answer.impulse.none" : "ask.answer.impulse.body",
                locale: request.locale,
                count
            )
            insightKeys = count == 0 ? [] : [SpendingInsightType.impulseCluster.rawValue]
            actions = [.reviewRecentSpending, .startCoolingOff24h]
        case .categoryChange:
            let change = leadingCategoryChange(request: request)
            if let change {
                let category = LocalizedCatalog.string(
                    change.category.localizedNameKey,
                    locale: request.locale
                )
                facts["category"] = category
                facts["current"] = formatter.string(from: change.current, locale: request.locale)
                facts["previous"] = formatter.string(from: change.previous, locale: request.locale)
                facts["templateBody"] = LocalizedCatalog.format(
                    "ask.answer.categoryChange.body",
                    locale: request.locale,
                    category,
                    facts["current"] ?? "—",
                    facts["previous"] ?? "—"
                )
            } else {
                facts["templateBody"] = LocalizedCatalog.string(
                    "ask.answer.categoryChange.none",
                    locale: request.locale
                )
            }
        case .alternative:
            facts["templateBody"] = LocalizedCatalog.string(
                "ask.answer.alternative.body",
                locale: request.locale
            )
            actions = [.addToWishlist, .startCoolingOff24h, .waitUntilNextCycle]
        case .wishlistStatus:
            let cooling = request.wishItems.filter {
                $0.status == .coolingOff || $0.status == .readyToReview
            }.count
            let active = request.wishItems.filter { $0.status == .active }.count
            facts["coolingCount"] = String(cooling)
            facts["activeCount"] = String(active)
            facts["templateBody"] = LocalizedCatalog.format(
                "ask.answer.wishlistStatus.body",
                locale: request.locale,
                cooling,
                active
            )
            actions = [.reviewRecentSpending, .addToWishlist]
        case .outOfScope:
            facts["templateBody"] = LocalizedCatalog.string(
                "ask.answer.outOfScope.body",
                locale: request.locale
            )
            actions = [.reviewRecentSpending, .adjustBudget]
        case .unknown:
            facts["templateBody"] = LocalizedCatalog.string(
                "ask.answer.unknown.body",
                locale: request.locale
            )
            actions = [.reviewRecentSpending, .addToWishlist]
        }

        return AskAggregateInput(
            localeIdentifier: request.locale.identifier,
            currencyCode: request.snapshot.currencyCode,
            intent: intent,
            budgetFactsFormatted: facts,
            relevantInsightKeys: insightKeys,
            allowedActions: actions,
            tone: request.tone
        )
    }

    private func leadingCategoryChange(
        request: AskMindBudgetRequest
    ) -> (category: ExpenseCategory, current: Money, previous: Money)? {
        guard let previousStart = request.calendar.date(
            byAdding: .month,
            value: -1,
            to: request.snapshot.cycle.start
        ) else { return nil }
        let previousEnd = request.snapshot.cycle.start
        var current: [ExpenseCategory: Int64] = [:]
        var previous: [ExpenseCategory: Int64] = [:]
        for expense in request.expenses {
            if request.snapshot.cycle.start <= expense.spentAt
                && expense.spentAt < request.snapshot.cycle.end {
                guard let sum = checkedAdd(current[expense.category, default: 0], expense.amount.minorUnits) else {
                    return nil
                }
                current[expense.category] = sum
            } else if previousStart <= expense.spentAt && expense.spentAt < previousEnd {
                guard let sum = checkedAdd(previous[expense.category, default: 0], expense.amount.minorUnits) else {
                    return nil
                }
                previous[expense.category] = sum
            }
        }
        let candidate = ExpenseCategory.allCases.compactMap { category -> (ExpenseCategory, Int64)? in
            let currentValue = current[category, default: 0]
            let previousValue = previous[category, default: 0]
            let (difference, overflow) = currentValue.subtractingReportingOverflow(previousValue)
            guard !overflow, difference > 0 else { return nil }
            return (category, difference)
        }.max { $0.1 < $1.1 }?.0
        guard let candidate else { return nil }
        let currentMoney = Money(
                minorUnits: current[candidate, default: 0],
                currencyCode: request.snapshot.currencyCode
              )
        let previousMoney = Money(
                minorUnits: previous[candidate, default: 0],
                currencyCode: request.snapshot.currencyCode
              )
        return (candidate, currentMoney, previousMoney)
    }

    private func checkedAdd(_ lhs: Int64, _ rhs: Int64) -> Int64? {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? nil : result
    }
}

extension AdviceTemplateGenerator {
    func answer(
        intent: AskIntentKey,
        context: RedactedAskContext,
        locale: Locale
    ) -> GeneratedAnswer {
        let body = context.budgetFactsFormatted["templateBody"]
            ?? LocalizedCatalog.string("ask.answer.unknown.body", locale: locale)
        let title = LocalizedCatalog.string(
            "ask.answer.\(intent.rawValue).title",
            locale: locale
        )
        let actions = Array(context.allowedActionIdentifiers.prefix(4))
        return GeneratedAnswer(title: title, body: body, actionIdentifiers: actions)
    }
}
