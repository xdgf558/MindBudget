import Foundation
import Testing
@testable import MindBudget

struct LocalizationTests {
    @Test
    func appBundleLoadsLocalizedPhaseThreeCopy() {
        let key = "onboarding.title"
        let localizedValue = Bundle.main.localizedString(
            forKey: key,
            value: nil,
            table: nil
        )

        #expect(Bundle.main.bundleURL.pathExtension == "app")
        #expect(localizedValue != key)
        #expect(localizedValue.isEmpty == false)
    }

    @Test
    func englishAndSimplifiedChineseCatalogsHaveMatchingCompleteKeys() throws {
        let english = try localizedStrings(language: "en")
        let chinese = try localizedStrings(language: "zh-Hans")

        #expect(english.keys == chinese.keys)
        #expect(english.count >= 560)
        for key in english.keys {
            let englishValue = try #require(english[key])
            let chineseValue = try #require(chinese[key])
            #expect(!englishValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!chineseValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!englishValue.contains("\u{FFFD}"))
            #expect(!chineseValue.contains("\u{FFFD}"))
            #expect(formatSpecifierKinds(in: englishValue) == formatSpecifierKinds(in: chineseValue))
        }
    }

    @Test
    func phaseTenRepairCopyIsAvailableInBothLanguages() throws {
        let english = try localizedBundle(language: "en")
        let chinese = try localizedBundle(language: "zh-Hans")

        #expect(
            english.localizedString(
                forKey: "settings.notifications.repair.action",
                value: nil,
                table: nil
            ) == "Review and remove unreadable records"
        )
        #expect(
            chinese.localizedString(
                forKey: "settings.notifications.repair.action",
                value: nil,
                table: nil
            ) == "查看并移除无法读取的记录"
        )
    }

    @Test
    func appDisplayNameIsLocalizedWithoutCombiningBrands() throws {
        let english = try localizedBundle(language: "en")
        let chinese = try localizedBundle(language: "zh-Hans")

        #expect(
            english.localizedString(
                forKey: "CFBundleDisplayName",
                value: nil,
                table: "InfoPlist"
            ) == "MindBudget"
        )
        #expect(
            chinese.localizedString(
                forKey: "CFBundleDisplayName",
                value: nil,
                table: "InfoPlist"
            ) == "花有数"
        )
        #expect(
            english.localizedString(
                forKey: "NSFaceIDUsageDescription",
                value: nil,
                table: "InfoPlist"
            ) == "Use Face ID to protect your local budget records."
        )
        #expect(
            chinese.localizedString(
                forKey: "NSFaceIDUsageDescription",
                value: nil,
                table: "InfoPlist"
            ) == "使用面容 ID 保护你保存在本机的预算记录。"
        )
        #expect(
            english.localizedString(
                forKey: "NSCameraUsageDescription",
                value: nil,
                table: "InfoPlist"
            ) == "Use the camera to capture a receipt for local processing."
        )
        #expect(
            chinese.localizedString(
                forKey: "NSCameraUsageDescription",
                value: nil,
                table: "InfoPlist"
            ) == "使用相机拍摄收据，并仅在本机处理图像。"
        )
    }

    @Test
    func foreignCurrencyLocalOnlyCopyExplainsExplicitOffAndPreservedStewardship() throws {
        let english = try localizedStrings(language: "en")
        let chinese = try localizedStrings(language: "zh-Hans")

        #expect(english["fx.help.sync"] ==
            "Foreign-currency records stay on this device. To add one, first turn off iCloud sync in Settings.")
        #expect(chinese["fx.help.sync"] == "外币记录仅保留在本机。新增前，请先在设置中主动关闭 iCloud 同步。")
        #expect(english["fx.help.offline"]?.contains(
            "These records stay on this device and cannot be used with iCloud sync."
        ) == true)
        #expect(chinese["fx.help.offline"]?.contains(
            "这些记录仅保留在本机，暂不可与 iCloud 同步同时使用。"
        ) == true)
        #expect(english["fx.error.sync"] ==
            "To add a foreign-currency record or convert an ordinary expense, first turn off iCloud sync in Settings. Your input has been kept. Existing foreign-currency records remain editable.")
        #expect(chinese["fx.error.sync"] ==
            "新增外币记录或将普通支出转为外币前，请先在设置中主动关闭 iCloud 同步。已保留您的输入；已有外币记录仍可编辑。")
        #expect(english["settings.icloudSync.status.foreignCurrency"] ==
            "Paused — foreign-currency records are local only")
        #expect(chinese["settings.icloudSync.status.foreignCurrency"] == "已暂停：外币记录仅限本机")
        #expect(english["settings.icloudSync.foreignCurrency.localOnly"]?.contains(
            "existing foreign-currency records remain editable and exportable without Pro"
        ) == true)
        #expect(chinese["settings.icloudSync.foreignCurrency.localOnly"]?.contains(
            "无需 Pro 也可继续编辑和导出已有外币记录"
        ) == true)
        #expect(english["settings.icloudSync.disclosure"]?.contains(
            "Foreign-currency recording is currently local only and cannot be used with iCloud sync."
        ) == true)
        #expect(chinese["settings.icloudSync.disclosure"]?.contains(
            "外币记账目前仅限本机，暂不可与 iCloud 同步同时使用。"
        ) == true)
    }

    @Test
    func simplifiedChineseCopyUsesOnlyTheChineseProductName() throws {
        let chinese = try localizedStrings(language: "zh-Hans")

        #expect(chinese.values.contains(where: { $0.contains("MindBudget") }) == false)
        #expect(chinese["ask.title"] == "问花有数")
        #expect(chinese["settings.ask.enabled"] == "显示“问花有数”")
    }

    @Test
    func allThreeSkinNamesAreLocalized() throws {
        let english = try localizedStrings(language: "en")
        let chinese = try localizedStrings(language: "zh-Hans")

        for skin in AppSkin.allCases {
            #expect(english[skin.nameLocalizationKey]?.isEmpty == false)
            #expect(chinese[skin.nameLocalizationKey]?.isEmpty == false)
            #expect(english[skin.descriptionLocalizationKey]?.isEmpty == false)
            #expect(chinese[skin.descriptionLocalizationKey]?.isEmpty == false)
        }
    }

    @Test
    func ledgerFilterRuntimeValuesResolveInsteadOfShowingCatalogKeys() throws {
        let english = try localizedBundle(language: "en")
        let chinese = try localizedBundle(language: "zh-Hans")
        let expectedRecordTypes: [LedgerRecordType: (english: String, chinese: String)] = [
            .all: ("All", "全部"),
            .expense: ("Expenses", "支出"),
            .income: ("Income", "收入"),
        ]
        let expectedBuckets: [BudgetBucket: (english: String, chinese: String)] = [
            .fixed: ("Fixed", "固定"),
            .discretionary: ("Flexible", "灵活"),
            .savings: ("Savings", "储蓄"),
        ]

        for recordType in LedgerRecordType.allCases {
            let expected = try #require(expectedRecordTypes[recordType])
            #expect(
                english.localizedString(
                    forKey: recordType.localizedNameKey,
                    value: nil,
                    table: nil
                ) == expected.english
            )
            #expect(
                chinese.localizedString(
                    forKey: recordType.localizedNameKey,
                    value: nil,
                    table: nil
                ) == expected.chinese
            )
        }

        for bucket in BudgetBucket.allCases {
            let expected = try #require(expectedBuckets[bucket])
            #expect(
                english.localizedString(
                    forKey: bucket.localizedNameKey,
                    value: nil,
                    table: nil
                ) == expected.english
            )
            #expect(
                chinese.localizedString(
                    forKey: bucket.localizedNameKey,
                    value: nil,
                    table: nil
                ) == expected.chinese
            )
        }
    }

    @Test
    func unavailableDailyAllowanceExplanationIsLocalizedWithoutJudgment() throws {
        let english = try localizedBundle(language: "en")
        let chinese = try localizedBundle(language: "zh-Hans")

        #expect(
            english.localizedString(
                forKey: "dashboard.today.noAllowance",
                value: nil,
                table: nil
            ) == "No daily amount is currently available from this cycle's flexible budget."
        )
        #expect(
            chinese.localizedString(
                forKey: "dashboard.today.noAllowance",
                value: nil,
                table: nil
            ) == "本周期灵活预算暂无可分配的今日额度。"
        )
    }

    @Test
    func installedReleaseNotesStayCurrentWhileEarlierVersionsCollapseIntoHistory() throws {
        let presentation = ReleaseNotesCatalog.presentation(installedVersion: "0.9.9")

        #expect(presentation.current?.version == "0.9.9")
        #expect(presentation.current?.items.count == 4)
        #expect(
            Set(presentation.current?.items.map(\.localizationKey) ?? []) == [
                "settings.releaseNotes.receiptImport",
                "settings.releaseNotes.optionalCloudSync",
                "settings.releaseNotes.optionalAnalytics",
                "settings.releaseNotes.accessibilityPolish",
            ]
        )
        #expect(
            presentation.history.map(\.version) == ["0.9.8", "0.9.7", "0.9.6", "0.9.5", "0.9.4", "0.9.2", "0.9.1", "0.9.0"]
        )

        let future = ReleaseNotesVersion(
            version: "0.10.0",
            items: [
                ReleaseNoteItem(
                    systemImage: "sparkles",
                    localizationKey: "settings.releaseNotes.included"
                )
            ]
        )
        let nextPresentation = ReleaseNotesCatalog.presentation(
            installedVersion: "0.10.0",
            versions: [future] + ReleaseNotesCatalog.versions
        )

        #expect(nextPresentation.current?.version == "0.10.0")
        #expect(
            nextPresentation.history.map(\.version) == ["0.9.9", "0.9.8", "0.9.7", "0.9.6", "0.9.5", "0.9.4", "0.9.2", "0.9.1", "0.9.0"]
        )
    }

    @Test
    func phaseTwelveLanguageAndPlanningCopyResolvesInBothCatalogs() throws {
        let english = try localizedStrings(language: "en")
        let chinese = try localizedStrings(language: "zh-Hans")
        let keys = [
            "settings.language.system",
            "settings.language.zh-Hans",
            "settings.language.en",
            "income.allocation.budget",
            "income.allocation.savings",
            "income.allocation.cycle.target",
            "income.allocation.cycle.unavailable",
            "income.error.budgetCycleUnavailable",
            "settings.savingsGoal.title",
            "settings.recurring.title",
            "settings.recurring.reconcile.pending",
            "expense.recurring.monthly",
            "settings.releaseNotes.appLanguage",
            "settings.releaseNotes.incomeAllocation",
            "settings.releaseNotes.globalSavingsGoal",
            "settings.releaseNotes.recurringFixedExpenses",
            "settings.releaseNotes.paceAppIcon",
            "settings.releaseNotes.savingsProgress",
            "settings.releaseNotes.aiAppLanguage",
            "settings.releaseNotes.truthfulCycleUsage",
            "settings.releaseNotes.askFallbackReasons",
            "settings.releaseNotes.simplifiedBudgetSetup",
            "settings.releaseNotes.subscriptionExperience",
            "settings.releaseNotes.trialLifecycle",
            "settings.releaseNotes.subscriptionGuidance",
            "settings.releaseNotes.insightsReview",
            "settings.releaseNotes.settingsGroups",
            "settings.releaseNotes.languageEntry",
            "settings.releaseNotes.chartPalette",
            "settings.releaseNotes.insightsGroups",
        ]

        for key in keys {
            #expect(english[key]?.isEmpty == false)
            #expect(chinese[key]?.isEmpty == false)
            #expect(english[key] != key)
            #expect(chinese[key] != key)
        }
    }

    private func localizedStrings(language: String) throws -> [String: String] {
        let bundle = try localizedBundle(language: language)
        let url = try #require(bundle.url(forResource: "Localizable", withExtension: "strings"))
        let data = try Data(contentsOf: url)
        let propertyList = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(propertyList as? [String: String])
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path))
    }

    /// Positional indices may differ by language, but both translations must accept the
    /// same argument kinds so a localized format cannot crash at runtime.
    private func formatSpecifierKinds(in value: String) -> [Character] {
        let conversions: Set<Character> = ["@", "d", "i", "u", "o", "x", "X", "f", "F", "e", "E", "g", "G", "a", "A", "c", "C", "s", "S", "p"]
        var kinds: [Character] = []
        var index = value.startIndex
        while index < value.endIndex {
            guard value[index] == "%" else {
                index = value.index(after: index)
                continue
            }
            index = value.index(after: index)
            if index < value.endIndex, value[index] == "%" {
                index = value.index(after: index)
                continue
            }
            guard index < value.endIndex,
                  conversions.contains(value[index])
                    || value[index].isNumber
                    || ".$-+#lhLzjtq".contains(value[index]) else {
                continue
            }
            while index < value.endIndex {
                let character = value[index]
                if conversions.contains(character) {
                    kinds.append(character)
                    index = value.index(after: index)
                    break
                }
                index = value.index(after: index)
            }
        }
        return kinds.sorted()
    }
}
