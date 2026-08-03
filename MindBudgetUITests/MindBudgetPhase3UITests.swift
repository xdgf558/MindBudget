import XCTest

final class MindBudgetPhase3UITests: XCTestCase {
    @MainActor
    func testEnglishOnboardingCopyRenders() {
        assertOnboardingCopy(
            language: "en",
            locale: "en_US",
            expectedLabel: "A calmer way to manage money"
        )
    }

    @MainActor
    func testSimplifiedChineseOnboardingCopyRenders() {
        assertOnboardingCopy(
            language: "zh-Hans",
            locale: "zh_CN",
            expectedLabel: "更从容地管理每一笔钱"
        )
    }

    @MainActor
    func testOnboardingAndManualExpenseFlow() {
        let app = launchApp(language: "en", locale: "en_US")

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))

        app.textFields["budget.monthlyIncome"].tap()
        app.textFields["budget.monthlyIncome"].typeText("3000")
        dismissDecimalKeyboard(in: app)
        app.textFields["budget.fixedExpenses"].tap()
        app.textFields["budget.fixedExpenses"].typeText("1000")
        dismissDecimalKeyboard(in: app)
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
        dismissDecimalKeyboard(in: app)
        app.buttons["budget.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(element("dashboard.available", in: app).exists)
        app.buttons["dashboard.quickAdd"].tap()

        XCTAssertTrue(element("expense.form", in: app).waitForExistence(timeout: 5))
        app.textFields["expense.amount"].tap()
        app.textFields["expense.amount"].typeText("12.34")
        dismissDecimalKeyboard(in: app)
        app.buttons["expense.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.expenses"].tap()
        XCTAssertTrue(app.staticTexts["Dining"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func assertOnboardingCopy(
        language: String,
        locale: String,
        expectedLabel: String
    ) {
        let app = launchApp(language: language, locale: locale)
        let title = app.staticTexts["onboarding.title"]

        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, expectedLabel)
    }

    @MainActor
    private func launchApp(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        app.launch()
        return app
    }

    @MainActor
    private func dismissDecimalKeyboard(in app: XCUIApplication) {
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2))
        doneButton.tap()
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
