import AppIntents
import CoreTransferable
import Foundation
import UniformTypeIdentifiers

enum ExpenseAmountBucket: String, Equatable, Sendable {
    case unavailable
    case underFivePercent
    case fiveToFifteenPercent
    case overFifteenPercent

    static func classify(amount: Money, plan: BudgetPlanSummary?) -> Self {
        guard let plan,
              plan.currencyCode == amount.currencyCode,
              plan.totalBudgetMinorUnits > 0 else { return .unavailable }
        let ratio = Decimal(amount.minorUnits) / Decimal(plan.totalBudgetMinorUnits)
        if ratio < Decimal(5) / Decimal(100) {
            return .underFivePercent
        }
        if ratio <= Decimal(15) / Decimal(100) {
            return .fiveToFifteenPercent
        }
        return .overFifteenPercent
    }

    var localizedKey: String { "entity.expense.amountBucket.\(rawValue)" }
}

struct ExpenseEntity: AppEntity, Equatable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "entity.expense.type"
    static let defaultQuery = ExpenseEntityQuery()

    let id: UUID
    let category: ExpenseCategory
    let spentAt: Date
    let amountBucket: ExpenseAmountBucket

    init(summary: ExpenseSummary, plan: BudgetPlanSummary?) {
        id = summary.id
        category = summary.category
        spentAt = summary.spentAt
        amountBucket = .classify(amount: summary.amount, plan: plan)
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: category.localizedNameKey),
            subtitle: LocalizedStringResource(stringLiteral: amountBucket.localizedKey),
            image: .init(systemName: category.symbolName)
        )
    }
}

struct ExpenseEntityQuery: EntityQuery {
    @Dependency private var service: MindBudgetIntentService

    func entities(for identifiers: [UUID]) async throws -> [ExpenseEntity] {
        (try? await service.expenseEntities(identifiers: identifiers)) ?? []
    }

    func suggestedEntities() async throws -> [ExpenseEntity] {
        Array(((try? await service.expenseEntities()) ?? []).prefix(20))
    }
}

struct BudgetSnapshotEntity: AppEntity, Equatable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "entity.budget.type"
    static let defaultQuery = BudgetSnapshotEntityQuery()

    let id: String
    let cycleStart: Date
    let cycleEnd: Date
    let daysRemaining: Int
    let isOverTotalBudget: Bool
    let isOverFreeBudget: Bool

    init(snapshot: ConfiguredBudgetSnapshot) {
        id = "current"
        cycleStart = snapshot.cycle.start
        cycleEnd = snapshot.cycle.end
        daysRemaining = snapshot.daysRemaining
        isOverTotalBudget = snapshot.remainingTotal.minorUnits < 0
        isOverFreeBudget = snapshot.remainingFree.minorUnits < 0
    }

    var displayRepresentation: DisplayRepresentation {
        let status: LocalizedStringResource = isOverTotalBudget || isOverFreeBudget
            ? "entity.budget.status.over"
            : "entity.budget.status.current"
        return DisplayRepresentation(
            title: "entity.budget.current",
            subtitle: status,
            image: .init(systemName: "chart.pie")
        )
    }
}

struct BudgetSnapshotEntityQuery: EntityQuery {
    @Dependency private var service: MindBudgetIntentService

    func entities(for identifiers: [String]) async throws -> [BudgetSnapshotEntity] {
        guard identifiers.contains("current") else { return [] }
        return (try? await service.budgetSnapshotEntities()) ?? []
    }

    func suggestedEntities() async throws -> [BudgetSnapshotEntity] {
        (try? await service.budgetSnapshotEntities()) ?? []
    }
}

struct WishlistItemEntity: AppEntity, Equatable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "entity.wishlist.type"
    static let defaultQuery = WishlistItemEntityQuery()

    let id: UUID
    let name: String
    let category: ExpenseCategory
    let status: WishItemStatus

    init(summary: WishItemSummary) {
        id = summary.id
        name = String(summary.name.prefix(IntentStringSanitizer.maximumLength))
        category = summary.category
        status = summary.status
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: LocalizedStringResource(stringLiteral: status.localizedNameKey),
            image: .init(systemName: "heart.text.square")
        )
    }
}

struct WishlistItemEntityQuery: EntityQuery {
    @Dependency private var service: MindBudgetIntentService

    func entities(for identifiers: [UUID]) async throws -> [WishlistItemEntity] {
        (try? await service.wishlistEntities(identifiers: identifiers)) ?? []
    }

    func suggestedEntities() async throws -> [WishlistItemEntity] {
        Array(((try? await service.wishlistEntities()) ?? []).prefix(20))
    }
}

struct CoolingOffPlanEntity: AppEntity, Equatable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "entity.cooling.type"
    static let defaultQuery = CoolingOffPlanEntityQuery()

    let id: UUID
    let wishItemID: UUID?
    let reviewAt: Date
    let status: CoolingOffStatus

    init(summary: CoolingOffPlanSummary) {
        id = summary.id
        wishItemID = summary.wishItemId
        reviewAt = summary.reviewAt
        status = summary.status
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "entity.cooling.title",
            subtitle: LocalizedStringResource(
                stringLiteral: "entity.cooling.status.\(status.rawValue)"
            ),
            image: .init(systemName: "hourglass")
        )
    }
}

struct CoolingOffPlanEntityQuery: EntityQuery {
    @Dependency private var service: MindBudgetIntentService

    func entities(for identifiers: [UUID]) async throws -> [CoolingOffPlanEntity] {
        (try? await service.coolingOffEntities(identifiers: identifiers)) ?? []
    }

    func suggestedEntities() async throws -> [CoolingOffPlanEntity] {
        Array(((try? await service.coolingOffEntities()) ?? []).prefix(20))
    }
}

struct MerchantEntity: AppEntity, Equatable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "entity.merchant.type"
    static let defaultQuery = MerchantEntityQuery()

    let id: UUID
    let displayName: String
    let primaryCategory: ExpenseCategory?

    init(summary: MerchantSummary) {
        id = summary.id
        displayName = String(summary.displayName.prefix(IntentStringSanitizer.maximumLength))
        primaryCategory = summary.primaryCategory
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: primaryCategory.map {
                LocalizedStringResource(stringLiteral: $0.localizedNameKey)
            },
            image: .init(systemName: "storefront")
        )
    }
}

struct MerchantEntityQuery: EntityQuery {
    @Dependency private var service: MindBudgetIntentService

    func entities(for identifiers: [UUID]) async throws -> [MerchantEntity] {
        (try? await service.merchantEntities(identifiers: identifiers)) ?? []
    }

    func suggestedEntities() async throws -> [MerchantEntity] {
        Array(((try? await service.merchantEntities()) ?? []).prefix(20))
    }
}

struct SpendingInsightEntity: AppEntity, Equatable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "entity.insight.type"
    static let defaultQuery = SpendingInsightEntityQuery()

    let id: UUID
    let type: SpendingInsightType
    let severity: InsightSeverity
    let relatedCategory: ExpenseCategory?

    init(summary: SpendingInsightSummary) {
        id = summary.id
        type = summary.type
        severity = summary.severity
        relatedCategory = summary.relatedCategory
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: "entity.insight.\(type.rawValue)"),
            subtitle: LocalizedStringResource(
                stringLiteral: "entity.insight.severity.\(severity.rawValue)"
            ),
            image: .init(systemName: "chart.xyaxis.line")
        )
    }
}

struct SpendingInsightEntityQuery: EntityQuery {
    @Dependency private var service: MindBudgetIntentService

    func entities(for identifiers: [UUID]) async throws -> [SpendingInsightEntity] {
        (try? await service.insightEntities(identifiers: identifiers)) ?? []
    }

    func suggestedEntities() async throws -> [SpendingInsightEntity] {
        Array(((try? await service.insightEntities()) ?? []).prefix(20))
    }
}

struct EmotionTagEntity: AppEntity, Equatable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "entity.emotion.type"
    static let defaultQuery = EmotionTagEntityQuery()

    let id: String
    let tag: EmotionTag

    init(tag: EmotionTag) {
        id = tag.rawValue
        self.tag = tag
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: tag.localizedNameKey),
            image: .init(systemName: "face.smiling")
        )
    }
}

struct EmotionTagEntityQuery: EntityQuery {
    @Dependency private var service: MindBudgetIntentService

    func entities(for identifiers: [String]) async throws -> [EmotionTagEntity] {
        (try? await service.emotionTagEntities(identifiers: identifiers)) ?? []
    }

    func suggestedEntities() async throws -> [EmotionTagEntity] {
        (try? await service.emotionTagEntities()) ?? []
    }
}

enum OnscreenTransferEntityKind: String, Codable, Sendable {
    case expense
    case budgetSnapshot
    case wishlistItem
}

/// The complete payload that an onscreen App Entity may export through
/// `Transferable`. Identity is sufficient for MindBudget's own intents to resolve
/// the authoritative entity through its query; no financial or user-authored fields
/// are duplicated into the transfer representation.
struct OnscreenTransferReference: Codable, Equatable, Sendable {
    static let currentVersion = 1

    let version: Int
    let entityKind: OnscreenTransferEntityKind
    let identifier: String

    init(entityKind: OnscreenTransferEntityKind, identifier: String) {
        version = Self.currentVersion
        self.entityKind = entityKind
        self.identifier = identifier
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
}

extension ExpenseEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { entity in
            try entity.onscreenTransferReference.encoded()
        }
    }

    var onscreenTransferReference: OnscreenTransferReference {
        OnscreenTransferReference(entityKind: .expense, identifier: id.uuidString)
    }
}

extension BudgetSnapshotEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { entity in
            try entity.onscreenTransferReference.encoded()
        }
    }

    var onscreenTransferReference: OnscreenTransferReference {
        OnscreenTransferReference(entityKind: .budgetSnapshot, identifier: id)
    }
}

extension WishlistItemEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { entity in
            try entity.onscreenTransferReference.encoded()
        }
    }

    var onscreenTransferReference: OnscreenTransferReference {
        OnscreenTransferReference(entityKind: .wishlistItem, identifier: id.uuidString)
    }
}

// IndexedEntity's default attribute set is derived from each entity's deliberately
// redacted display representation. None of these types carries an exact amount or note.
// Actual Core Spotlight association remains gated to the iOS 26 product layer.
@available(iOS 18.0, *)
extension ExpenseEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension BudgetSnapshotEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension WishlistItemEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension CoolingOffPlanEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension MerchantEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension SpendingInsightEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension EmotionTagEntity: IndexedEntity {}
