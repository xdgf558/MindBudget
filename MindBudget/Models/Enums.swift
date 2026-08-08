import Foundation

enum PersistedModelError: Error, Equatable, Sendable {
    case unsupportedCurrency(entity: String, id: UUID, currencyCode: String)
    case invalidRawValue(entity: String, id: UUID, field: String, rawValue: String)
}

func validatedPersistedEnum<Value: RawRepresentable>(
    _ type: Value.Type,
    rawValue: String,
    entity: String,
    id: UUID,
    field: String
) throws -> Value where Value.RawValue == String {
    guard let value = Value(rawValue: rawValue) else {
        throw PersistedModelError.invalidRawValue(
            entity: entity,
            id: id,
            field: field,
            rawValue: rawValue
        )
    }
    return value
}

func validatedPersistedEnumIfPresent<Value: RawRepresentable>(
    _ type: Value.Type,
    rawValue: String?,
    entity: String,
    id: UUID,
    field: String
) throws -> Value? where Value.RawValue == String {
    guard let rawValue else { return nil }
    return try validatedPersistedEnum(
        type,
        rawValue: rawValue,
        entity: entity,
        id: id,
        field: field
    )
}

protocol StringIdentified: RawRepresentable, Identifiable where RawValue == String {}

extension StringIdentified {
    var id: String { rawValue }
}

enum BudgetBucket: String, Codable, CaseIterable, Sendable, StringIdentified {
    case fixed
    case discretionary
    case savings
}

enum ExpenseCategory: String, Codable, CaseIterable, Sendable, StringIdentified {
    case food, coffee, groceries, transport, shopping, clothing
    case electronics, entertainment, social, gifts, subscriptions
    case health, travel, rent, utilities, education, other

    var defaultBucket: BudgetBucket {
        switch self {
        case .rent, .utilities, .subscriptions, .education, .health:
            .fixed
        case .food, .coffee, .groceries, .transport, .shopping, .clothing,
             .electronics, .entertainment, .social, .gifts, .travel, .other:
            .discretionary
        }
    }

    var localizedNameKey: String { "category.\(rawValue)" }

    var symbolName: String {
        switch self {
        case .food: "fork.knife"
        case .coffee: "cup.and.saucer"
        case .groceries: "basket"
        case .transport: "car"
        case .shopping: "bag"
        case .clothing: "tshirt"
        case .electronics: "laptopcomputer"
        case .entertainment: "film"
        case .social: "person.2"
        case .gifts: "gift"
        case .subscriptions: "repeat"
        case .health: "cross.case"
        case .travel: "airplane"
        case .rent: "house"
        case .utilities: "bolt"
        case .education: "book"
        case .other: "ellipsis.circle"
        }
    }
}

enum EmotionTag: String, Codable, CaseIterable, Sendable, StringIdentified {
    case neutral, stressed, tired, bored, lonely
    case excited, celebrating, anxious
    case socialPressure, imageBoost, impulse

    var localizedNameKey: String { "emotion.\(rawValue)" }
}

enum PurchaseReason: String, Codable, CaseIterable, Sendable, StringIdentified {
    case need, planned, reward, stressRelief, socialEvent
    case imageUpgrade, curiosity, convenience, impulse, other

    var localizedNameKey: String { "purchaseReason.\(rawValue)" }
}

enum PaymentMethod: String, Codable, CaseIterable, Sendable, StringIdentified {
    case cash, debitCard, creditCard, mobilePay, transfer, other
}

enum ExpenseSource: String, Codable, CaseIterable, Sendable, StringIdentified {
    case manual, csvImport, siriIntent, shortcut, wishlistConversion
}

enum IncomeCategory: String, Codable, CaseIterable, Sendable, StringIdentified {
    case salary, bonus, freelance, investment, gift, refund, other

    var localizedNameKey: String { "income.category.\(rawValue)" }

    var symbolName: String {
        switch self {
        case .salary: "briefcase"
        case .bonus: "sparkles"
        case .freelance: "laptopcomputer"
        case .investment: "chart.line.uptrend.xyaxis"
        case .gift: "gift"
        case .refund: "arrow.uturn.backward.circle"
        case .other: "ellipsis.circle"
        }
    }
}

enum ReflectionContext: String, Codable, CaseIterable, Sendable, StringIdentified {
    case beforeLargePurchase, afterLargePurchase, coolingOffReview, monthlyReview, manual
}

enum SpendingInsightType: String, Codable, CaseIterable, Sendable, StringIdentified {
    case highSinglePurchase
    case categoryBudgetRisk
    case lateNightSpending
    case repeatedStressSpending
    case imageRelatedIncrease
    case impulseCluster
    case wishlistCoolingOff
    case coolingOffSuccess
    case monthlySummary
    case safeToProceed

    var canInterrupt: Bool {
        switch self {
        case .highSinglePurchase, .categoryBudgetRisk, .lateNightSpending,
             .repeatedStressSpending, .imageRelatedIncrease, .impulseCluster:
            true
        case .wishlistCoolingOff, .coolingOffSuccess, .monthlySummary, .safeToProceed:
            false
        }
    }
}

enum InsightSeverity: String, Codable, CaseIterable, Sendable, StringIdentified, Comparable {
    case info, gentle, caution, high

    static func < (lhs: InsightSeverity, rhs: InsightSeverity) -> Bool {
        Self.allCases.firstIndex(of: lhs)! < Self.allCases.firstIndex(of: rhs)!
    }
}

enum ReminderTone: String, Codable, CaseIterable, Sendable, StringIdentified {
    case soft, direct, minimal
}

enum WishItemStatus: String, Codable, CaseIterable, Sendable, StringIdentified {
    case active, coolingOff, readyToReview, purchased, skipped, archived

    var localizedNameKey: String { "wishlist.status.\(rawValue)" }

    var countsTowardOpenLimit: Bool {
        switch self {
        case .active, .coolingOff, .readyToReview:
            true
        case .purchased, .skipped, .archived:
            false
        }
    }
}

enum WishlistPolicy {
    static let maximumOpenItems = 5
}

enum CoolingOffStatus: String, Codable, CaseIterable, Sendable, StringIdentified {
    case scheduled, active, completed, cancelled
}

enum CoolingOffOutcome: String, Codable, CaseIterable, Sendable, StringIdentified {
    case purchased, skipped, extended, noResponse
}

enum ReminderChannel: String, Codable, CaseIterable, Sendable, StringIdentified {
    case inline, card, sheet, notification
}

enum ReminderResponse: String, Codable, CaseIterable, Sendable, StringIdentified {
    case acted, dismissed, ignored
}
