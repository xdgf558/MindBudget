import SwiftUI

struct ForeignCurrencyEntrySection: View {
    @ObservedObject var model: ExpenseFormViewModel
    let accountingCurrency: String
    @Environment(\.existingPremiumEntryAccess) private var access
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var presentsRateDate = false
    @FocusState private var focusedNumericField: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("fx.mode", isOn: Binding(
                get: { model.foreignCurrencyForm != nil },
                set: { model.setForeignCurrencyEnabled(
                    $0, access: access, accountingCurrency: accountingCurrency,
                    locale: locale, calendar: calendar
                ) }
            ))
            .disabled(model.existingExpense?.foreignCurrency != nil
                      || (!access.permitsNewForeignCurrency && model.foreignCurrencyForm == nil))
            .accessibilityIdentifier("fx.enabled")

            if let state = model.foreignCurrencyForm {
                fields(state)
            } else {
                Text(access.permitsNewForeignCurrency ? "fx.help.offline" : "fx.help.pro")
                    .font(.footnote)
            }
        }
        .budgetCard(cornerRadius: 18, contentPadding: 16)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedNumericField != nil {
                    Spacer()
                    Button("common.done") { focusedNumericField = nil }
                        .accessibilityIdentifier("fx.keyboard.done")
                }
            }
        }
    }

    @ViewBuilder private func fields(_ state: ForeignCurrencyFormState) -> some View {
        Picker("fx.originalCurrency", selection: Binding<String?>(
            get: { state.originalCurrencyCode },
            set: { code in model.updateForeignCurrency({ $0.selectCurrency(code) }, locale: locale) }
        )) {
            Text("fx.selectCurrency").tag(Optional<String>.none)
            ForEach(Money.supportedCurrencyCodes.filter { $0 != state.accountingCurrencyCode }, id: \.self) { code in
                Text("\(code) — \(locale.localizedString(forCurrencyCode: code) ?? code)")
                    .tag(Optional(code))
            }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("fx.originalCurrency")

        numericField(
            "fx.originalAmount", text: state.originalAmountText,
            identifier: "fx.originalAmount", input: .originalAmount
        )
        Text(direction(original: state.originalCurrencyCode ?? "—", accounting: state.accountingCurrencyCode))
            .font(.footnote)
            .accessibilityIdentifier("fx.direction")
        numericField("fx.rate", text: state.rateText, identifier: "fx.rate", input: .rate)
        Text("fx.rateDate")
        rateDateControl(state)
        Text(state.rateTimeZoneIdentifier)
            .font(.caption)
            .accessibilityIdentifier("fx.rateTimeZone")
        numericField(
            "fx.accountingAmount", text: state.accountingAmountText,
            identifier: "fx.accountingAmount", input: .accountingAmount
        )
        Text(state.accountingCurrencyCode)
            .font(.caption)
        Text(state.source == .manualRate ? "fx.source.manual" : "fx.source.override")
            .font(.footnote)
            .accessibilityIdentifier("fx.source")
        if let resolved = try? state.resolve() {
            Text(ForeignCurrencyPresentation.accountingAmount(resolved.accounting, locale: locale))
                .font(.headline)
                .accessibilityIdentifier("fx.preview")
        } else {
            Text("fx.error.input")
                .font(.footnote)
                .accessibilityIdentifier("fx.invalidPreview")
        }
        Text("fx.help.locked")
            .font(.footnote)
        Text("fx.help.manualOnly")
            .font(.footnote)
        if model.existingExpense?.foreignCurrency != nil {
            Text("fx.help.stewardship")
                .font(.footnote)
        }
    }

    private func numericField(
        _ key: LocalizedStringKey, text: String, identifier: String,
        input: NumericInput
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(key).font(.subheadline)
            TextField("", text: Binding(
                get: { text },
                set: { newText in
                    model.updateForeignCurrency({ state in
                        switch input {
                        case .originalAmount:
                            state.setOriginalAmount(newText)
                        case .rate:
                            state.setRate(newText)
                        case .accountingAmount:
                            state.setAccountingAmount(newText)
                        }
                    }, locale: locale)
                }
            ))
                .focused($focusedNumericField, equals: identifier)
                .accessibilityLabel(key)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(identifier)
        }
    }

    private enum NumericInput: Sendable {
        case originalAmount
        case rate
        case accountingAmount
    }

    @ViewBuilder private func rateDateControl(_ state: ForeignCurrencyFormState) -> some View {
        let picker = DatePicker("fx.rateDate", selection: Binding(
            get: { state.rateDate },
            set: { date in model.updateForeignCurrency({ $0.setRateDate(date) }, locale: locale) }
        ), displayedComponents: .date)
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Keep the localized date wrappable without embedding a vertical wheel inside
                // the long form's scroll gesture. The native editor has its own sheet.
                Button {
                    presentsRateDate = true
                } label: {
                    Text(rateDateLabel(state))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("fx.rateDate"))
                .accessibilityValue(rateDateLabel(state))
                .sheet(isPresented: $presentsRateDate) {
                    NavigationStack {
                        picker.datePickerStyle(.wheel)
                            .labelsHidden()
                            .environment(\.timeZone, TimeZone(identifier: state.rateTimeZoneIdentifier) ?? calendar.timeZone)
                            .accessibilityIdentifier("fx.rateDate.editor")
                            .navigationTitle("fx.rateDate")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("common.done") { presentsRateDate = false }
                                        .accessibilityIdentifier("fx.rateDate.done")
                                }
                            }
                    }
                }
            } else {
                picker.datePickerStyle(.compact)
            }
        }
        .labelsHidden()
        .environment(\.timeZone, TimeZone(identifier: state.rateTimeZoneIdentifier) ?? calendar.timeZone)
        .accessibilityIdentifier("fx.rateDate")
    }

    private func rateDateLabel(_ state: ForeignCurrencyFormState) -> String {
        var savedCalendar = calendar
        savedCalendar.timeZone = TimeZone(identifier: state.rateTimeZoneIdentifier) ?? calendar.timeZone
        return state.rateDate.formatted(Date.FormatStyle(
            date: .numeric, time: .omitted, locale: locale,
            calendar: savedCalendar, timeZone: savedCalendar.timeZone
        ))
    }

    private func direction(original: String, accounting: String) -> String {
        String.localizedStringWithFormat(
            LocalizedCatalog.string("fx.direction.format", locale: locale), original, accounting
        )
    }
}

enum ForeignCurrencyPresentation {
    static func rateDate(_ value: ExpenseForeignCurrency, calendar: Calendar, locale: Locale) -> String {
        var savedCalendar = calendar
        savedCalendar.timeZone = TimeZone(identifier: value.rateTimeZoneIdentifier) ?? calendar.timeZone
        return value.rateDate.formatted(Date.FormatStyle(
            date: .numeric, time: .omitted, locale: locale,
            calendar: savedCalendar, timeZone: savedCalendar.timeZone
        ))
    }

    static func amount(_ money: Money, locale: Locale) -> String {
        "\(MoneyInputParser().inputText(for: money, locale: locale)) \(money.currencyCode)"
    }

    static func accountingAmount(_ money: Money, locale: Locale) -> String {
        String.localizedStringWithFormat(
            LocalizedCatalog.string("fx.accounting.format", locale: locale), amount(money, locale: locale)
        )
    }
}
