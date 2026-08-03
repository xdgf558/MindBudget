import Foundation
import SwiftData

@Model
final class CategoryBudget {
    @Attribute(.unique) var id: UUID
    var categoryRaw: String
    var limitMinorUnits: Int64
    var warningThresholdBasisPoints: Int
    var createdAt: Date
    var updatedAt: Date
    var plan: BudgetPlan?

    init(
        id: UUID,
        categoryRaw: String,
        limitMinorUnits: Int64,
        warningThresholdBasisPoints: Int,
        createdAt: Date,
        updatedAt: Date,
        plan: BudgetPlan?
    ) {
        self.id = id
        self.categoryRaw = categoryRaw
        self.limitMinorUnits = limitMinorUnits
        self.warningThresholdBasisPoints = warningThresholdBasisPoints
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.plan = plan
    }

}
