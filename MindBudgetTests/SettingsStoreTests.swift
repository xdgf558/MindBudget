import Foundation
import Testing
@testable import MindBudget

@MainActor
struct SettingsStoreTests {
    @Test
    func privacySensitiveSettingsDefaultOff() {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)

        #expect(store.enableAIEnhancement == false)
        #expect(store.enableSiriIntegration == false)
        #expect(store.enableSpotlightIndexing == false)
        #expect(store.enableLocalNotifications == false)
        #expect(store.enableAskMindBudget)
        #expect(store.preferencesSnapshot.maxDailyInterruptions == 2)
    }

    @Test
    func bucketOverridesPersistOnlyDifferencesFromDefaults() throws {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)

        try store.saveBucketOverrides([.rent: .discretionary, .food: .discretionary])
        let reloaded = SettingsStore(defaults: fixture.defaults)

        #expect(reloaded.bucket(for: .rent) == .discretionary)
        #expect(reloaded.bucket(for: .food) == .discretionary)
        #expect(reloaded.bucketOverrides().count == 1)
    }

    @Test
    func invalidRuleWriteDoesNotReplaceLastValidConfiguration() throws {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)
        store.currencyCode = "USD"
        let valid = RuleConfiguration.defaults(currencyCode: "USD")
        try store.saveRuleConfiguration(valid)
        let validData = store.ruleConfigurationJSON

        let invalid = RuleConfiguration(
            largePurchaseFloor: valid.largePurchaseFloor,
            largePurchaseFreeBudgetRatio: valid.largePurchaseFreeBudgetRatio,
            lateNightStartHour: valid.lateNightStartHour,
            lateNightEndHour: valid.lateNightEndHour,
            lateNightMinimumRatio: valid.lateNightMinimumRatio,
            stressWindowDays: valid.stressWindowDays,
            stressMinimumCount: valid.stressMinimumCount,
            impulseWindowHours: valid.impulseWindowHours,
            impulseMinimumCount: valid.impulseMinimumCount,
            imageIncreaseMultiplier: valid.imageIncreaseMultiplier,
            imageBaselineMonths: valid.imageBaselineMonths,
            minimumBaselineMonthsRequired: valid.minimumBaselineMonthsRequired,
            categoryWarningThresholdBasisPoints: 12_000
        )

        #expect(throws: ConfigurationValidationError.self) {
            try store.saveRuleConfiguration(invalid)
        }
        #expect(store.ruleConfigurationJSON == validData)
        #expect(store.ruleConfiguration() == valid)
    }

    @Test
    func corruptedConfigurationFallsBackWithoutDestroyingStoredBytes() {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)
        store.currencyCode = "CNY"
        let corrupted = Data("not-json".utf8)
        store.ruleConfigurationJSON = corrupted

        let result = store.ruleConfiguration()

        #expect(result == RuleConfiguration.defaults(currencyCode: "CNY"))
        #expect(store.ruleConfigurationJSON == corrupted)
        #expect(store.configurationDiagnostic != nil)
    }

    @Test
    func dailyInterruptionLimitIsClampedAtTheSettingsBoundary() {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)

        store.maxDailyInterruptions = 99
        #expect(store.maxDailyInterruptions == SettingsStore.maximumDailyInterruptions)
        store.maxDailyInterruptions = -1
        #expect(store.maxDailyInterruptions == 0)
    }

    private func isolatedDefaults() -> DefaultsFixture {
        let suiteName = "MindBudgetTests.\(UUID().uuidString)"
        return DefaultsFixture(
            suiteName: suiteName,
            defaults: UserDefaults(suiteName: suiteName)!
        )
    }

    private struct DefaultsFixture {
        let suiteName: String
        let defaults: UserDefaults

        func cleanup() {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }
}
