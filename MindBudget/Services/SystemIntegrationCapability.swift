import Foundation

#if canImport(AppIntents)
import AppIntents
#endif

#if canImport(CoreSpotlight)
@preconcurrency import CoreSpotlight
#endif

struct SystemIntegrationPreferencesSnapshot: Equatable, Sendable {
    let accountingCurrencyCode: String
    let budgetCycleStartDay: Int
    let siriEnabled: Bool
    let spotlightEnabled: Bool
    let merchantNamesEnabled: Bool
    let notificationPreferences: PreferencesSnapshot
}

enum SystemIntegrationAvailability: Equatable, Sendable {
    case available
    case productDisabled
    case buildUnsupported
    case runtimeUnavailable
    case userDisabled

    var isAvailable: Bool { self == .available }
}

/// The only place where product-scope flags are combined with compile-time,
/// runtime, and user-preference checks for Siri and Spotlight.
struct SystemIntegrationCapability: Sendable {
    private let siriProductEnabled: Bool
    private let spotlightProductEnabled: Bool
    private let siriRuntimeAvailable: @Sendable () -> Bool
    private let spotlightRuntimeAvailable: @Sendable () -> Bool

    init(
        siriProductEnabled: Bool = FeatureFlags.enableSiriIntegration,
        spotlightProductEnabled: Bool = FeatureFlags.enableSpotlightIndexing,
        siriRuntimeAvailable: @escaping @Sendable () -> Bool = Self.defaultSiriRuntimeAvailability,
        spotlightRuntimeAvailable: @escaping @Sendable () -> Bool = Self.defaultSpotlightRuntimeAvailability
    ) {
        self.siriProductEnabled = siriProductEnabled
        self.spotlightProductEnabled = spotlightProductEnabled
        self.siriRuntimeAvailable = siriRuntimeAvailable
        self.spotlightRuntimeAvailable = spotlightRuntimeAvailable
    }

    func siriAvailability(userEnabled: Bool) -> SystemIntegrationAvailability {
        guard siriProductEnabled else { return .productDisabled }
        #if canImport(AppIntents)
        guard #available(iOS 17.0, *) else { return .buildUnsupported }
        #else
        return .buildUnsupported
        #endif
        guard userEnabled else { return .userDisabled }
        guard siriRuntimeAvailable() else { return .runtimeUnavailable }
        return .available
    }

    func spotlightAvailability(userEnabled: Bool) -> SystemIntegrationAvailability {
        guard spotlightProductEnabled else { return .productDisabled }
        #if canImport(CoreSpotlight)
        guard #available(iOS 17.0, *) else { return .buildUnsupported }
        #else
        return .buildUnsupported
        #endif
        guard userEnabled else { return .userDisabled }
        guard spotlightRuntimeAvailable() else { return .runtimeUnavailable }
        return .available
    }

    private static func defaultSiriRuntimeAvailability() -> Bool {
        #if canImport(AppIntents)
        if #available(iOS 17.0, *) { return true }
        #endif
        return false
    }

    private static func defaultSpotlightRuntimeAvailability() -> Bool {
        #if canImport(CoreSpotlight)
        if #available(iOS 17.0, *) {
            return CSSearchableIndex.isIndexingAvailable()
        }
        #endif
        return false
    }
}

protocol SystemIntegrationPreferencesProviding: Sendable {
    func snapshot() async -> SystemIntegrationPreferencesSnapshot
}

actor UserDefaultsSystemIntegrationPreferencesProvider: SystemIntegrationPreferencesProviding {
    private let defaults: UserDefaults

    init(suiteName: String? = nil) {
        if let suiteName, let defaults = UserDefaults(suiteName: suiteName) {
            self.defaults = defaults
        } else {
            defaults = .standard
        }
    }

    func snapshot() -> SystemIntegrationPreferencesSnapshot {
        let tone = ReminderTone(rawValue: defaults.string(forKey: "reminderToneRaw") ?? "")
            ?? .soft
        let quietHours: QuietHours?
        if defaults.object(forKey: "quietHoursEnabled") == nil
            || defaults.bool(forKey: "quietHoursEnabled") {
            quietHours = try? QuietHours(
                startHour: defaults.object(forKey: "quietHoursStartHour") == nil
                    ? 21
                    : defaults.integer(forKey: "quietHoursStartHour"),
                endHour: defaults.object(forKey: "quietHoursEndHour") == nil
                    ? 9
                    : defaults.integer(forKey: "quietHoursEndHour")
            )
        } else {
            quietHours = nil
        }
        let storedLimit = defaults.object(forKey: "maxDailyInterruptions") == nil
            ? SettingsStore.maximumDailyInterruptions
            : defaults.integer(forKey: "maxDailyInterruptions")
        return SystemIntegrationPreferencesSnapshot(
            accountingCurrencyCode: defaults.string(forKey: "currencyCode") ?? "",
            budgetCycleStartDay: defaults.object(forKey: "budgetCycleStartDay") == nil
                ? 1
                : defaults.integer(forKey: "budgetCycleStartDay"),
            siriEnabled: defaults.bool(forKey: "enableSiriIntegration"),
            spotlightEnabled: defaults.bool(forKey: "enableSpotlightIndexing"),
            merchantNamesEnabled: defaults.bool(forKey: "indexMerchantNames"),
            notificationPreferences: PreferencesSnapshot(
                reminderTone: tone,
                gentleRemindersEnabled: defaults.object(forKey: "enableGentleReminders") == nil
                    || defaults.bool(forKey: "enableGentleReminders"),
                notificationsEnabled: defaults.bool(forKey: "enableLocalNotifications"),
                quietHours: quietHours,
                maxDailyInterruptions: min(
                    max(storedLimit, 0),
                    SettingsStore.maximumDailyInterruptions
                )
            )
        )
    }
}

@MainActor
extension SettingsStore {
    var systemIntegrationPreferencesSnapshot: SystemIntegrationPreferencesSnapshot {
        SystemIntegrationPreferencesSnapshot(
            accountingCurrencyCode: currencyCode,
            budgetCycleStartDay: budgetCycleStartDay,
            siriEnabled: enableSiriIntegration,
            spotlightEnabled: enableSpotlightIndexing,
            merchantNamesEnabled: indexMerchantNames,
            notificationPreferences: preferencesSnapshot
        )
    }
}
