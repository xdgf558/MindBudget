import AppIntents
import Foundation

enum IntentMoneyTransportError: Error, Equatable, Sendable {
    case invalidAmount
    case unsupportedPrecision
    case unsupportedCurrency
}

/// The single transport adapter allowed to receive App Intents floating-point
/// parameters. Every value is converted to exact minor units before it reaches
/// a domain service or persistence boundary.
enum IntentMoneyTransport {
    static func money(from majorUnits: Double, currencyCode: String) throws -> Money {
        guard majorUnits.isFinite, majorUnits > 0,
              Money.isSupported(currencyCode) else {
            throw IntentMoneyTransportError.invalidAmount
        }
        guard let decimal = Decimal(
            string: String(majorUnits),
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw IntentMoneyTransportError.invalidAmount
        }
        let money: Money
        do {
            money = try Money.validated(decimal: decimal, currencyCode: currencyCode)
        } catch MoneyError.unsupportedCurrency {
            throw IntentMoneyTransportError.unsupportedCurrency
        } catch {
            throw IntentMoneyTransportError.invalidAmount
        }
        guard money.minorUnits > 0,
              money.minorUnits <= Money.maximumMinorUnits(for: currencyCode),
              money.decimal == decimal else {
            throw IntentMoneyTransportError.unsupportedPrecision
        }
        return money
    }
}

struct RecordExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.record.title"
    static let description = IntentDescription("intent.record.description")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "intent.parameter.amount") var amount: Double
    @Parameter(title: "intent.parameter.category") var category: ExpenseCategory
    @Parameter(title: "intent.parameter.bucket") var bucket: BudgetBucket?
    @Parameter(title: "intent.parameter.merchant") var merchantName: String?
    @Parameter(title: "intent.parameter.currency") var currencyCode: String?

    @Dependency private var service: MindBudgetIntentService

    static var parameterSummary: some ParameterSummary {
        Summary("intent.record.summary \(\.$amount) \(\.$category)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let preferences = try await service.requireSiri()
            let requestedCurrency = normalizedCurrencyCode(
                currencyCode,
                fallback: preferences.accountingCurrencyCode
            )
            let money = try IntentMoneyTransport.money(
                from: amount,
                currencyCode: requestedCurrency
            )
            var calendar = Calendar.autoupdatingCurrent
            calendar.timeZone = .autoupdatingCurrent
            let result = try await service.recordExpense(
                amount: money,
                category: category,
                bucket: bucket ?? category.defaultBucket,
                merchantName: merchantName,
                requestedCurrencyCode: currencyCode,
                now: Date(),
                calendar: calendar
            )
            let key = result.wasDuplicate
                ? "intent.record.duplicate"
                : "intent.record.success"
            return .result(dialog: IntentDialog(LocalizedStringResource(stringLiteral: key)))
        } catch let error as IntentExecutionError {
            return .result(dialog: IntentDialog(error.dialogKey))
        } catch {
            return .result(dialog: IntentDialog("intent.error.invalidAmount"))
        }
    }
}

struct AddWishlistItemIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.wishlist.add.title"
    static let description = IntentDescription("intent.wishlist.add.description")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "intent.parameter.itemName") var itemName: String
    @Parameter(title: "intent.parameter.estimatedPrice") var estimatedPrice: Double?
    @Parameter(title: "intent.parameter.category") var category: ExpenseCategory
    @Parameter(title: "intent.parameter.currency") var currencyCode: String?

    @Dependency private var service: MindBudgetIntentService

    static var parameterSummary: some ParameterSummary {
        Summary("intent.wishlist.add.summary \(\.$itemName) \(\.$category)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let preferences = try await service.requireSiri()
            let requestedCurrency = normalizedCurrencyCode(
                currencyCode,
                fallback: preferences.accountingCurrencyCode
            )
            let price = try estimatedPrice.map {
                try IntentMoneyTransport.money(from: $0, currencyCode: requestedCurrency)
            }
            _ = try await service.addWishlistItem(
                name: itemName,
                estimatedPrice: price,
                category: category,
                requestedCurrencyCode: currencyCode,
                now: Date()
            )
            return .result(dialog: IntentDialog("intent.wishlist.add.success"))
        } catch let error as IntentExecutionError {
            return .result(dialog: IntentDialog(error.dialogKey))
        } catch {
            return .result(dialog: IntentDialog("intent.error.invalidAmount"))
        }
    }
}

struct CheckBudgetImpactIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.impact.title"
    static let description = IntentDescription("intent.impact.description")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "intent.parameter.amount") var amount: Double
    @Parameter(title: "intent.parameter.category") var category: ExpenseCategory
    @Parameter(title: "intent.parameter.bucket") var bucket: BudgetBucket?
    @Parameter(title: "intent.parameter.itemName") var candidateName: String?
    @Parameter(title: "intent.parameter.currency") var currencyCode: String?

    @Dependency private var service: MindBudgetIntentService

    static var parameterSummary: some ParameterSummary {
        Summary("intent.impact.summary \(\.$amount) \(\.$category)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let preferences = try await service.requireSiri()
            let requestedCurrency = normalizedCurrencyCode(
                currencyCode,
                fallback: preferences.accountingCurrencyCode
            )
            let money = try IntentMoneyTransport.money(
                from: amount,
                currencyCode: requestedCurrency
            )
            var calendar = Calendar.autoupdatingCurrent
            calendar.timeZone = .autoupdatingCurrent
            let result = try await service.checkBudgetImpact(
                amount: money,
                category: category,
                bucket: bucket ?? category.defaultBucket,
                candidateName: candidateName,
                requestedCurrencyCode: currencyCode,
                now: Date(),
                calendar: calendar
            )
            let locale = Locale.autoupdatingCurrent
            let remaining = CurrencyFormatterService().string(
                from: result.impact.remainingFreeAfter,
                locale: locale
            )
            let key = result.impact.willExceedTotalBudget || result.impact.willExceedFreeBudget
                ? "intent.impact.over"
                : "intent.impact.within"
            let text = LocalizedCatalog.format(key, locale: locale, remaining)
            return .result(dialog: IntentDialog("\(text)"))
        } catch let error as IntentExecutionError {
            return .result(dialog: IntentDialog(error.dialogKey))
        } catch {
            return .result(dialog: IntentDialog("intent.error.invalidAmount"))
        }
    }
}

private func normalizedCurrencyCode(_ value: String?, fallback: String) -> String {
    let normalized = value?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .uppercased()
    guard let normalized, !normalized.isEmpty else { return fallback }
    return normalized
}
