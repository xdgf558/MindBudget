import XCTest

final class MindBudgetPhase3UITests: XCTestCase {
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
        XCTAssertEqual(localizedLanguageDestination.label, "语言")
        XCTAssertEqual(element("settings.appearance", in: app).label, "外观与皮肤")
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
        XCTAssertTrue(element("budget.flexiblePreview", in: app).exists)
        assertBudgetKeyboardHasNoCompletionToolbar(in: app)
        XCTAssertTrue(app.buttons["budget.save"].exists)
        app.buttons["budget.save"].tap()

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        let dailyAmount = element("dashboard.today.left", in: app)
        XCTAssertTrue(dailyAmount.exists)
        let dailyAmountBeforeExpense = dailyAmount.label
        assertCompactEmptyStateAction(
            app.buttons["dashboard.empty.addEntry"],
            named: "Dashboard Add Entry"
        )
        assertPrimaryNavigationIsBottomAnchored(in: app)
        XCTAssertTrue(app.buttons["tab.dashboard"].isSelected)
        XCTAssertEqual(app.buttons["tab.dashboard"].value as? String, "Tab 1 of 4")
        let paceTrack = element("dashboard.pace.track", in: app)
        XCTAssertTrue(paceTrack.exists)
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
        XCTAssertTrue(otherCategory.isSelected)
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
        XCTAssertTrue(app.staticTexts["settings.version.value"].label.contains("0.9.8"))
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
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            ]
        )
        completeBudgetSetup(in: app)
        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
        app.buttons["dashboard.settings"].tap()
        XCTAssertTrue(element("settings.view", in: app).waitForExistence(timeout: 5))

        for skin in ["auroraGlow", "warmBotanical", "neonPulse"] {
            for _ in 0..<6 where !element("settings.appearance", in: app).isHittable {
                app.swipeDown()
            }
            let appearance = element("settings.appearance", in: app)
            XCTAssertTrue(appearance.waitForExistence(timeout: 2))
            appearance.tap()

            let skinControl = element("settings.appearance.skin.\(skin)", in: app)
            for _ in 0..<4 where !skinControl.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(skinControl.waitForExistence(timeout: 2))
            skinControl.tap()
            let selectedExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate { object, _ in
                    (object as? XCUIElement)?.isSelected == true
                },
                object: skinControl
            )
            XCTAssertEqual(
                XCTWaiter.wait(for: [selectedExpectation], timeout: 2),
                .completed,
                "Appearance selection did not settle: \(skin)"
            )
            app.navigationBars.buttons.element(boundBy: 0).tap()

            let proEntry = element("settings.pro", in: app)
            for _ in 0..<7 where !proEntry.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(proEntry.waitForExistence(timeout: 2))
            proEntry.tap()
            XCTAssertTrue(element("commerce.pro.view", in: app).waitForExistence(timeout: 5))

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
    func testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable() {
        let app = launchApp(
            language: "en",
            locale: "en_US",
            additionalArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            ]
        )

        XCTAssertTrue(app.staticTexts["onboarding.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.continue"].isHittable)
        completeBudgetSetup(in: app)

        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
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
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
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
        app.textFields["budget.monthlyIncome"].tap()
        app.textFields["budget.monthlyIncome"].typeText("3000")
        app.textFields["budget.totalBudget"].tap()
        app.textFields["budget.totalBudget"].typeText("2500")
        app.textFields["budget.savingGoal"].tap()
        app.textFields["budget.savingGoal"].typeText("500")
        app.buttons["budget.save"].tap()
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
