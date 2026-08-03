import Foundation

struct CoolingOffCountdown: Equatable, Sendable {
    let days: Int
    let hours: Int
    let minutes: Int
    let isComplete: Bool

    static func remaining(
        from now: Date,
        until reviewAt: Date,
        calendar: Calendar
    ) -> CoolingOffCountdown {
        guard now < reviewAt else {
            return CoolingOffCountdown(days: 0, hours: 0, minutes: 0, isComplete: true)
        }

        let components = calendar.dateComponents(
            [.hour, .minute, .second],
            from: now,
            to: reviewAt
        )
        let totalHours = max(0, components.hour ?? 0)
        let days = totalHours / 24
        let hours = totalHours % 24
        var minutes = max(0, components.minute ?? 0)
        if days == 0, hours == 0, minutes == 0, (components.second ?? 0) > 0 {
            minutes = 1
        }
        return CoolingOffCountdown(
            days: days,
            hours: hours,
            minutes: minutes,
            isComplete: false
        )
    }
}
