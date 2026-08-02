import XCTest

final class MindBudgetPlaceholderUITests: XCTestCase {
    @MainActor
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["bootstrap.status.ready"].waitForExistence(timeout: 5))
    }
}
