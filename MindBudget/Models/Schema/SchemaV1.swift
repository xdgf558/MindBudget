import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Expense.self,
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
