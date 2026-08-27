import SwiftUI

struct ReceiptReviewCard: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.mindBudgetTheme) private var theme

    let result: ReceiptStructuredExtractionResult
    let thumbnailData: Data?
    let confirm: () -> Void
    let rescan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(theme.accentDeep)
                    .frame(width: 32, height: 32)
                    .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 11))
                Text("receipt.review.title")
                    .font(.headline)
                    .foregroundStyle(theme.ink)
                Spacer()
                ReceiptThumbnailView(data: thumbnailData, width: 34, height: 44)
            }

            Text("receipt.review.detail")
                .font(.subheadline)
                .foregroundStyle(theme.inkSecondary)

            VStack(spacing: 0) {
                reviewRow("receipt.field.merchant", value: merchantText(result.fields.merchantName))
                Divider().overlay(theme.hairline)
                reviewRow("receipt.field.date", value: dateText(result.fields.purchaseDate))
                Divider().overlay(theme.hairline)
                reviewRow("receipt.field.total", value: totalText(result.fields.total))
            }
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.hairline, lineWidth: 1)
            }

            if case let .exactMatches(ids) = result.duplicateResolution {
                Label(
                    String.localizedStringWithFormat(
                        LocalizedCatalog.string("receipt.duplicate.warning", locale: locale),
                        ids.count
                    ),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(theme.attentionText)
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier("receipt.duplicate.warning")
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    confirmButton
                    rescanButton(fullWidth: true)
                }
            } else {
                HStack(spacing: 10) {
                    confirmButton
                    rescanButton(fullWidth: false)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface.opacity(0.98), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.hairlineStrong, lineWidth: 1)
        }
        .shadow(color: theme.accent.opacity(0.09), radius: 8, y: 3)
        .accessibilityIdentifier("receipt.review")
    }

    private var confirmButton: some View {
        Button("receipt.review.confirm", action: confirm)
            .buttonStyle(MindBudgetPrimaryButtonStyle())
            .frame(maxWidth: .infinity, minHeight: 46)
            .accessibilityIdentifier("receipt.review.confirm")
    }

    private func rescanButton(fullWidth: Bool) -> some View {
        Button(action: rescan) {
            Image(systemName: "arrow.counterclockwise")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.accentDeep)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(width: fullWidth ? nil : 52, height: 46)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.hairlineStrong, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("receipt.scanAnother")
        .accessibilityIdentifier("receipt.scanAnother")
    }

    private func reviewRow(_ title: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(theme.inkSecondary)
            Spacer(minLength: 8)
            Text(verbatim: value)
                .fontWeight(.semibold)
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .font(.body)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func merchantText(_ field: ReceiptFieldResolution<String>) -> String {
        field.acceptedValue ?? localizedUnavailable(field)
    }

    private func dateText(_ field: ReceiptFieldResolution<ReceiptCalendarDate>) -> String {
        guard let value = field.acceptedValue else { return localizedUnavailable(field) }
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = value.year
        components.month = value.month
        components.day = value.day
        components.hour = 12
        guard let date = calendar.date(from: components) else {
            return LocalizedCatalog.string("receipt.field.needsReview", locale: locale)
        }
        return date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale, calendar: calendar)
        )
    }

    private func totalText(_ field: ReceiptFieldResolution<Money>) -> String {
        guard let value = field.acceptedValue else { return localizedUnavailable(field) }
        return CurrencyFormatterService().string(from: value, locale: locale)
    }

    private func localizedUnavailable<Value>(_ field: ReceiptFieldResolution<Value>) -> String {
        switch field {
        case .missing:
            LocalizedCatalog.string("receipt.field.missing", locale: locale)
        case .rejected:
            LocalizedCatalog.string("receipt.field.needsReview", locale: locale)
        case .accepted:
            preconditionFailure("Accepted fields are formatted by their typed caller")
        }
    }
}
