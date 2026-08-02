import XCTest

final class MindBudgetPlaceholderUITests: XCTestCase {
    @MainActor
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let statusText = app.staticTexts["bootstrap.status.ready"]
        XCTAssertTrue(statusText.waitForExistence(timeout: 5))
        XCTAssertEqual(statusText.label, "MindBudget is ready")
    }
}
