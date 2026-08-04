import Foundation
import SwiftUI

enum QuietHoursError: Error, Equatable, Sendable {
    case invalidHour
    case identicalBounds
}

struct QuietHours: Codable, Equatable, Sendable {
    let startHour: Int
    let endHour: Int

    init(startHour: Int, endHour: Int) throws {
        guard (0...23).contains(startHour), (0...23).contains(endHour) else {
            throw QuietHoursError.invalidHour
        }
        guard startHour != endHour else {
            throw QuietHoursError.identicalBounds
        }
        self.startHour = startHour
        self.endHour = endHour
    }

    func contains(hour: Int) -> Bool {
        guard (0...23).contains(hour) else { return false }
        return startHour < endHour
            ? hour >= startHour && hour < endHour
            : hour >= startHour || hour < endHour
    }
}

struct PreferencesSnapshot: Equatable, Sendable {
    let reminderTone: ReminderTone
    let gentleRemindersEnabled: Bool
    let notificationsEnabled: Bool
    let quietHours: QuietHours?
    let maxDailyInterruptions: Int
}

@MainActor
final class SettingsStore: ObservableObject {
    nonisolated static let maximumDailyInterruptions = 2

    @AppStorage var currencyCode: String {
        didSet { reloadRuleConfiguration() }
    }
    @AppStorage var enableGentleReminders: Bool
    @AppStorage var enableLocalNotifications: Bool
    @AppStorage var enableAIEnhancement: Bool
    @AppStorage var enableSiriIntegration: Bool
    @AppStorage var enableSpotlightIndexing: Bool
    @AppStorage var enableAskMindBudget: Bool
    @AppStorage var reminderToneRaw: String
    @AppStorage var quietHoursStartHour: Int
    @AppStorage var quietHoursEndHour: Int
    @AppStorage var quietHoursEnabled: Bool
    @AppStorage private var storedMaxDailyInterruptions: Int
    @AppStorage var indexMerchantNames: Bool
    @AppStorage var firstLaunchCompleted: Bool
    @AppStorage var budgetCycleStartDay: Int
    @AppStorage private(set) var categoryBucketOverridesJSON: Data
    @AppStorage var ruleConfigurationJSON: Data {
        didSet { reloadRuleConfiguration() }
    }

    @Published private(set) var configurationDiagnostic: String?
    private var cachedBucketOverrides: [ExpenseCategory: BudgetBucket]
    private var cachedRuleConfiguration: RuleConfiguration
    private var bucketConfigurationDiagnostic: String?
    private var ruleConfigurationDiagnostic: String?

    init(defaults: UserDefaults = .standard) {
        _currencyCode = AppStorage(wrappedValue: "", "currencyCode", store: defaults)
        _enableGentleReminders = AppStorage(wrappedValue: true, "enableGentleReminders", store: defaults)
        _enableLocalNotifications = AppStorage(wrappedValue: false, "enableLocalNotifications", store: defaults)
        _enableAIEnhancement = AppStorage(wrappedValue: false, "enableAIEnhancement", store: defaults)
        _enableSiriIntegration = AppStorage(wrappedValue: false, "enableSiriIntegration", store: defaults)
        _enableSpotlightIndexing = AppStorage(wrappedValue: false, "enableSpotlightIndexing", store: defaults)
        _enableAskMindBudget = AppStorage(wrappedValue: true, "enableAskMindBudget", store: defaults)
        _reminderToneRaw = AppStorage(wrappedValue: ReminderTone.soft.rawValue, "reminderToneRaw", store: defaults)
        _quietHoursStartHour = AppStorage(wrappedValue: 21, "quietHoursStartHour", store: defaults)
        _quietHoursEndHour = AppStorage(wrappedValue: 9, "quietHoursEndHour", store: defaults)
        _quietHoursEnabled = AppStorage(wrappedValue: true, "quietHoursEnabled", store: defaults)
        _storedMaxDailyInterruptions = AppStorage(wrappedValue: 2, "maxDailyInterruptions", store: defaults)
        _indexMerchantNames = AppStorage(wrappedValue: false, "indexMerchantNames", store: defaults)
        _firstLaunchCompleted = AppStorage(wrappedValue: false, "firstLaunchCompleted", store: defaults)
        _budgetCycleStartDay = AppStorage(wrappedValue: 1, "budgetCycleStartDay", store: defaults)
        _categoryBucketOverridesJSON = AppStorage(wrappedValue: Data(), "categoryBucketOverridesJSON", store: defaults)
        _ruleConfigurationJSON = AppStorage(wrappedValue: Data(), "ruleConfigurationJSON", store: defaults)
        configurationDiagnostic = nil
        cachedBucketOverrides = [:]
        cachedRuleConfiguration = RuleConfiguration.defaults(currencyCode: "USD")
        bucketConfigurationDiagnostic = nil
        ruleConfigurationDiagnostic = nil
        reloadBucketOverrides()
        reloadRuleConfiguration()
    }

    var reminderTone: ReminderTone {
        ReminderTone(rawValue: reminderToneRaw) ?? .soft
    }

    var preferencesSnapshot: PreferencesSnapshot {
        PreferencesSnapshot(
            reminderTone: reminderTone,
            gentleRemindersEnabled: enableGentleReminders,
            notificationsEnabled: enableLocalNotifications,
            quietHours: quietHoursEnabled
                ? try? QuietHours(startHour: quietHoursStartHour, endHour: quietHoursEndHour)
                : nil,
            maxDailyInterruptions: maxDailyInterruptions
        )
    }

    var maxDailyInterruptions: Int {
        get {
            min(max(storedMaxDailyInterruptions, 0), Self.maximumDailyInterruptions)
        }
        set {
            storedMaxDailyInterruptions = min(max(newValue, 0), Self.maximumDailyInterruptions)
        }
    }

    func bucket(for category: ExpenseCategory) -> BudgetBucket {
        bucketOverrides()[category] ?? category.defaultBucket
    }

    func bucketOverrides() -> [ExpenseCategory: BudgetBucket] {
        cachedBucketOverrides
    }

    func reloadBucketOverrides() {
        guard !categoryBucketOverridesJSON.isEmpty else {
            cachedBucketOverrides = [:]
            bucketConfigurationDiagnostic = nil
            refreshConfigurationDiagnostic()
            return
        }

        do {
            let rawOverrides = try SettingsCodec.decode(
                [String: String].self,
                from: categoryBucketOverridesJSON
            )
            let overrides = try rawOverrides.reduce(into: [ExpenseCategory: BudgetBucket]()) { result, entry in
                guard let category = ExpenseCategory(rawValue: entry.key),
                      let bucket = BudgetBucket(rawValue: entry.value) else {
                    throw ConfigurationValidationError.invalidValue("categoryBucketOverrides")
                }
                guard bucket != category.defaultBucket else { return }
                result[category] = bucket
            }
            cachedBucketOverrides = overrides
            bucketConfigurationDiagnostic = nil
        } catch {
            cachedBucketOverrides = [:]
            bucketConfigurationDiagnostic = "categoryBucketOverrides: \(error)"
        }
        refreshConfigurationDiagnostic()
    }

    func saveBucketOverrides(_ overrides: [ExpenseCategory: BudgetBucket]) throws {
        let rawOverrides = overrides.reduce(into: [String: String]()) { result, entry in
            guard entry.value != entry.key.defaultBucket else { return }
            result[entry.key.rawValue] = entry.value.rawValue
        }
        let encoded = try SettingsCodec.encode(rawOverrides)
        categoryBucketOverridesJSON = encoded
        cachedBucketOverrides = overrides.reduce(into: [:]) { result, entry in
            guard entry.value != entry.key.defaultBucket else { return }
            result[entry.key] = entry.value
        }
        bucketConfigurationDiagnostic = nil
        refreshConfigurationDiagnostic()
    }

    func ruleConfiguration() -> RuleConfiguration {
        cachedRuleConfiguration
    }

    func reloadRuleConfiguration() {
        let fallbackCurrency = Money.isSupported(currencyCode) ? currencyCode : "USD"
        let fallback = RuleConfiguration.defaults(currencyCode: fallbackCurrency)
        guard !ruleConfigurationJSON.isEmpty else {
            cachedRuleConfiguration = fallback
            ruleConfigurationDiagnostic = nil
            refreshConfigurationDiagnostic()
            return
        }

        do {
            let configuration = try SettingsCodec.decode(
                RuleConfiguration.self,
                from: ruleConfigurationJSON
            )
            try configuration.validate(accountingCurrencyCode: fallbackCurrency)
            cachedRuleConfiguration = configuration
            ruleConfigurationDiagnostic = nil
        } catch {
            cachedRuleConfiguration = fallback
            ruleConfigurationDiagnostic = "ruleConfiguration: \(error)"
        }
        refreshConfigurationDiagnostic()
    }

    func saveRuleConfiguration(_ configuration: RuleConfiguration) throws {
        guard Money.isSupported(currencyCode) else {
            throw ConfigurationValidationError.invalidValue("currencyCode")
        }
        try configuration.validate(accountingCurrencyCode: currencyCode)
        let encoded = try SettingsCodec.encode(configuration)
        ruleConfigurationJSON = encoded
        ruleConfigurationDiagnostic = nil
        refreshConfigurationDiagnostic()
    }

    func resetAfterDataDeletion() {
        currencyCode = ""
        enableGentleReminders = true
        enableLocalNotifications = false
        enableAIEnhancement = false
        enableSiriIntegration = false
        enableSpotlightIndexing = false
        enableAskMindBudget = true
        reminderToneRaw = ReminderTone.soft.rawValue
        quietHoursStartHour = 21
        quietHoursEndHour = 9
        quietHoursEnabled = true
        maxDailyInterruptions = 2
        indexMerchantNames = false
        budgetCycleStartDay = 1
        categoryBucketOverridesJSON = Data()
        ruleConfigurationJSON = Data()
        reloadBucketOverrides()
        reloadRuleConfiguration()
        firstLaunchCompleted = false
    }

    private func refreshConfigurationDiagnostic() {
        let combined = [bucketConfigurationDiagnostic, ruleConfigurationDiagnostic]
            .compactMap { $0 }
            .joined(separator: "; ")
        configurationDiagnostic = combined.isEmpty ? nil : combined
    }
}
