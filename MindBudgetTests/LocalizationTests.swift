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
        let presentation = ReleaseNotesCatalog.presentation(installedVersion: "0.9.5")

        #expect(presentation.current?.version == "0.9.5")
        #expect(presentation.current?.items.count == 4)
        #expect(
            presentation.current?.items.map(\.localizationKey).contains(
                "settings.releaseNotes.savingsProgress"
            ) == true
        )
        #expect(
            presentation.current?.items.map(\.localizationKey).contains(
                "settings.releaseNotes.aiAppLanguage"
            ) == true
        )
        #expect(
            presentation.current?.items.map(\.localizationKey).contains(
                "settings.releaseNotes.truthfulCycleUsage"
            ) == true
        )
        #expect(
            presentation.current?.items.map(\.localizationKey).contains(
                "settings.releaseNotes.askFallbackReasons"
            ) == true
        )
        #expect(presentation.history.map(\.version) == ["0.9.4", "0.9.2", "0.9.1", "0.9.0"])

        let future = ReleaseNotesVersion(
            version: "0.9.6",
            items: [
                ReleaseNoteItem(
                    systemImage: "sparkles",
                    localizationKey: "settings.releaseNotes.included"
                )
            ]
        )
        let nextPresentation = ReleaseNotesCatalog.presentation(
            installedVersion: "0.9.6",
            versions: [future] + ReleaseNotesCatalog.versions
        )

        #expect(nextPresentation.current?.version == "0.9.6")
        #expect(
            nextPresentation.history.map(\.version) == ["0.9.5", "0.9.4", "0.9.2", "0.9.1", "0.9.0"]
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
