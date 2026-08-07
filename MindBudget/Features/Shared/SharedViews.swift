import Foundation
import SwiftUI

enum MoneyInputError: Error, Equatable, Sendable {
    case empty
    case invalid
    case tooManyFractionDigits
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
        guard Money.isSupported(currencyCode) else {
            throw MoneyInputError.amountOutOfRange
        }
        guard let normalized = normalizedDecimalLiteral(from: trimmed, locale: locale),
              let decimal = Decimal(
                string: normalized,
                locale: Locale(identifier: "en_US_POSIX")
              ) else {
            throw MoneyInputError.invalid
        }
        let fractionDigitCount = normalized
            .split(separator: ".", omittingEmptySubsequences: false)
            .dropFirst()
            .first?
            .count ?? 0
        guard fractionDigitCount <= Money.exponent(for: currencyCode) else {
            throw MoneyInputError.tooManyFractionDigits
        }
        guard decimal >= 0 else { throw MoneyInputError.negative }
        guard allowsZero || decimal > 0 else { throw MoneyInputError.nonPositive }

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
        let rules = MoneyGroupingRulesCache.shared.rules(for: locale)
        let primarySize = rules.primarySize
        let secondarySize = rules.secondarySize
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

private struct MoneyGroupingRules: Sendable {
    let primarySize: Int
    let secondarySize: Int
}

private final class MoneyGroupingRulesCache: @unchecked Sendable {
    static let shared = MoneyGroupingRulesCache()

    private let lock = NSLock()
    private var storage: [String: MoneyGroupingRules] = [:]

    func rules(for locale: Locale) -> MoneyGroupingRules {
        let key = locale.identifier
        lock.lock()
        if let cached = storage[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let primarySize = max(1, formatter.groupingSize)
        let rules = MoneyGroupingRules(
            primarySize: primarySize,
            secondarySize: formatter.secondaryGroupingSize > 0
                ? formatter.secondaryGroupingSize
                : primarySize
        )

        lock.lock()
        let resolved = storage[key] ?? rules
        storage[key] = resolved
        lock.unlock()
        return resolved
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
            .fontDesign(.rounded)
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
    var actionAccessibilityIdentifier = "empty.action"
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(titleKey, systemImage: symbolName)
        } description: {
            Text(messageKey)
        } actions: {
            if let actionTitleKey, let action {
                Button(actionTitleKey, action: action)
                    .buttonStyle(MindBudgetCompactPrimaryButtonStyle())
                    .accessibilityIdentifier(actionAccessibilityIdentifier)
            }
        }
    }
}

struct EmotionTagPicker: View {
    @Binding var selection: EmotionTag?
    @Environment(\.mindBudgetTheme) private var theme

    var body: some View {
        MindBudgetFlowLayout(spacing: 8) {
            selectionButton(title: "common.none", value: nil)
            ForEach(EmotionTag.allCases) { tag in
                selectionButton(title: LocalizedStringKey(tag.localizedNameKey), value: tag)
            }
        }
        .accessibilityIdentifier("expense.emotion")
    }

    private func selectionButton(
        title: LocalizedStringKey,
        value: EmotionTag?
    ) -> some View {
        Button {
            selection = value
        } label: {
            Text(title)
                .font(.subheadline.weight(selection == value ? .semibold : .regular))
                .padding(.horizontal, 12)
                .frame(minHeight: 40)
                .background(
                    selection == value ? theme.accent : theme.surface,
                    in: Capsule()
                )
                .foregroundStyle(selection == value ? Color.white : theme.inkSecondary)
                .overlay {
                    if selection != value {
                        Capsule().stroke(theme.hairlineStrong, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct PurchaseReasonPicker: View {
    @Binding var selection: PurchaseReason?
    @Environment(\.mindBudgetTheme) private var theme

    var body: some View {
        MindBudgetFlowLayout(spacing: 8) {
            selectionButton(title: "common.none", value: nil)
            ForEach(PurchaseReason.allCases) { reason in
                selectionButton(title: LocalizedStringKey(reason.localizedNameKey), value: reason)
            }
        }
        .accessibilityIdentifier("expense.reason")
    }

    private func selectionButton(
        title: LocalizedStringKey,
        value: PurchaseReason?
    ) -> some View {
        Button {
            selection = value
        } label: {
            Text(title)
                .font(.subheadline.weight(selection == value ? .semibold : .regular))
                .padding(.horizontal, 12)
                .frame(minHeight: 40)
                .background(
                    selection == value ? theme.accent : theme.surface,
                    in: Capsule()
                )
                .foregroundStyle(selection == value ? Color.white : theme.inkSecondary)
                .overlay {
                    if selection != value {
                        Capsule().stroke(theme.hairlineStrong, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
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
                .buttonStyle(MindBudgetPrimaryButtonStyle())
        }
        .accessibilityIdentifier("error.state")
    }
}

extension View {
    func budgetCard(
        cornerRadius: CGFloat = 20,
        contentPadding: CGFloat = 18
    ) -> some View {
        modifier(
            BudgetCardModifier(
                cornerRadius: cornerRadius,
                contentPadding: contentPadding
            )
        )
    }

    func mindBudgetScreenBackground() -> some View {
        modifier(MindBudgetScreenBackgroundModifier())
    }
}

private struct BudgetCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let contentPadding: CGFloat
    @Environment(\.mindBudgetTheme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                theme.surface.opacity(theme.skin == .warmBotanical ? 0.98 : 0.88),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.hairline, lineWidth: 1)
            }
            .shadow(
                color: theme.accent.opacity(theme.skin == .warmBotanical ? 0.07 : 0.14),
                radius: theme.skin == .warmBotanical ? 6 : 12,
                y: 3
            )
    }
}

private struct MindBudgetScreenBackgroundModifier: ViewModifier {
    @Environment(\.mindBudgetTheme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(MindBudgetThemeBackground())
            .tint(theme.accent)
    }
}

struct MindBudgetPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.mindBudgetTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(Color.white)
            .background(
                theme.accentGradient.opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.38),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .contentShape(Rectangle())
    }
}

struct MindBudgetCompactPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.mindBudgetTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 22)
            .frame(minWidth: 140, minHeight: 50)
            .foregroundStyle(Color.white)
            .background(
                theme.accentGradient.opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.38),
                in: RoundedRectangle(cornerRadius: 15)
            )
            .contentShape(Rectangle())
    }
}

struct MindBudgetSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.mindBudgetTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(theme.accent.opacity(isEnabled ? 1 : 0.38))
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.hairlineStrong, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.78 : 1)
            .contentShape(Rectangle())
    }
}

struct MindBudgetFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? max(0, x - spacing), height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
