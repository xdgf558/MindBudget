import XCTest

final class MindBudgetLocalizationUITests: XCTestCase {
    @MainActor
    func testEnglishBootstrapCopyRenders() {
        assertBootstrapCopy(
            language: "en",
            locale: "en_US",
            expectedLabel: "MindBudget is ready"
        )
    }

    @MainActor
    func testSimplifiedChineseBootstrapCopyRenders() {
        assertBootstrapCopy(
            language: "zh-Hans",
            locale: "zh_CN",
            expectedLabel: "MindBudget 已就绪"
        )
    }

    @MainActor
    private func assertBootstrapCopy(
        language: String,
        locale: String,
        expectedLabel: String
    ) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        app.launch()

        let statusText = app.staticTexts["bootstrap.status.ready"]
        XCTAssertTrue(statusText.waitForExistence(timeout: 5))
        XCTAssertEqual(statusText.label, expectedLabel)
    }
}
