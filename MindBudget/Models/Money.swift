import Foundation

enum MoneyError: Error, Equatable, Sendable {
    case unsupportedCurrency(String)
    case amountOutOfRange
}

struct Money: Hashable, Codable, Sendable, Comparable {
    static var supportedCurrencyCodes: [String] {
        currencyExponents.keys.sorted()
    }

    let minorUnits: Int64
    let currencyCode: String

    var exponent: Int {
        Self.exponent(for: currencyCode)
    }

    var decimal: Decimal {
        Decimal(minorUnits) / Self.scale(for: currencyCode)
    }

    init(minorUnits: Int64, currencyCode: String) {
        precondition(Self.isSupported(currencyCode), "Unsupported ISO 4217 currency code")
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }

    init(decimal: Decimal, currencyCode: String) {
        precondition(Self.isSupported(currencyCode), "Unsupported ISO 4217 currency code")

        var scaledValue = decimal * Self.scale(for: currencyCode)
        var roundedValue = Decimal()
        NSDecimalRound(&roundedValue, &scaledValue, 0, .bankers)

        precondition(
            roundedValue >= Decimal(Int64.min) && roundedValue <= Decimal(Int64.max),
            "Money amount exceeds Int64 storage"
        )

        self.minorUnits = NSDecimalNumber(decimal: roundedValue).int64Value
        self.currencyCode = currencyCode
    }

    static func validated(minorUnits: Int64, currencyCode: String) throws -> Money {
        guard isSupported(currencyCode) else {
            throw MoneyError.unsupportedCurrency(currencyCode)
        }
        return Money(minorUnits: minorUnits, currencyCode: currencyCode)
    }

    static func validated(decimal: Decimal, currencyCode: String) throws -> Money {
        guard isSupported(currencyCode) else {
            throw MoneyError.unsupportedCurrency(currencyCode)
        }

        let scale = scale(for: currencyCode)
        var scaledValue = decimal * scale
        var roundedValue = Decimal()
        NSDecimalRound(&roundedValue, &scaledValue, 0, .bankers)
        guard roundedValue >= Decimal(Int64.min), roundedValue <= Decimal(Int64.max) else {
            throw MoneyError.amountOutOfRange
        }

        return Money(
            minorUnits: NSDecimalNumber(decimal: roundedValue).int64Value,
            currencyCode: currencyCode
        )
    }

    static func isSupported(_ currencyCode: String) -> Bool {
        currencyExponents[currencyCode] != nil
    }

    static func exponent(for currencyCode: String) -> Int {
        guard let exponent = currencyExponents[currencyCode] else {
            preconditionFailure("Unsupported ISO 4217 currency code")
        }
        return exponent
    }

    static func scale(for currencyCode: String) -> Decimal {
        switch exponent(for: currencyCode) {
        case 0: 1
        case 1: 10
        case 2: 100
        case 3: 1_000
        default: preconditionFailure("Unsupported currency exponent")
        }
    }

    static func maximumMinorUnits(for currencyCode: String) -> Int64 {
        precondition(isSupported(currencyCode), "Unsupported ISO 4217 currency code")

        // This is a storage-safety limit, not a purchasing-power judgment. Keeping
        // one million additions of the maximum accepted entry below Int64.max gives
        // aggregate calculations generous headroom without penalizing low-value
        // currencies such as KRW, VND, or IDR.
        return Int64.max / 1_000_000
    }

    static func + (lhs: Money, rhs: Money) -> Money {
        requireMatchingCurrencies(lhs, rhs)
        let (sum, overflow) = lhs.minorUnits.addingReportingOverflow(rhs.minorUnits)
        precondition(!overflow, "Money addition overflow")
        return Money(minorUnits: sum, currencyCode: lhs.currencyCode)
    }

    static func - (lhs: Money, rhs: Money) -> Money {
        requireMatchingCurrencies(lhs, rhs)
        let (difference, overflow) = lhs.minorUnits.subtractingReportingOverflow(rhs.minorUnits)
        precondition(!overflow, "Money subtraction overflow")
        return Money(minorUnits: difference, currencyCode: lhs.currencyCode)
    }

    func scaled(by ratio: Decimal) -> Money {
        Money(decimal: decimal * ratio, currencyCode: currencyCode)
    }

    static func < (lhs: Money, rhs: Money) -> Bool {
        requireMatchingCurrencies(lhs, rhs)
        return lhs.minorUnits < rhs.minorUnits
    }

    private enum CodingKeys: String, CodingKey {
        case minorUnits
        case currencyCode
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let minorUnits = try container.decode(Int64.self, forKey: .minorUnits)
        let currencyCode = try container.decode(String.self, forKey: .currencyCode)
        guard Self.isSupported(currencyCode) else {
            throw DecodingError.dataCorruptedError(
                forKey: .currencyCode,
                in: container,
                debugDescription: "Unsupported ISO 4217 currency code"
            )
        }
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }

    private static func requireMatchingCurrencies(_ lhs: Money, _ rhs: Money) {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cross-currency arithmetic is unsupported")
    }

    private static let currencyExponents: [String: Int] = [
        "AED": 2,
        "AUD": 2,
        "BHD": 3,
        "BRL": 2,
        "CAD": 2,
        "CHF": 2,
        "CLP": 0,
        "CNY": 2,
        "CZK": 2,
        "DKK": 2,
        "EUR": 2,
        "GBP": 2,
        "HKD": 2,
        "HUF": 2,
        "IDR": 2,
        "ILS": 2,
        "INR": 2,
        "JPY": 0,
        "KWD": 3,
        "KRW": 0,
        "MXN": 2,
        "MYR": 2,
        "NOK": 2,
        "NZD": 2,
        "PHP": 2,
        "PLN": 2,
        "QAR": 2,
        "RON": 2,
        "SAR": 2,
        "SEK": 2,
        "SGD": 2,
        "THB": 2,
        "TRY": 2,
        "TWD": 2,
        "USD": 2,
        "VND": 0,
        "ZAR": 2
    ]
}
