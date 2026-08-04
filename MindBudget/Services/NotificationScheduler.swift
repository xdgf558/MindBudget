import Foundation
@preconcurrency import UserNotifications

enum NotificationAuthorizationState: String, Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    var permitsScheduling: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral: true
        case .notDetermined, .denied: false
        }
    }
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

struct DeliveredCoolingNotification: Equatable, Sendable {
    let planID: UUID
    let deliveredAt: Date
}

struct NotificationReconciliation: Equatable, Sendable {
    let authorizationState: NotificationAuthorizationState
    let identifierUpdates: [CoolingNotificationIdentifierUpdate]
    let deliveredNotifications: [DeliveredCoolingNotification]
    let scheduledCount: Int
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

struct LocalNotificationRequest: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
    let dateComponents: DateComponents
    let planID: UUID
    let wishItemID: UUID
}

struct DeliveredLocalNotification: Equatable, Sendable {
    let identifier: String
    let deliveredAt: Date
}

protocol LocalNotificationCenterClient: Sendable {
    func authorizationState() async -> NotificationAuthorizationState
    func requestAuthorization() async throws -> NotificationAuthorizationState
    func pendingRequestIdentifiers() async -> Set<String>
    func deliveredNotifications() async -> [DeliveredLocalNotification]
    func add(_ request: LocalNotificationRequest) async throws
    func removePendingRequests(withIdentifiers identifiers: [String]) async throws
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) async throws
    func removeAllNotifications() async throws
}

protocol NotificationScheduling: Sendable {
    func authorizationState() async -> NotificationAuthorizationState
    func requestAuthorization() async throws -> NotificationAuthorizationState
    func reconcile(
        candidates: [CoolingNotificationCandidate],
        preferences: PreferencesSnapshot,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> NotificationReconciliation
    func cancelAll() async throws
}

struct NotificationScheduler: NotificationScheduling, Sendable {
    private let center: any LocalNotificationCenterClient
    private let throttle: any ReminderThrottling

    init(
        center: any LocalNotificationCenterClient = SystemLocalNotificationCenter(),
        throttle: any ReminderThrottling = ReminderThrottle()
    ) {
        self.center = center
        self.throttle = throttle
    }

    func authorizationState() async -> NotificationAuthorizationState {
        await center.authorizationState()
    }

    func requestAuthorization() async throws -> NotificationAuthorizationState {
        try await center.requestAuthorization()
    }

    func reconcile(
        candidates: [CoolingNotificationCandidate],
        preferences: PreferencesSnapshot,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> NotificationReconciliation {
        let authorizationState = await center.authorizationState()
        let pendingIdentifiers = await center.pendingRequestIdentifiers()
        let delivered = await center.deliveredNotifications()
        let storedIdentifiers = Set(candidates.compactMap(\.notificationIdentifier))
        let appPendingIdentifiers = pendingIdentifiers.filter {
            $0.hasPrefix(CoolingNotificationIdentifier.prefix) || storedIdentifiers.contains($0)
        }
        let appDelivered = delivered.filter {
            $0.identifier.hasPrefix(CoolingNotificationIdentifier.prefix)
                || storedIdentifiers.contains($0.identifier)
        }

        guard preferences.notificationsEnabled, authorizationState.permitsScheduling else {
            try await center.removePendingRequests(withIdentifiers: Array(appPendingIdentifiers))
            try await center.removeDeliveredNotifications(
                withIdentifiers: appDelivered.map(\.identifier)
            )
            return NotificationReconciliation(
                authorizationState: authorizationState,
                identifierUpdates: candidates.compactMap { candidate in
                    candidate.notificationIdentifier == nil
                        ? nil
                        : CoolingNotificationIdentifierUpdate(
                            planID: candidate.planID,
                            identifier: nil
                        )
                },
                deliveredNotifications: [],
                scheduledCount: 0
            )
        }

        let deliveredByIdentifier = Dictionary(
            uniqueKeysWithValues: appDelivered.map { ($0.identifier, $0) }
        )
        var identifierUpdates: [CoolingNotificationIdentifierUpdate] = []
        var deliveredNotifications: [DeliveredCoolingNotification] = []
        var keptIdentifiers: Set<String> = []
        var deliveredIdentifiersToRemove: [String] = []
        var scheduledCount = 0

        for candidate in candidates {
            let stableIdentifier = CoolingNotificationIdentifier.requestID(for: candidate.planID)
            let knownIdentifiers = [candidate.notificationIdentifier, stableIdentifier].compactMap { $0 }
            if let deliveredNotification = knownIdentifiers.compactMap({
                deliveredByIdentifier[$0]
            }).first {
                deliveredNotifications.append(
                    DeliveredCoolingNotification(
                        planID: candidate.planID,
                        deliveredAt: deliveredNotification.deliveredAt
                    )
                )
                deliveredIdentifiersToRemove.append(deliveredNotification.identifier)
                if candidate.notificationIdentifier != nil {
                    identifierUpdates.append(
                        CoolingNotificationIdentifierUpdate(
                            planID: candidate.planID,
                            identifier: nil
                        )
                    )
                }
                continue
            }

            guard candidate.outcome == nil,
                  candidate.status == .active
                    || candidate.status == .scheduled
                    || candidate.status == .completed else {
                if candidate.notificationIdentifier != nil {
                    identifierUpdates.append(
                        CoolingNotificationIdentifierUpdate(
                            planID: candidate.planID,
                            identifier: nil
                        )
                    )
                }
                continue
            }

            let decision = throttle.decide(
                for: ReminderRequest(
                    kind: .coolingOffDue,
                    draft: nil,
                    requestedChannel: .notification,
                    requestedDeliveryDate: candidate.reviewAt
                ),
                history: [],
                preferences: preferences,
                now: now,
                calendar: calendar
            )
            guard decision.channel == .notification,
                  let scheduledFor = decision.scheduledFor,
                  scheduledFor > now else {
                if candidate.notificationIdentifier != nil {
                    identifierUpdates.append(
                        CoolingNotificationIdentifierUpdate(
                            planID: candidate.planID,
                            identifier: nil
                        )
                    )
                }
                continue
            }

            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: scheduledFor
            )
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            let copy = NotificationCopy.coolingOff(
                itemName: candidate.itemName,
                durationHours: candidate.durationHours,
                locale: locale
            )
            try await center.add(
                LocalNotificationRequest(
                    identifier: stableIdentifier,
                    title: copy.title,
                    body: copy.body,
                    dateComponents: components,
                    planID: candidate.planID,
                    wishItemID: candidate.wishItemID
                )
            )
            keptIdentifiers.insert(stableIdentifier)
            scheduledCount += 1
            if candidate.notificationIdentifier != stableIdentifier {
                identifierUpdates.append(
                    CoolingNotificationIdentifierUpdate(
                        planID: candidate.planID,
                        identifier: stableIdentifier
                    )
                )
            }
        }

        let stalePendingIdentifiers = appPendingIdentifiers.subtracting(keptIdentifiers)
        try await center.removePendingRequests(withIdentifiers: Array(stalePendingIdentifiers))
        try await center.removeDeliveredNotifications(
            withIdentifiers: deliveredIdentifiersToRemove
        )

        return NotificationReconciliation(
            authorizationState: authorizationState,
            identifierUpdates: identifierUpdates,
            deliveredNotifications: deliveredNotifications,
            scheduledCount: scheduledCount
        )
    }

    func cancelAll() async throws {
        try await center.removeAllNotifications()
    }
}

actor SystemLocalNotificationCenter: LocalNotificationCenterClient {
    private let center: UNUserNotificationCenter
    private let foregroundDelegate: MindBudgetNotificationDelegate

    init() {
        let center = UNUserNotificationCenter.current()
        let foregroundDelegate = MindBudgetNotificationDelegate()
        self.center = center
        self.foregroundDelegate = foregroundDelegate
        center.delegate = foregroundDelegate
    }

    func authorizationState() async -> NotificationAuthorizationState {
        let settings = await center.notificationSettings()
        return Self.map(settings.authorizationStatus)
    }

    func requestAuthorization() async throws -> NotificationAuthorizationState {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
        return await authorizationState()
    }

    func pendingRequestIdentifiers() async -> Set<String> {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: Set(requests.map(\.identifier)))
            }
        }
    }

    func deliveredNotifications() async -> [DeliveredLocalNotification] {
        await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                continuation.resume(
                    returning: notifications.map {
                        DeliveredLocalNotification(
                            identifier: $0.request.identifier,
                            deliveredAt: $0.date
                        )
                    }
                )
            }
        }
    }

    func add(_ request: LocalNotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.userInfo = [
            "coolingOffPlanID": request.planID.uuidString,
            "wishItemID": request.wishItemID.uuidString,
        ]
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

    func removePendingRequests(withIdentifiers identifiers: [String]) async throws {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) async throws {
        guard !identifiers.isEmpty else { return }
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removeAllNotifications() async throws {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    private static func map(_ status: UNAuthorizationStatus) -> NotificationAuthorizationState {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .authorized
        case .provisional: .provisional
        case .ephemeral: .ephemeral
        @unknown default: .denied
        }
    }
}

final class MindBudgetNotificationDelegate: NSObject, UNUserNotificationCenterDelegate,
    @unchecked Sendable {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard notification.request.identifier.hasPrefix(
            CoolingNotificationIdentifier.prefix
        ) else {
            return []
        }
        return [.banner, .list, .sound]
    }
}

private enum NotificationCopy {
    static func coolingOff(
        itemName: String,
        durationHours: Int,
        locale: Locale
    ) -> (title: String, body: String) {
        let sanitizedName = sanitizedItemName(itemName)
        let safeName = sanitizedName.isEmpty
            ? localizedString("notification.cooling.itemFallback", locale: locale)
            : sanitizedName
        return (
            String(
                format: localizedString("notification.cooling.title", locale: locale),
                locale: locale,
                safeName
            ),
            String(
                format: localizedString("notification.cooling.body", locale: locale),
                locale: locale,
                durationHours
            )
        )
    }

    private static func sanitizedItemName(_ value: String) -> String {
        let cleaned = value.unicodeScalars
            .map { CharacterSet.controlCharacters.contains($0) ? " " : String($0) }
            .joined()
            .split(whereSeparator: \Character.isWhitespace)
            .joined(separator: " ")
        return String(cleaned.prefix(60))
    }

    private static func localizedString(_ key: String, locale: Locale) -> String {
        let localizations = Bundle.main.localizations.filter { $0 != "Base" }
        guard let localization = Bundle.preferredLocalizations(
            from: localizations,
            forPreferences: [locale.identifier]
        ).first,
        let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
        let localizedBundle = Bundle(path: path) else {
            return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }
        return localizedBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
