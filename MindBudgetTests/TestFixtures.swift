import Foundation
@testable import MindBudget

enum TestFixtures {
    static let now = Date(timeIntervalSince1970: 1_784_851_200)

    static var utcCalendar: Calendar {
        calendar(timeZoneIdentifier: "UTC")
    }

    static var shanghaiCalendar: Calendar {
        calendar(timeZoneIdentifier: "Asia/Shanghai")
    }

    static var losAngelesCalendar: Calendar {
        calendar(timeZoneIdentifier: "America/Los_Angeles")
    }

    static func sample(
        _ scenario: SampleDataScenario,
        currencyCode: String = "USD",
        calendar: Calendar? = nil
    ) throws -> SampleDataBundle {
        try SampleDataFactory.make(
            scenario: scenario,
            referenceDate: now,
            calendar: calendar ?? utcCalendar,
            currencyCode: currencyCode
        )
    }

    private static func calendar(timeZoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
        return calendar
    }
}
