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
        for key in ["1", "2", ".", "3", "4"] {
            element("expense.keypad.\(key)", in: app).tap()
        }
        app.buttons["expense.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.expenses"].tap()
        XCTAssertTrue(app.staticTexts["Dining"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testWishlistAndCoolingOffFlow() {
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
        app.buttons["tab.wishlist"].tap()
        XCTAssertTrue(element("wishlist.empty", in: app).waitForExistence(timeout: 5))
        app.buttons["wishlist.add"].tap()

        XCTAssertTrue(app.textFields["wishlist.name"].waitForExistence(timeout: 5))
        app.textFields["wishlist.name"].typeText("Headphones")
        app.buttons["wishlist.save"].tap()

        XCTAssertTrue(app.staticTexts["Headphones"].waitForExistence(timeout: 5))
        app.staticTexts["Headphones"].tap()
        XCTAssertTrue(app.buttons["wishlist.startCooling"].waitForExistence(timeout: 5))
        app.buttons["wishlist.startCooling"].tap()
        XCTAssertTrue(app.buttons["wishlist.cooling.start"].waitForExistence(timeout: 5))
        let notificationToggle = app.switches["wishlist.cooling.notification"]
        if notificationToggle.waitForExistence(timeout: 2),
           notificationToggle.value as? String == "1" {
            notificationToggle.tap()
        }
        app.buttons["wishlist.cooling.start"].tap()

        XCTAssertTrue(
            element("wishlist.cooling.countdown", in: app).waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testInsightsShowsLocalSummaryAndHonestEmptyState() {
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
        app.buttons["tab.insights"].tap()

        XCTAssertTrue(element("insights.view", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Last 7 days"].exists)
        XCTAssertTrue(element("insights.empty", in: app).exists)
        XCTAssertTrue(element("insights.disclaimer", in: app).exists)
    }

    @MainActor
    func testAskReturnsATemplateAnswerWithEnhancementOff() {
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
        app.buttons["dashboard.ask"].tap()
        XCTAssertTrue(app.textFields["ask.question"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["How much is left?"].waitForExistence(timeout: 2))
        app.buttons["How much is left?"].tap()
        app.buttons["ask.submit"].tap()

        XCTAssertTrue(element("ask.answer", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Budget remaining"].exists)
        XCTAssertFalse(app.staticTexts["On-device enhanced"].exists)
    }

    @MainActor
    func testSettingsShowsExportAndPrivacyControls() {
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
        app.buttons["dashboard.settings"].tap()

        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))
        let exportControl = element("settings.export", in: app)
        for _ in 0..<4 where !exportControl.exists {
            app.swipeUp()
        }
        XCTAssertTrue(exportControl.waitForExistence(timeout: 2))
        XCTAssertTrue(element("settings.privacy", in: app).waitForExistence(timeout: 2))
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
