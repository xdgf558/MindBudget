import Foundation

/// Lossless user inputs; a failed resolution never falls back to an earlier successful preview.
struct ForeignCurrencyFormState: Equatable {
    let accountingCurrencyCode: String
    let rateTimeZoneIdentifier: String
    private(set) var originalCurrencyCode: String?
    private(set) var originalAmountText: String
    private(set) var rateText: String
    private(set) var accountingAmountText: String
    private(set) var rateDate: Date
    private(set) var source: ForeignCurrencyRateSource
    private let calendar: Calendar
    private let locale: Locale

    struct Resolution: Equatable {
        let accounting: Money
        let foreign: ExpenseForeignCurrency
    }

    init(accountingCurrencyCode: String, selectedDate: Date, calendar: Calendar, locale: Locale) {
        self.accountingCurrencyCode = accountingCurrencyCode
        self.calendar = calendar
        self.locale = locale
        rateTimeZoneIdentifier = calendar.timeZone.identifier
        rateDate = calendar.startOfDay(for: selectedDate)
        originalCurrencyCode = nil
        originalAmountText = ""
        rateText = ""
        accountingAmountText = ""
        source = .manualRate
    }

    init(existing: ExpenseForeignCurrency, accounting: Money, calendar: Calendar, locale: Locale) throws {
        try existing.validate(accounting: accounting)
        guard let zone = TimeZone(identifier: existing.rateTimeZoneIdentifier) else {
            throw ForeignCurrencyError.unreadableMetadata
        }
        var savedCalendar = calendar
        savedCalendar.timeZone = zone
        self.calendar = savedCalendar
        self.locale = locale
        accountingCurrencyCode = accounting.currencyCode
        rateTimeZoneIdentifier = existing.rateTimeZoneIdentifier
        rateDate = existing.rateDate
        originalCurrencyCode = existing.original.currencyCode
        originalAmountText = MoneyInputParser().inputText(for: existing.original, locale: locale)
        accountingAmountText = MoneyInputParser().inputText(for: accounting, locale: locale)
        rateText = try existing.rate.display(locale: locale).text
        source = existing.source
        // Override resolves from the two exact money values, never from the displayed rate.
    }

    func resolve() throws -> Resolution {
        guard let originalCurrencyCode else { throw ForeignCurrencyError.currencyMismatch }
        let parser = MoneyInputParser()
        let original = try parser.money(from: originalAmountText, currencyCode: originalCurrencyCode, locale: locale)
        let converter = ForeignCurrencyConverter()
        let accounting: Money
        let rate: ForeignCurrencyRate
        switch source {
        case .manualRate:
            rate = try ForeignCurrencyRate.parse(rateText, locale: locale)
            accounting = try converter.convert(original: original, accountingCurrency: accountingCurrencyCode, rate: rate)
        case .manualHomeAmountOverride:
            accounting = try parser.money(from: accountingAmountText, currencyCode: accountingCurrencyCode, locale: locale)
            rate = try converter.effectiveRate(original: original, accounting: accounting)
        }
        let foreign = try ExpenseForeignCurrency(
            original: original, rate: rate, selectedDate: rateDate, calendar: calendar, source: source
        )
        try foreign.validate(accounting: accounting)
        return Resolution(accounting: accounting, foreign: foreign)
    }

    mutating func selectCurrency(_ code: String?) {
        originalCurrencyCode = code
        refreshDerivedText()
    }

    mutating func setOriginalAmount(_ text: String) {
        originalAmountText = text
        refreshDerivedText()
    }

    mutating func setRate(_ text: String) {
        rateText = text
        source = .manualRate
        refreshDerivedText()
    }

    mutating func setAccountingAmount(_ text: String) {
        accountingAmountText = text
        source = .manualHomeAmountOverride
        refreshDerivedText()
    }

    mutating func setRateDate(_ date: Date) {
        rateDate = date.timeIntervalSinceReferenceDate.isFinite ? calendar.startOfDay(for: date) : date
    }

    private mutating func refreshDerivedText() {
        guard let value = try? resolve() else { return } // Preserve invalid user inputs, not a usable preview.
        switch source {
        case .manualRate:
            accountingAmountText = MoneyInputParser().inputText(for: value.accounting, locale: locale)
        case .manualHomeAmountOverride:
            if let display = try? value.foreign.rate.display(locale: locale) { rateText = display.text }
        }
    }
}
