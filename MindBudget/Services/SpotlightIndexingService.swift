import Foundation
@preconcurrency import CoreSpotlight
import UniformTypeIdentifiers

#if canImport(AppIntents)
import AppIntents
#endif

enum MindBudgetSearchDomain {
    static let root = "mindbudget.local"
}

enum MindBudgetSearchIdentifier {
    static let expensePrefix = "mindbudget.expense."
    static let budget = "mindbudget.budget.current"
    static let wishlistPrefix = "mindbudget.wishlist."
    static let coolingPrefix = "mindbudget.cooling."
    static let merchantPrefix = "mindbudget.merchant."
    static let insightPrefix = "mindbudget.insight."
    static let emotionPrefix = "mindbudget.emotion."

    static func expense(_ id: UUID) -> String { expensePrefix + id.uuidString.lowercased() }
    static func wishlist(_ id: UUID) -> String { wishlistPrefix + id.uuidString.lowercased() }
    static func cooling(_ id: UUID) -> String { coolingPrefix + id.uuidString.lowercased() }
    static func merchant(_ id: UUID) -> String { merchantPrefix + id.uuidString.lowercased() }
    static func insight(_ id: UUID) -> String { insightPrefix + id.uuidString.lowercased() }
    static func emotion(_ tag: EmotionTag) -> String { emotionPrefix + tag.rawValue }

    static func navigationRequest(for identifier: String) -> MindBudgetNavigationRequest? {
        if identifier == budget { return .dashboard }
        if identifier.hasPrefix(expensePrefix) { return .expenses }
        if identifier.hasPrefix(coolingPrefix) {
            return .wishlist
        }
        if identifier.hasPrefix(merchantPrefix) { return .expenses }
        if identifier.hasPrefix(insightPrefix) || identifier.hasPrefix(emotionPrefix) {
            return .insights
        }
        guard identifier.hasPrefix(wishlistPrefix),
              let id = UUID(uuidString: String(identifier.dropFirst(wishlistPrefix.count))) else {
            return nil
        }
        return .wishlistItem(id)
    }
}

struct SpotlightDocument: Equatable, Sendable {
    let identifier: String
    let domainIdentifier: String
    let title: String
    let contentDescription: String
    let keywords: [String]
    let appEntity: SpotlightIndexedEntity?

    init(
        identifier: String,
        domainIdentifier: String,
        title: String,
        contentDescription: String,
        keywords: [String],
        appEntity: SpotlightIndexedEntity? = nil
    ) {
        self.identifier = identifier
        self.domainIdentifier = domainIdentifier
        self.title = title
        self.contentDescription = contentDescription
        self.keywords = keywords
        self.appEntity = appEntity
    }
}

/// The only entity payload accepted by the app-owned Spotlight boundary. Associated
/// values are the amount-free AppEntity projections rather than SwiftData models.
enum SpotlightIndexedEntity: Equatable, Sendable {
    case expense(ExpenseEntity)
    case budget(BudgetSnapshotEntity)
    case wishlistItem(WishlistItemEntity)
    case coolingOff(CoolingOffPlanEntity)
    case merchant(MerchantEntity)
    case insight(SpendingInsightEntity)
    case emotion(EmotionTagEntity)

    #if canImport(AppIntents)
    @available(iOS 26.0, *)
    func associate(with attributes: CSSearchableItemAttributeSet) {
        switch self {
        case let .expense(entity): attributes.associateAppEntity(entity)
        case let .budget(entity): attributes.associateAppEntity(entity)
        case let .wishlistItem(entity): attributes.associateAppEntity(entity)
        case let .coolingOff(entity): attributes.associateAppEntity(entity)
        case let .merchant(entity): attributes.associateAppEntity(entity)
        case let .insight(entity): attributes.associateAppEntity(entity)
        case let .emotion(entity): attributes.associateAppEntity(entity)
        }
    }
    #endif
}

protocol SpotlightIndexClient: Sendable {
    func replace(domainIdentifier: String, with documents: [SpotlightDocument]) async throws
    func delete(domainIdentifier: String) async throws
}

actor CoreSpotlightIndexClient: SpotlightIndexClient {
    private let index: CSSearchableIndex

    init(index: CSSearchableIndex = .default()) {
        self.index = index
    }

    func replace(domainIdentifier: String, with documents: [SpotlightDocument]) async throws {
        try await delete(domainIdentifier: domainIdentifier)
        guard !documents.isEmpty else { return }
        let items = documents.map { document in
            let attributes = CSSearchableItemAttributeSet(contentType: .data)
            attributes.title = document.title
            attributes.contentDescription = document.contentDescription
            attributes.keywords = document.keywords
            #if canImport(AppIntents)
            if #available(iOS 26.0, *), let appEntity = document.appEntity {
                appEntity.associate(with: attributes)
            }
            #endif
            return CSSearchableItem(
                uniqueIdentifier: document.identifier,
                domainIdentifier: document.domainIdentifier,
                attributeSet: attributes
            )
        }
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            index.indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func delete(domainIdentifier: String) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            index.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

enum SpotlightReconciliationResult: Equatable, Sendable {
    case indexed(Int)
    case cleared
    case unavailable
    case failed
}

protocol SpotlightIndexing: Sendable {
    func reconcile(
        dataActor: DataActor,
        preferences: SystemIntegrationPreferencesSnapshot,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async -> SpotlightReconciliationResult
}

actor SpotlightIndexingService: SpotlightIndexing {
    private let client: any SpotlightIndexClient
    private let capability: SystemIntegrationCapability
    private var hasClearedWhileDisabled = false

    init(
        client: any SpotlightIndexClient = CoreSpotlightIndexClient(),
        capability: SystemIntegrationCapability = SystemIntegrationCapability()
    ) {
        self.client = client
        self.capability = capability
    }

    func reconcile(
        dataActor: DataActor,
        preferences: SystemIntegrationPreferencesSnapshot,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async -> SpotlightReconciliationResult {
        let availability = capability.spotlightAvailability(
            userEnabled: preferences.spotlightEnabled
        )
        guard availability.isAvailable else {
            if hasClearedWhileDisabled { return .cleared }
            do {
                try await client.delete(domainIdentifier: MindBudgetSearchDomain.root)
                hasClearedWhileDisabled = true
                return availability == .runtimeUnavailable ? .unavailable : .cleared
            } catch {
                return availability == .runtimeUnavailable ? .unavailable : .failed
            }
        }

        do {
            async let expenses = dataActor.fetchExpenseSummaries()
            async let plans = dataActor.fetchBudgetPlanSummaries()
            async let wishItems = dataActor.fetchWishItemSummaries()
            async let coolingPlans = dataActor.fetchCoolingOffPlanSummaries()
            async let merchants = dataActor.fetchMerchantSummaries()
            async let eligibleMerchantKeys = dataActor.fetchMerchantIndexingEligibleNormalizedNames()
            async let insights = dataActor.fetchSpendingInsightSummaries()
            let documents = makeDocuments(
                expenses: try await expenses,
                plans: try await plans,
                wishItems: try await wishItems,
                coolingPlans: try await coolingPlans,
                merchants: try await merchants,
                eligibleMerchantKeys: try await eligibleMerchantKeys,
                insights: try await insights,
                indexMerchantNames: preferences.merchantNamesEnabled,
                now: now,
                calendar: calendar,
                locale: locale
            )
            try await client.replace(
                domainIdentifier: MindBudgetSearchDomain.root,
                with: documents
            )
            hasClearedWhileDisabled = false
            return .indexed(documents.count)
        } catch {
            return .failed
        }
    }

    func makeDocuments(
        expenses: [ExpenseSummary],
        plans: [BudgetPlanSummary],
        wishItems: [WishItemSummary],
        coolingPlans: [CoolingOffPlanSummary],
        merchants: [MerchantSummary],
        eligibleMerchantKeys: Set<String>,
        insights: [SpendingInsightSummary],
        indexMerchantNames: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) -> [SpotlightDocument] {
        var documents: [SpotlightDocument] = expenses.map { expense in
            let category = LocalizedCatalog.string(expense.category.localizedNameKey, locale: locale)
            let plan = plans.first {
                $0.cycleStart <= expense.spentAt && expense.spentAt < $0.cycleEnd
            }
            let bucket = ExpenseAmountBucket.classify(amount: expense.amount, plan: plan)
            return SpotlightDocument(
                identifier: MindBudgetSearchIdentifier.expense(expense.id),
                domainIdentifier: MindBudgetSearchDomain.root,
                title: LocalizedCatalog.format("spotlight.expense.title", locale: locale, category),
                contentDescription: LocalizedCatalog.string(bucket.localizedKey, locale: locale),
                keywords: [category, LocalizedCatalog.string("spotlight.keyword.expense", locale: locale)],
                appEntity: .expense(ExpenseEntity(summary: expense, plan: plan))
            )
        }

        if let plan = plans.first(where: { $0.cycleStart <= now && now < $0.cycleEnd }) {
            let currentExpenses = expenses.filter { plan.cycleStart <= $0.spentAt && $0.spentAt < plan.cycleEnd }
            let snapshot = try? BudgetEngine().snapshot(
                cycle: DateInterval(start: plan.cycleStart, end: plan.cycleEnd),
                currencyCode: plan.currencyCode,
                expenses: currentExpenses,
                plan: plan,
                now: now,
                calendar: calendar
            )
            let stateKey: String
            let indexedEntity: SpotlightIndexedEntity?
            if case let .configured(configured) = snapshot {
                stateKey = configured.remainingTotal.minorUnits < 0
                    || configured.remainingFree.minorUnits < 0
                    ? "entity.budget.status.over"
                    : "entity.budget.status.current"
                indexedEntity = .budget(BudgetSnapshotEntity(snapshot: configured))
            } else {
                stateKey = "entity.budget.status.current"
                indexedEntity = nil
            }
            documents.append(
                SpotlightDocument(
                    identifier: MindBudgetSearchIdentifier.budget,
                    domainIdentifier: MindBudgetSearchDomain.root,
                    title: LocalizedCatalog.string("entity.budget.current", locale: locale),
                    contentDescription: LocalizedCatalog.string(stateKey, locale: locale),
                    keywords: [LocalizedCatalog.string("spotlight.keyword.budget", locale: locale)],
                    appEntity: indexedEntity
                )
            )
        }

        documents.append(contentsOf: wishItems.map { item in
            SpotlightDocument(
                identifier: MindBudgetSearchIdentifier.wishlist(item.id),
                domainIdentifier: MindBudgetSearchDomain.root,
                title: String(item.name.prefix(IntentStringSanitizer.maximumLength)),
                contentDescription: LocalizedCatalog.string(item.status.localizedNameKey, locale: locale),
                keywords: [
                    LocalizedCatalog.string("spotlight.keyword.wishlist", locale: locale),
                    LocalizedCatalog.string(item.category.localizedNameKey, locale: locale),
                ],
                appEntity: .wishlistItem(WishlistItemEntity(summary: item))
            )
        })

        documents.append(contentsOf: coolingPlans.map { plan in
            SpotlightDocument(
                identifier: MindBudgetSearchIdentifier.cooling(plan.id),
                domainIdentifier: MindBudgetSearchDomain.root,
                title: LocalizedCatalog.string("entity.cooling.title", locale: locale),
                contentDescription: LocalizedCatalog.string(
                    "entity.cooling.status.\(plan.status.rawValue)",
                    locale: locale
                ),
                keywords: [LocalizedCatalog.string("spotlight.keyword.cooling", locale: locale)],
                appEntity: .coolingOff(CoolingOffPlanEntity(summary: plan))
            )
        })

        if indexMerchantNames {
            documents.append(contentsOf: merchants.compactMap { merchant in
                guard eligibleMerchantKeys.contains(merchant.normalizedName) else { return nil }
                return SpotlightDocument(
                    identifier: MindBudgetSearchIdentifier.merchant(merchant.id),
                    domainIdentifier: MindBudgetSearchDomain.root,
                    title: String(merchant.displayName.prefix(IntentStringSanitizer.maximumLength)),
                    contentDescription: merchant.primaryCategory.map {
                        LocalizedCatalog.string($0.localizedNameKey, locale: locale)
                    } ?? LocalizedCatalog.string("category.other", locale: locale),
                    keywords: [LocalizedCatalog.string("spotlight.keyword.merchant", locale: locale)],
                    appEntity: .merchant(MerchantEntity(summary: merchant))
                )
            })
        }

        documents.append(contentsOf: insights.map { insight in
            SpotlightDocument(
                identifier: MindBudgetSearchIdentifier.insight(insight.id),
                domainIdentifier: MindBudgetSearchDomain.root,
                title: LocalizedCatalog.string("entity.insight.\(insight.type.rawValue)", locale: locale),
                contentDescription: LocalizedCatalog.string(
                    "entity.insight.severity.\(insight.severity.rawValue)",
                    locale: locale
                ),
                keywords: [LocalizedCatalog.string("spotlight.keyword.insight", locale: locale)],
                appEntity: .insight(SpendingInsightEntity(summary: insight))
            )
        })

        documents.append(contentsOf: EmotionTag.allCases.map { tag in
            SpotlightDocument(
                identifier: MindBudgetSearchIdentifier.emotion(tag),
                domainIdentifier: MindBudgetSearchDomain.root,
                title: LocalizedCatalog.string(tag.localizedNameKey, locale: locale),
                contentDescription: LocalizedCatalog.string("entity.emotion.type", locale: locale),
                keywords: [LocalizedCatalog.string("spotlight.keyword.emotion", locale: locale)],
                appEntity: .emotion(EmotionTagEntity(tag: tag))
            )
        })

        return documents.sorted { $0.identifier < $1.identifier }
    }
}
