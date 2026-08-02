import Foundation

enum SampleDataScenario: String, CaseIterable, Sendable {
    case newUser
    case threeMonthHistory
    case endOfCycle
    case overspent
}

enum SampleDataError: Error, Equatable, Sendable {
    case unsupportedCurrency(String)
    case dateCalculationFailed
}

struct SampleDataBundle: Sendable {
    let expenses: [ExpenseDraft]
    let budgetPlans: [BudgetPlanDraft]
    let wishItems: [WishItemDraft]
    let coolingOffPlans: [CoolingOffPlanDraft]
}

enum SampleDataFactory {
    static func make(
        scenario: SampleDataScenario,
        referenceDate: Date,
        calendar: Calendar,
        currencyCode: String
    ) throws -> SampleDataBundle {
        guard Money.isSupported(currencyCode) else {
            throw SampleDataError.unsupportedCurrency(currencyCode)
        }

        switch scenario {
        case .newUser:
            return SampleDataBundle(expenses: [], budgetPlans: [], wishItems: [], coolingOffPlans: [])
        case .threeMonthHistory:
            return try threeMonthHistory(
                referenceDate: referenceDate,
                calendar: calendar,
                currencyCode: currencyCode
            )
        case .endOfCycle:
            return try endOfCycle(
                referenceDate: referenceDate,
                calendar: calendar,
                currencyCode: currencyCode
            )
        case .overspent:
            return try overspent(
                referenceDate: referenceDate,
                calendar: calendar,
                currencyCode: currencyCode
            )
        }
    }

    private static func threeMonthHistory(
        referenceDate: Date,
        calendar: Calendar,
        currencyCode: String
    ) throws -> SampleDataBundle {
        var plans: [BudgetPlanDraft] = []
        var expenses: [ExpenseDraft] = []

        for offset in -2...0 {
            let interval = try monthInterval(offset: offset, from: referenceDate, calendar: calendar)
            plans.append(plan(interval: interval, currencyCode: currencyCode, createdAt: referenceDate))

            guard let firstExpenseDate = calendar.date(byAdding: .day, value: 4, to: interval.start),
                  let secondExpenseDate = calendar.date(byAdding: .day, value: 12, to: interval.start) else {
                throw SampleDataError.dateCalculationFailed
            }
            expenses.append(
                expense(
                    amountMajorUnits: Decimal(42 + offset + 2),
                    currencyCode: currencyCode,
                    category: .groceries,
                    merchantName: "Neighborhood Market",
                    spentAt: firstExpenseDate,
                    calendar: calendar
                )
            )
            expenses.append(
                expense(
                    amountMajorUnits: Decimal(18 + offset + 2),
                    currencyCode: currencyCode,
                    category: .transport,
                    merchantName: nil,
                    spentAt: secondExpenseDate,
                    calendar: calendar
                )
            )
        }

        guard let reviewAt = calendar.date(byAdding: .hour, value: 24, to: referenceDate) else {
            throw SampleDataError.dateCalculationFailed
        }
        let wishId = UUID()
        let wish = WishItemDraft(
            id: wishId,
            name: "Noise-cancelling headphones",
            estimatedPrice: Money(decimal: 180, currencyCode: currencyCode),
            currencyCode: currencyCode,
            category: .electronics,
            reason: .convenience,
            emotionTag: nil,
            sourceContextLabel: nil,
            createdAt: referenceDate,
            updatedAt: referenceDate,
            coolingOffHours: 24,
            targetReviewDate: reviewAt,
            status: .coolingOff,
            notes: nil,
            purchasedExpenseId: nil
        )
        let coolingOff = CoolingOffPlanDraft(
            id: UUID(),
            wishItemId: wishId,
            startedAt: referenceDate,
            reviewAt: reviewAt,
            durationHours: 24,
            status: .active,
            notificationIdentifier: nil,
            completedAt: nil,
            outcome: nil
        )

        return SampleDataBundle(
            expenses: expenses,
            budgetPlans: plans,
            wishItems: [wish],
            coolingOffPlans: [coolingOff]
        )
    }

    private static func endOfCycle(
        referenceDate: Date,
        calendar: Calendar,
        currencyCode: String
    ) throws -> SampleDataBundle {
        let interval = try monthInterval(offset: 0, from: referenceDate, calendar: calendar)
        guard let expenseDate = calendar.date(byAdding: .hour, value: -2, to: interval.end) else {
            throw SampleDataError.dateCalculationFailed
        }
        return SampleDataBundle(
            expenses: [
                expense(
                    amountMajorUnits: 65,
                    currencyCode: currencyCode,
                    category: .food,
                    merchantName: "Dinner",
                    spentAt: expenseDate,
                    calendar: calendar
                )
            ],
            budgetPlans: [plan(interval: interval, currencyCode: currencyCode, createdAt: referenceDate)],
            wishItems: [],
            coolingOffPlans: []
        )
    }

    private static func overspent(
        referenceDate: Date,
        calendar: Calendar,
        currencyCode: String
    ) throws -> SampleDataBundle {
        let interval = try monthInterval(offset: 0, from: referenceDate, calendar: calendar)
        guard let firstDate = calendar.date(byAdding: .day, value: 2, to: interval.start),
              let secondDate = calendar.date(byAdding: .day, value: 8, to: interval.start) else {
            throw SampleDataError.dateCalculationFailed
        }
        let overspentPlan = BudgetPlanDraft(
            id: UUID(),
            cycleStart: interval.start,
            cycleEnd: interval.end,
            currencyCode: currencyCode,
            monthlyIncomeMinorUnits: Money(decimal: 1_000, currencyCode: currencyCode).minorUnits,
            totalBudgetMinorUnits: Money(decimal: 1_000, currencyCode: currencyCode).minorUnits,
            fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0,
            createdAt: referenceDate,
            updatedAt: referenceDate,
            categoryBudgets: []
        )
        return SampleDataBundle(
            expenses: [
                expense(
                    amountMajorUnits: 700,
                    currencyCode: currencyCode,
                    category: .shopping,
                    merchantName: nil,
                    spentAt: firstDate,
                    calendar: calendar
                ),
                expense(
                    amountMajorUnits: 500,
                    currencyCode: currencyCode,
                    category: .travel,
                    merchantName: nil,
                    spentAt: secondDate,
                    calendar: calendar
                )
            ],
            budgetPlans: [overspentPlan],
            wishItems: [],
            coolingOffPlans: []
        )
    }

    private static func monthInterval(
        offset: Int,
        from referenceDate: Date,
        calendar: Calendar
    ) throws -> DateInterval {
        guard let month = calendar.date(byAdding: .month, value: offset, to: referenceDate),
              let interval = calendar.dateInterval(of: .month, for: month) else {
            throw SampleDataError.dateCalculationFailed
        }
        return interval
    }

    private static func plan(
        interval: DateInterval,
        currencyCode: String,
        createdAt: Date
    ) -> BudgetPlanDraft {
        BudgetPlanDraft(
            id: UUID(),
            cycleStart: interval.start,
            cycleEnd: interval.end,
            currencyCode: currencyCode,
            monthlyIncomeMinorUnits: Money(decimal: 4_000, currencyCode: currencyCode).minorUnits,
            totalBudgetMinorUnits: Money(decimal: 3_000, currencyCode: currencyCode).minorUnits,
            fixedExpensesMinorUnits: Money(decimal: 1_200, currencyCode: currencyCode).minorUnits,
            savingGoalMinorUnits: Money(decimal: 500, currencyCode: currencyCode).minorUnits,
            createdAt: createdAt,
            updatedAt: createdAt,
            categoryBudgets: [
                CategoryBudgetDraft(
                    id: UUID(),
                    category: .food,
                    limitMinorUnits: Money(decimal: 600, currencyCode: currencyCode).minorUnits,
                    warningThresholdBasisPoints: 8_000,
                    createdAt: createdAt,
                    updatedAt: createdAt
                )
            ]
        )
    }

    private static func expense(
        amountMajorUnits: Decimal,
        currencyCode: String,
        category: ExpenseCategory,
        merchantName: String?,
        spentAt: Date,
        calendar: Calendar
    ) -> ExpenseDraft {
        ExpenseDraft(
            id: UUID(),
            amount: Money(decimal: amountMajorUnits, currencyCode: currencyCode),
            category: category,
            bucket: category.defaultBucket,
            merchantName: merchantName,
            note: nil,
            spentAt: spentAt,
            spentTimeZoneIdentifier: calendar.timeZone.identifier,
            createdAt: spentAt,
            updatedAt: spentAt,
            paymentMethod: nil,
            emotionTag: nil,
            purchaseReason: nil,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }
}
