import Foundation

protocol CurrencyFormatting: Sendable {
    func string(from money: Money, locale: Locale) -> String
}

struct CurrencyFormatterService: CurrencyFormatting, Sendable {
    func string(from money: Money, locale: Locale) -> String {
        money.decimal.formatted(
            .currency(code: money.currencyCode)
                .precision(.fractionLength(money.exponent))
                .locale(locale)
        )
    }
}
