import Foundation

enum ConfigurationValidationError: Error, Equatable, Sendable {
    case invalidValue(String)
    case currencyMismatch(expected: String, actual: String)
}

struct RuleConfiguration: Codable, Equatable, Sendable {
    let largePurchaseFloor: Money
    let largePurchaseFreeBudgetRatio: Decimal
    let lateNightStartHour: Int
    let lateNightEndHour: Int
    let lateNightMinimumRatio: Decimal
    let stressWindowDays: Int
    let stressMinimumCount: Int
    let impulseWindowHours: Int
    let impulseMinimumCount: Int
    let imageIncreaseMultiplier: Decimal
    let imageBaselineMonths: Int
    let minimumBaselineMonthsRequired: Int
    let categoryWarningThresholdBasisPoints: Int

    static func defaults(currencyCode: String) -> RuleConfiguration {
        let floorMajorUnits: Decimal
        switch currencyCode {
        case "CNY": floorMajorUnits = 500
        case "JPY": floorMajorUnits = 10_000
        case "KRW": floorMajorUnits = 100_000
        default: floorMajorUnits = 100
        }

        return RuleConfiguration(
            largePurchaseFloor: Money(decimal: floorMajorUnits, currencyCode: currencyCode),
            largePurchaseFreeBudgetRatio: decimal("0.15"),
            lateNightStartHour: 22,
            lateNightEndHour: 5,
            lateNightMinimumRatio: decimal("0.05"),
            stressWindowDays: 7,
            stressMinimumCount: 3,
            impulseWindowHours: 72,
            impulseMinimumCount: 3,
            imageIncreaseMultiplier: decimal("1.4"),
            imageBaselineMonths: 3,
            minimumBaselineMonthsRequired: 2,
            categoryWarningThresholdBasisPoints: 8_000
        )
    }

    func validate(accountingCurrencyCode: String) throws {
        guard Money.isSupported(accountingCurrencyCode) else {
            throw ConfigurationValidationError.invalidValue("accountingCurrencyCode")
        }
        guard largePurchaseFloor.currencyCode == accountingCurrencyCode else {
            throw ConfigurationValidationError.currencyMismatch(
                expected: accountingCurrencyCode,
                actual: largePurchaseFloor.currencyCode
            )
        }
        guard largePurchaseFloor.minorUnits > 0,
              largePurchaseFloor.minorUnits <= Money.maximumMinorUnits(for: accountingCurrencyCode) else {
            throw ConfigurationValidationError.invalidValue("largePurchaseFloor")
        }
        guard largePurchaseFreeBudgetRatio > 0, largePurchaseFreeBudgetRatio <= 1 else {
            throw ConfigurationValidationError.invalidValue("largePurchaseFreeBudgetRatio")
        }
        guard (0...23).contains(lateNightStartHour),
              (0...23).contains(lateNightEndHour),
              lateNightStartHour != lateNightEndHour else {
            throw ConfigurationValidationError.invalidValue("lateNightHours")
        }
        guard lateNightMinimumRatio > 0, lateNightMinimumRatio <= 1 else {
            throw ConfigurationValidationError.invalidValue("lateNightMinimumRatio")
        }
        guard stressWindowDays > 0, stressMinimumCount > 0,
              impulseWindowHours > 0, impulseMinimumCount > 0 else {
            throw ConfigurationValidationError.invalidValue("patternWindows")
        }
        guard imageIncreaseMultiplier >= 1,
              imageBaselineMonths > 0,
              (1...imageBaselineMonths).contains(minimumBaselineMonthsRequired) else {
            throw ConfigurationValidationError.invalidValue("imageBaseline")
        }
        guard (1...10_000).contains(categoryWarningThresholdBasisPoints) else {
            throw ConfigurationValidationError.invalidValue("categoryWarningThresholdBasisPoints")
        }
    }

    private static func decimal(_ value: String) -> Decimal {
        guard let decimal = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            preconditionFailure("Invalid built-in decimal configuration")
        }
        return decimal
    }
}

enum SettingsCodec {
    static func encode<Value: Encodable>(_ value: Value) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        try JSONDecoder().decode(type, from: data)
    }
}
