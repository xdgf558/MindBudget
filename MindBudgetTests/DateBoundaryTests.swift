import Foundation
import Testing
@testable import MindBudget

struct DateBoundaryTests {
    private let calculator = BudgetCycleCalculator()

    @Test
    func naturalMonthUsesHalfOpenCalendarBoundaries() throws {
        let calendar = TestFixtures.utcCalendar
        let interval = try calculator.interval(
            containing: date(2026, 1, 20, calendar: calendar),
            startDay: 1,
            calendar: calendar
        )

        #expect(interval.start == date(2026, 1, 1, calendar: calendar))
        #expect(interval.end == date(2026, 2, 1, calendar: calendar))
    }

    @Test
    func customStartDayCanReachIntoPreviousMonth() throws {
        let calendar = TestFixtures.utcCalendar
        let interval = try calculator.interval(
            containing: date(2026, 1, 10, calendar: calendar),
            startDay: 25,
            calendar: calendar
        )

        #expect(interval.start == date(2025, 12, 25, calendar: calendar))
        #expect(interval.end == date(2026, 1, 25, calendar: calendar))
    }

    @Test
    func startDay31ClampsToFebruaryThenReturnsToMarch31() throws {
        let calendar = TestFixtures.utcCalendar
        let february = try calculator.interval(
            containing: date(2026, 2, 15, calendar: calendar),
            startDay: 31,
            calendar: calendar
        )
        let march = try calculator.interval(
            containing: date(2026, 3, 1, calendar: calendar),
            startDay: 31,
            calendar: calendar
        )

        #expect(february.start == date(2026, 1, 31, calendar: calendar))
        #expect(february.end == date(2026, 2, 28, calendar: calendar))
        #expect(march.start == date(2026, 2, 28, calendar: calendar))
        #expect(march.end == date(2026, 3, 31, calendar: calendar))
    }

    @Test
    func leapYearClampsToFebruary29() throws {
        let calendar = TestFixtures.utcCalendar
        let interval = try calculator.interval(
            containing: date(2028, 2, 20, calendar: calendar),
            startDay: 31,
            calendar: calendar
        )

        #expect(interval.start == date(2028, 1, 31, calendar: calendar))
        #expect(interval.end == date(2028, 2, 29, calendar: calendar))
    }

    @Test
    func springForwardKeepsLocalCalendarBoundaries() throws {
        let calendar = TestFixtures.losAngelesCalendar
        let interval = try calculator.interval(
            containing: date(2024, 3, 10, hour: 12, calendar: calendar),
            startDay: 10,
            calendar: calendar
        )
        let expectedStart = date(2024, 3, 10, calendar: calendar)
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: expectedStart))

        #expect(interval.start == expectedStart)
        #expect(interval.end == date(2024, 4, 10, calendar: calendar))
        #expect(nextDay.timeIntervalSince(expectedStart) == 23 * 60 * 60)
        #expect(calendar.dateComponents([.day], from: interval.start, to: interval.end).day == 31)
    }

    @Test
    func fallBackKeepsLocalCalendarBoundaries() throws {
        let calendar = TestFixtures.losAngelesCalendar
        let interval = try calculator.interval(
            containing: date(2024, 11, 3, hour: 12, calendar: calendar),
            startDay: 3,
            calendar: calendar
        )
        let expectedStart = date(2024, 11, 3, calendar: calendar)
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: expectedStart))

        #expect(interval.start == expectedStart)
        #expect(interval.end == date(2024, 12, 3, calendar: calendar))
        #expect(nextDay.timeIntervalSince(expectedStart) == 25 * 60 * 60)
        #expect(calendar.dateComponents([.day], from: interval.start, to: interval.end).day == 30)
    }

    @Test
    func recordedHourUsesTheExpenseTimeZone() throws {
        let losAngeles = TestFixtures.losAngelesCalendar
        let spentAt = date(2026, 1, 15, hour: 23, minute: 30, calendar: losAngeles)

        let hour = try calculator.recordedLocalHour(
            at: spentAt,
            timeZoneIdentifier: "America/Los_Angeles",
            calendar: TestFixtures.utcCalendar
        )

        #expect(hour == 23)
    }

    @Test
    func invalidStartDayAndTimeZoneAreRejected() throws {
        let calendar = TestFixtures.utcCalendar

        #expect(throws: BudgetCycleError.invalidStartDay(0)) {
            _ = try calculator.interval(
                containing: date(2026, 1, 1, calendar: calendar),
                startDay: 0,
                calendar: calendar
            )
        }
        #expect(throws: BudgetCycleError.invalidTimeZone("Not/AZone")) {
            _ = try calculator.recordedLocalHour(
                at: date(2026, 1, 1, calendar: calendar),
                timeZoneIdentifier: "Not/AZone",
                calendar: calendar
            )
        }
    }

    @Test
    func cycleAdvanceRequiresBothTransitionAndFirstRegularConfirmation() throws {
        let calendar = TestFixtures.utcCalendar
        let original = DateInterval(
            start: date(2026, 1, 1, calendar: calendar),
            end: date(2026, 2, 1, calendar: calendar)
        )

        let transition = try calculator.nextCycle(
            after: original,
            startDay: 15,
            calendar: calendar
        )
        #expect(transition.confirmationReason == .transition)
        #expect(transition.interval.start == original.end)
        #expect(transition.interval.end == date(2026, 2, 15, calendar: calendar))

        let firstRegular = try calculator.nextCycle(
            after: transition.interval,
            startDay: 15,
            calendar: calendar
        )
        #expect(firstRegular.confirmationReason == .firstRegularCycleAfterTransition)
        #expect(firstRegular.interval.start == date(2026, 2, 15, calendar: calendar))
        #expect(firstRegular.interval.end == date(2026, 3, 15, calendar: calendar))

        let following = try calculator.nextCycle(
            after: firstRegular.interval,
            startDay: 15,
            calendar: calendar
        )
        #expect(following.confirmationReason == nil)
        #expect(following.interval.start == date(2026, 3, 15, calendar: calendar))
        #expect(following.interval.end == date(2026, 4, 15, calendar: calendar))
    }

    @Test
    func lazyRollForwardCreatesContiguousCopiedPlans() async throws {
        let calendar = TestFixtures.utcCalendar
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.makeDataActor()
        let initial = plan(
            start: date(2026, 1, 1, calendar: calendar),
            end: date(2026, 2, 1, calendar: calendar),
            timestamp: date(2026, 1, 1, calendar: calendar)
        )
        _ = try await actor.createBudgetPlan(initial)

        let result = try await actor.ensurePlanCovering(
            date: date(2026, 4, 20, calendar: calendar),
            futureCycleStartDay: 1,
            calendar: calendar,
            timestamp: date(2026, 4, 20, calendar: calendar)
        )
        let plans = try await actor.fetchBudgetPlanSummaries()

        guard case let .covered(covered) = result else {
            Issue.record("Expected a covered future plan")
            return
        }
        #expect(plans.count == 4)
        #expect(covered.cycleStart == date(2026, 4, 1, calendar: calendar))
        #expect(covered.cycleEnd == date(2026, 5, 1, calendar: calendar))
        #expect(zip(plans, plans.dropFirst()).allSatisfy { pair in
            pair.0.cycleEnd == pair.1.cycleStart
        })
        #expect(plans.allSatisfy { $0.totalBudgetMinorUnits == initial.totalBudgetMinorUnits })
        #expect(plans.allSatisfy { $0.categoryBudgets.first?.limitMinorUnits == 60_000 })
        #expect(Set(plans.map(\.id)).count == plans.count)
    }

    @Test
    func transitionBudgetNeverPropagatesIntoTheFirstRegularCycle() async throws {
        let calendar = TestFixtures.utcCalendar
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let originalStart = date(2026, 1, 1, calendar: calendar)
        let originalEnd = date(2026, 2, 1, calendar: calendar)
        let initial = plan(
            start: originalStart,
            end: originalEnd,
            timestamp: originalStart
        )
        _ = try await actor.createBudgetPlan(initial)

        let transitionResult = try await actor.ensurePlanCovering(
            date: date(2026, 2, 20, calendar: calendar),
            futureCycleStartDay: 15,
            calendar: calendar,
            timestamp: date(2026, 2, 20, calendar: calendar)
        )
        var plans = try await actor.fetchBudgetPlanSummaries()

        guard case let .transitionPlanRequired(requirement) = transitionResult else {
            Issue.record("Expected an explicit transition-plan requirement")
            return
        }
        #expect(plans.count == 1)
        #expect(plans[0].cycleStart == originalStart)
        #expect(plans[0].cycleEnd == originalEnd)
        #expect(requirement.interval.start == originalEnd)
        #expect(requirement.interval.end == date(2026, 2, 15, calendar: calendar))
        #expect(requirement.firstRegularInterval.start == requirement.interval.end)
        #expect(requirement.firstRegularInterval.end == date(2026, 3, 15, calendar: calendar))
        #expect(requirement.precedingPlan.id == plans[0].id)
        #expect(requirement.futureCycleStartDay == 15)

        let confirmedTransition = plan(
            start: requirement.interval.start,
            end: requirement.interval.end,
            timestamp: date(2026, 2, 1, calendar: calendar),
            totalBudget: 210_000
        )
        _ = try await actor.createBudgetPlan(confirmedTransition)
        let firstRegularResult = try await actor.ensurePlanCovering(
            date: date(2026, 2, 20, calendar: calendar),
            futureCycleStartDay: 15,
            calendar: calendar,
            timestamp: date(2026, 2, 20, calendar: calendar)
        )
        plans = try await actor.fetchBudgetPlanSummaries()

        guard case let .firstRegularPlanRequired(firstRegularRequirement) = firstRegularResult else {
            Issue.record("Expected the first regular cycle to require its own budget")
            return
        }
        #expect(plans.count == 2)
        #expect(plans[1].cycleStart == originalEnd)
        #expect(plans[1].cycleEnd == date(2026, 2, 15, calendar: calendar))
        #expect(plans[1].totalBudgetMinorUnits == 210_000)
        #expect(firstRegularRequirement.interval == requirement.firstRegularInterval)
        #expect(firstRegularRequirement.futureCycleStartDay == 15)

        let confirmedFirstRegular = plan(
            start: firstRegularRequirement.interval.start,
            end: firstRegularRequirement.interval.end,
            timestamp: date(2026, 2, 15, calendar: calendar),
            totalBudget: 300_000
        )
        _ = try await actor.createBudgetPlan(confirmedFirstRegular)
        let coveredResult = try await actor.ensurePlanCovering(
            date: date(2026, 4, 20, calendar: calendar),
            futureCycleStartDay: 15,
            calendar: calendar,
            timestamp: date(2026, 4, 20, calendar: calendar)
        )
        plans = try await actor.fetchBudgetPlanSummaries()

        guard case let .covered(covered) = coveredResult else {
            Issue.record("Expected automatic coverage after both budgets were confirmed")
            return
        }
        #expect(plans.count == 5)
        #expect(plans.map(\.totalBudgetMinorUnits) == [300_000, 210_000, 300_000, 300_000, 300_000])
        #expect(covered.cycleStart == date(2026, 4, 15, calendar: calendar))
        #expect(covered.id == plans[4].id)
    }

    @Test
    func ensureCoverageDoesNotInventInitialOrHistoricalPlans() async throws {
        let calendar = TestFixtures.utcCalendar
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let target = date(2026, 1, 10, calendar: calendar)

        let unconfigured = try await actor.ensurePlanCovering(
            date: target,
            futureCycleStartDay: 1,
            calendar: calendar,
            timestamp: target
        )
        #expect(unconfigured == .unconfigured)

        _ = try await actor.createBudgetPlan(
            plan(
                start: date(2026, 2, 1, calendar: calendar),
                end: date(2026, 3, 1, calendar: calendar),
                timestamp: target
            )
        )
        let historical = try await actor.ensurePlanCovering(
            date: target,
            futureCycleStartDay: 1,
            calendar: calendar,
            timestamp: target
        )
        #expect(historical == .historicalPlanRequired)
        #expect(try await actor.fetchBudgetPlanSummaries().count == 1)
    }

    @Test
    func lazyRollForwardRejectsMoreThanTheAutomaticLimitAtomically() async throws {
        let calendar = TestFixtures.utcCalendar
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let initial = plan(
            start: date(2026, 1, 1, calendar: calendar),
            end: date(2026, 2, 1, calendar: calendar),
            timestamp: date(2026, 1, 1, calendar: calendar)
        )
        _ = try await actor.createBudgetPlan(initial)

        do {
            _ = try await actor.ensurePlanCovering(
                date: date(2099, 1, 1, calendar: calendar),
                futureCycleStartDay: 1,
                calendar: calendar,
                timestamp: date(2026, 1, 1, calendar: calendar)
            )
            Issue.record("Expected automatic generation to stop at its safety limit")
        } catch let error as BudgetCycleError {
            #expect(
                error == .generationLimitExceeded(
                    limit: BudgetPlanGenerationPolicy.maximumAutomaticPlans
                )
            )
        }

        #expect(try await actor.fetchBudgetPlanSummaries().count == 1)
    }

    @Test
    func overlapValidatorRejectsConflictingIntervals() throws {
        let calendar = TestFixtures.utcCalendar
        let first = summary(
            start: date(2026, 1, 1, calendar: calendar),
            end: date(2026, 2, 1, calendar: calendar)
        )
        let second = summary(
            start: date(2026, 1, 15, calendar: calendar),
            end: date(2026, 2, 15, calendar: calendar)
        )

        #expect(throws: BudgetCycleError.overlappingPlans) {
            try calculator.validateNonOverlapping([first, second])
        }
    }

    @Test
    func planFactoryRejectsReusedHistoricalIdentity() throws {
        let calendar = TestFixtures.utcCalendar
        let previous = BudgetPlanSummary(
            id: UUID(),
            cycleStart: date(2026, 1, 1, calendar: calendar),
            cycleEnd: date(2026, 2, 1, calendar: calendar),
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 400_000,
            totalBudgetMinorUnits: 300_000,
            fixedExpensesMinorUnits: 100_000,
            savingGoalMinorUnits: 50_000,
            categoryBudgets: [
                CategoryBudgetSummary(
                    id: UUID(),
                    category: .food,
                    limitMinorUnits: 60_000,
                    warningThresholdBasisPoints: 8_000
                )
            ]
        )
        let next = DateInterval(
            start: previous.cycleEnd,
            end: date(2026, 3, 1, calendar: calendar)
        )

        #expect(throws: BudgetPlanFactoryError.duplicateIdentity) {
            _ = try BudgetPlanFactory().makePlan(
                copying: previous,
                interval: next,
                planID: previous.id,
                categoryBudgetIDs: [UUID()],
                timestamp: previous.cycleEnd
            )
        }
        #expect(throws: BudgetPlanFactoryError.duplicateIdentity) {
            _ = try BudgetPlanFactory().makePlan(
                copying: previous,
                interval: next,
                planID: UUID(),
                categoryBudgetIDs: [previous.categoryBudgets[0].id],
                timestamp: previous.cycleEnd
            )
        }
    }

    private func plan(
        start: Date,
        end: Date,
        timestamp: Date,
        totalBudget: Int64 = 300_000
    ) -> BudgetPlanDraft {
        BudgetPlanDraft(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 400_000,
            totalBudgetMinorUnits: totalBudget,
            fixedExpensesMinorUnits: 100_000,
            savingGoalMinorUnits: 50_000,
            createdAt: timestamp,
            updatedAt: timestamp,
            categoryBudgets: [
                CategoryBudgetDraft(
                    id: UUID(),
                    category: .food,
                    limitMinorUnits: 60_000,
                    warningThresholdBasisPoints: 8_000,
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
            ]
        )
    }

    private func summary(start: Date, end: Date) -> BudgetPlanSummary {
        BudgetPlanSummary(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 400_000,
            totalBudgetMinorUnits: 300_000,
            fixedExpensesMinorUnits: 100_000,
            savingGoalMinorUnits: 50_000,
            categoryBudgets: []
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 0,
        minute: Int = 0,
        calendar: Calendar
    ) -> Date {
        let result = calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )
        precondition(result != nil, "Test date must be representable")
        return result!
    }
}
