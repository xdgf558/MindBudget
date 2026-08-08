import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Expense.self,
            Income.self,
            BudgetPlan.self,
            CategoryBudget.self,
            WishItem.self,
            CoolingOffPlan.self,
            SpendingInsight.self,
            ReflectionLog.self,
            Merchant.self,
            ReminderEvent.self
        ]
    }
}

enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(3, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Expense.self,
            Income.self,
            IncomeAllocation.self,
            SavingsGoal.self,
            RecurringFixedExpenseRule.self,
            RecurringExpenseOccurrence.self,
            BudgetPlan.self,
            CategoryBudget.self,
            WishItem.self,
            CoolingOffPlan.self,
            SpendingInsight.self,
            ReflectionLog.self,
            Merchant.self,
            ReminderEvent.self
        ]
    }
}
