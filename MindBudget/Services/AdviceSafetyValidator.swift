import Foundation

enum AdviceSafetyViolation: Error, Equatable, Sendable {
    case titleTooLong
    case bodyTooLong
    case bannedPhrase
    case noActionableOption
    case invalidActionCount
    case missingContinuePurchase
    case unknownAction
    case diagnosis
    case financialAdvice
    case imperativeProhibition
    case fabricatedNumber
    case emptyField
    case unexpectedLanguage
}

struct AdviceSafetyValidator: Sendable {
    private let shamePhrases: [String]
    private let diagnosisPhrases: [String]
    private let financialAdvicePhrases: [String]
    private let prohibitionPhrases: [String]

    init(
        shamePhrases: [String] = BannedPhraseCatalog.shame,
        diagnosisPhrases: [String] = BannedPhraseCatalog.diagnosis,
        financialAdvicePhrases: [String] = BannedPhraseCatalog.financialAdvice,
        prohibitionPhrases: [String] = BannedPhraseCatalog.prohibition
    ) {
        self.shamePhrases = shamePhrases
        self.diagnosisPhrases = diagnosisPhrases
        self.financialAdvicePhrases = financialAdvicePhrases
        self.prohibitionPhrases = prohibitionPhrases
    }

    func validate(answer: GeneratedAnswer, context: RedactedAskContext) throws {
        try validateText(title: answer.title, body: answer.body)
        try validateLanguage(
            title: answer.title,
            body: answer.body,
            localeIdentifier: context.localeIdentifier
        )
        let isPurchaseDecision = context.questionIntentKey == .canIAfford
            && !context.requiresPurchaseDetails
        try validateActions(
            answer.actionIdentifiers,
            allowed: context.allowedActionIdentifiers,
            minimumCount: isPurchaseDecision ? 2 : 0,
            maximumCount: 4,
            requiresContinuePurchase: isPurchaseDecision
        )
        guard AllowedNumericTokens(context: context).containsEveryNumber(
            in: [answer.title, answer.body]
        ) else {
            throw AdviceSafetyViolation.fabricatedNumber
        }
    }

    func validate(advice: GeneratedAdvice, context: RedactedAdviceContext) throws {
        try validateText(title: advice.title, body: advice.body)
        try validateLanguage(
            title: advice.title,
            body: advice.body,
            localeIdentifier: context.localeIdentifier
        )
        guard advice.title.count <= context.maxTitleLength else {
            throw AdviceSafetyViolation.titleTooLong
        }
        guard advice.body.count <= context.maxBodyLength else {
            throw AdviceSafetyViolation.bodyTooLong
        }
        try validateActions(
            advice.actionIdentifiers,
            allowed: context.allowedActionIdentifiers,
            minimumCount: 2,
            maximumCount: 4,
            requiresContinuePurchase: true
        )
        guard AllowedNumericTokens(context: context).containsEveryNumber(
            in: [advice.title, advice.body]
        ) else {
            throw AdviceSafetyViolation.fabricatedNumber
        }
    }

    func validate(summary: GeneratedSummary, context: RedactedSummaryContext) throws {
        try validateText(title: summary.title, body: summary.body)
        try validateLanguage(
            title: summary.title,
            body: summary.body,
            localeIdentifier: context.localeIdentifier
        )
        try validateActions(
            summary.actionIdentifiers,
            allowed: context.allowedActionIdentifiers,
            minimumCount: 0,
            maximumCount: 3,
            requiresContinuePurchase: false
        )
        guard AllowedNumericTokens(context: context).containsEveryNumber(
            in: [summary.title, summary.body]
        ) else {
            throw AdviceSafetyViolation.fabricatedNumber
        }
    }

    private func validateText(title: String, body: String) throws {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !body.isEmpty else { throw AdviceSafetyViolation.emptyField }
        guard title.count <= 24 else { throw AdviceSafetyViolation.titleTooLong }
        guard body.count <= 120 else { throw AdviceSafetyViolation.bodyTooLong }
        let combined = "\(title) \(body)"
        if containsAny(shamePhrases, in: combined) {
            throw AdviceSafetyViolation.bannedPhrase
        }
        if containsAny(diagnosisPhrases, in: combined) {
            throw AdviceSafetyViolation.diagnosis
        }
        if containsAny(financialAdvicePhrases, in: combined) {
            throw AdviceSafetyViolation.financialAdvice
        }
        if containsAny(prohibitionPhrases, in: combined) {
            throw AdviceSafetyViolation.imperativeProhibition
        }
    }

    private func validateActions(
        _ actions: [String],
        allowed: [String],
        minimumCount: Int,
        maximumCount: Int,
        requiresContinuePurchase: Bool
    ) throws {
        if minimumCount > 0, actions.isEmpty {
            throw AdviceSafetyViolation.noActionableOption
        }
        guard (minimumCount...maximumCount).contains(actions.count),
              Set(actions).count == actions.count else {
            throw AdviceSafetyViolation.invalidActionCount
        }
        guard actions.allSatisfy(allowed.contains) else {
            throw AdviceSafetyViolation.unknownAction
        }
        if requiresContinuePurchase,
           !actions.contains(SuggestedAction.continuePurchase.rawValue) {
            throw AdviceSafetyViolation.missingContinuePurchase
        }
    }

    /// The model is a wording layer, so returning copy in a different app language is an
    /// invalid proposal rather than a reason to expose mixed-language UI. Only the two shipped
    /// interface languages are checked; an unsupported locale continues through the existing
    /// capability/fallback path without inventing a language classification rule.
    private func validateLanguage(
        title: String,
        body: String,
        localeIdentifier: String
    ) throws {
        let locale = localeIdentifier.lowercased()
        let scalars = "\(title) \(body)".unicodeScalars
        let hanCount = scalars.count(where: Self.isHan)

        if locale.hasPrefix("zh") {
            guard hanCount >= 2 else {
                throw AdviceSafetyViolation.unexpectedLanguage
            }
        } else if locale.hasPrefix("en") {
            guard hanCount == 0,
                  scalars.count(where: Self.isBasicLatinLetter) >= 4 else {
                throw AdviceSafetyViolation.unexpectedLanguage
            }
        }
    }

    private static func isHan(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3400...0x4DBF,
             0x4E00...0x9FFF,
             0xF900...0xFAFF,
             0x20000...0x2FA1F:
            true
        default:
            false
        }
    }

    private static func isBasicLatinLetter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x41...0x5A, 0x61...0x7A:
            true
        default:
            false
        }
    }

    private func containsAny(_ phrases: [String], in text: String) -> Bool {
        phrases.contains { text.localizedCaseInsensitiveContains($0) }
    }
}

private enum BannedPhraseCatalog {
    private struct Resource: Decodable {
        let shame: [String]
        let diagnosis: [String]
        let financialAdvice: [String]
        let imperativeProhibition: [String]
    }

    private static let fallback = Resource(
        shame: [
        "irresponsible", "bad with money", "wasteful", "you failed",
        "不负责任", "乱花钱", "浪费", "你又失败了"
        ],
        diagnosis: [
        "you are addicted", "you have a disorder", "diagnosis",
        "你上瘾了", "你有病", "诊断"
        ],
        financialAdvice: [
        "buy this stock", "guaranteed return", "financial advice",
        "买这只股票", "保证收益", "投资建议"
        ],
        imperativeProhibition: [
        "you must not buy", "do not buy this", "never buy",
        "你必须不买", "不准买", "绝对不要买"
        ]
    )

    private static let resource: Resource = {
        guard let url = Bundle.main.url(forResource: "BannedPhrases", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Resource.self, from: data) else {
            return fallback
        }
        return decoded
    }()

    static let shame = resource.shame
    static let diagnosis = resource.diagnosis
    static let financialAdvice = resource.financialAdvice
    static let prohibition = resource.imperativeProhibition
}
