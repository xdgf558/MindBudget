import AppIntents

extension ExpenseCategory: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "intent.category.type"
    static let caseDisplayRepresentations: [ExpenseCategory: DisplayRepresentation] = [
        .food: "category.food",
        .coffee: "category.coffee",
        .groceries: "category.groceries",
        .transport: "category.transport",
        .shopping: "category.shopping",
        .clothing: "category.clothing",
        .electronics: "category.electronics",
        .entertainment: "category.entertainment",
        .social: "category.social",
        .gifts: "category.gifts",
        .subscriptions: "category.subscriptions",
        .health: "category.health",
        .travel: "category.travel",
        .rent: "category.rent",
        .utilities: "category.utilities",
        .education: "category.education",
        .other: "category.other",
    ]
}

extension BudgetBucket: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "intent.bucket.type"
    static let caseDisplayRepresentations: [BudgetBucket: DisplayRepresentation] = [
        .fixed: "bucket.fixed",
        .discretionary: "bucket.discretionary",
        .savings: "bucket.savings",
    ]
}
