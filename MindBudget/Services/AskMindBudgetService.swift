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
    let premiumEntryAccess: ExistingPremiumEntryAccess
}

struct AskMindBudgetResponse: Equatable, Sendable {
    let intent: AskIntentKey
    let answer: GeneratedAnswer
    let source: AdviceGenerationSource
}

struct LocalSearchResult: Equatable, Sendable {
    let expenses: [ExpenseSummary]
    let wishItems: [WishItemSummary]
}

/// Selects only the authoritative SwiftData projections needed by a classified intent.
/// Spotlight may help users navigate to app-owned objects, but it is never a source for
/// amounts, counts, dates, or any other fact supplied to Foundation Models.
struct LocalSearchService: Sendable {
    func retrieve(
        intent: AskIntentKey,
        snapshot: ConfiguredBudgetSnapshot,
        expenses: [ExpenseSummary],
        wishItems: [WishItemSummary],
        calendar: Calendar
    ) -> LocalSearchResult {
        let relevantExpenses: [ExpenseSummary]
        switch intent {
        case .stressPattern, .impulsePattern:
            relevantExpenses = expenses.filter {
                snapshot.cycle.start <= $0.spentAt && $0.spentAt < snapshot.cycle.end
            }
        case .categoryChange:
            guard let previousStart = calendar.date(
                byAdding: .month,
                value: -1,
                to: snapshot.cycle.start
            ) else {
                return LocalSearchResult(expenses: [], wishItems: [])
            }
            relevantExpenses = expenses.filter {
                previousStart <= $0.spentAt && $0.spentAt < snapshot.cycle.end
            }
        default:
            relevantExpenses = []
        }

        return LocalSearchResult(
            expenses: relevantExpenses,
            wishItems: intent == .wishlistStatus ? wishItems : []
        )
    }
}

struct AskMindBudgetService: Sendable {
    private let classifier: IntentClassifier
    private let localSearch: LocalSearchService
    private let redactor: PrivacyRedactor
    private let modelFactory: @Sendable (Bool) -> any AIAdviceGenerating
    private let runtimeAvailability: @Sendable (Locale) async -> AIAvailability

    init(
        classifier: IntentClassifier = IntentClassifier(),
        localSearch: LocalSearchService = LocalSearchService(),
        redactor: PrivacyRedactor = PrivacyRedactor(),
        modelFactory: @escaping @Sendable (Bool) -> any AIAdviceGenerating = { _ in
            FoundationModelsAdviceGenerator()
        },
        runtimeAvailability: @escaping @Sendable (Locale) async -> AIAvailability = { locale in
            await FoundationModelsAdviceGenerator.runtimeAvailability(locale: locale)
        }
    ) {
        self.classifier = classifier
        self.localSearch = localSearch
        self.redactor = redactor
        self.modelFactory = modelFactory
        self.runtimeAvailability = runtimeAvailability
    }

    func answer(_ request: AskMindBudgetRequest) async -> AskMindBudgetResponse {
        // The raw question remains a local, ephemeral classifier input and is never
        // included in an aggregate context or sent to a language model.
        let intent = classifier.classify(request.question, locale: request.locale)
        let localResults = localSearch.retrieve(
            intent: intent,
            snapshot: request.snapshot,
            expenses: request.expenses,
            wishItems: request.wishItems,
            calendar: request.calendar
        )
        let input = aggregateInput(
            intent: intent,
            request: request,
            localResults: localResults
        )
        let context = redactor.redactAsk(input)
        let capability = AIEnhancementCapability(
            userEnabled: request.premiumEntryAccess.enablesAppleOnDeviceAI(
                userEnabled: request.enhancementEnabled
            ),
            targetLocale: request.locale,
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
        request: AskMindBudgetRequest,
        localResults: LocalSearchResult
    ) -> AskAggregateInput {
        let currentExpenses = localResults.expenses.filter {
            request.snapshot.cycle.start <= $0.spentAt
                && $0.spentAt < request.snapshot.cycle.end
        }
        let facts: AskAggregateFacts
        var insights: [SpendingInsightType] = []
        var actions: [SuggestedAction] = [.reviewRecentSpending, .adjustBudget]

        switch intent {
        case .canIAfford:
            guard let amount = request.purchaseAmount,
                  let category = request.purchaseCategory,
                  let bucket = request.purchaseBucket else {
                facts = .affordabilityNeedsDetails
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
            facts = .affordability(
                candidateAmount: amount,
                availableRightNow: request.snapshot.availableRightNow,
                isAffordable: affordable
            )
            actions = affordable
                ? [.reviewRecentSpending, .continuePurchase]
                : [.addToWishlist, .adjustBudget, .continuePurchase]
        case .remainingBudget:
            facts = .remainingBudget(
                remainingFree: request.snapshot.remainingFree,
                safeDailySpend: request.snapshot.safeDailySpend,
                daysRemaining: request.snapshot.daysRemaining
            )
        case .stressPattern:
            let count = currentExpenses.filter {
                $0.emotionTag == .stressed || $0.emotionTag == .anxious
                    || $0.purchaseReason == .stressRelief
            }.count
            facts = .stressPattern(count: count)
            insights = count == 0 ? [] : [.repeatedStressSpending]
        case .impulsePattern:
            let count = currentExpenses.filter {
                $0.emotionTag == .impulse || $0.purchaseReason == .impulse
            }.count
            facts = .impulsePattern(count: count)
            insights = count == 0 ? [] : [.impulseCluster]
            actions = [.reviewRecentSpending, .startCoolingOff24h]
        case .categoryChange:
            let change = leadingCategoryChange(
                request: request,
                expenses: localResults.expenses
            )
            if let change {
                facts = .categoryChange(
                    category: change.category,
                    current: change.current,
                    previous: change.previous
                )
            } else {
                facts = .noCategoryChange
            }
        case .alternative:
            facts = .alternative
            actions = [.addToWishlist, .startCoolingOff24h, .waitUntilNextCycle]
        case .wishlistStatus:
            let cooling = localResults.wishItems.filter {
                $0.status == .coolingOff || $0.status == .readyToReview
            }.count
            let active = localResults.wishItems.filter { $0.status == .active }.count
            facts = .wishlistStatus(coolingCount: cooling, activeCount: active)
            actions = [.reviewRecentSpending, .addToWishlist]
        case .outOfScope:
            facts = .outOfScope
            actions = [.reviewRecentSpending, .adjustBudget]
        case .unknown:
            facts = .unknown
            actions = [.reviewRecentSpending, .addToWishlist]
        }

        return AskAggregateInput(
            locale: request.locale,
            currencyCode: request.snapshot.currencyCode,
            facts: facts,
            budgetBreakdown: intent == .remainingBudget
                ? AskBudgetBreakdown(
                    remainingTotal: request.snapshot.remainingTotal,
                    availableRightNow: request.snapshot.availableRightNow,
                    pendingFixed: request.snapshot.pendingFixed,
                    pendingSaving: request.snapshot.pendingSaving
                )
                : nil,
            relevantInsights: insights,
            allowedActions: actions,
            tone: request.tone
        )
    }

    private func leadingCategoryChange(
        request: AskMindBudgetRequest,
        expenses: [ExpenseSummary]
    ) -> (category: ExpenseCategory, current: Money, previous: Money)? {
        guard let previousStart = request.calendar.date(
            byAdding: .month,
            value: -1,
            to: request.snapshot.cycle.start
        ) else { return nil }
        let previousEnd = request.snapshot.cycle.start
        var current: [ExpenseCategory: Int64] = [:]
        var previous: [ExpenseCategory: Int64] = [:]
        for expense in expenses {
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
        let body = context.templateBody(locale: locale)
        let title = LocalizedCatalog.string(
            "ask.answer.\(intent.rawValue).title",
            locale: locale
        )
        return GeneratedAnswer(
            title: title,
            body: body,
            actionIdentifiers: context.allowedActionIdentifiers
        )
    }
}
