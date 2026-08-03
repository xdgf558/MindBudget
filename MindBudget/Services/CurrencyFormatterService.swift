import Foundation

enum CurrencyFormattingError: Error, Equatable, Sendable {
    case formattingFailed(currencyCode: String)
}

protocol CurrencyFormatting: Sendable {
    func string(from money: Money, locale: Locale) throws -> String
}

struct CurrencyFormatterService: CurrencyFormatting, Sendable {
    func string(from money: Money, locale: Locale) throws -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode
        formatter.minimumFractionDigits = money.exponent
        formatter.maximumFractionDigits = money.exponent
        formatter.roundingMode = .halfEven
        formatter.usesGroupingSeparator = true

        guard let result = formatter.string(
            from: NSDecimalNumber(decimal: money.decimal)
        ) else {
            throw CurrencyFormattingError.formattingFailed(currencyCode: money.currencyCode)
        }
        return result
    }
}
