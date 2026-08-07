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
