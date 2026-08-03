import Foundation
import Testing
@testable import MindBudget

struct ModelContractTests {
    @Test
    func categoryDefaultsMatchTheBudgetContract() {
        let fixed: Set<ExpenseCategory> = [.rent, .utilities, .subscriptions, .education, .health]

        for category in ExpenseCategory.allCases {
            #expect(category.defaultBucket == (fixed.contains(category) ? .fixed : .discretionary))
        }
    }

    @Test
    func wishItemStateMachineAcceptsDocumentedTransitions() throws {
        try WishItemStateMachine.validateTransition(from: .active, to: .coolingOff)
        try WishItemStateMachine.validateTransition(from: .coolingOff, to: .readyToReview)
        try WishItemStateMachine.validateTransition(from: .readyToReview, to: .active)
        try WishItemStateMachine.validateTransition(from: .purchased, to: .archived)
        try WishItemStateMachine.validateTransition(from: .skipped, to: .active)
        try WishItemStateMachine.validateTransition(from: .archived, to: .active)
    }

    @Test
    func wishItemStateMachineRejectsIllegalTransition() {
        #expect(
            throws: WishItemTransitionError.invalidTransition(from: .purchased, to: .active)
        ) {
            try WishItemStateMachine.validateTransition(from: .purchased, to: .active)
        }
    }

    @Test
    func quietHoursSupportsRangesThatCrossMidnight() throws {
        let quietHours = try QuietHours(startHour: 21, endHour: 9)

        #expect(quietHours.contains(hour: 21))
        #expect(quietHours.contains(hour: 2))
        #expect(!quietHours.contains(hour: 9))
        #expect(!quietHours.contains(hour: 14))
        #expect(throws: QuietHoursError.identicalBounds) {
            _ = try QuietHours(startHour: 9, endHour: 9)
        }
    }
}
