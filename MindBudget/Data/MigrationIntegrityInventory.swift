import Foundation
import SwiftData

/// The C4A-02 post-open inventory deliberately validates before it writes any companion repair.
/// It is a recovery boundary, not a new money representation or a replacement migration plan.
enum MigrationIntegrityInventory {
    enum Error: Swift.Error, Equatable, Sendable {
        case unsupportedCurrency
        case invalidPersistedAmount
        case mixedAccountingCurrency
        case duplicateIdentity
        case invalidMerchantAggregate
    }

    static func validateAndRepair(in container: ModelContainer) throws {
        let context = ModelContext(container)
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let incomes = try context.fetch(FetchDescriptor<Income>())
        let plans = try context.fetch(FetchDescriptor<BudgetPlan>())
        let planSemantics = try context.fetch(FetchDescriptor<BudgetPlanSemantics>())
        let categories = try context.fetch(FetchDescriptor<CategoryBudget>())
        let wishes = try context.fetch(FetchDescriptor<WishItem>())
        let coolingOff = try context.fetch(FetchDescriptor<CoolingOffPlan>())
        let insights = try context.fetch(FetchDescriptor<SpendingInsight>())
        let reflections = try context.fetch(FetchDescriptor<ReflectionLog>())
        let merchants = try context.fetch(FetchDescriptor<Merchant>())
        let merchantContexts = try context.fetch(FetchDescriptor<MerchantAccountingContext>())
        let reminders = try context.fetch(FetchDescriptor<ReminderEvent>())
        let savingsGoals = try context.fetch(FetchDescriptor<SavingsGoal>())
        let recurringRules = try context.fetch(FetchDescriptor<RecurringFixedExpenseRule>())
        let occurrences = try context.fetch(FetchDescriptor<RecurringExpenseOccurrence>())
        let allocations = try context.fetch(FetchDescriptor<IncomeAllocation>())

        // Fetching every V5 model is the unreadable-store inventory. The concrete validation below
        // covers all persisted monetary owners; C4A-03 owns its exhaustive malformed-shape matrix.
        _ = [planSemantics.count, categories.count, wishes.count, coolingOff.count, insights.count,
             reflections.count, reminders.count, occurrences.count]
        try requireUnique(expenses.map(\.id))
        try requireUnique(incomes.map(\.id))
        try requireUnique(plans.map(\.id))
        try requireUnique(merchants.map(\.id))
        try requireUnique(merchantContexts.map(\.merchantID))
        try requireUnique(savingsGoals.map(\.id))
        try requireUnique(recurringRules.map(\.id))
        try requireUnique(recurringRules.map(\.originExpenseID))
        try requireUnique(allocations.map(\.id))
        try requireUnique(allocations.map(\.incomeID))
        try requireUnique(categories.map(\.id))
        try requireUnique(wishes.map(\.id))
        try requireUnique(coolingOff.map(\.id))
        try requireUnique(insights.map(\.id))
        try requireUnique(reflections.map(\.id))
        try requireUnique(reminders.map(\.id))
        try requireUnique(occurrences.map(\.id))
        try requireUnique(planSemantics.map(\.planID))
        try requireUnique(insights.map(\.dedupeKey))
        try requireUnique(occurrences.map(\.occurrenceKey))

        var financialCurrencies = try Set(expenses.map(validateExpense)).union(incomes.map(validateIncome))
        for plan in plans { financialCurrencies.insert(try validatePlan(plan)) }
        for goal in savingsGoals { financialCurrencies.insert(try validateGoal(goal)) }
        for rule in recurringRules { financialCurrencies.insert(try validateRecurring(rule)) }
        for allocation in allocations { try validateAllocation(allocation) }
        for wish in wishes { financialCurrencies.insert(try validateWish(wish)) }

        let incomeByID = Dictionary(uniqueKeysWithValues: incomes.map { ($0.id, $0) })
        let planByID = Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0) })
        let planIDs = Set(planByID.keys)
        var categoryKeys = Set<String>()
        for category in categories {
            guard category.limitMinorUnits >= 0,
                  let plan = category.plan,
                  planIDs.contains(plan.id),
                  ExpenseCategory(rawValue: category.categoryRaw) != nil,
                  categoryKeys.insert("\(plan.id.uuidString):\(category.categoryRaw)").inserted else {
                throw Error.invalidPersistedAmount
            }
        }
        for semantics in planSemantics where !planIDs.contains(semantics.planID) {
            throw Error.invalidPersistedAmount
        }
        for allocation in allocations {
            guard let income = incomeByID[allocation.incomeID] else {
                throw Error.invalidPersistedAmount
            }
            let (allocated, overflow) = allocation.allocatedToBudgetMinorUnits.addingReportingOverflow(
                allocation.allocatedToSavingsMinorUnits
            )
            guard !overflow, allocated <= income.amountMinorUnits else {
                throw Error.invalidPersistedAmount
            }
            if allocation.allocatedToBudgetMinorUnits == 0 {
                guard allocation.budgetPlanID == nil else { throw Error.invalidPersistedAmount }
            } else {
                guard let planID = allocation.budgetPlanID,
                      let plan = planByID[planID],
                      plan.currencyCode == income.currencyCode,
                      plan.cycleStart <= income.receivedAt,
                      income.receivedAt < plan.cycleEnd else {
                    throw Error.invalidPersistedAmount
                }
            }
        }
        // Occurrence and reflection IDs are durable historical provenance, not required live
        // relationships: normal deletion intentionally leaves them intact. The same applies to a
        // recurring rule's origin expense. Only live companion/ownership relationships above are
        // migration-blocking references.
        for insight in insights { financialCurrencies.formUnion(try validateInsight(insight)) }
        guard financialCurrencies.count <= 1 else { throw Error.mixedAccountingCurrency }

        // Build an entire repair plan before mutating anything. A malformed merchant never gets
        // partially rewritten to zero or a guessed currency.
        let plannedMerchants = try merchantPlans(from: expenses)
        let existingByNormalizedName = try uniqueMerchantMap(merchants)
        let existingContexts = try uniqueContextMap(merchantContexts)
        // Merchant is a rebuildable cache. Historical stores may legitimately contain a ledger
        // fact without the corresponding cache row (the accepted V1 migration fixture proves this
        // shape). Preserve that absence rather than inventing a UUID; only a stored Merchant amount
        // needs a proven expense plan and explicit companion currency.
        guard Set(existingByNormalizedName.keys).isSubset(of: Set(plannedMerchants.keys)),
              existingContexts.keys.allSatisfy({ merchantID in merchants.contains(where: { $0.id == merchantID }) }) else {
            throw Error.invalidMerchantAggregate
        }
        for merchant in merchants {
            guard let plan = plannedMerchants[merchant.normalizedName] else {
                throw Error.invalidMerchantAggregate
            }
            merchant.totalMinorUnitsAllTime = plan.totalMinorUnits
            if let contextRecord = existingContexts[merchant.id] {
                contextRecord.currencyCode = plan.currencyCode
            } else {
                context.insert(MerchantAccountingContext(merchantID: merchant.id, currencyCode: plan.currencyCode))
            }
        }
        try context.save()
    }

    private struct MerchantPlan {
        let normalizedName: String
        let totalMinorUnits: Int64
        let currencyCode: String
    }

    private static func merchantPlans(from expenses: [Expense]) throws -> [String: MerchantPlan] {
        let grouped = Dictionary(grouping: expenses.compactMap { expense -> (String, Expense)? in
            guard let key = expense.normalizedMerchantName else { return nil }
            return (key, expense)
        }, by: \.0)
        var plans: [String: MerchantPlan] = [:]
        for (key, pairs) in grouped {
            let values = pairs.map(\.1)
            guard let currencyCode = values.first?.currencyCode,
                  values.allSatisfy({ $0.currencyCode == currencyCode }),
                  Money.isSupported(currencyCode) else { throw Error.mixedAccountingCurrency }
            var total: Int64 = 0
            for expense in values {
                _ = try validateExpense(expense)
                let (next, overflow) = total.addingReportingOverflow(expense.amountMinorUnits)
                guard !overflow else { throw Error.invalidMerchantAggregate }
                total = next
            }
            plans[key] = MerchantPlan(
                normalizedName: key,
                totalMinorUnits: total,
                currencyCode: currencyCode
            )
        }
        return plans
    }

    @discardableResult
    private static func validateExpense(_ expense: Expense) throws -> String {
        guard Money.isSupported(expense.currencyCode) else { throw Error.unsupportedCurrency }
        guard expense.amountMinorUnits > 0,
              expense.amountMinorUnits <= Money.maximumMinorUnits(for: expense.currencyCode) else { throw Error.invalidPersistedAmount }
        return expense.currencyCode
    }

    @discardableResult
    private static func validateIncome(_ income: Income) throws -> String {
        guard Money.isSupported(income.currencyCode) else { throw Error.unsupportedCurrency }
        guard income.amountMinorUnits > 0,
              income.amountMinorUnits <= Money.maximumMinorUnits(for: income.currencyCode) else { throw Error.invalidPersistedAmount }
        return income.currencyCode
    }

    private static func validatePlan(_ plan: BudgetPlan) throws -> String {
        guard Money.isSupported(plan.currencyCode),
              [plan.monthlyIncomeMinorUnits, plan.totalBudgetMinorUnits, plan.fixedExpensesMinorUnits, plan.savingGoalMinorUnits].allSatisfy({ $0 >= 0 }) else { throw Error.invalidPersistedAmount }
        return plan.currencyCode
    }

    private static func validateGoal(_ goal: SavingsGoal) throws -> String {
        guard Money.isSupported(goal.currencyCode),
              goal.targetMinorUnits >= 0,
              goal.startingBalanceMinorUnits >= 0,
              goal.targetMinorUnits <= Money.maximumMinorUnits(for: goal.currencyCode),
              goal.startingBalanceMinorUnits <= Money.maximumMinorUnits(for: goal.currencyCode) else { throw Error.invalidPersistedAmount }
        return goal.currencyCode
    }

    private static func validateRecurring(_ rule: RecurringFixedExpenseRule) throws -> String {
        guard Money.isSupported(rule.currencyCode),
              rule.amountMinorUnits > 0,
              rule.amountMinorUnits <= Money.maximumMinorUnits(for: rule.currencyCode) else { throw Error.invalidPersistedAmount }
        return rule.currencyCode
    }

    private static func validateAllocation(_ allocation: IncomeAllocation) throws {
        guard allocation.allocatedToBudgetMinorUnits >= 0, allocation.allocatedToSavingsMinorUnits >= 0 else { throw Error.invalidPersistedAmount }
    }

    private static func validateWish(_ wish: WishItem) throws -> String {
        guard Money.isSupported(wish.currencyCode) else { throw Error.unsupportedCurrency }
        guard wish.estimatedPriceMinorUnits.map({ (1...Money.maximumMinorUnits(for: wish.currencyCode)).contains($0) }) ?? true else {
            throw Error.invalidPersistedAmount
        }
        return wish.currencyCode
    }

    private static func requireUnique<Value: Hashable>(_ values: [Value]) throws {
        guard Set(values).count == values.count else { throw Error.duplicateIdentity }
    }

    private static func uniqueMerchantMap(_ merchants: [Merchant]) throws -> [String: Merchant] {
        var result: [String: Merchant] = [:]
        for merchant in merchants {
            guard !merchant.normalizedName.isEmpty,
                  result[merchant.normalizedName] == nil else { throw Error.duplicateIdentity }
            result[merchant.normalizedName] = merchant
        }
        return result
    }

    private static func uniqueContextMap(_ contexts: [MerchantAccountingContext]) throws -> [UUID: MerchantAccountingContext] {
        var result: [UUID: MerchantAccountingContext] = [:]
        for context in contexts {
            guard result[context.merchantID] == nil else { throw Error.duplicateIdentity }
            result[context.merchantID] = context
        }
        return result
    }

    private static func validateInsight(_ insight: SpendingInsight) throws -> Set<String> {
        guard let data = insight.payloadJSON.data(using: .utf8),
              let payload = try? SettingsCodec.decode([String: InsightValue].self, from: data) else {
            throw Error.invalidPersistedAmount
        }
        var currencies = Set<String>()
        for value in payload.values {
            if case let .money(money) = value {
                guard Money.isSupported(money.currencyCode) else { throw Error.invalidPersistedAmount }
                currencies.insert(money.currencyCode)
            }
        }
        return currencies
    }
}
