import Foundation

enum SuggestedAction: String, Codable, CaseIterable, Sendable {
    case addToWishlist
    case startCoolingOff24h
    case startCoolingOff72h
    case waitUntilNextCycle
    case reduceAnotherCategory
    case reviewRecentSpending
    case setReminderTomorrow
    case adjustBudget
    case continuePurchase
}

struct ReminderContext: Sendable {
    let candidate: PurchaseCandidate?
    let impact: BudgetImpact?
    let snapshot: BudgetSnapshot
    let drafts: [InsightDraft]
    let suggestedActions: [SuggestedAction]
    let tone: ReminderTone
}

struct ReminderMessage: Equatable, Sendable {
    enum Source: String, Sendable {
        case template
        case model
        case modelValidatedFallback
        case modelErrorFallback
        case modelUnavailableFallback
        case modelTimedOutFallback
    }

    let title: String
    let body: String
    let supportingDetails: [String]
    let actions: [SuggestedAction]
    let severity: InsightSeverity
    let channel: ReminderChannel
    let source: Source
}

struct ReminderWording: Equatable, Sendable {
    let title: String
    let body: String
}

protocol ReminderWordingEnhancing: Sendable {
    func enhance(
        template: ReminderWording,
        tone: ReminderTone,
        localeIdentifier: String
    ) async throws -> ReminderWording
}

protocol ReminderGenerating: Sendable {
    func buildContext(
        candidate: PurchaseCandidate?,
        impact: BudgetImpact?,
        snapshot: BudgetSnapshot,
        drafts: [InsightDraft],
        tone: ReminderTone
    ) -> ReminderContext

    func generateReminder(
        context: ReminderContext,
        channel: ReminderChannel,
        locale: Locale
    ) async -> ReminderMessage?
}

struct ReminderEngine: ReminderGenerating, Sendable {
    private let enhancer: (any ReminderWordingEnhancing)?
    private let aiEnhancementEnabled: Bool
    private let aiGenerator: any AIAdviceGenerating
    private let aiRuntimeAvailability: @Sendable (Locale) async -> AIAvailability

    init(
        enhancer: (any ReminderWordingEnhancing)? = nil,
        aiEnhancementEnabled: Bool = false,
        aiGenerator: any AIAdviceGenerating = FoundationModelsAdviceGenerator(),
        aiRuntimeAvailability: @escaping @Sendable (Locale) async -> AIAvailability = { locale in
            await FoundationModelsAdviceGenerator.runtimeAvailability(locale: locale)
        }
    ) {
        self.enhancer = enhancer
        self.aiEnhancementEnabled = aiEnhancementEnabled
        self.aiGenerator = aiGenerator
        self.aiRuntimeAvailability = aiRuntimeAvailability
    }

    func buildContext(
        candidate: PurchaseCandidate?,
        impact: BudgetImpact?,
        snapshot: BudgetSnapshot,
        drafts: [InsightDraft],
        tone: ReminderTone
    ) -> ReminderContext {
        let sorted = drafts.sorted {
            if $0.severity == $1.severity { return $0.type.rawValue < $1.type.rawValue }
            return $0.severity > $1.severity
        }
        return ReminderContext(
            candidate: candidate,
            impact: impact,
            snapshot: snapshot,
            drafts: sorted,
            suggestedActions: [.addToWishlist, .continuePurchase],
            tone: tone
        )
    }

    func generateReminder(
        context: ReminderContext,
        channel: ReminderChannel,
        locale: Locale
    ) async -> ReminderMessage? {
        guard let primary = context.drafts.first else { return nil }
        let template = AdviceTemplateGenerator().wording(
            for: primary,
            tone: context.tone,
            locale: locale
        )
        let actions = validActions(context.suggestedActions)
        let supportingDetails = context.drafts.dropFirst().prefix(2).map {
            LocalizedCatalog.string($0.titleKey, locale: locale)
        }

        if enhancer == nil, aiEnhancementEnabled,
           let candidate = context.candidate {
            let generatedFallback = GeneratedAdvice(
                title: template.title,
                body: template.body,
                actionIdentifiers: actions.map(\.rawValue),
                severity: primary.severity
            )
            let redacted = PrivacyRedactor().redactAdvice(
                AdviceAggregateInput(
                    localeIdentifier: locale.identifier,
                    currencyCode: candidate.amount.currencyCode,
                    purchaseCategory: candidate.category,
                    purchaseAmountFormatted: CurrencyFormatterService().string(
                        from: candidate.amount,
                        locale: locale
                    ),
                    remainingFreeAfterFormatted: context.impact.map {
                        CurrencyFormatterService().string(
                            from: $0.remainingFreeAfter,
                            locale: locale
                        )
                    } ?? "—",
                    freeBudgetImpactPercent: percent(
                        context.impact?.impactRatioOfFreeBudget
                    ),
                    daysOfBudgetConsumed: percent(
                        context.impact?.daysOfBudgetConsumed,
                        multiplier: 1
                    ),
                    categoryBudgetUsedPercent: percent(
                        context.impact?.categoryRisk?.usedRatio
                    ),
                    recentStressPurchaseCount7d: insightCount(
                        .repeatedStressSpending,
                        drafts: context.drafts
                    ),
                    recentImpulsePurchaseCount72h: insightCount(
                        .impulseCluster,
                        drafts: context.drafts
                    ),
                    allowedActions: actions,
                    tone: context.tone,
                    maxTitleLength: 24,
                    maxBodyLength: bodyLimit(for: context.tone)
                )
            )
            let result = await CompositeAdviceGenerator(
                model: aiGenerator,
                capability: AIEnhancementCapability(
                    userEnabled: true,
                    targetLocale: locale,
                    runtimeAvailability: aiRuntimeAvailability
                )
            ).reminder(fallback: generatedFallback, context: redacted)
            return message(
                wording: ReminderWording(
                    title: result.advice.title,
                    body: result.advice.body
                ),
                supportingDetails: supportingDetails,
                actions: result.advice.actionIdentifiers.compactMap {
                    SuggestedAction(rawValue: $0)
                },
                primary: primary,
                channel: channel,
                source: reminderSource(result.source),
                tone: context.tone
            )
        }

        guard let enhancer else {
            return message(
                wording: template,
                supportingDetails: supportingDetails,
                actions: actions,
                primary: primary,
                channel: channel,
                source: .template,
                tone: context.tone
            )
        }

        do {
            let enhanced = try await enhancer.enhance(
                template: template,
                tone: context.tone,
                localeIdentifier: locale.identifier
            )
            guard wordingIsStructurallySafe(enhanced, tone: context.tone) else {
                return message(
                    wording: template,
                    supportingDetails: supportingDetails,
                    actions: actions,
                    primary: primary,
                    channel: channel,
                    source: .modelValidatedFallback,
                    tone: context.tone
                )
            }
            return message(
                wording: enhanced,
                supportingDetails: supportingDetails,
                actions: actions,
                primary: primary,
                channel: channel,
                source: .model,
                tone: context.tone
            )
        } catch {
            return message(
                wording: template,
                supportingDetails: supportingDetails,
                actions: actions,
                primary: primary,
                channel: channel,
                source: .modelValidatedFallback,
                tone: context.tone
            )
        }
    }

    private func percent(_ ratio: Decimal?, multiplier: Int = 100) -> Int? {
        guard let ratio else { return nil }
        return NSDecimalNumber(decimal: ratio * Decimal(multiplier)).intValue
    }

    private func reminderSource(_ source: AdviceGenerationSource) -> ReminderMessage.Source {
        switch source {
        case .template: .template
        case .model: .model
        case .modelValidatedFallback: .modelValidatedFallback
        case .modelErrorFallback: .modelErrorFallback
        case .modelUnavailableFallback: .modelUnavailableFallback
        case .modelTimedOutFallback: .modelTimedOutFallback
        }
    }

    private func insightCount(
        _ type: SpendingInsightType,
        drafts: [InsightDraft]
    ) -> Int {
        guard let draft = drafts.first(where: { $0.type == type }),
              case let .integer(value) = draft.payload["count"] else { return 0 }
        return max(0, value)
    }

    private func validActions(_ proposed: [SuggestedAction]) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []
        for action in proposed where !actions.contains(action) {
            actions.append(action)
        }
        if !actions.contains(.continuePurchase) { actions.append(.continuePurchase) }
        if actions.count < 2 { actions.insert(.addToWishlist, at: 0) }
        if actions.count > 4 { actions = Array(actions.prefix(4)) }
        if !actions.contains(.continuePurchase) {
            actions[actions.count - 1] = .continuePurchase
        }
        return actions
    }

    private func message(
        wording: ReminderWording,
        supportingDetails: [String],
        actions: [SuggestedAction],
        primary: InsightDraft,
        channel: ReminderChannel,
        source: ReminderMessage.Source,
        tone: ReminderTone
    ) -> ReminderMessage {
        ReminderMessage(
            title: String(wording.title.prefix(24)),
            body: String(wording.body.prefix(bodyLimit(for: tone))),
            supportingDetails: supportingDetails,
            actions: actions,
            severity: primary.severity,
            channel: channel,
            source: source
        )
    }

    private func wordingIsStructurallySafe(
        _ wording: ReminderWording,
        tone: ReminderTone
    ) -> Bool {
        !wording.title.isEmpty
            && !wording.body.isEmpty
            && wording.title.count <= 24
            && wording.body.count <= bodyLimit(for: tone)
            && !wording.title.contains("!")
            && !wording.body.contains("!")
    }

    private func bodyLimit(for tone: ReminderTone) -> Int {
        switch tone {
        case .soft: 80
        case .direct: 40
        case .minimal: 20
        }
    }
}

struct AdviceTemplateGenerator: Sendable {
    func wording(
        for draft: InsightDraft,
        tone: ReminderTone,
        locale: Locale
    ) -> ReminderWording {
        let family = family(for: draft.type)
        let title = LocalizedCatalog.string(
            "reminder.template.\(family).title",
            locale: locale
        )
        let body: String
        switch tone {
        case .minimal:
            body = minimalBody(for: draft, locale: locale)
        case .soft, .direct:
            body = standardBody(for: draft, family: family, tone: tone, locale: locale)
        }
        return ReminderWording(title: title, body: body)
    }

    private func standardBody(
        for draft: InsightDraft,
        family: String,
        tone: ReminderTone,
        locale: Locale
    ) -> String {
        let key = "reminder.template.\(family).\(tone.rawValue).body"
        switch family {
        case "category":
            return LocalizedCatalog.format(
                key,
                locale: locale,
                categoryName(draft, locale: locale),
                percent(draft)
            )
        case "pattern":
            return LocalizedCatalog.format(key, locale: locale, count(draft))
        case "change":
            return LocalizedCatalog.format(key, locale: locale, percent(draft))
        case "budget", "safe":
            return LocalizedCatalog.format(key, locale: locale, moneyText(draft, locale: locale))
        default:
            return LocalizedCatalog.string(key, locale: locale)
        }
    }

    private func minimalBody(for draft: InsightDraft, locale: Locale) -> String {
        let value: String
        switch family(for: draft.type) {
        case "category", "change": value = "\(percent(draft))%"
        case "pattern": value = String(count(draft))
        case "budget", "safe": value = moneyText(draft, locale: locale)
        default: value = "—"
        }
        return LocalizedCatalog.format(
            "reminder.template.minimal.body",
            locale: locale,
            value
        )
    }

    private func family(for type: SpendingInsightType) -> String {
        switch type {
        case .highSinglePurchase: "budget"
        case .categoryBudgetRisk: "category"
        case .imageRelatedIncrease: "change"
        case .safeToProceed: "safe"
        case .lateNightSpending, .repeatedStressSpending, .impulseCluster,
             .wishlistCoolingOff, .coolingOffSuccess, .monthlySummary:
            "pattern"
        }
    }

    private func moneyText(_ draft: InsightDraft, locale: Locale) -> String {
        let money: Money?
        if case let .money(value) = draft.payload["remainingFreeAfter"] {
            money = value
        } else if case let .money(value) = draft.payload["amount"] {
            money = value
        } else {
            money = nil
        }
        guard let money else { return "—" }
        return CurrencyFormatterService().string(from: money, locale: locale)
    }

    private func categoryName(_ draft: InsightDraft, locale: Locale) -> String {
        guard case let .category(category) = draft.payload["category"] else { return "—" }
        return LocalizedCatalog.string(category.localizedNameKey, locale: locale)
    }

    private func percent(_ draft: InsightDraft) -> Int {
        let payloadValue = draft.payload["risk"] ?? draft.payload["change"]
        guard case let .basisPoints(value) = payloadValue else { return 0 }
        return max(0, value / 100)
    }

    private func count(_ draft: InsightDraft) -> Int {
        guard case let .integer(value) = draft.payload["count"] else { return 0 }
        return max(0, value)
    }
}

struct InsightPresentationFormatter: Sendable {
    func wording(
        for insight: SpendingInsightSummary,
        locale: Locale
    ) -> ReminderWording {
        let title = LocalizedCatalog.string(insight.titleKey, locale: locale)
        let body: String
        switch insight.type {
        case .highSinglePurchase:
            body = LocalizedCatalog.format(
                insight.bodyKey,
                locale: locale,
                money(insight.payload["amount"], locale: locale)
            )
        case .categoryBudgetRisk:
            body = LocalizedCatalog.format(
                insight.bodyKey,
                locale: locale,
                category(insight.payload["category"], locale: locale),
                percent(insight.payload["risk"])
            )
        case .lateNightSpending, .repeatedStressSpending, .impulseCluster,
             .coolingOffSuccess:
            body = LocalizedCatalog.format(
                insight.bodyKey,
                locale: locale,
                integer(insight.payload["count"])
            )
        case .imageRelatedIncrease:
            body = LocalizedCatalog.format(
                insight.bodyKey,
                locale: locale,
                money(insight.payload["current"], locale: locale),
                percent(insight.payload["change"])
            )
        case .safeToProceed:
            body = LocalizedCatalog.format(
                insight.bodyKey,
                locale: locale,
                money(insight.payload["remainingFreeAfter"], locale: locale)
            )
        case .wishlistCoolingOff, .monthlySummary:
            body = LocalizedCatalog.string(insight.bodyKey, locale: locale)
        }
        return ReminderWording(title: title, body: body)
    }

    private func money(_ value: InsightValue?, locale: Locale) -> String {
        guard case let .money(money) = value else { return "—" }
        return CurrencyFormatterService().string(from: money, locale: locale)
    }

    private func category(_ value: InsightValue?, locale: Locale) -> String {
        guard case let .category(category) = value else { return "—" }
        return LocalizedCatalog.string(category.localizedNameKey, locale: locale)
    }

    private func percent(_ value: InsightValue?) -> Int {
        guard case let .basisPoints(basisPoints) = value else { return 0 }
        return max(0, basisPoints / 100)
    }

    private func integer(_ value: InsightValue?) -> Int {
        guard case let .integer(integer) = value else { return 0 }
        return max(0, integer)
    }
}

enum LocalizedCatalog {
    static func string(_ key: String, locale: Locale) -> String {
        localizedBundle(for: locale).localizedString(forKey: key, value: nil, table: nil)
    }

    static func format(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        String(format: string(key, locale: locale), locale: locale, arguments: arguments)
    }

    private static func localizedBundle(for locale: Locale) -> Bundle {
        let localizations = Bundle.main.localizations.filter { $0 != "Base" }
        guard let localization = Bundle.preferredLocalizations(
            from: localizations,
            forPreferences: [locale.identifier]
        ).first,
        let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
        let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
