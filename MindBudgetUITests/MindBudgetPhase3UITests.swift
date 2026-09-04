import XCTest

final class MindBudgetPhase3UITests: XCTestCase {
    @MainActor
    func testManualForeignCurrencyEnglishProCreateAndDetail() async throws {
        try await exerciseForeignCurrency(language: "en", locale: "en_US", ax5: false)
    }

    @MainActor
    func testManualForeignCurrencyChineseAX5ProCreateAndDetail() async throws {
        try await exerciseForeignCurrency(language: "zh-Hans", locale: "zh_CN", ax5: true)
    }

    @MainActor
    private func exerciseForeignCurrency(language: String, locale: String, ax5: Bool) async throws {
        guard ProcessInfo.processInfo.environment["MINDBUDGET_FX_UI_TESTS"] == "1" else {
            throw XCTSkip("Requires the separately compiled FX UI host; this skip is not UI evidence.")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        if ax5 {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        continueAfterFailure = false
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["fx.testHost"].waitForExistence(timeout: 8),
                      "Normal AppBootstrap must never substitute for the compiled in-memory host")
        XCTAssertTrue(element("expense.form", in: app).waitForExistence(timeout: 5))
        let toggle = app.switches["fx.enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let granted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: toggle)
        XCTAssertEqual(XCTWaiter.wait(for: [granted], timeout: 10), .completed,
                       "The isolated fixture must reach the real Commerce access boundary")
        revealFX(toggle, in: app)
        // At AX5 the switch's accessibility frame includes its multiline label. Hit the
        // trailing native switch, not the center of that combined label rectangle.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '1'"), object: toggle)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        XCTAssertLessThanOrEqual(app.scrollViews["expense.form"].frame.width,
                                 app.windows.firstMatch.frame.width + 1,
                                 "AX5 content must not force the form wider than the viewport")
        let currency = app.buttons["fx.originalCurrency"]
        revealFX(currency, in: app)
        currency.tap()
        let euro = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "EUR")).firstMatch
        for _ in 0..<10 {
            if euro.exists && euro.isHittable { break }
            let menu = app.collectionViews.firstMatch
            XCTAssertTrue(menu.waitForExistence(timeout: 2))
            let top = menu.frame.minY
            let origin = app.coordinate(withNormalizedOffset: .zero)
            origin.withOffset(CGVector(dx: menu.frame.midX, dy: top + 300))
                .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: menu.frame.midX, dy: top + 80)))
        }
        XCTAssertTrue(euro.exists && euro.isHittable)
        euro.tap()
        if ax5 {
            let date = app.buttons["fx.rateDate"]
            revealFX(date, in: app)
            XCTAssertFalse((date.value as? String ?? "").isEmpty)
            date.tap()
            XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 3))
            app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "2024年")
            XCTAssertEqual(app.pickerWheels.element(boundBy: 0).value as? String, "2024年")
            let done = app.buttons["fx.rateDate.done"]
            XCTAssertTrue(done.waitForExistence(timeout: 3) && done.isHittable)
            done.tap()
            XCTAssertTrue(app.buttons["fx.rateDate"].waitForExistence(timeout: 3))
            XCTAssertTrue((app.buttons["fx.rateDate"].value as? String ?? "").contains("2024"))
        }
        enterFX("3", into: app.textFields["fx.originalAmount"], in: app)
        enterFX("2", into: app.textFields["fx.rate"], in: app)
        XCTAssertEqual(app.textFields["fx.originalAmount"].label, ax5 ? "原币金额" : "Original amount")
        XCTAssertEqual(app.textFields["fx.originalAmount"].value as? String, "3")
        XCTAssertEqual(app.textFields["fx.rate"].value as? String, "2")
        XCTAssertEqual(app.textFields["fx.accountingAmount"].value as? String, "6")
        let direction = app.staticTexts["fx.direction"].label
        XCTAssertTrue(direction.contains("EUR") && direction.contains("USD"))
        if let original = direction.range(of: "EUR"), let accounting = direction.range(of: "USD") {
            XCTAssertLessThan(original.lowerBound, accounting.lowerBound)
        } else { XCTFail("Accessible rate direction lost a currency identity") }
        dismissFXKeyboard(in: app)
        let preview = app.staticTexts["fx.preview"]
        revealFX(preview, in: app)
        XCTAssertTrue(preview.waitForExistence(timeout: 3))
        XCTAssertTrue(preview.label.contains("USD"))
        XCTAssertTrue(preview.label.contains("6"))
        let formImage = XCTAttachment(screenshot: app.screenshot())
        formImage.name = "FX manual form - \(language) - AX5 \(ax5)"
        formImage.lifetime = .keepAlways
        add(formImage)
        let save = app.buttons["expense.save"]
        revealFX(save, in: app)
        save.tap()
        XCTAssertTrue(app.buttons["expense.edit"].waitForExistence(timeout: 5))
        let detailImage = XCTAttachment(screenshot: app.screenshot())
        detailImage.name = "FX saved detail - \(language) - AX5 \(ax5)"
        detailImage.lifetime = .keepAlways
        add(detailImage)
        let spokenAmounts = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@", "EUR", "USD"
        )).firstMatch
        XCTAssertTrue(spokenAmounts.waitForExistence(timeout: 3))
        let spoken = spokenAmounts.label
        // The combined accessibility element must announce original before accounting money.
        XCTAssertTrue(spoken.contains("3 EUR") && spoken.contains("6 USD"))
        if let original = spoken.range(of: "3 EUR"), let accounting = spoken.range(of: "6 USD") {
            XCTAssertLessThan(original.lowerBound, accounting.lowerBound)
        } else { XCTFail("Combined accessibility amount lost its original/accounting values") }
        let spokenRate = element("fx.detail.rate", in: app).label
        XCTAssertTrue(spokenRate.contains("EUR") && spokenRate.contains("USD") && spokenRate.contains("2"))
        if ax5 {
            let savedDate = element("fx.detail.rateDate", in: app)
            XCTAssertTrue((savedDate.label + (savedDate.value as? String ?? "")).contains("2024"))
        }
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "EUR")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "USD")).firstMatch.exists)
        // Actual stored FX remains editable after access expires and Settings changes to JPY.
        app.buttons["fx.testHost.revoke"].tap()
        app.buttons["expense.edit"].tap()
        XCTAssertTrue(app.switches["fx.enabled"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["fx.enabled"].isEnabled)
        if ax5 {
            XCTAssertTrue((app.buttons["fx.rateDate"].value as? String ?? "").contains("2024"))
        }
        enterFX("3", into: app.textFields["fx.rate"], in: app)
        dismissFXKeyboard(in: app)
        revealFX(app.staticTexts["fx.preview"], in: app)
        XCTAssertTrue(app.staticTexts["fx.preview"].label.contains("USD"))
        XCTAssertTrue(app.staticTexts["fx.preview"].label.contains("9"))
        revealFX(app.buttons["expense.save"], in: app)
        app.buttons["expense.save"].tap()
        XCTAssertTrue(app.buttons["expense.edit"].waitForExistence(timeout: 5))
        let updated = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "USD", "9")).firstMatch
        XCTAssertTrue(updated.waitForExistence(timeout: 5))
    }

    @MainActor
    private func dismissFXKeyboard(in app: XCUIApplication) {
        let done = app.buttons["fx.keyboard.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 3) && done.isHittable,
                      "FX numeric editing needs an accessible way to finish and read the result")
        done.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                  object: app.keyboards.firstMatch)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 3), .completed)
    }

    @MainActor
    private func enterFX(_ value: String, into field: XCUIElement, in app: XCUIApplication) {
        revealFX(field, in: app)
        field.tap()
        if let existing = field.value as? String, existing != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        field.typeText(value)
    }

    @MainActor
    private func revealFX(_ control: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<14 {
            let navBottom = app.navigationBars.allElementsBoundByIndex.last(where: \.isHittable)?.frame.maxY ?? 0
            let window = app.windows.firstMatch.frame
            let sentinel = app.staticTexts["fx.testHost"]
            let hostTop = sentinel.exists && sentinel.isHittable && sentinel.frame.minY > navBottom
                ? sentinel.frame.minY : window.maxY
            let keyboardTop = app.keyboards.firstMatch.exists
                ? min(app.keyboards.firstMatch.frame.minY, hostTop) : hostTop
            let save = app.buttons["expense.save"]
            let contentBottom = save.exists && save.frame.minY > navBottom
                ? min(save.frame.minY, keyboardTop) : keyboardTop
            let isSave = control.exists && control.identifier == "expense.save"
            let limit = isSave ? keyboardTop : contentBottom
            let needsHitPoint = control.exists && control.elementType != .staticText
            if control.exists && (!needsHitPoint || control.isHittable) && control.frame.minY > navBottom
                && control.frame.maxY < limit { return }
            let top = navBottom + 12
            let height = contentBottom - top - 12
            guard height > 60 else { XCTFail("No unobscured FX scroll viewport"); return }
            let moveDown = control.exists && control.frame.minY < top
            let center = top + height / 2
            let distance = min(max(control.exists ? abs(control.frame.midY - center) : 120, 30), min(180, height * 0.45))
            let origin = app.coordinate(withNormalizedOffset: .zero)
            // A pan beginning inside a numeric TextField is consumed by its text interaction;
            // the AX5 run stalled at exactly that frame. Date wheels also own vertical pans.
            // Choose a gap in the actual scroll content, keeping BOTH endpoints unobscured.
            let occupied = (app.textFields.allElementsBoundByIndex + app.pickerWheels.allElementsBoundByIndex
                            + app.buttons.allElementsBoundByIndex)
                .map(\.frame).filter { $0.minX <= window.midX && $0.maxX >= window.midX }
            let lowerStart = moveDown ? top : top + distance
            let upperStart = moveDown ? contentBottom - 12 - distance : contentBottom - 12
            let candidates = stride(from: upperStart, through: lowerStart, by: -8.0)
            guard let startY = candidates.first(where: { y in
                !occupied.contains { $0.minY - 8 <= y && $0.maxY + 8 >= y }
            }) else { XCTFail("No unobscured non-editor FX pan origin"); return }
            let start = origin.withOffset(CGVector(dx: window.midX, dy: startY))
            let end = origin.withOffset(CGVector(dx: window.midX, dy: startY + (moveDown ? distance : -distance)))
            XCTContext.runActivity(named: "FX viewport target \(control.frame), visible \(top)...\(contentBottom), down \(moveDown)") { _ in
                // End at rest: a default 500pt/s release adds momentum beyond the calculated
                // displacement and can oscillate an AX5 label above/below the keyboard gap.
                start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
            }
        }
        let failureImage = XCTAttachment(screenshot: app.screenshot())
        failureImage.name = "FX failed viewport"
        failureImage.lifetime = .keepAlways
        add(failureImage)
        XCTFail("FX control did not enter the unobscured viewport: \(control); frame=\(control.frame); \(app.debugDescription)")
    }

    @MainActor
    func testColdLaunchShowsLocalizedBrandAnimation() {
        let app = launchApp(
            language: "zh-Hans",
            locale: "zh_CN",
            additionalArguments: ["-ui-testing-hold-launch-animation"]
        )

        XCTAssertTrue(element("launch.animation", in: app).waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["launch.brandName"].label, "花有数")
        XCTAssertEqual(
            app.staticTexts["launch.brandSubtitle"].label,
            "温和的预算与消费复盘工具"
        )
    }

    @MainActor
    func testEnglishOnboardingCopyRenders() {
        assertOnboardingCopy(
            language: "en",
            locale: "en_US",
            expectedLabel: "A calmer way to manage money"
        )
    }

    @MainActor
    func testSimplifiedChineseOnboardingBudgetKeyboardAndSettingsToneRender() {
        let app = assertOnboardingCopy(
            language: "zh-Hans",
            locale: "zh_CN",
            expectedLabel: "更从容地管理每一笔钱"
        )

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["本月收入"].exists)
        XCTAssertTrue(app.staticTexts["预计支出"].exists)
        XCTAssertFalse(app.textFields["budget.fixedExpenses"].exists)
        app.textFields["budget.monthlyIncome"].tap()
        assertBudgetKeyboardHasNoCompletionToolbar(in: app)
        app.textFields["budget.monthlyIncome"].typeText("3000")
        let totalBudgetField = app.textFields["budget.totalBudget"]
        XCTAssertNotEqual(totalBudgetField.value as? String, "3000")
        totalBudgetField.tap()
        totalBudgetField.typeText("2500")
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
        XCTAssertTrue(app.staticTexts["本期可支配预算"].exists)
        app.buttons["budget.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(element("dashboard.today.left", in: app).exists)
        app.buttons["dashboard.settings"].tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))
        app.buttons["settings.reminders"].tap()
        XCTAssertTrue(element("settings.reminders.view", in: app).waitForExistence(timeout: 5))
        let tonePicker = element("settings.reminders.tone", in: app)
        XCTAssertTrue(tonePicker.exists)
        XCTAssertEqual(tonePicker.value as? String, "柔和")
        XCTAssertFalse(app.staticTexts["settings.reminders.tone.soft"].exists)
    }

    @MainActor
    func testSimplifiedChineseLedgerFilterValuesRenderWithoutCatalogKeys() {
        let app = launchApp(language: "zh-Hans", locale: "zh_CN")
        completeBudgetSetup(in: app)

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["tab.log"].tap()
        XCTAssertTrue(element("expenses.list", in: app).waitForExistence(timeout: 5))
        app.buttons["expenses.filter"].tap()

        for (identifier, label) in [
            ("expenses.filter.recordType.all", "全部"),
            ("expenses.filter.recordType.expense", "支出"),
            ("expenses.filter.recordType.income", "收入"),
        ] {
            let segment = element(identifier, in: app)
            XCTAssertTrue(segment.waitForExistence(timeout: 2))
            XCTAssertEqual(segment.label, label)
        }

        let bucketPicker = element("expenses.filter.bucket", in: app)
        XCTAssertTrue(bucketPicker.exists)
        bucketPicker.tap()

        for (identifier, label) in [
            ("expenses.filter.bucket.fixed", "固定"),
            ("expenses.filter.bucket.discretionary", "灵活"),
            ("expenses.filter.bucket.savings", "储蓄"),
        ] {
            let option = element(identifier, in: app)
            XCTAssertTrue(option.waitForExistence(timeout: 2))
            XCTAssertEqual(option.label, label)
        }

        XCTAssertFalse(app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "ledger.type.",
            "bucket."
        )).firstMatch.exists)
    }

    @MainActor
    func testAppLanguageChangesImmediatelyWithoutRelaunching() {
        let app = launchApp(language: "en", locale: "en_US")
        completeBudgetSetup(in: app)

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.settings"].tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))
        element("settings.language", in: app).tap()
        XCTAssertTrue(element("settings.language.view", in: app).waitForExistence(timeout: 2))

        let simplifiedChinese = app.buttons["Simplified Chinese"]
        XCTAssertTrue(simplifiedChinese.waitForExistence(timeout: 2))
        simplifiedChinese.tap()

        // The language page stays on screen while the language changes, so its own navigation bar
        // title is the strictest check that the new language took effect immediately.
        XCTAssertTrue(app.navigationBars["语言"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let localizedLanguageDestination = element("settings.language", in: app)
        XCTAssertTrue(localizedLanguageDestination.waitForExistence(timeout: 3))
        assertEventuallyHasLabel(
            localizedLanguageDestination,
            "语言",
            message: "Language row did not settle after changing the app language"
        )
        let localizedAppearanceDestination = element("settings.appearance", in: app)
        XCTAssertTrue(localizedAppearanceDestination.waitForExistence(timeout: 3))
        assertEventuallyHasLabel(
            localizedAppearanceDestination,
            "外观与皮肤",
            message: "Appearance row did not settle after changing the app language"
        )
    }

    @MainActor
    func testOnboardingAndManualExpenseFlow() {
        let app = launchApp(language: "en", locale: "en_US")

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))

        app.textFields["budget.monthlyIncome"].tap()
        app.textFields["budget.monthlyIncome"].typeText("3000")
        app.textFields["budget.totalBudget"].tap()
        app.textFields["budget.totalBudget"].typeText("2500")
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
        XCTAssertTrue(element("budget.flexiblePreview", in: app).waitForExistence(timeout: 2))
        assertBudgetKeyboardHasNoCompletionToolbar(in: app)
        XCTAssertTrue(app.buttons["budget.save"].waitForExistence(timeout: 2))
        app.buttons["budget.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        let dailyAmount = element("dashboard.today.left", in: app)
        XCTAssertTrue(dailyAmount.waitForExistence(timeout: 2))
        let dailyAmountBeforeExpense = dailyAmount.label
        assertCompactEmptyStateAction(
            app.buttons["dashboard.empty.addEntry"],
            named: "Dashboard Add Entry"
        )
        assertPrimaryNavigationIsBottomAnchored(in: app)
        assertEventuallySelected(
            app.buttons["tab.dashboard"],
            message: "Dashboard tab did not settle after onboarding"
        )
        XCTAssertEqual(app.buttons["tab.dashboard"].value as? String, "Tab 1 of 4")
        let paceTrack = element("dashboard.pace.track", in: app)
        XCTAssertTrue(paceTrack.waitForExistence(timeout: 2))
        XCTAssertFalse((paceTrack.value as? String ?? "").isEmpty)
        app.buttons["dashboard.empty.addEntry"].tap()
        let addExpense = firstElement("entry.add.expense", in: app)
        let addIncomeFromEmptyState = firstElement("entry.add.income", in: app)
        XCTAssertTrue(addExpense.waitForExistence(timeout: 5))
        XCTAssertTrue(addIncomeFromEmptyState.exists)
        addExpense.tap()

        XCTAssertTrue(element("expense.form", in: app).waitForExistence(timeout: 5))
        for key in ["1", "2", ".", "3", "4"] {
            element("expense.keypad.\(key)", in: app).tap()
        }
        let categoryScroll = element("expense.category.scroll", in: app)
        for _ in 0..<4 where !categoryScroll.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(categoryScroll.isHittable)
        let otherCategory = app.buttons["expense.category.other"]
        for _ in 0..<8 where !otherCategory.isHittable {
            categoryScroll.swipeLeft()
        }
        XCTAssertTrue(otherCategory.isHittable)
        otherCategory.tap()
        assertEventuallySelected(
            otherCategory,
            message: "Expense category selection did not settle before Save"
        )
        app.buttons["expense.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        let refreshedDailyAmount = element("dashboard.today.left", in: app)
        let dailyAmountChanged = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", dailyAmountBeforeExpense),
            object: refreshedDailyAmount
        )
        XCTAssertEqual(XCTWaiter.wait(for: [dailyAmountChanged], timeout: 5), .completed)
        app.buttons["dashboard.quickAdd"].tap()
        let addIncome = firstElement("entry.add.income", in: app)
        XCTAssertTrue(addIncome.waitForExistence(timeout: 5))
        addIncome.tap()
        XCTAssertTrue(element("income.form", in: app).waitForExistence(timeout: 5))
        for key in ["5", "0", "0"] {
            element("income.keypad.\(key)", in: app).tap()
        }
        app.buttons["income.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.expenses"].tap()
        XCTAssertTrue(app.staticTexts["Other"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Salary"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testWishlistAndCoolingOffFlow() {
        let app = launchApp(language: "en", locale: "en_US")

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))
        app.textFields["budget.monthlyIncome"].tap()
        app.textFields["budget.monthlyIncome"].typeText("3000")
        app.textFields["budget.totalBudget"].tap()
        app.textFields["budget.totalBudget"].typeText("2500")
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
        app.buttons["budget.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["tab.wishlist"].tap()
        XCTAssertTrue(app.buttons["tab.wishlist"].isSelected)
        XCTAssertEqual(app.buttons["tab.wishlist"].value as? String, "Tab 4 of 4")
        XCTAssertFalse(app.buttons["tab.dashboard"].isSelected)
        let emptyAddButton = app.buttons["wishlist.empty.add"]
        assertCompactEmptyStateAction(emptyAddButton, named: "Wishlist Add Item")
        emptyAddButton.tap()

        XCTAssertTrue(app.textFields["wishlist.name"].waitForExistence(timeout: 5))
        app.textFields["wishlist.name"].typeText("Headphones")
        app.buttons["wishlist.save"].tap()

        XCTAssertTrue(app.staticTexts["Headphones"].waitForExistence(timeout: 5))
        app.staticTexts["Headphones"].tap()
        XCTAssertTrue(app.buttons["wishlist.startCooling"].waitForExistence(timeout: 5))
        app.buttons["wishlist.startCooling"].tap()
        XCTAssertTrue(app.buttons["wishlist.cooling.start"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            element("wishlist.cooling.duration.fixed", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertFalse(element("wishlist.cooling.duration.picker", in: app).exists)
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
        app.textFields["budget.totalBudget"].tap()
        app.textFields["budget.totalBudget"].typeText("2500")
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
        app.buttons["budget.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["tab.insights"].tap()

        XCTAssertTrue(element("insights.view", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Last 30 days"].exists)
        XCTAssertTrue(element("insights.empty", in: app).exists)
        XCTAssertTrue(element("insights.disclaimer", in: app).exists)
        // With no recorded spending there are no category segments, but the 30-day trend still
        // renders. Its group heading must render with it rather than leaving the card ungrouped.
        XCTAssertTrue(element("insights.group.composition", in: app).exists)
        XCTAssertTrue(element("insights.group.currentCycle", in: app).exists)
        XCTAssertTrue(element("insights.group.longTerm", in: app).exists)

        app.buttons["tab.dashboard"].tap()
        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.quickAdd"].tap()
        let addExpense = firstElement("entry.add.expense", in: app)
        XCTAssertTrue(addExpense.waitForExistence(timeout: 5))
        addExpense.tap()
        XCTAssertTrue(element("expense.form", in: app).waitForExistence(timeout: 5))
        for key in ["1", "2", ".", "3", "4"] {
            element("expense.keypad.\(key)", in: app).tap()
        }
        app.buttons["expense.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["tab.insights"].tap()
        let recentTotal = element("insights.summary.thirtyDays.amount", in: app)
        XCTAssertTrue(recentTotal.waitForExistence(timeout: 5))
        XCTAssertTrue(recentTotal.label.contains("12.34"))
        let categoryPie = element("insights.chart.category.pie", in: app)
        for _ in 0..<5 where !categoryPie.exists {
            app.swipeUp()
        }
        XCTAssertTrue(categoryPie.waitForExistence(timeout: 3))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Insights category pie"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCategoryChartLegendKeepsSixItemsReachableInEnglish() {
        assertCategoryChartLegend(language: "en", locale: "en_US")
    }

    @MainActor
    func testCategoryChartLegendKeepsSixItemsReachableInSimplifiedChinese() {
        assertCategoryChartLegend(language: "zh-Hans", locale: "zh_CN")
    }

    @MainActor
    func testAskReturnsATemplateAnswerWithEnhancementOff() {
        let app = launchApp(language: "en", locale: "en_US")

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))
        app.textFields["budget.monthlyIncome"].tap()
        app.textFields["budget.monthlyIncome"].typeText("3000")
        app.textFields["budget.totalBudget"].tap()
        app.textFields["budget.totalBudget"].typeText("2500")
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
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
        XCTAssertTrue(app.staticTexts["Enhancement unavailable"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "On-device enhancement is off or unavailable, so the complete local answer is shown."
            ].exists
        )
    }

    @MainActor
    func testSimplifiedChineseAskLocalizesAnswerAndDynamicActions() {
        let app = launchApp(language: "zh-Hans", locale: "zh_CN")

        completeBudgetSetup(in: app)
        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.ask"].tap()
        XCTAssertTrue(app.textFields["ask.question"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["这个周期还剩多少？"].waitForExistence(timeout: 2))
        app.buttons["这个周期还剩多少？"].tap()
        app.buttons["ask.submit"].tap()

        XCTAssertTrue(element("ask.answer", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["剩余预算"].exists)
        XCTAssertTrue(app.staticTexts["增强暂不可用"].exists)
        XCTAssertTrue(
            app.staticTexts["本机增强已关闭或暂不可用，已显示完整的本地回答。"].exists
        )
        XCTAssertTrue(app.staticTexts["回看近期消费"].exists)
        XCTAssertTrue(app.staticTexts["检查预算设置"].exists)
        XCTAssertFalse(app.staticTexts["ask.action.reviewRecentSpending"].exists)
        XCTAssertFalse(app.staticTexts["ask.action.adjustBudget"].exists)
    }

    @MainActor
    func testSettingsShowsExportAndPrivacyControls() {
        let app = launchApp(language: "en", locale: "en_US")

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))
        app.textFields["budget.monthlyIncome"].tap()
        app.textFields["budget.monthlyIncome"].typeText("3000")
        app.textFields["budget.totalBudget"].tap()
        app.textFields["budget.totalBudget"].typeText("2500")
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
        app.buttons["budget.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.settings"].tap()

        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))
        for identifier in [
            "settings.language",
            "settings.appearance",
            "settings.budget",
            "settings.savingsGoal",
            "settings.recurring",
            "settings.reminders",
            "settings.ai",
            "settings.integrations",
            "settings.pro",
        ] {
            XCTAssertTrue(element(identifier, in: app).exists)
        }

        element("settings.budget", in: app).tap()
        XCTAssertTrue(element("settings.budget.view", in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(app.textFields["settings.budget.fixedExpenses"].exists)
        let totalBudgetField = app.textFields["settings.budget.totalBudget"]
        XCTAssertTrue(totalBudgetField.waitForExistence(timeout: 2))
        XCTAssertTrue(totalBudgetField.isEnabled)
        totalBudgetField.tap()
        totalBudgetField.typeText("0")
        let flexiblePreview = element("settings.budget.flexiblePreview", in: app)
        for _ in 0..<4 where !flexiblePreview.exists {
            app.swipeUp()
        }
        XCTAssertTrue(flexiblePreview.exists)
        let saveBudget = app.buttons["settings.budget.save"]
        for _ in 0..<4 where !saveBudget.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(saveBudget.isHittable)
        saveBudget.tap()
        XCTAssertTrue(element("settings.budget.saved", in: app).waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 2))

        element("settings.appearance", in: app).tap()
        XCTAssertTrue(element("settings.appearance.view", in: app).waitForExistence(timeout: 2))
        for skin in ["auroraGlow", "warmBotanical", "neonPulse"] {
            XCTAssertTrue(element("settings.appearance.skin.\(skin)", in: app).exists)
        }
        let neonSkin = element("settings.appearance.skin.neonPulse", in: app)
        neonSkin.tap()
        XCTAssertTrue(neonSkin.isSelected)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 2))
        let exportControl = element("settings.export", in: app)
        for _ in 0..<4 where !exportControl.exists {
            app.swipeUp()
        }
        XCTAssertTrue(exportControl.waitForExistence(timeout: 2))
        let privacyControl = element("settings.privacy", in: app)
        XCTAssertTrue(privacyControl.waitForExistence(timeout: 2))
        privacyControl.tap()
        XCTAssertTrue(element("settings.privacy.appLock", in: app).waitForExistence(timeout: 2))
        let telemetryControl = element("settings.privacy.telemetry", in: app)
        XCTAssertTrue(telemetryControl.waitForExistence(timeout: 2))
        telemetryControl.tap()
        let telemetryToggle = element("settings.telemetry.toggle", in: app)
        XCTAssertTrue(telemetryToggle.waitForExistence(timeout: 2))
        XCTAssertEqual(telemetryToggle.value as? String, "0")
        let neverIncludedDisclosure =
            "Never included: amounts, merchants, categories, notes, receipt images or text, StoreKit identifiers, iCloud records, free-form text, advertising data, or third-party analytics."
        XCTAssertTrue(
            app.staticTexts
                .matching(NSPredicate(format: "label == %@", neverIncludedDisclosure))
                .firstMatch.exists
        )
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("settings.privacy.appLock", in: app).waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 2))

        let aboutControl = element("settings.about", in: app)
        for _ in 0..<3 where !aboutControl.exists {
            app.swipeUp()
        }
        XCTAssertTrue(aboutControl.waitForExistence(timeout: 2))
        aboutControl.tap()
        XCTAssertTrue(element("settings.about.view", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["settings.version.value"].label.contains("0.9.9"))
        XCTAssertTrue(element("settings.releaseNotes", in: app).exists)
        XCTAssertFalse(element("settings.releaseNotes.history.0.9.1", in: app).exists)
        XCTAssertFalse(element("settings.releaseNotes.history.0.9.0", in: app).exists)
        let releaseHistory = element("settings.releaseNotes.history", in: app)
        for _ in 0..<5 where !releaseHistory.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(releaseHistory.isHittable)
        releaseHistory.tap()
        let previousRelease = element("settings.releaseNotes.history.0.9.1", in: app)
        for _ in 0..<5 where !previousRelease.exists {
            app.swipeUp()
        }
        XCTAssertTrue(previousRelease.waitForExistence(timeout: 2))
    }

    @MainActor
    func testProSubscriptionIsOnlyShownAfterAUserOpensTheSettingsEntry() {
        let app = launchApp(language: "en", locale: "en_US")
        completeBudgetSetup(in: app)

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(element("commerce.pro.view", in: app).exists)

        app.buttons["dashboard.settings"].tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))
        let proEntry = element("settings.pro", in: app)
        XCTAssertTrue(proEntry.waitForExistence(timeout: 2))
        proEntry.tap()

        XCTAssertTrue(element("commerce.pro.view", in: app).waitForExistence(timeout: 5))
        for identifier in [
            "commerce.pro.purchase",
            "commerce.pro.restore",
            "commerce.pro.manage",
        ] {
            let control = element(identifier, in: app)
            for _ in 0..<5 where !control.exists {
                app.swipeUp()
            }
            XCTAssertTrue(control.waitForExistence(timeout: 2))
        }
    }

    @MainActor
    func testProSubscriptionKeepsAX5ControlsReachableAcrossEveryAppearance() {
        let app = launchApp(
            language: "en",
            locale: "en_US",
            additionalArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
            ]
        )
        completeBudgetSetup(in: app)
        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.settings"].tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))

        for skin in ["auroraGlow", "warmBotanical", "neonPulse"] {
            for _ in 0..<6 where !element("settings.appearance", in: app).isHittable {
                app.swipeUp()
            }
            let appearance = element("settings.appearance", in: app)
            XCTAssertTrue(appearance.waitForExistence(timeout: 2))
            appearance.tap()

            let skinControl = app.buttons["settings.appearance.skin.\(skin)"]
            for _ in 0..<4 where !skinControl.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(skinControl.waitForExistence(timeout: 2))
            skinControl.tap()
            // Hosted run 33772144343 returned a Selected snapshot only after the old
            // two-second waiter had interrupted its first cross-process query. Keep
            // the query button-specific and allow time for the query itself to finish.
            guard assertEventuallySelected(
                skinControl,
                timeout: 5,
                message: "Appearance selection did not settle: \(skin)"
            ) else {
                return
            }
            app.navigationBars.buttons.element(boundBy: 0).tap()

            let proEntry = element("settings.pro", in: app)
            let settingsNavigationBottom = app.navigationBars.firstMatch.frame.maxY
            for _ in 0..<7 where
                !proEntry.isHittable || proEntry.frame.midY <= settingsNavigationBottom
            {
                app.swipeDown()
            }
            XCTAssertTrue(proEntry.waitForExistence(timeout: 2))
            XCTAssertGreaterThan(
                proEntry.frame.midY,
                settingsNavigationBottom,
                "Pro row hit point remained behind the Settings navigation bar"
            )
            let proView = element("commerce.pro.view", in: app)
            guard tapAndWaitForDestination(
                proEntry,
                destination: proView,
                message: "Pro destination did not settle after tapping its Settings row"
            ) else {
                return
            }

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "MindBudget Pro AX5 - \(skin)"
            screenshot.lifetime = .keepAlways
            add(screenshot)

            for identifier in [
                "commerce.pro.purchase",
                "commerce.pro.restore",
                "commerce.pro.manage",
            ] {
                let control = element(identifier, in: app)
                for _ in 0..<8 where !control.exists || control.frame.maxY > app.frame.maxY {
                    app.swipeUp()
                }
                XCTAssertTrue(control.waitForExistence(timeout: 2), "Missing AX5 control: \(identifier)")
                if identifier != "commerce.pro.purchase" {
                    XCTAssertTrue(control.isHittable, "Clipped AX5 control: \(identifier)")
                }
                XCTAssertGreaterThanOrEqual(control.frame.minX, app.frame.minX)
                XCTAssertLessThanOrEqual(control.frame.maxX, app.frame.maxX)
                XCTAssertGreaterThanOrEqual(control.frame.minY, app.frame.minY)
                XCTAssertLessThanOrEqual(control.frame.maxY, app.frame.maxY)
            }

            for destination in ["terms", "privacy"] {
                let link = element("commerce.pro.\(destination)", in: app)
                for _ in 0..<8 where !link.isHittable {
                    app.swipeUp()
                }
                XCTAssertTrue(
                    link.waitForExistence(timeout: 2),
                    "Missing AX5 legal link: \(destination)"
                )
                XCTAssertTrue(link.isHittable, "Clipped AX5 legal link: \(destination)")
                link.tap()

                let destinationView = element("commerce.pro.\(destination).view", in: app)
                XCTAssertTrue(
                    destinationView.waitForExistence(timeout: 5),
                    "Missing AX5 legal destination: \(destination)"
                )
                XCTAssertGreaterThanOrEqual(destinationView.frame.minX, app.frame.minX)
                XCTAssertLessThanOrEqual(destinationView.frame.maxX, app.frame.maxX)

                assertNavigationBackButtonReady(
                    in: app,
                    message: "AX5 legal navigation did not settle before capture: \(destination) / \(skin)"
                )

                let legalScreenshot = XCTAttachment(screenshot: app.screenshot())
                legalScreenshot.name = "MindBudget Pro \(destination) AX5 - \(skin)"
                legalScreenshot.lifetime = .keepAlways
                add(legalScreenshot)

                app.navigationBars.buttons.element(boundBy: 0).tap()
                XCTAssertTrue(element("commerce.pro.view", in: app).waitForExistence(timeout: 2))
            }

            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 2))
        }
    }

    @MainActor
    func testPhysicalC602AX5BilingualLightAndDarkAppearanceEvidence() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("C6-02 bilingual light/dark evidence requires a signed physical iPhone")
#else
        let variants = [
            (language: "en", locale: "en_US", skin: "warmBotanical", name: "English light"),
            (language: "en", locale: "en_US", skin: "neonPulse", name: "English dark"),
            (language: "zh-Hans", locale: "zh_CN", skin: "warmBotanical", name: "Chinese light"),
            (language: "zh-Hans", locale: "zh_CN", skin: "neonPulse", name: "Chinese dark"),
        ]

        for variant in variants {
            let app = launchApp(
                language: variant.language,
                locale: variant.locale,
                additionalArguments: [
                    "-UIPreferredContentSizeCategoryName",
                    "UICTContentSizeCategoryAccessibilityXXXL",
                ]
            )
            completeBudgetSetup(in: app)
            XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["dashboard.settings"].isHittable)
            app.buttons["dashboard.settings"].tap()
            XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))

            let appearance = element("settings.appearance", in: app)
            for _ in 0..<6 where !appearance.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(appearance.waitForExistence(timeout: 2))
            appearance.tap()

            let skinControl = app.buttons["settings.appearance.skin.\(variant.skin)"]
            for _ in 0..<4 where !skinControl.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(skinControl.waitForExistence(timeout: 2))
            skinControl.tap()
            guard assertEventuallySelected(
                skinControl,
                timeout: 5,
                message: "Physical AX5 appearance selection did not settle: \(variant.name)"
            ) else {
                app.terminate()
                return
            }
            assertNavigationBackButtonReady(
                in: app,
                message: "Physical AX5 Appearance navigation did not settle: \(variant.name)"
            )
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 3))

            let proEntry = element("settings.pro", in: app)
            let settingsNavigationBottom = app.navigationBars.firstMatch.frame.maxY
            for _ in 0..<7 where
                !proEntry.isHittable || proEntry.frame.midY <= settingsNavigationBottom
            {
                app.swipeDown()
            }
            XCTAssertTrue(proEntry.waitForExistence(timeout: 2))
            XCTAssertGreaterThan(
                proEntry.frame.midY,
                settingsNavigationBottom,
                "Physical AX5 Pro row remained behind the Settings navigation bar"
            )

            let proView = element("commerce.pro.view", in: app)
            guard tapAndWaitForDestination(
                proEntry,
                destination: proView,
                message: "Physical AX5 Pro destination did not settle: \(variant.name)"
            ) else {
                app.terminate()
                continue
            }
            assertNavigationBackButtonReady(
                in: app,
                message: "Physical AX5 Pro navigation did not settle: \(variant.name)"
            )

            let expectedTitle = variant.language == "zh-Hans" ? "花有数 Pro" : "MindBudget Pro"
            XCTAssertTrue(
                app.staticTexts[expectedTitle].waitForExistence(timeout: 3),
                "Missing localized Pro title: \(variant.name)"
            )

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "C6-02 physical AX5 - \(variant.name)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.terminate()
        }
#endif
    }

    @MainActor
    func testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable() {
        let accessibility1App = launchApp(
            language: "en",
            locale: "en_US",
            additionalArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityM",
            ]
        )
        completeBudgetSetup(in: accessibility1App)
        XCTAssertTrue(element("dashboard.view", in: accessibility1App).waitForExistence(timeout: 5))
        let accessibility1Content = element("dashboard.header.date", in: accessibility1App)
        XCTAssertTrue(accessibility1Content.waitForExistence(timeout: 2))
        let accessibility1ContentHeight = accessibility1Content.frame.height
        accessibility1App.terminate()

        let app = launchApp(
            language: "en",
            locale: "en_US",
            additionalArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
            ]
        )

        XCTAssertTrue(app.staticTexts["onboarding.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.continue"].isHittable)
        completeBudgetSetup(in: app)

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        let accessibility5Content = element("dashboard.header.date", in: app)
        XCTAssertTrue(accessibility5Content.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(
            accessibility5Content.frame.height,
            accessibility1ContentHeight + 1,
            "AX5 page content must remain larger than AX1 when navigation chrome is capped"
        )
        assertPrimaryNavigationIsBottomAnchored(in: app)
        for identifier in [
            "tab.dashboard",
            "tab.log",
            "dashboard.quickAdd",
            "tab.insights",
            "tab.wishlist",
        ] {
            let control = app.buttons[identifier]
            XCTAssertTrue(control.exists, "Missing AX5 navigation control: \(identifier)")
            XCTAssertTrue(control.isHittable, "Clipped AX5 navigation control: \(identifier)")
        }
        for identifier in ["tab.dashboard", "tab.log", "tab.insights", "tab.wishlist"] {
            XCTAssertLessThanOrEqual(
                app.buttons[identifier].frame.height,
                96,
                "AX5 navigation chrome must not consume the content viewport: \(identifier)"
            )
        }
        XCTAssertTrue(app.buttons["dashboard.settings"].isHittable)
    }

    @MainActor
    func testPseudoLongTextKeepsOnboardingAndPrimaryNavigationReachable() {
        let app = launchApp(
            language: "en",
            locale: "en_US",
            additionalArguments: [
                "-NSDoubleLocalizedStrings",
                "YES",
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
            ]
        )
        let title = app.staticTexts["onboarding.title"]

        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(title.label.count, "A calmer way to manage money".count)
        XCTAssertTrue(app.buttons["onboarding.continue"].isHittable)
        completeBudgetSetup(in: app)

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dashboard.quickAdd"].isHittable)
        XCTAssertTrue(app.buttons["dashboard.settings"].isHittable)
        XCTAssertTrue(app.buttons["tab.wishlist"].isHittable)
    }

    @MainActor
    @discardableResult
    private func assertOnboardingCopy(
        language: String,
        locale: String,
        expectedLabel: String
    ) -> XCUIApplication {
        let app = launchApp(language: language, locale: locale)
        let title = app.staticTexts["onboarding.title"]

        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, expectedLabel)
        return app
    }

    @MainActor
    private func assertBudgetKeyboardHasNoCompletionToolbar(in app: XCUIApplication) {
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        XCTAssertEqual(
            app.toolbars.buttons.count,
            0,
            "Budget entry must not expose a second keyboard-level completion action"
        )
    }

    @MainActor
    private func assertCompactEmptyStateAction(
        _ button: XCUIElement,
        named name: String
    ) {
        XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing \(name) action")
        XCTAssertGreaterThanOrEqual(
            button.frame.width,
            140,
            "\(name) action lost its horizontal breathing room"
        )
        XCTAssertGreaterThan(
            button.frame.width,
            button.frame.height * 2,
            "\(name) action became a cramped square control"
        )
    }

    @MainActor
    @discardableResult
    private func assertEventuallySelected(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        message: String
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { object, _ in
                (object as? XCUIElement)?.isSelected == true
            },
            object: element
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, message)
        return result == .completed
    }

    @MainActor
    private func assertEventuallyHasLabel(
        _ element: XCUIElement,
        _ expectedLabel: String,
        timeout: TimeInterval = 3,
        message: String
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expectedLabel),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, message)
    }

    @MainActor
    private func assertNavigationBackButtonReady(
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        message: String
    ) {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                guard backButton.exists,
                      backButton.isHittable else { return false }

                let frame = backButton.frame
                let hitPoint = CGPoint(x: frame.midX, y: frame.midY)
                return !frame.isEmpty
                    && app.frame.contains(hitPoint)
            },
            object: backButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, message)

        // On a physical device, the accessibility hierarchy can report a completed push one
        // compositor frame before navigation chrome appears in the first screenshot. Consume
        // that non-evidence frame only after the button geometry is ready, then let the caller
        // retain the following capture.
        XCTAssertFalse(app.screenshot().pngRepresentation.isEmpty, message)
    }

    @MainActor
    private func tapAndWaitForDestination(
        _ source: XCUIElement,
        destination: XCUIElement,
        attempts: Int = 2,
        timeout: TimeInterval = 3,
        message: String
    ) -> Bool {
        for _ in 0..<attempts {
            if destination.exists {
                return true
            }
            guard source.waitForExistence(timeout: timeout), source.isHittable else {
                continue
            }
            source.tap()
            if destination.waitForExistence(timeout: timeout) {
                return true
            }
        }
        XCTFail(message)
        return false
    }

    @MainActor
    private func launchApp(
        language: String,
        locale: String,
        additionalArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ] + additionalArguments
        app.launch()
        return app
    }

    @MainActor
    private func completeBudgetSetup(in app: XCUIApplication) {
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))
        let monthlyIncome = app.textFields["budget.monthlyIncome"]
        enterBudgetValue("3000", into: monthlyIncome, in: app)

        let totalBudget = app.textFields["budget.totalBudget"]
        enterBudgetValue("2500", into: totalBudget, in: app)

        let savingGoal = app.textFields["budget.savingGoal"]
        enterBudgetValue("500", into: savingGoal, in: app)

        let save = app.buttons["budget.save"]
        makeBudgetSaveReady(save, in: app)
        let dashboard = element("dashboard.view", in: app)
        // The active SwiftUI TextField accessibility value can lag its rendered digits under
        // pseudo-localization. The bounded Dashboard transition is the end-to-end authority that
        // all three values reached the view model, validated, persisted, and dismissed the form.
        // Under hosted load, a Form can report the Save control hittable while its first
        // synthesized tap is consumed by the still-focused decimal keyboard/scroll transaction.
        // Retry only while the authoritative destination is absent; this is an interaction
        // handshake, not an XCTest runner retry that could hide a failed assertion.
        _ = tapAndWaitForDestination(
            save,
            destination: dashboard,
            attempts: 2,
            timeout: 5,
            message: "Budget setup did not accept and persist all entered values"
        )
    }

    @MainActor
    private func makeBudgetSaveReady(
        _ save: XCUIElement,
        in app: XCUIApplication
    ) {
        let budgetForm = app.collectionViews["budget.setup.view"]

        for _ in 0..<12 {
            let navigationBottom = app.navigationBars.firstMatch.frame.maxY
            let keyboard = app.keyboards.firstMatch
            let safeBottom = keyboard.exists
                ? keyboard.frame.minY - 8
                : app.frame.maxY - 8
            if save.exists {
                let frame = save.frame
                if save.isHittable,
                   !frame.isEmpty,
                   frame.midY > navigationBottom + 8,
                   frame.maxY < safeBottom
                {
                    return
                }
            }

            // isHittable can remain true while the decimal keyboard covers the lower part of the
            // SwiftUI Form. Move the Form by a bounded amount until the whole Save control is in
            // the real interaction lane; do not rely on XCTest's implicit scroll-to-visible tap.
            let lowerPoint = budgetForm.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)
            )
            let upperPoint = budgetForm.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.34)
            )
            lowerPoint.press(forDuration: 0.05, thenDragTo: upperPoint)
        }

        XCTFail("Budget Save did not enter the safe interaction lane")
    }

    @MainActor
    private func enterBudgetValue(
        _ value: String,
        into field: XCUIElement,
        in app: XCUIApplication
    ) {
        let budgetForm = app.collectionViews["budget.setup.view"]

        for _ in 0..<12 {
            if field.exists {
                let navigationBottom = app.navigationBars.firstMatch.frame.maxY
                let keyboard = app.keyboards.firstMatch
                let safeBottom = keyboard.exists
                    ? keyboard.frame.minY - 8
                    : app.frame.maxY - 80
                let frame = field.frame
                if field.isHittable,
                   frame.midY > navigationBottom + 8,
                   frame.midY < safeBottom
                {
                    field.tap()
                    field.typeText(value)
                    return
                }

                // A full-screen swipe can move a large AX5 field from behind the keyboard to
                // behind the navigation bar (and back again) without ever exposing its hit point.
                // Move only a small portion of the budget form so the field converges into the
                // actual lane between those two pieces of system chrome.
                let upperPoint = budgetForm.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.5, dy: 0.38)
                )
                let lowerPoint = budgetForm.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)
                )
                if frame.midY <= navigationBottom + 8 {
                    upperPoint.press(forDuration: 0.05, thenDragTo: lowerPoint)
                } else {
                    lowerPoint.press(forDuration: 0.05, thenDragTo: upperPoint)
                }
            } else {
                app.swipeUp()
            }
        }

        XCTFail("Budget field did not enter the safe interaction lane: \(field.identifier)")
    }

    @MainActor
    private func makeHittable(
        _ element: XCUIElement,
        in app: XCUIApplication
    ) {
        for _ in 0..<8 where !element.exists || !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 2))
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func recordExpense(in app: XCUIApplication, category: String) {
        app.buttons["dashboard.quickAdd"].tap()
        // SwiftUI can expose this Menu action as either a Button or a DisclosureTriangle across
        // repeated UI-test launches. The stable contract is its accessibility identifier.
        let addExpense = firstElement("entry.add.expense", in: app)
        XCTAssertTrue(addExpense.waitForExistence(timeout: 5))
        addExpense.tap()
        XCTAssertTrue(element("expense.form", in: app).waitForExistence(timeout: 3))
        element("expense.keypad.1", in: app).tap()

        let categoryScroll = element("expense.category.scroll", in: app)
        let categoryButton = app.buttons["expense.category.\(category)"]
        for _ in 0..<12 where !categoryButton.isHittable {
            categoryScroll.swipeLeft()
        }
        XCTAssertTrue(categoryButton.isHittable, "Missing category: \(category)")
        categoryButton.tap()
        app.buttons["expense.save"].tap()
        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 3))
    }

    @MainActor
    private func assertCategoryChartLegend(language: String, locale: String) {
        let app = launchApp(language: language, locale: locale)
        completeBudgetSetup(in: app)
        for category in ["food", "coffee", "groceries", "transport", "shopping", "clothing"] {
            recordExpense(in: app, category: category)
        }

        app.buttons["tab.insights"].tap()
        let legend = element("insights.chart.category.legend", in: app)
        for _ in 0..<8 where !legend.exists || legend.frame.maxY > app.frame.maxY {
            app.swipeUp()
        }
        XCTAssertTrue(legend.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(legend.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(legend.frame.maxX, app.frame.maxX)

        for category in ["food", "coffee", "groceries", "transport", "shopping", "clothing"] {
            let item = element("insights.chart.category.legend.\(category)", in: app)
            for _ in 0..<8 where !item.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(item.waitForExistence(timeout: 2), "Missing legend item: \(category)")
            XCTAssertTrue(item.isHittable, "Clipped legend item: \(category)")
            XCTAssertGreaterThanOrEqual(item.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(item.frame.maxX, app.frame.maxX)
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Insights category legend - \(language)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func assertPrimaryNavigationIsBottomAnchored(in app: XCUIApplication) {
        let dashboardTab = app.buttons["tab.dashboard"]
        let quickAdd = app.buttons["dashboard.quickAdd"]
        let appFrame = app.frame

        XCTAssertTrue(dashboardTab.exists)
        XCTAssertTrue(quickAdd.exists)
        XCTAssertGreaterThan(dashboardTab.frame.midY, appFrame.maxY - 200)
        XCTAssertGreaterThan(quickAdd.frame.midY, appFrame.maxY - 240)
        XCTAssertLessThan(quickAdd.frame.midY, dashboardTab.frame.midY)
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func firstElement(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
