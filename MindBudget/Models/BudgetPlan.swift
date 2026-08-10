import Foundation
import SwiftData

@Model
final class BudgetPlan {
    @Attribute(.unique) var id: UUID
    var cycleStart: Date
    var cycleEnd: Date
    var currencyCode: String
    var monthlyIncomeMinorUnits: Int64
    var totalBudgetMinorUnits: Int64
    var fixedExpensesMinorUnits: Int64
    var savingGoalMinorUnits: Int64
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CategoryBudget.plan)
    var categoryBudgets: [CategoryBudget]

    init(
        id: UUID,
        cycleStart: Date,
        cycleEnd: Date,
        currencyCode: String,
        monthlyIncomeMinorUnits: Int64,
        totalBudgetMinorUnits: Int64,
        fixedExpensesMinorUnits: Int64,
        savingGoalMinorUnits: Int64,
        createdAt: Date,
        updatedAt: Date,
        categoryBudgets: [CategoryBudget]
    ) {
        self.id = id
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.currencyCode = currencyCode
        self.monthlyIncomeMinorUnits = monthlyIncomeMinorUnits
        self.totalBudgetMinorUnits = totalBudgetMinorUnits
        self.fixedExpensesMinorUnits = fixedExpensesMinorUnits
        self.savingGoalMinorUnits = savingGoalMinorUnits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categoryBudgets = categoryBudgets
    }
}

enum BudgetPlanAuthority: String, Codable, Sendable {
    /// Plans created before the income-based budget setup shipped. Their persisted
    /// expected-expense amount remains the funding base for that legacy cycle.
    case legacyExpectedExpenses

    /// Plans created by the current setup. Monthly income is the funding base.
    case incomeBased
}

/// Companion metadata intentionally lives outside `BudgetPlan` so adding the authority
/// marker does not alter the historical schema hashes for Schema V1 through V3.
@Model
final class BudgetPlanSemantics {
    @Attribute(.unique) var planID: UUID
    var authorityRaw: String

    init(planID: UUID, authorityRaw: String) {
        self.planID = planID
        self.authorityRaw = authorityRaw
    }
}
