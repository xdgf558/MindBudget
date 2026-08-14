import Foundation
@preconcurrency import UserNotifications

/// StoreKit-verified facts for an introductory free trial that is active now.
///
/// This projection is process-local entitlement evidence. It is never reconstructed from the
/// presentation cache, a configured seven-day fixture, or a locally persisted unlock.
struct TrialLifecycleProjection: Equatable, Sendable {
    let productID: StoreProductID
    let renewalDate: Date?
    let willAutoRenew: Bool
}

enum TrialLifecyclePresentation {
    /// Product identity is interpreted only inside Commerce. Feature/App layers receive the
    /// already-matched live display value and cannot create a second product-ID decision path.
    static func liveDisplayPrice(
        for trial: TrialLifecycleProjection,
        catalog: StoreCatalogAvailability
    ) -> String? {
        guard case let .live(snapshot) = catalog else { return nil }
        return snapshot.products.first { $0.id == trial.productID }?.displayPrice
    }
}

enum TrialRenewalReminderIdentifier {
    static let requestID = "mindbudget.commerce.trial-renewal"
    static let advanceDayCount = 5
}

struct TrialRenewalNotificationRequest: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
    let dateComponents: DateComponents
}

protocol TrialRenewalNotificationCenterClient: Sendable {
    func authorizationState() async -> NotificationAuthorizationState
    func add(_ request: TrialRenewalNotificationRequest) async throws
    func removePendingRequest(withIdentifier identifier: String) async
}

enum TrialRenewalReminderDelivery: Equatable, Sendable {
    case inactive
    case inAppOnly
    case scheduled(Date)
}

struct TrialRenewalReminderReconciliation: Equatable, Sendable {
    let authorizationState: NotificationAuthorizationState
    let delivery: TrialRenewalReminderDelivery

    static let inactive = TrialRenewalReminderReconciliation(
        authorizationState: .notDetermined,
        delivery: .inactive
    )
}

protocol TrialLifecycleScheduling: Sendable {
    /// Reconciles one stable pending request. This never asks for notification permission.
    func reconcile(
        trial: TrialLifecycleProjection?,
        notificationsEnabled: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> TrialRenewalReminderReconciliation
}

actor TrialLifecycleScheduler: TrialLifecycleScheduling {
    private let center: any TrialRenewalNotificationCenterClient
    /// Notification-center mutations are ordered even though this actor can re-enter at every
    /// center await. The newest reconciliation therefore always runs after, and supersedes, every
    /// older add/remove operation instead of letting an old add land after a newer cancellation.
    private var reconciliationTail: Task<Void, Never>?
    private var reconciliationSequence = 0

    init(center: any TrialRenewalNotificationCenterClient = SystemTrialRenewalNotificationCenter()) {
        self.center = center
    }

    func reconcile(
        trial: TrialLifecycleProjection?,
        notificationsEnabled: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> TrialRenewalReminderReconciliation {
        reconciliationSequence += 1
        let sequence = reconciliationSequence
        let predecessor = reconciliationTail
        let operation = Task { [center] in
            await predecessor?.value
            return try await Self.performReconciliation(
                center: center,
                trial: trial,
                notificationsEnabled: notificationsEnabled,
                now: now,
                calendar: calendar,
                locale: locale
            )
        }
        reconciliationTail = Task {
            _ = try? await operation.value
        }

        do {
            let result = try await operation.value
            if sequence == reconciliationSequence {
                reconciliationTail = nil
            }
            return result
        } catch {
            if sequence == reconciliationSequence {
                reconciliationTail = nil
            }
            throw error
        }
    }

    private static func performReconciliation(
        center: any TrialRenewalNotificationCenterClient,
        trial: TrialLifecycleProjection?,
        notificationsEnabled: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> TrialRenewalReminderReconciliation {
        let authorizationState = await center.authorizationState()
        guard let trial,
              trial.willAutoRenew,
              let renewalDate = trial.renewalDate,
              renewalDate > now else {
            await center.removePendingRequest(
                withIdentifier: TrialRenewalReminderIdentifier.requestID
            )
            return TrialRenewalReminderReconciliation(
                authorizationState: authorizationState,
                delivery: .inactive
            )
        }

        guard let scheduledFor = calendar.date(
            byAdding: .day,
            value: -TrialRenewalReminderIdentifier.advanceDayCount,
            to: renewalDate
        ), scheduledFor > now else {
            await center.removePendingRequest(
                withIdentifier: TrialRenewalReminderIdentifier.requestID
            )
            return TrialRenewalReminderReconciliation(
                authorizationState: authorizationState,
                delivery: .inAppOnly
            )
        }

        guard notificationsEnabled, authorizationState.permitsScheduling else {
            await center.removePendingRequest(
                withIdentifier: TrialRenewalReminderIdentifier.requestID
            )
            return TrialRenewalReminderReconciliation(
                authorizationState: authorizationState,
                delivery: .inAppOnly
            )
        }

        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: scheduledFor
        )
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        // Remove first so a failed replacement cannot leave a stale date or product switch
        // reminder pending. The stable identifier still makes successful replacement idempotent.
        await center.removePendingRequest(
            withIdentifier: TrialRenewalReminderIdentifier.requestID
        )
        try await center.add(
            TrialRenewalNotificationRequest(
                identifier: TrialRenewalReminderIdentifier.requestID,
                title: LocalizedCatalog.string(
                    "notification.trialRenewal.title",
                    locale: locale
                ),
                body: LocalizedCatalog.string(
                    "notification.trialRenewal.body",
                    locale: locale
                ),
                dateComponents: components
            )
        )
        return TrialRenewalReminderReconciliation(
            authorizationState: authorizationState,
            delivery: .scheduled(scheduledFor)
        )
    }
}

actor SystemTrialRenewalNotificationCenter: TrialRenewalNotificationCenterClient {
    private let center = UNUserNotificationCenter.current()

    func authorizationState() async -> NotificationAuthorizationState {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .ephemeral: return .ephemeral
        @unknown default: return .denied
        }
    }

    func add(_ request: TrialRenewalNotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.userInfo = ["commerceReminder": "trialRenewal"]
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: request.dateComponents,
            repeats: false
        )
        try await center.add(
            UNNotificationRequest(
                identifier: request.identifier,
                content: content,
                trigger: trigger
            )
        )
    }

    func removePendingRequest(withIdentifier identifier: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

struct NoopTrialLifecycleScheduler: TrialLifecycleScheduling, Sendable {
    func reconcile(
        trial: TrialLifecycleProjection?,
        notificationsEnabled: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> TrialRenewalReminderReconciliation {
        .inactive
    }
}
