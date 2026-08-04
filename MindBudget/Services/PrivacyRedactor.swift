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

struct RedactedSummaryContext: Codable, Equatable, Sendable {
    let localeIdentifier: String
    let cycleLabel: String
    let topCategoryKeys: [String]
    let categoryChangeDirections: [String: String]
    let totalUsedPercent: Int
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
            "coolingOffPurchasedCount": String(coolingOffPurchasedCount),
            "totalUsedPercent": String(totalUsedPercent)
        ]) { first, _ in first }
        return PromptDataEncoder.lines(
            scalars: [
                "locale": localeIdentifier,
                "cycleLabel": cycleLabel,
                "tone": tonePreference
            ],
            facts: categoryChangeDirections.merging(counts) { first, _ in first },
            insightKeys: topCategoryKeys,
            actions: allowedActionIdentifiers
        )
    }
}

struct RedactedAskContext: Codable, Equatable, Sendable {
    let localeIdentifier: String
    let currencyCode: String
    let questionIntentKey: AskIntentKey
    let budgetFactsFormatted: [String: String]
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
            facts: budgetFactsFormatted,
            insightKeys: relevantInsightKeys,
            actions: allowedActionIdentifiers
        )
    }
}

/// Allow-listed inputs are intentionally aggregate-only. Detail projections, notes,
/// raw transaction rows, timestamps, and merchant lists cannot be supplied here.
struct AskAggregateInput: Equatable, Sendable {
    let localeIdentifier: String
    let currencyCode: String
    let intent: AskIntentKey
    let budgetFactsFormatted: [String: String]
    let relevantInsightKeys: [String]
    let allowedActions: [SuggestedAction]
    let tone: ReminderTone
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
    let totalUsedPercent: Int
    let emotionCounts: [EmotionTag: Int]
    let coolingOffSkippedCount: Int
    let coolingOffPurchasedCount: Int
    let tone: ReminderTone
}

struct PrivacyRedactor: Sendable {
    func redactAsk(_ input: AskAggregateInput) -> RedactedAskContext {
        RedactedAskContext(
            localeIdentifier: input.localeIdentifier,
            currencyCode: input.currencyCode,
            questionIntentKey: input.intent,
            budgetFactsFormatted: input.budgetFactsFormatted,
            relevantInsightKeys: input.relevantInsightKeys,
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
            totalUsedPercent: input.totalUsedPercent,
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
            in: context.budgetFactsFormatted.values,
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
            in: [context.cycleLabel, String(context.totalUsedPercent)]
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
