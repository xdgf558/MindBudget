import Combine
import Foundation
import Testing
import UIKit
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
        #expect(store.requireFaceID == false)
        #expect(store.enableAskMindBudget)
        #expect(store.preferencesSnapshot.maxDailyInterruptions == 2)
    }

    @Test
    func faceIDProtectionPersistsAndResetsWithPrivacyPreferences() {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)

        store.requireFaceID = true
        #expect(SettingsStore(defaults: fixture.defaults).requireFaceID)

        store.resetAfterDataDeletion()
        #expect(!store.requireFaceID)
    }

    @Test
    func appLockNeverUnlocksAfterCancelledAuthentication() async throws {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let settings = SettingsStore(defaults: fixture.defaults)
        settings.requireFaceID = true
        let controller = try DataController(isStoredInMemoryOnly: true)
        let session = AppSession(
            dataActor: controller.dataActor,
            appLockAuthenticator: StubAppLockAuthenticator(
                availability: .available,
                authenticationResult: false
            ),
            appLockInitiallyEnabled: true
        )

        await session.unlockAppIfNeeded(
            settings: settings,
            localizedReason: "Test"
        )

        #expect(session.appLockState == .locked)
        #expect(session.appLockOperationError == .authenticationFailed)
    }

    @Test
    func enablingAppLockRequiresAvailableFaceIDAndSuccessfulAuthentication() async throws {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let settings = SettingsStore(defaults: fixture.defaults)
        let controller = try DataController(isStoredInMemoryOnly: true)
        let unavailableSession = AppSession(
            dataActor: controller.dataActor,
            appLockAuthenticator: StubAppLockAuthenticator(
                availability: .unavailable,
                authenticationResult: true
            )
        )

        let unavailableResult = await unavailableSession.setAppLockProtection(
            enabled: true,
            settings: settings,
            localizedReason: "Test"
        )
        #expect(!unavailableResult)
        #expect(!settings.requireFaceID)
        #expect(unavailableSession.appLockOperationError == .faceIDUnavailable)

        let availableSession = AppSession(
            dataActor: controller.dataActor,
            appLockAuthenticator: StubAppLockAuthenticator(
                availability: .available,
                authenticationResult: true
            )
        )
        let availableResult = await availableSession.setAppLockProtection(
            enabled: true,
            settings: settings,
            localizedReason: "Test"
        )
        #expect(availableResult)
        #expect(settings.requireFaceID)
        #expect(availableSession.appLockState == .unlocked)
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
            lateNightWindowDays: valid.lateNightWindowDays,
            lateNightMinimumCount: valid.lateNightMinimumCount,
            stressWindowDays: valid.stressWindowDays,
            stressMinimumCount: valid.stressMinimumCount,
            impulseWindowHours: valid.impulseWindowHours,
            impulseMinimumCount: valid.impulseMinimumCount,
            imageIncreaseMultiplier: valid.imageIncreaseMultiplier,
            imageRelatedMinimumAmount: valid.imageRelatedMinimumAmount,
            imageBaselineMonths: valid.imageBaselineMonths,
            minimumBaselineMonthsRequired: valid.minimumBaselineMonthsRequired,
            categoryWarningThresholdBasisPoints: 12_000,
            safeProceedBufferBasisPoints: valid.safeProceedBufferBasisPoints
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

    @Test
    func appSkinDefaultsPersistsAndFallsBackWithoutRewritingCorruptState() {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)

        #expect(store.appSkin == .warmBotanical)
        store.appSkinRaw = AppSkin.neonPulse.rawValue
        #expect(SettingsStore(defaults: fixture.defaults).appSkin == .neonPulse)

        store.appSkinRaw = "future-or-corrupt-skin"
        #expect(store.appSkin == .warmBotanical)
        #expect(store.appSkinRaw == "future-or-corrupt-skin")

        store.resetAfterDataDeletion()
        #expect(store.appSkin == .warmBotanical)
    }

    @Test
    func appLanguageDefaultsToSystemAndPersistsAnExplicitLocale() {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)

        #expect(store.appLanguage == .system)
        store.appLanguageRaw = AppLanguage.simplifiedChinese.rawValue
        let reloaded = SettingsStore(defaults: fixture.defaults)
        #expect(reloaded.appLanguage == .simplifiedChinese)
        #expect(reloaded.selectedLocale.identifier.hasPrefix("zh-Hans"))

        reloaded.appLanguageRaw = AppLanguage.english.rawValue
        #expect(reloaded.selectedLocale.identifier.hasPrefix("en"))

        reloaded.appLanguageRaw = "future-language"
        #expect(reloaded.appLanguage == .system)
        #expect(reloaded.appLanguageRaw == "future-language")
    }

    @Test
    func changingAppLanguagePublishesAnImmediateRootViewUpdate() {
        let fixture = isolatedDefaults()
        defer { fixture.cleanup() }
        let store = SettingsStore(defaults: fixture.defaults)
        var updateCount = 0
        let observation = store.objectWillChange.sink {
            updateCount += 1
        }

        store.appLanguageRaw = AppLanguage.simplifiedChinese.rawValue

        #expect(updateCount == 1)
        #expect(store.selectedLocale.identifier.hasPrefix("zh-Hans"))
        #expect(fixture.defaults.string(forKey: "appLanguageRaw") == "zh-Hans")
        withExtendedLifetime(observation) {}
    }

    @Test
    func everySkinShipsItsPortraitBackgroundArtwork() throws {
        for skin in AppSkin.allCases {
            let image = try #require(UIImage(named: skin.backgroundAssetName))
            #expect(image.size.width >= 800)
            #expect(image.size.height >= 1_700)
            #expect(image.size.height > image.size.width * 2)
        }
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

private struct StubAppLockAuthenticator: AppLockAuthenticating {
    let availability: FaceIDAvailability
    let authenticationResult: Bool

    @MainActor
    func faceIDAvailability() -> FaceIDAvailability {
        availability
    }

    @MainActor
    func authenticate(localizedReason: String) async -> Bool {
        authenticationResult
    }
}
