import Foundation
import Testing
@testable import MindBudget

struct CurrencyFormatterServiceTests {
    private let formatter = CurrencyFormatterService()

    @Test
    func formatsMinorUnitsWithTheCurrencyExponent() {
        let value = formatter.string(
            from: Money(minorUnits: 123_456, currencyCode: "USD"),
            locale: Locale(identifier: "en_US")
        )

        #expect(value.contains("1,234.56"))
    }

    @Test
    func zeroExponentCurrencyDoesNotInventDecimals() {
        let value = formatter.string(
            from: Money(minorUnits: 123_456, currencyCode: "JPY"),
            locale: Locale(identifier: "en_US")
        )

        #expect(value.contains("123,456"))
        #expect(!value.contains("."))
    }

    @Test
    func threeDigitExponentRemainsVisible() {
        let value = formatter.string(
            from: Money(minorUnits: 1_234, currencyCode: "KWD"),
            locale: Locale(identifier: "en_US")
        )

        #expect(value.contains("1.234"))
    }

    @Test
    func negativeAmountsRemainVisible() {
        let value = formatter.string(
            from: Money(minorUnits: -123_456, currencyCode: "USD"),
            locale: Locale(identifier: "en_US")
        )

        #expect(value.contains("1,234.56"))
        #expect(value.contains("-"))
    }
}
