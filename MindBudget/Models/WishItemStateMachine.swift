import Foundation

enum WishItemTransitionError: Error, Equatable, Sendable {
    case invalidTransition(from: WishItemStatus, to: WishItemStatus)
}

enum WishItemStateMachine {
    static func validateTransition(from current: WishItemStatus, to next: WishItemStatus) throws {
        guard current != next, allowedTransitions[current, default: []].contains(next) else {
            throw WishItemTransitionError.invalidTransition(from: current, to: next)
        }
    }

    private static let allowedTransitions: [WishItemStatus: Set<WishItemStatus>] = [
        .active: [.coolingOff, .purchased, .skipped, .archived],
        .coolingOff: [.readyToReview, .purchased, .skipped, .archived],
        .readyToReview: [.purchased, .skipped, .active, .archived],
        .purchased: [.archived],
        .skipped: [.archived, .active],
        .archived: [.active]
    ]
}
