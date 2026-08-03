import Foundation
import SwiftUI

enum MoneyInputError: Error, Equatable, Sendable {
    case empty
    case invalid
    case nonPositive
    case negative
    case amountOutOfRange
}

struct MoneyInputParser: Sendable {
    func money(
        from text: String,
        currencyCode: String,
        locale: Locale,
        allowsZero: Bool = false
    ) throws -> Money {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MoneyInputError.empty }
        guard let decimal = decimal(from: trimmed, locale: locale) else {
            throw MoneyInputError.invalid
        }
        guard decimal >= 0 else { throw MoneyInputError.negative }
        guard allowsZero || decimal > 0 else { throw MoneyInputError.nonPositive }

        guard Money.isSupported(currencyCode) else {
            throw MoneyInputError.amountOutOfRange
        }
        var scaled = decimal * Money.scale(for: currencyCode)
        var integralMinorUnits = Decimal()
        NSDecimalRound(&integralMinorUnits, &scaled, 0, .plain)
        guard scaled == integralMinorUnits else {
            // Manual entry must never silently round away digits the user typed.
            throw MoneyInputError.invalid
        }

        let money: Money
        do {
            money = try Money.validated(decimal: decimal, currencyCode: currencyCode)
        } catch {
            throw MoneyInputError.amountOutOfRange
        }
        guard money.minorUnits <= Money.maximumMinorUnits(for: currencyCode) else {
            throw MoneyInputError.amountOutOfRange
        }
        return money
    }

    func inputText(for money: Money, locale: Locale) -> String {
        money.decimal.formatted(
            .number
                .grouping(.never)
                .precision(.fractionLength(0...money.exponent))
                .locale(locale)
        )
    }

    private func decimal(from text: String, locale: Locale) -> Decimal? {
        guard let normalized = normalizedDecimalLiteral(from: text, locale: locale) else {
            return nil
        }
        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    private func normalizedDecimalLiteral(from text: String, locale: Locale) -> String? {
        var value = text.map { character -> String in
            if let digit = character.wholeNumberValue, (0...9).contains(digit) {
                return String(digit)
            }
            return String(character)
        }.joined()
        let decimalSeparator = locale.decimalSeparator ?? "."
        let groupingSeparator = locale.groupingSeparator ?? ""
        if groupingSeparator == " "
            || groupingSeparator == "\u{00A0}"
            || groupingSeparator == "\u{202F}" {
            value = value
                .replacingOccurrences(of: " ", with: groupingSeparator)
                .replacingOccurrences(of: "\u{00A0}", with: groupingSeparator)
                .replacingOccurrences(of: "\u{202F}", with: groupingSeparator)
        }

        var sign = ""
        if let first = value.first, first == "+" || first == "-" {
            sign = String(first)
            value.removeFirst()
        }
        let decimalParts = value.components(separatedBy: decimalSeparator)
        guard decimalParts.count <= 2 else { return nil }
        let integerPart = decimalParts[0]
        let fractionPart = decimalParts.count == 2 ? decimalParts[1] : nil
        guard validGroupedInteger(integerPart, separator: groupingSeparator, locale: locale),
              fractionPart?.allSatisfy(isASCIIDigit) != false,
              integerPart.contains(where: isASCIIDigit)
                || fractionPart?.contains(where: isASCIIDigit) == true else {
            return nil
        }

        let integerDigits = groupingSeparator.isEmpty
            ? integerPart
            : integerPart.replacingOccurrences(of: groupingSeparator, with: "")
        let fraction = fractionPart.map { ".\($0)" } ?? ""
        return "\(sign)\(integerDigits)\(fraction)"
    }

    private func validGroupedInteger(
        _ value: String,
        separator: String,
        locale: Locale
    ) -> Bool {
        guard !value.isEmpty else { return true }
        guard !separator.isEmpty, value.contains(separator) else {
            return value.allSatisfy(isASCIIDigit)
        }
        let groups = value.components(separatedBy: separator)
        guard groups.count > 1, groups.allSatisfy({ !$0.isEmpty && $0.allSatisfy(isASCIIDigit) }) else {
            return false
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let primarySize = max(1, formatter.groupingSize)
        let secondarySize = formatter.secondaryGroupingSize > 0
            ? formatter.secondaryGroupingSize
            : primarySize
        guard groups.last?.count == primarySize else { return false }
        let middleGroups = groups.dropFirst().dropLast()
        guard middleGroups.allSatisfy({ $0.count == secondarySize }) else { return false }
        guard let firstCount = groups.first?.count else { return false }
        return (1...secondarySize).contains(firstCount)
    }

    private func isASCIIDigit(_ character: Character) -> Bool {
        character >= "0" && character <= "9"
    }
}

struct MoneyText: View {
    let money: Money
    var font: Font = .body
    var weight: Font.Weight = .regular

    @Environment(\.locale) private var locale

    var body: some View {
        Text(CurrencyFormatterService().string(from: money, locale: locale))
            .font(font)
            .fontWeight(weight)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let amount = money.decimal.formatted(
            .number
                .precision(.fractionLength(0...money.exponent))
                .locale(locale)
        )
        let currency = locale.localizedString(forCurrencyCode: money.currencyCode)
            ?? money.currencyCode
        return "\(amount) \(currency)"
    }
}

struct EmptyStateView: View {
    let symbolName: String
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    var actionTitleKey: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(titleKey, systemImage: symbolName)
        } description: {
            Text(messageKey)
        } actions: {
            if let actionTitleKey, let action {
                Button(actionTitleKey, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct ErrorStateView: View {
    let messageKey: LocalizedStringKey
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("error.title", systemImage: "arrow.clockwise.circle")
        } description: {
            Text(messageKey)
        } actions: {
            Button("common.retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .accessibilityIdentifier("error.state")
    }
}

extension View {
    func budgetCard() -> some View {
        padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
