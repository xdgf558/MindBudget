import Foundation

enum ReminderKind: Equatable, Sendable {
    case behavioralInsight
    case coolingOffDue
}

struct ReminderRequest: Equatable, Sendable {
    let kind: ReminderKind
    let draft: InsightDraft?
    let requestedChannel: ReminderChannel?
    let requestedDeliveryDate: Date?
}

struct ThrottleDecision: Equatable, Sendable {
    enum SuppressionReason: String, Equatable, Sendable {
        case userDisabledReminders
        case duplicateWithinCooldown
        case notificationsNotAuthorized
        case invalidRequest
    }

    let shouldShowNow: Bool
    let channel: ReminderChannel?
    let scheduledFor: Date?
    let deferredUntil: Date?
    let suppressionReason: SuppressionReason?
}

struct ReminderThrottlePolicy: Equatable, Sendable {
    let scopedCooldownHours: Int
    let consecutiveNegativeResponseCount: Int
    let negativeResponseWindowDays: Int

    static let approved = ReminderThrottlePolicy(
        scopedCooldownHours: 24,
        consecutiveNegativeResponseCount: 3,
        negativeResponseWindowDays: 14
    )

    init(
        scopedCooldownHours: Int,
        consecutiveNegativeResponseCount: Int,
        negativeResponseWindowDays: Int
    ) {
        precondition(scopedCooldownHours > 0)
        precondition(consecutiveNegativeResponseCount > 0)
        precondition(negativeResponseWindowDays > 0)
        self.scopedCooldownHours = scopedCooldownHours
        self.consecutiveNegativeResponseCount = consecutiveNegativeResponseCount
        self.negativeResponseWindowDays = negativeResponseWindowDays
    }
}

protocol ReminderThrottling: Sendable {
    func decide(
        for request: ReminderRequest,
        history: [ReminderEventSummary],
        preferences: PreferencesSnapshot,
        now: Date,
        calendar: Calendar
    ) -> ThrottleDecision
}

struct ReminderThrottle: ReminderThrottling, Sendable {
    private let policy: ReminderThrottlePolicy
    private let dayInterval: @Sendable (Calendar, Date) -> DateInterval?

    init(
        policy: ReminderThrottlePolicy = .approved,
        dayInterval: @escaping @Sendable (Calendar, Date) -> DateInterval? = {
            calendar, date in calendar.dateInterval(of: .day, for: date)
        }
    ) {
        self.policy = policy
        self.dayInterval = dayInterval
    }

    func decide(
        for request: ReminderRequest,
        history: [ReminderEventSummary],
        preferences: PreferencesSnapshot,
        now: Date,
        calendar: Calendar
    ) -> ThrottleDecision {
        if request.kind == .behavioralInsight, !preferences.gentleRemindersEnabled {
            return suppressed(.userDisabledReminders)
        }
        if request.kind == .coolingOffDue, !preferences.notificationsEnabled {
            return suppressed(.notificationsNotAuthorized)
        }

        guard request.kind == .coolingOffDue || request.draft != nil else {
            return suppressed(.invalidRequest)
        }

        var channel = baseChannel(for: request)
        if request.kind == .behavioralInsight,
           (preferences.reminderTone == .minimal || request.draft?.severity == .info) {
            channel = downgradedNoninterruptingChannel(channel)
        }

        if request.kind == .behavioralInsight, let draft = request.draft {
            let scopedHistory = history
                .filter { $0.scopeKey == draft.throttleMetadata.scopeKey }
                .sorted { $0.shownAt > $1.shownAt }
            let cooldownStart = calendar.date(
                byAdding: .hour,
                value: -policy.scopedCooldownHours,
                to: now
            ) ?? .distantPast
            if let recent = scopedHistory.first(where: {
                cooldownStart <= $0.shownAt && $0.shownAt <= now
            }), !isCategoryRecrossingException(draft: draft, recent: recent) {
                return suppressed(.duplicateWithinCooldown)
            }

            let responded = scopedHistory.filter { $0.response != nil }
            let recentResponses = Array(
                responded.prefix(policy.consecutiveNegativeResponseCount)
            )
            let responseWindowStart = calendar.date(
                byAdding: .day,
                value: -policy.negativeResponseWindowDays,
                to: now
            ) ?? .distantPast
            if recentResponses.count == policy.consecutiveNegativeResponseCount,
               recentResponses.allSatisfy({
                    $0.response == .ignored || $0.response == .dismissed
               }),
               let mostRecentResponseDate = recentResponses.first?.respondedAt,
               responseWindowStart <= mostRecentResponseDate,
               mostRecentResponseDate <= now {
                channel = .card
            }

            if channel == .sheet || channel == .notification {
                if let day = dayInterval(calendar, now) {
                    let interruptionCount = history.filter { event in
                        event.isInterrupting
                            && (event.channel == .sheet || event.channel == .notification)
                            && day.contains(event.shownAt)
                    }.count
                    if interruptionCount >= preferences.maxDailyInterruptions {
                        channel = downgradedNoninterruptingChannel(channel)
                    }
                } else {
                    channel = downgradedNoninterruptingChannel(channel)
                }
            }
        }

        if channel == .notification {
            let requested = request.requestedDeliveryDate ?? now
            if let quietHours = preferences.quietHours,
               quietHours.contains(hour: calendar.component(.hour, from: requested)),
               let deferred = nextQuietHoursEnd(
                    after: requested,
                    quietHours: quietHours,
                    calendar: calendar
               ) {
                return ThrottleDecision(
                    shouldShowNow: false,
                    channel: .notification,
                    scheduledFor: deferred,
                    deferredUntil: deferred,
                    suppressionReason: nil
                )
            }
            return ThrottleDecision(
                shouldShowNow: false,
                channel: .notification,
                scheduledFor: requested,
                deferredUntil: nil,
                suppressionReason: nil
            )
        }

        return ThrottleDecision(
            shouldShowNow: true,
            channel: channel,
            scheduledFor: nil,
            deferredUntil: nil,
            suppressionReason: nil
        )
    }

    private func baseChannel(for request: ReminderRequest) -> ReminderChannel {
        if let requested = request.requestedChannel { return requested }
        if request.kind == .coolingOffDue { return .notification }
        guard let draft = request.draft else { return .card }
        guard draft.type.canInterrupt else { return .card }
        return switch draft.severity {
        case .high, .caution: .sheet
        case .gentle: .inline
        case .info: .card
        }
    }

    private func downgradedNoninterruptingChannel(
        _ channel: ReminderChannel
    ) -> ReminderChannel {
        switch channel {
        case .sheet: .inline
        case .notification: .card
        case .inline, .card: channel
        }
    }

    private func isCategoryRecrossingException(
        draft: InsightDraft,
        recent: ReminderEventSummary
    ) -> Bool {
        draft.type == .categoryBudgetRisk
            && (draft.throttleMetadata.categoryRiskBasisPoints ?? 0) >= 10_000
            && (recent.categoryRiskBasisPoints ?? 10_000) < 10_000
    }

    private func nextQuietHoursEnd(
        after date: Date,
        quietHours: QuietHours,
        calendar: Calendar
    ) -> Date? {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: quietHours.endHour),
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }

    private func suppressed(_ reason: ThrottleDecision.SuppressionReason) -> ThrottleDecision {
        ThrottleDecision(
            shouldShowNow: false,
            channel: nil,
            scheduledFor: nil,
            deferredUntil: nil,
            suppressionReason: reason
        )
    }
}
