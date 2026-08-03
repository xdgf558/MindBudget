import Foundation
import Testing
@testable import MindBudget

struct CurrencyFormatterServiceTests {
    private let formatter = CurrencyFormatterService()

    @Test
    func formatsMinorUnitsWithTheCurrencyExponent() throws {
        let value = try formatter.string(
            from: Money(minorUnits: 123_456, currencyCode: "USD"),
            locale: Locale(identifier: "en_US")
        )

        #expect(value == "$1,234.56")
    }

    @Test
    func zeroExponentCurrencyDoesNotInventDecimals() throws {
        let value = try formatter.string(
            from: Money(minorUnits: 123_456, currencyCode: "JPY"),
            locale: Locale(identifier: "en_US")
        )

        #expect(value == "¥123,456")
    }

    @Test
    func negativeAmountsRemainVisible() throws {
        let value = try formatter.string(
            from: Money(minorUnits: -123_456, currencyCode: "USD"),
            locale: Locale(identifier: "en_US")
        )

        #expect(value.contains("1,234.56"))
        #expect(value.contains("-"))
    }
}
