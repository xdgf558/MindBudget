import Foundation
import SwiftData

@Model
final class WishItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var estimatedPriceMinorUnits: Int64?
    var currencyCode: String
    var categoryRaw: String
    var reasonRaw: String?
    var emotionTagRaw: String?
    var sourceContextLabel: String?
    var createdAt: Date
    var updatedAt: Date
    var coolingOffHours: Int
    var targetReviewDate: Date?
    var statusRaw: String
    var notes: String?
    var purchasedExpenseId: UUID?

    @Relationship(deleteRule: .cascade, inverse: \CoolingOffPlan.wishItem)
    var coolingOffPlans: [CoolingOffPlan]

    init(
        id: UUID,
        name: String,
        estimatedPriceMinorUnits: Int64?,
        currencyCode: String,
        categoryRaw: String,
        reasonRaw: String?,
        emotionTagRaw: String?,
        sourceContextLabel: String?,
        createdAt: Date,
        updatedAt: Date,
        coolingOffHours: Int,
        targetReviewDate: Date?,
        statusRaw: String,
        notes: String?,
        purchasedExpenseId: UUID?,
        coolingOffPlans: [CoolingOffPlan]
    ) {
        self.id = id
        self.name = name
        self.estimatedPriceMinorUnits = estimatedPriceMinorUnits
        self.currencyCode = currencyCode
        self.categoryRaw = categoryRaw
        self.reasonRaw = reasonRaw
        self.emotionTagRaw = emotionTagRaw
        self.sourceContextLabel = sourceContextLabel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.coolingOffHours = coolingOffHours
        self.targetReviewDate = targetReviewDate
        self.statusRaw = statusRaw
        self.notes = notes
        self.purchasedExpenseId = purchasedExpenseId
        self.coolingOffPlans = coolingOffPlans
    }

    func transition(to nextStatus: WishItemStatus, at date: Date) throws {
        let currentStatus: WishItemStatus = try validatedPersistedEnum(
            WishItemStatus.self,
            rawValue: statusRaw,
            entity: "WishItem",
            id: id,
            field: "statusRaw"
        )
        try WishItemStateMachine.validateTransition(from: currentStatus, to: nextStatus)
        statusRaw = nextStatus.rawValue
        updatedAt = date
    }
}
