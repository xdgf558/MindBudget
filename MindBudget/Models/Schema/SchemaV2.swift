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
