import Foundation
import SwiftData

enum ForeignCurrencyError: Error, Equatable, Sendable {
    case invalidRate
    case invalidRateText
    case invalidAmount
    case currencyMismatch
    case overflow
    case unreadableMetadata
    case unsupportedSource
    case syncRequiresCompanionProtocol
}

/// One original major unit buys N/D accounting major units. Always positive and reduced.
struct ForeignCurrencyRate: Hashable, Sendable {
    let numerator: Int64
    let denominator: Int64

    init(numerator: Int64, denominator: Int64) throws {
        guard numerator > 0, denominator > 0 else { throw ForeignCurrencyError.invalidRate }
        let divisor = Self.gcd(numerator, denominator)
        self.numerator = numerator / divisor
        self.denominator = denominator / divisor
    }

    private static func gcd(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        var a = lhs
        var b = rhs
        while b != 0 { (a, b) = (b, a % b) }
        return a
    }

    /// Closed lexical contract: locale decimal separator, decimal digits only, no grouping/sign.
    /// Normalize to eight places with half-even rounding BEFORE reduction. Reject a carry beyond
    /// ten integer digits so the canonical display remains valid input to this same parser.
    static func parse(_ text: String, locale: Locale) throws -> Self {
        guard text.unicodeScalars.count <= 32,
              let separator = locale.decimalSeparator, !separator.isEmpty else {
            throw ForeignCurrencyError.invalidRateText
        }
        let parts = text.components(separatedBy: separator)
        guard (1...2).contains(parts.count), !parts[0].isEmpty,
              parts.count == 1 || !parts[1].isEmpty else { throw ForeignCurrencyError.invalidRateText }
        func digits(_ part: String) throws -> [Int64] {
            try part.unicodeScalars.map { scalar in
                guard scalar.properties.generalCategory == .decimalNumber,
                      let value = Character(String(scalar)).wholeNumberValue, (0...9).contains(value) else {
                    throw ForeignCurrencyError.invalidRateText
                }
                return Int64(value)
            }
        }
        let whole = try digits(parts[0])
        let fraction = parts.count == 2 ? try digits(parts[1]) : []
        guard whole.count <= 10, fraction.count <= 12 else { throw ForeignCurrencyError.invalidRateText }
        var scaled = whole.reduce(Int64(0)) { $0 * 10 + $1 } * 100_000_000
        var places = Int64(0)
        for index in 0..<8 { places = places * 10 + (index < fraction.count ? fraction[index] : 0) }
        scaled += places
        if fraction.count > 8 {
            let first = fraction[8]
            let greaterThanHalf = first > 5 || (first == 5 && fraction.dropFirst(9).contains { $0 != 0 })
            if greaterThanHalf || (first == 5 && scaled % 2 != 0) { scaled += 1 }
        }
        guard scaled < 1_000_000_000_000_000_000 else { throw ForeignCurrencyError.invalidRateText }
        return try Self(numerator: scaled, denominator: 100_000_000)
    }

    struct Display: Equatable, Sendable {
        let text: String
        let isApproximate: Bool
    }

    /// Display only; an override's nonterminating fraction is never replaced by this text.
    func display(locale: Locale) throws -> Display {
        var whole = numerator / denominator
        let remainder = numerator % denominator
        let scaled = try FXWide(UInt64(remainder)).multiplied(by: 100_000_000)
        let divisor = FXWide(UInt64(denominator))
        let rounded = try FXWide.roundedQuotient(scaled, divisor, maximum: 100_000_000)
        let exact = try divisor.multiplied(by: rounded) == scaled
        var fractional = rounded
        if fractional == 100_000_000 { whole += 1; fractional = 0 }
        var text = String(whole)
        if fractional != 0 {
            var tail = String(fractional)
            tail = String(repeating: "0", count: 8 - tail.count) + tail
            while tail.last == "0" { tail.removeLast() }
            text += (locale.decimalSeparator ?? ".") + tail
        }
        return Display(text: text, isApproximate: !exact)
    }
}

/// Bounded two-word unsigned integer intermediates, never persisted as money. For supported
/// money (<= Int64.max / 1_000_000), Int64 rates and scales <= 1_000 all products fit 128 bits.
/// Every multiplication still checks overflow. Division uses a bounded integer binary search.
private struct FXWide: Equatable, Comparable {
    let high: UInt64
    let low: UInt64

    init(_ value: UInt64) { high = 0; low = value }
    private init(high: UInt64, low: UInt64) { self.high = high; self.low = low }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.high == rhs.high ? lhs.low < rhs.low : lhs.high < rhs.high
    }

    func multiplied(by factor: UInt64) throws -> Self {
        let bottom = low.multipliedFullWidth(by: factor)
        let top = high.multipliedReportingOverflow(by: factor)
        let sum = top.partialValue.addingReportingOverflow(bottom.high)
        guard !top.overflow, !sum.overflow else { throw ForeignCurrencyError.overflow }
        return Self(high: sum.partialValue, low: bottom.low)
    }

    private func subtracting(_ rhs: Self) -> Self {
        precondition(self >= rhs)
        let bottom = low.subtractingReportingOverflow(rhs.low)
        return Self(high: high - rhs.high - (bottom.overflow ? 1 : 0), low: bottom.partialValue)
    }

    static func roundedQuotient(_ value: Self, _ divisor: Self, maximum: UInt64) throws -> UInt64 {
        guard divisor > Self(0), value < (try divisor.multiplied(by: maximum + 1)) else {
            throw ForeignCurrencyError.overflow
        }
        var lower: UInt64 = 0
        var upper = maximum
        while lower < upper {
            let midpoint = lower + (upper - lower + 1) / 2
            if try divisor.multiplied(by: midpoint) <= value { lower = midpoint }
            else { upper = midpoint - 1 }
        }
        let remainder = value.subtracting(try divisor.multiplied(by: lower))
        let twice = try remainder.multiplied(by: 2)
        let increment = twice > divisor || (twice == divisor && lower % 2 == 1)
        guard !increment || lower < maximum else { throw ForeignCurrencyError.overflow }
        return lower + (increment ? 1 : 0)
    }
}

struct ForeignCurrencyConverter: Sendable {
    func convert(original: Money, accountingCurrency: String, rate: ForeignCurrencyRate) throws -> Money {
        try Self.validate(original)
        guard Money.isSupported(accountingCurrency),
              original.currencyCode != accountingCurrency else { throw ForeignCurrencyError.currencyMismatch }
        // O * N * accountingScale / (D * originalScale), not the inverse rate.
        let numerator = try FXWide(UInt64(original.minorUnits))
            .multiplied(by: UInt64(rate.numerator))
            .multiplied(by: Self.scale(accountingCurrency))
        let denominator = try FXWide(UInt64(rate.denominator))
            .multiplied(by: Self.scale(original.currencyCode))
        let result = try FXWide.roundedQuotient(
            numerator, denominator, maximum: UInt64(Money.maximumMinorUnits(for: accountingCurrency))
        )
        guard result > 0 else { throw ForeignCurrencyError.invalidAmount }
        return Money(minorUnits: Int64(result), currencyCode: accountingCurrency)
    }

    func effectiveRate(original: Money, accounting: Money) throws -> ForeignCurrencyRate {
        try Self.validate(original)
        try Self.validate(accounting)
        guard original.currencyCode != accounting.currencyCode else { throw ForeignCurrencyError.currencyMismatch }
        let numerator = accounting.minorUnits.multipliedReportingOverflow(by: Int64(Self.scale(original.currencyCode)))
        let denominator = original.minorUnits.multipliedReportingOverflow(by: Int64(Self.scale(accounting.currencyCode)))
        guard !numerator.overflow, !denominator.overflow else { throw ForeignCurrencyError.overflow }
        let rate = try ForeignCurrencyRate(numerator: numerator.partialValue, denominator: denominator.partialValue)
        guard try convert(original: original, accountingCurrency: accounting.currencyCode, rate: rate) == accounting else {
            throw ForeignCurrencyError.invalidRate
        }
        return rate
    }

    private static func validate(_ money: Money) throws {
        guard Money.isSupported(money.currencyCode), money.minorUnits > 0,
              money.minorUnits <= Money.maximumMinorUnits(for: money.currencyCode) else {
            throw ForeignCurrencyError.invalidAmount
        }
    }

    private static func scale(_ currency: String) -> UInt64 {
        (0..<Money.exponent(for: currency)).reduce(UInt64(1)) { value, _ in value * 10 }
    }
}

enum ForeignCurrencyRateSource: String, Sendable {
    case manualRate
    case manualHomeAmountOverride
}

struct ExpenseForeignCurrency: Hashable, Sendable {
    let original: Money
    let rate: ForeignCurrencyRate
    let rateDate: Date
    let rateTimeZoneIdentifier: String
    let source: ForeignCurrencyRateSource

    init(original: Money, rate: ForeignCurrencyRate, selectedDate: Date, calendar: Calendar,
         source: ForeignCurrencyRateSource = .manualRate) throws {
        guard selectedDate.timeIntervalSinceReferenceDate.isFinite else { throw ForeignCurrencyError.unreadableMetadata }
        self.original = original
        self.rate = rate
        self.rateDate = calendar.startOfDay(for: selectedDate)
        self.rateTimeZoneIdentifier = calendar.timeZone.identifier
        self.source = source
    }

    private init(original: Money, rate: ForeignCurrencyRate, rateDate: Date,
                 rateTimeZoneIdentifier: String, source: ForeignCurrencyRateSource) {
        self.original = original
        self.rate = rate
        self.rateDate = rateDate
        self.rateTimeZoneIdentifier = rateTimeZoneIdentifier
        self.source = source
    }

    func validate(accounting: Money) throws {
        guard let zone = TimeZone(identifier: rateTimeZoneIdentifier),
              rateDate.timeIntervalSinceReferenceDate.isFinite else { throw ForeignCurrencyError.unreadableMetadata }
        var calendar = Calendar.current
        calendar.timeZone = zone
        guard calendar.startOfDay(for: rateDate) == rateDate else { throw ForeignCurrencyError.unreadableMetadata }
        let converter = ForeignCurrencyConverter()
        guard try converter.convert(original: original, accountingCurrency: accounting.currencyCode, rate: rate) == accounting else {
            throw ForeignCurrencyError.invalidRate
        }
        if source == .manualHomeAmountOverride {
            guard try converter.effectiveRate(original: original, accounting: accounting) == rate else {
                throw ForeignCurrencyError.invalidRate
            }
        } else {
            // Manual text rates must be exactly representable by the canonical eight-place input.
            guard 100_000_000 % rate.denominator == 0,
                  rate.numerator / rate.denominator < 10_000_000_000 else {
                throw ForeignCurrencyError.invalidRate
            }
        }
    }

    func overriding(accounting: Money) throws -> Self {
        let rate = try ForeignCurrencyConverter().effectiveRate(original: original, accounting: accounting)
        return Self(original: original, rate: rate, rateDate: rateDate,
                    rateTimeZoneIdentifier: rateTimeZoneIdentifier, source: .manualHomeAmountOverride)
    }

    static func read(_ row: ExpenseForeignCurrencyMetadata, accounting: Money) throws -> Self {
        guard let source = ForeignCurrencyRateSource(rawValue: row.rateSourceRaw) else {
            throw ForeignCurrencyError.unreadableMetadata
        }
        let rate = try ForeignCurrencyRate(numerator: row.rateNumerator, denominator: row.rateDenominator)
        guard rate.numerator == row.rateNumerator, rate.denominator == row.rateDenominator else {
            throw ForeignCurrencyError.unreadableMetadata
        }
        let value = Self(original: try Money.validated(minorUnits: row.originalAmountMinorUnits,
                                                      currencyCode: row.originalCurrencyCode),
                         rate: rate, rateDate: row.rateDate, rateTimeZoneIdentifier: row.rateTimeZoneIdentifier, source: source)
        try value.validate(accounting: accounting)
        return value
    }
}

/// V7 companion only. Do not add fields to the frozen Expense or its sync payload.
@Model
final class ExpenseForeignCurrencyMetadata {
    @Attribute(.unique) var expenseID: UUID
    var originalAmountMinorUnits: Int64
    var originalCurrencyCode: String
    var rateNumerator: Int64
    var rateDenominator: Int64
    var rateDate: Date
    var rateTimeZoneIdentifier: String
    var rateSourceRaw: String

    init(expenseID: UUID, value: ExpenseForeignCurrency) {
        self.expenseID = expenseID
        originalAmountMinorUnits = value.original.minorUnits
        originalCurrencyCode = value.original.currencyCode
        rateNumerator = value.rate.numerator
        rateDenominator = value.rate.denominator
        rateDate = value.rateDate
        rateTimeZoneIdentifier = value.rateTimeZoneIdentifier
        rateSourceRaw = value.source.rawValue
    }
}
