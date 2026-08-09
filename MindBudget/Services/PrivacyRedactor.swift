import Foundation

struct RedactedAdviceContext: Codable, Equatable, Sendable {
    let localeIdentifier: String
    let currencyCode: String
    let purchaseAmountFormatted: String
    let purchaseCategoryKey: String
    let remainingFreeAfterFormatted: String
    let freeBudgetImpactPercent: Int?
    let daysOfBudgetConsumed: Int?
    let categoryBudgetUsedPercent: Int?
    let recentStressPurchaseCount7d: Int
    let recentImpulsePurchaseCount72h: Int
    let tonePreference: String
    let allowedActionIdentifiers: [String]
    let maxTitleLength: Int
    let maxBodyLength: Int

    var promptData: String {
        PromptDataEncoder.lines(
            scalars: [
                "locale": localeIdentifier,
                "currency": currencyCode,
                "category": purchaseCategoryKey,
                "amount": purchaseAmountFormatted,
                "remainingFreeAfter": remainingFreeAfterFormatted,
                "tone": tonePreference
            ],
            facts: [
                "freeBudgetImpactPercent": freeBudgetImpactPercent.map(String.init) ?? "none",
                "daysOfBudgetConsumed": daysOfBudgetConsumed.map(String.init) ?? "none",
                "categoryBudgetUsedPercent": categoryBudgetUsedPercent.map(String.init) ?? "none",
                "recentStressPurchaseCount7d": String(recentStressPurchaseCount7d),
                "recentImpulsePurchaseCount72h": String(recentImpulsePurchaseCount72h),
                "maxTitleLength": String(maxTitleLength),
                "maxBodyLength": String(maxBodyLength)
            ],
            insightKeys: [],
            actions: allowedActionIdentifiers
        )
    }
}

enum SummaryBudgetUsage: Codable, Equatable, Sendable {
    case unavailable
    case lessThanOnePercent
    case percent(Int)

    fileprivate var promptState: String {
        switch self {
        case .unavailable: "unavailable"
        case .lessThanOnePercent: "lessThanOnePercent"
        case .percent: "percent"
        }
    }

    fileprivate var promptFacts: [String: String] {
        switch self {
        case .unavailable:
            [:]
        case .lessThanOnePercent:
            ["totalUsedPercentUpperBound": "1"]
        case let .percent(value):
            ["totalUsedPercent": String(value)]
        }
    }

    fileprivate var numericValues: [String] {
        Array(promptFacts.values)
    }
}

struct RedactedSummaryContext: Codable, Equatable, Sendable {
    let localeIdentifier: String
    let cycleLabel: String
    let topCategoryKeys: [String]
    let categoryChangeDirections: [String: String]
    let budgetUsage: SummaryBudgetUsage
    let emotionTagCounts: [String: Int]
    let coolingOffSkippedCount: Int
    let coolingOffPurchasedCount: Int
    let tonePreference: String

    var allowedActionIdentifiers: [String] {
        [
            SuggestedAction.reviewRecentSpending.rawValue,
            SuggestedAction.adjustBudget.rawValue
        ]
    }

    var promptData: String {
        let counts = emotionTagCounts.mapValues(String.init).merging([
            "coolingOffSkippedCount": String(coolingOffSkippedCount),
            "coolingOffPurchasedCount": String(coolingOffPurchasedCount)
        ]) { first, _ in first }
        return PromptDataEncoder.lines(
            scalars: [
                "locale": localeIdentifier,
                "cycleLabel": cycleLabel,
                "budgetUsageState": budgetUsage.promptState,
                "tone": tonePreference
            ],
            facts: categoryChangeDirections
                .merging(counts) { first, _ in first }
                .merging(budgetUsage.promptFacts) { first, _ in first },
            insightKeys: topCategoryKeys,
            actions: allowedActionIdentifiers
        )
    }
}

enum AskAggregateFacts: Equatable, Sendable {
    case affordabilityNeedsDetails
    case affordability(candidateAmount: Money, availableRightNow: Money, isAffordable: Bool)
    case remainingBudget(remainingFree: Money, safeDailySpend: Money, daysRemaining: Int)
    case stressPattern(count: Int)
    case impulsePattern(count: Int)
    case categoryChange(category: ExpenseCategory, current: Money, previous: Money)
    case noCategoryChange
    case alternative
    case wishlistStatus(coolingCount: Int, activeCount: Int)
    case outOfScope
    case unknown

    var intent: AskIntentKey {
        switch self {
        case .affordabilityNeedsDetails, .affordability: .canIAfford
        case .remainingBudget: .remainingBudget
        case .stressPattern: .stressPattern
        case .impulsePattern: .impulsePattern
        case .categoryChange, .noCategoryChange: .categoryChange
        case .alternative: .alternative
        case .wishlistStatus: .wishlistStatus
        case .outOfScope: .outOfScope
        case .unknown: .unknown
        }
    }
}

struct AskBudgetBreakdown: Equatable, Sendable {
    let remainingTotal: Money
    let availableRightNow: Money
    let pendingFixed: Money
    let pendingSaving: Money
}

fileprivate enum RedactedAskFacts: Codable, Equatable, Sendable {
    case affordabilityNeedsDetails
    case affordability(
        candidateAmountFormatted: String,
        availableRightNowFormatted: String,
        isAffordable: Bool
    )
    case remainingBudget(
        remainingFreeFormatted: String,
        safeDailySpendFormatted: String,
        daysRemaining: Int
    )
    case remainingBudgetBreakdown(
        remainingTotalFormatted: String,
        availableRightNowFormatted: String,
        availableOverageFormatted: String?,
        pendingFixedFormatted: String,
        pendingSavingFormatted: String,
        safeDailySpendFormatted: String,
        daysRemaining: Int
    )
    case stressPattern(count: Int)
    case impulsePattern(count: Int)
    case categoryChange(
        category: ExpenseCategory,
        currentFormatted: String,
        previousFormatted: String
    )
    case noCategoryChange
    case alternative
    case wishlistStatus(coolingCount: Int, activeCount: Int)
    case outOfScope
    case unknown

    var promptFacts: [String: String] {
        switch self {
        case .affordabilityNeedsDetails:
            ["requiresDetails": "true"]
        case let .affordability(candidate, available, isAffordable):
            [
                "candidateAmount": candidate,
                "availableRightNow": available,
                "affordability": isAffordable ? "within" : "outside"
            ]
        case let .remainingBudget(remaining, daily, days):
            [
                "remainingFree": remaining,
                "safeDailySpend": daily,
                "daysRemaining": String(days)
            ]
        case let .remainingBudgetBreakdown(
            total,
            available,
            overage,
            pendingFixed,
            pendingSaving,
            daily,
            days
        ):
            [
                "remainingTotal": total,
                "availableRightNow": available,
                "availableOverage": overage ?? "none",
                "pendingFixed": pendingFixed,
                "pendingSaving": pendingSaving,
                "safeDailySpend": daily,
                "daysRemaining": String(days)
            ]
        case let .stressPattern(count), let .impulsePattern(count):
            ["count": String(count)]
        case let .categoryChange(category, current, previous):
            [
                "categoryKey": category.localizedNameKey,
                "current": current,
                "previous": previous
            ]
        case .noCategoryChange:
            ["hasCategoryChange": "false"]
        case .alternative, .outOfScope, .unknown:
            [:]
        case let .wishlistStatus(coolingCount, activeCount):
            [
                "coolingCount": String(coolingCount),
                "activeCount": String(activeCount)
            ]
        }
    }

    var numericValues: [String] {
        switch self {
        case .affordabilityNeedsDetails, .noCategoryChange, .alternative, .outOfScope, .unknown:
            []
        case let .affordability(candidate, available, _):
            [candidate, available]
        case let .remainingBudget(remaining, daily, days):
            [remaining, daily, String(days)]
        case let .remainingBudgetBreakdown(
            total,
            available,
            overage,
            pendingFixed,
            pendingSaving,
            daily,
            days
        ):
            [total, available, pendingFixed, pendingSaving, daily, String(days)]
                + (overage.map { [$0] } ?? [])
        case let .stressPattern(count), let .impulsePattern(count):
            [String(count)]
        case let .categoryChange(_, current, previous):
            [current, previous]
        case let .wishlistStatus(coolingCount, activeCount):
            [String(coolingCount), String(activeCount)]
        }
    }

    var requiresPurchaseDetails: Bool {
        if case .affordabilityNeedsDetails = self { return true }
        return false
    }

    func templateBody(locale: Locale) -> String {
        switch self {
        case .affordabilityNeedsDetails:
            LocalizedCatalog.string("ask.answer.canIAfford.clarify", locale: locale)
        case let .affordability(candidate, available, isAffordable):
            LocalizedCatalog.format(
                isAffordable ? "ask.answer.canIAfford.within" : "ask.answer.canIAfford.outside",
                locale: locale,
                candidate,
                available
            )
        case let .remainingBudget(remaining, daily, days):
            LocalizedCatalog.format(
                "ask.answer.remainingBudget.body",
                locale: locale,
                remaining,
                daily,
                days
            )
        case let .remainingBudgetBreakdown(
            total,
            available,
            overage,
            pendingFixed,
            pendingSaving,
            daily,
            days
        ):
            if let overage {
                LocalizedCatalog.format(
                    "ask.answer.remainingBudget.breakdown.over",
                    locale: locale,
                    total,
                    pendingFixed,
                    pendingSaving,
                    overage,
                    daily,
                    days
                )
            } else {
                LocalizedCatalog.format(
                    "ask.answer.remainingBudget.breakdown",
                    locale: locale,
                    total,
                    pendingFixed,
                    pendingSaving,
                    available,
                    daily,
                    days
                )
            }
        case let .stressPattern(count):
            LocalizedCatalog.format(
                count == 0 ? "ask.answer.stress.none" : "ask.answer.stress.body",
                locale: locale,
                count
            )
        case let .impulsePattern(count):
            LocalizedCatalog.format(
                count == 0 ? "ask.answer.impulse.none" : "ask.answer.impulse.body",
                locale: locale,
                count
            )
        case let .categoryChange(category, current, previous):
            LocalizedCatalog.format(
                "ask.answer.categoryChange.body",
                locale: locale,
                LocalizedCatalog.string(category.localizedNameKey, locale: locale),
                current,
                previous
            )
        case .noCategoryChange:
            LocalizedCatalog.string("ask.answer.categoryChange.none", locale: locale)
        case .alternative:
            LocalizedCatalog.string("ask.answer.alternative.body", locale: locale)
        case let .wishlistStatus(coolingCount, activeCount):
            LocalizedCatalog.format(
                "ask.answer.wishlistStatus.body",
                locale: locale,
                coolingCount,
                activeCount
            )
        case .outOfScope:
            LocalizedCatalog.string("ask.answer.outOfScope.body", locale: locale)
        case .unknown:
            LocalizedCatalog.string("ask.answer.unknown.body", locale: locale)
        }
    }
}

struct RedactedAskContext: Codable, Equatable, Sendable {
    let localeIdentifier: String
    let currencyCode: String
    let questionIntentKey: AskIntentKey
    fileprivate let facts: RedactedAskFacts
    let relevantInsightKeys: [String]
    let allowedActionIdentifiers: [String]
    let tonePreference: String

    var promptData: String {
        PromptDataEncoder.lines(
            scalars: [
                "locale": localeIdentifier,
                "currency": currencyCode,
                "intent": questionIntentKey.rawValue,
                "tone": tonePreference
            ],
            facts: facts.promptFacts,
            insightKeys: relevantInsightKeys,
            actions: allowedActionIdentifiers
        )
    }

    var requiresPurchaseDetails: Bool {
        facts.requiresPurchaseDetails
    }

    func templateBody(locale: Locale) -> String {
        facts.templateBody(locale: locale)
    }
}

/// Allow-listed inputs are intentionally aggregate-only. Detail projections, notes,
/// raw transaction rows, timestamps, merchant lists, and arbitrary fact strings cannot
/// be supplied here.
struct AskAggregateInput: Equatable, Sendable {
    let locale: Locale
    let currencyCode: String
    let facts: AskAggregateFacts
    let budgetBreakdown: AskBudgetBreakdown?
    let relevantInsights: [SpendingInsightType]
    let allowedActions: [SuggestedAction]
    let tone: ReminderTone

    init(
        locale: Locale,
        currencyCode: String,
        facts: AskAggregateFacts,
        budgetBreakdown: AskBudgetBreakdown? = nil,
        relevantInsights: [SpendingInsightType],
        allowedActions: [SuggestedAction],
        tone: ReminderTone
    ) {
        self.locale = locale
        self.currencyCode = currencyCode
        self.facts = facts
        self.budgetBreakdown = budgetBreakdown
        self.relevantInsights = relevantInsights
        self.allowedActions = allowedActions
        self.tone = tone
    }
}

struct AdviceAggregateInput: Equatable, Sendable {
    let localeIdentifier: String
    let currencyCode: String
    let purchaseCategory: ExpenseCategory
    let purchaseAmountFormatted: String
    let remainingFreeAfterFormatted: String
    let freeBudgetImpactPercent: Int?
    let daysOfBudgetConsumed: Int?
    let categoryBudgetUsedPercent: Int?
    let recentStressPurchaseCount7d: Int
    let recentImpulsePurchaseCount72h: Int
    let allowedActions: [SuggestedAction]
    let tone: ReminderTone
    let maxTitleLength: Int
    let maxBodyLength: Int
}

struct SummaryAggregateInput: Equatable, Sendable {
    let localeIdentifier: String
    let cycleLabel: String
    let topCategories: [ExpenseCategory]
    let categoryChangeDirections: [ExpenseCategory: String]
    let budgetUsage: SummaryBudgetUsage
    let emotionCounts: [EmotionTag: Int]
    let coolingOffSkippedCount: Int
    let coolingOffPurchasedCount: Int
    let tone: ReminderTone
}

struct PrivacyRedactor: Sendable {
    func redactAsk(_ input: AskAggregateInput) -> RedactedAskContext {
        precondition(Money.isSupported(input.currencyCode), "Unsupported accounting currency")
        let formatter = CurrencyFormatterService()
        func formatted(_ money: Money) -> String {
            precondition(
                money.currencyCode == input.currencyCode,
                "Ask fact currency must match the accounting currency"
            )
            return formatter.string(from: money, locale: input.locale)
        }
        func remainingBudgetFacts(
            remaining: Money,
            daily: Money,
            days: Int
        ) -> RedactedAskFacts {
            guard let breakdown = input.budgetBreakdown else {
                return .remainingBudget(
                    remainingFreeFormatted: formatted(remaining),
                    safeDailySpendFormatted: formatted(daily),
                    daysRemaining: days
                )
            }
            let availableMinorUnits = breakdown.availableRightNow.minorUnits
            let overage: Money? = availableMinorUnits < 0 && availableMinorUnits != Int64.min
                ? Money(
                    minorUnits: -availableMinorUnits,
                    currencyCode: breakdown.availableRightNow.currencyCode
                )
                : nil
            return .remainingBudgetBreakdown(
                remainingTotalFormatted: formatted(breakdown.remainingTotal),
                availableRightNowFormatted: formatted(breakdown.availableRightNow),
                availableOverageFormatted: overage.map(formatted),
                pendingFixedFormatted: formatted(breakdown.pendingFixed),
                pendingSavingFormatted: formatted(breakdown.pendingSaving),
                safeDailySpendFormatted: formatted(daily),
                daysRemaining: days
            )
        }
        let facts: RedactedAskFacts = switch input.facts {
        case .affordabilityNeedsDetails:
            .affordabilityNeedsDetails
        case let .affordability(candidate, available, isAffordable):
            .affordability(
                candidateAmountFormatted: formatted(candidate),
                availableRightNowFormatted: formatted(available),
                isAffordable: isAffordable
            )
        case let .remainingBudget(remaining, daily, days):
            remainingBudgetFacts(remaining: remaining, daily: daily, days: days)
        case let .stressPattern(count):
            .stressPattern(count: count)
        case let .impulsePattern(count):
            .impulsePattern(count: count)
        case let .categoryChange(category, current, previous):
            .categoryChange(
                category: category,
                currentFormatted: formatted(current),
                previousFormatted: formatted(previous)
            )
        case .noCategoryChange:
            .noCategoryChange
        case .alternative:
            .alternative
        case let .wishlistStatus(coolingCount, activeCount):
            .wishlistStatus(coolingCount: coolingCount, activeCount: activeCount)
        case .outOfScope:
            .outOfScope
        case .unknown:
            .unknown
        }
        return RedactedAskContext(
            localeIdentifier: input.locale.identifier,
            currencyCode: input.currencyCode,
            questionIntentKey: input.facts.intent,
            facts: facts,
            relevantInsightKeys: unique(input.relevantInsights.map(\.rawValue)),
            allowedActionIdentifiers: unique(input.allowedActions.map(\.rawValue)),
            tonePreference: input.tone.rawValue
        )
    }

    func redactAdvice(_ input: AdviceAggregateInput) -> RedactedAdviceContext {
        RedactedAdviceContext(
            localeIdentifier: input.localeIdentifier,
            currencyCode: input.currencyCode,
            purchaseAmountFormatted: input.purchaseAmountFormatted,
            purchaseCategoryKey: input.purchaseCategory.localizedNameKey,
            remainingFreeAfterFormatted: input.remainingFreeAfterFormatted,
            freeBudgetImpactPercent: input.freeBudgetImpactPercent,
            daysOfBudgetConsumed: input.daysOfBudgetConsumed,
            categoryBudgetUsedPercent: input.categoryBudgetUsedPercent,
            recentStressPurchaseCount7d: input.recentStressPurchaseCount7d,
            recentImpulsePurchaseCount72h: input.recentImpulsePurchaseCount72h,
            tonePreference: input.tone.rawValue,
            allowedActionIdentifiers: unique(input.allowedActions.map(\.rawValue)),
            maxTitleLength: input.maxTitleLength,
            maxBodyLength: input.maxBodyLength
        )
    }

    func redactSummary(_ input: SummaryAggregateInput) -> RedactedSummaryContext {
        RedactedSummaryContext(
            localeIdentifier: input.localeIdentifier,
            cycleLabel: input.cycleLabel,
            topCategoryKeys: input.topCategories.map(\.localizedNameKey),
            categoryChangeDirections: Dictionary(
                uniqueKeysWithValues: input.categoryChangeDirections.map {
                    ($0.key.localizedNameKey, $0.value)
                }
            ),
            budgetUsage: input.budgetUsage,
            emotionTagCounts: Dictionary(uniqueKeysWithValues: input.emotionCounts.map {
                ($0.key.rawValue, $0.value)
            }),
            coolingOffSkippedCount: input.coolingOffSkippedCount,
            coolingOffPurchasedCount: input.coolingOffPurchasedCount,
            tonePreference: input.tone.rawValue
        )
    }

    private func unique(_ values: [String]) -> [String] {
        values.reduce(into: []) { result, value in
            if !result.contains(value) { result.append(value) }
        }
    }
}

struct AllowedNumericTokens: Equatable, Sendable {
    let values: Set<String>
    private let localeIdentifier: String

    init(context: RedactedAskContext) {
        localeIdentifier = context.localeIdentifier
        values = Self.tokens(
            in: context.facts.numericValues,
            localeIdentifier: context.localeIdentifier
        )
    }

    init(context: RedactedAdviceContext) {
        localeIdentifier = context.localeIdentifier
        let formatted = [context.purchaseAmountFormatted, context.remainingFreeAfterFormatted]
        let integerValues = [
            context.freeBudgetImpactPercent,
            context.daysOfBudgetConsumed,
            context.categoryBudgetUsedPercent
        ].compactMap { $0 }.map(String.init) + [
            String(context.recentStressPurchaseCount7d),
            String(context.recentImpulsePurchaseCount72h)
        ]
        values = Self.tokens(
            in: formatted + integerValues,
            localeIdentifier: context.localeIdentifier
        )
    }

    init(context: RedactedSummaryContext) {
        localeIdentifier = context.localeIdentifier
        values = Self.tokens(
            in: [context.cycleLabel]
                + context.budgetUsage.numericValues
                + context.emotionTagCounts.values.map(String.init)
                + [
                    String(context.coolingOffSkippedCount),
                    String(context.coolingOffPurchasedCount)
                ],
            localeIdentifier: context.localeIdentifier
        )
    }

    func containsEveryNumber(in strings: [String]) -> Bool {
        Self.tokens(
            in: strings,
            localeIdentifier: localeIdentifier
        ).isSubset(of: values)
    }

    private static func tokens<S: Sequence>(
        in strings: S,
        localeIdentifier: String?
    ) -> Set<String> where S.Element == String {
        strings.reduce(into: Set<String>()) { result, string in
            result.formUnion(tokens(in: string, localeIdentifier: localeIdentifier))
        }
    }

    private static func tokens(
        in string: String,
        localeIdentifier: String?
    ) -> Set<String> {
        var result = Set<String>()
        var token = ""
        var pendingNegative = false
        func finish() {
            defer { token = "" }
            guard let normalized = canonical(
                token,
                localeIdentifier: localeIdentifier
            ) else { return }
            result.insert(normalized)
        }
        for character in string {
            if let value = character.wholeNumberValue, (0...9).contains(value) {
                if token.isEmpty, pendingNegative { token = "-" }
                token.append(String(value))
            } else if isNumericSeparator(character), !token.isEmpty {
                token.append(character)
            } else {
                if !token.isEmpty {
                    finish()
                    pendingNegative = false
                }
                if character == "-" || character == "\u{2212}" {
                    pendingNegative = true
                } else if character.isWhitespace {
                    pendingNegative = false
                }
            }
        }
        finish()
        return result
    }

    private static func canonical(
        _ token: String,
        localeIdentifier: String?
    ) -> String? {
        var value = token.trimmingCharacters(in: numericSeparators)
        guard value.contains(where: { $0.isNumber }) else { return nil }
        let isNegative = value.first == "-"
        if isNegative { value.removeFirst() }

        let locale = localeIdentifier.map(Locale.init(identifier:)) ?? Locale(identifier: "en_US_POSIX")
        let decimal = locale.decimalSeparator?.first ?? "."
        let grouping = locale.groupingSeparator?.first ?? ","
        if grouping != decimal {
            value.removeAll { $0 == grouping || $0 == " " || $0 == "\u{00A0}" || $0 == "\u{202F}" }
        }
        if decimal != "." {
            value = value.replacingOccurrences(of: String(decimal), with: ".")
        }
        guard value.filter({ $0 == "." }).count <= 1 else { return nil }
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard let integerPart = parts.first else { return nil }
        let integer = String(integerPart.drop(while: { $0 == "0" }))
        let normalizedInteger = integer.isEmpty ? "0" : integer
        guard parts.count == 2 else {
            return isNegative && normalizedInteger != "0"
                ? "-\(normalizedInteger)"
                : normalizedInteger
        }
        let fraction = String(parts[1])
        let canonical = fraction.isEmpty
            ? normalizedInteger
            : "\(normalizedInteger).\(fraction)"
        return isNegative && canonical != "0" ? "-\(canonical)" : canonical
    }

    private static func isNumericSeparator(_ character: Character) -> Bool {
        character == "." || character == "," || character == " "
            || character == "\u{00A0}" || character == "\u{202F}"
    }

    private static let numericSeparators = CharacterSet(
        charactersIn: "., \u{00A0}\u{202F}"
    )
}

private enum PromptDataEncoder {
    static func lines(
        scalars: [String: String],
        facts: [String: String],
        insightKeys: [String],
        actions: [String]
    ) -> String {
        let scalarLines = scalars.keys.sorted().map { "\($0)=\(sanitize(scalars[$0] ?? ""))" }
        let factLines = facts.keys.sorted().map { "fact.\($0)=\(sanitize(facts[$0] ?? ""))" }
        return (scalarLines + factLines + [
            "insights=\(insightKeys.map(sanitize).joined(separator: ","))",
            "allowedActions=\(actions.map(sanitize).joined(separator: ","))"
        ]).joined(separator: "\n")
    }

    private static func sanitize(_ value: String) -> String {
        String(value.unicodeScalars
            .filter { !CharacterSet.controlCharacters.contains($0) }
            .prefix(120))
    }
}
