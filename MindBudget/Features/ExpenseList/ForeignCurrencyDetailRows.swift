import SwiftUI

struct ForeignCurrencyDetailRows: View {
    let value: ExpenseForeignCurrency
    let accountingCurrency: String
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        if let display = try? value.rate.display(locale: locale) {
            VStack(alignment: .leading, spacing: 6) {
                Text("fx.rate").font(.caption)
                Text(String.localizedStringWithFormat(
                    LocalizedCatalog.string(display.isApproximate ? "fx.savedRate.approximate" : "fx.savedRate.exact", locale: locale),
                    value.original.currencyCode, display.text, accountingCurrency
                ))
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("fx.detail.rate")
        }
        LabeledContent("fx.rateDate") {
            Text(ForeignCurrencyPresentation.rateDate(value, calendar: calendar, locale: locale))
        }
        .accessibilityIdentifier("fx.detail.rateDate")
        LabeledContent("fx.rateTimeZone") { Text(value.rateTimeZoneIdentifier) }
        LabeledContent("fx.source") {
            Text(value.source == .manualRate ? "fx.source.manual" : "fx.source.override")
        }
        Text("fx.help.locked").font(.footnote)
    }
}
