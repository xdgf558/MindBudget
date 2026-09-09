import Foundation

// Exact, gate-compared declarations for unreachable DataActor entry points. Do not pull in
// NotificationScheduler / AppIntents / sample-generation runtimes merely to resolve these DTOs.
struct IntentExpenseWriteResult: Equatable, Sendable {
    let expense: ExpenseSummary
    let wasDuplicate: Bool
}

struct CoolingNotificationCandidate: Equatable, Sendable {
    let planID: UUID
    let wishItemID: UUID
    let itemName: String
    let reviewAt: Date
    let durationHours: Int
    let status: CoolingOffStatus
    let outcome: CoolingOffOutcome?
    let notificationIdentifier: String?
}

struct CoolingNotificationCandidateBatch: Equatable, Sendable {
    let candidates: [CoolingNotificationCandidate]
    let invalidPlanIDs: [UUID]

    var containsInvalidData: Bool {
        !invalidPlanIDs.isEmpty
    }
}

struct CoolingNotificationIdentifierUpdate: Equatable, Sendable {
    let planID: UUID
    let identifier: String?
}

struct SampleDataBundle: Sendable {
    let expenses: [ExpenseDraft]
    let budgetPlans: [BudgetPlanDraft]
    let wishItems: [WishItemDraft]
    let coolingOffPlans: [CoolingOffPlanDraft]
}

enum CoolingNotificationIdentifier {
    static let prefix = "mindbudget.cooling-off."

    static func requestID(for planID: UUID) -> String {
        prefix + planID.uuidString.lowercased()
    }

    static func scopeKey(for planID: UUID) -> String {
        "coolingOff:\(planID.uuidString.lowercased())"
    }
}
