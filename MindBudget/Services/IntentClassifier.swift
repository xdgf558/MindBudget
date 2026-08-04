import Foundation

struct IntentClassifier: Sendable {
    func classify(_ question: String, locale: Locale = .current) -> AskIntentKey {
        let normalized = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return .unknown }
        if containsAny(normalized, keywords: Self.outOfScopeKeywords, locale: locale) {
            return .outOfScope
        }
        for intent in Self.precedence {
            if containsAny(
                normalized,
                keywords: Self.keywords[intent] ?? [],
                locale: locale
            ) {
                return intent
            }
        }
        return .unknown
    }

    private func containsAny(_ text: String, keywords: [String], locale: Locale) -> Bool {
        let foldedText = text.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: locale
        )
        return keywords.contains {
            foldedText.contains(
                $0.folding(
                    options: [.caseInsensitive, .diacriticInsensitive],
                    locale: locale
                )
            )
        }
    }

    private static let precedence: [AskIntentKey] = [
        .canIAfford,
        .remainingBudget,
        .stressPattern,
        .impulsePattern,
        .categoryChange,
        .alternative,
        .wishlistStatus
    ]

    private static let keywords: [AskIntentKey: [String]] = [
        .canIAfford: ["还能买", "买得起", "够不够", "can i afford", "can i buy"],
        .stressPattern: ["压力", "心情", "情绪", "stress", "mood"],
        .impulsePattern: ["冲动", "剁手", "impulse"],
        .categoryChange: ["涨", "多花", "哪类", "which category", "increased"],
        .remainingBudget: ["还剩", "剩多少", "remaining", "left"],
        .alternative: ["替代", "便宜", "不花钱", "alternative", "cheaper"],
        .wishlistStatus: ["愿望清单", "冷静期", "wishlist", "cooling"]
    ]

    private static let outOfScopeKeywords = [
        "股票", "基金", "投资", "税", "贷款", "法律", "诊断", "抑郁",
        "stock", "fund", "invest", "tax", "loan", "legal", "diagnose", "depression"
    ]
}
