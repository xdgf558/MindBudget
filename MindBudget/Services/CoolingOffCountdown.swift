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

enum CoolingOffCountdownText {
    static func string(for countdown: CoolingOffCountdown, locale: Locale) -> String {
        if countdown.isComplete {
            return localizedString("wishlist.cooling.ready", locale: locale)
        }
        if countdown.days > 0 {
            return String(
                format: localizedString("wishlist.cooling.remaining.days", locale: locale),
                locale: locale,
                countdown.days,
                countdown.hours
            )
        }
        if countdown.hours > 0 {
            return String(
                format: localizedString("wishlist.cooling.remaining.hours", locale: locale),
                locale: locale,
                countdown.hours,
                countdown.minutes
            )
        }
        return String(
            format: localizedString("wishlist.cooling.remaining.minutes", locale: locale),
            locale: locale,
            countdown.minutes
        )
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
