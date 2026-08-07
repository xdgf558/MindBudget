import Foundation
import Testing
@testable import MindBudget

struct MoneyTests {
    @Test
    func decimalConversionUsesExactMinorUnits() {
        let amount = Money(decimal: decimal("12.34"), currencyCode: "USD")

        #expect(amount.minorUnits == 1_234)
        #expect(amount.decimal == decimal("12.34"))
        #expect(Money(minorUnits: 1_234, currencyCode: "USD") == amount)
    }

    @Test
    func conversionUsesBankersRounding() {
        let roundDownToEven = Money(decimal: decimal("1.005"), currencyCode: "USD")
        let roundUpToEven = Money(decimal: decimal("1.015"), currencyCode: "USD")

        #expect(roundDownToEven.minorUnits == 100)
        #expect(roundUpToEven.minorUnits == 102)
    }

    @Test
    func zeroExponentCurrencyDoesNotInventFractionalUnits() {
        let amount = Money(decimal: decimal("1234.5"), currencyCode: "JPY")

        #expect(amount.exponent == 0)
        #expect(amount.minorUnits == 1_234)
    }

    @Test
    func entryLimitIsCurrencyNeutralAndLeavesAggregationHeadroom() {
        let expectedLimit = Int64.max / 1_000_000

        #expect(Money.maximumMinorUnits(for: "USD") == expectedLimit)
        #expect(Money.maximumMinorUnits(for: "JPY") == expectedLimit)
        #expect(Money.maximumMinorUnits(for: "KRW") == expectedLimit)
        #expect(Money.maximumMinorUnits(for: "VND") == expectedLimit)
        #expect(expectedLimit > 1_000_000)
    }

    @Test
    func onboardingCurrencyTableIncludesLocalAndThreeDigitExponents() {
        #expect(Money.supportedCurrencyCodes.contains("SGD"))
        #expect(Money(decimal: decimal("1.234"), currencyCode: "KWD").minorUnits == 1_234)
        #expect(Money(decimal: decimal("10.4"), currencyCode: "CLP").minorUnits == 10)
    }

    @Test
    func arithmeticAndScalingStayInIntegerAndDecimalDomain() {
        let lhs = Money(minorUnits: 1_005, currencyCode: "CNY")
        let rhs = Money(minorUnits: 95, currencyCode: "CNY")

        #expect((lhs + rhs).minorUnits == 1_100)
        #expect((lhs - rhs).minorUnits == 910)
        #expect(lhs.scaled(by: decimal("0.5")).minorUnits == 502)
    }

    @Test
    func decodingRejectsUnsupportedCurrency() {
        let encoded = Data(#"{"minorUnits":100,"currencyCode":"ZZZ"}"#.utf8)

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Money.self, from: encoded)
        }
    }

    @Test
    func validatedFactoriesRejectUnsupportedCurrenciesAndPreserveExactValues() throws {
        let minorUnits = try Money.validated(minorUnits: 1_234, currencyCode: "USD")
        let decimalAmount = try Money.validated(
            decimal: decimal("12.34"),
            currencyCode: "USD"
        )

        #expect(minorUnits == decimalAmount)
        #expect(throws: MoneyError.unsupportedCurrency("ZZZ")) {
            try Money.validated(minorUnits: 1, currencyCode: "ZZZ")
        }
        #expect(throws: MoneyError.unsupportedCurrency("ZZZ")) {
            try Money.validated(decimal: decimal("1"), currencyCode: "ZZZ")
        }
    }

    @Test
    func comparisonUsesMinorUnitsWithinTheSameCurrency() {
        let smaller = Money(minorUnits: 99, currencyCode: "CNY")
        let larger = Money(minorUnits: 100, currencyCode: "CNY")

        #expect(smaller < larger)
        #expect(!(larger < smaller))
    }

    private func decimal(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
    }
}
