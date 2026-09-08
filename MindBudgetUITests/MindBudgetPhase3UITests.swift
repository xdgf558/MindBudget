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
    func testManualForeignCurrencyChineseAX5ExpiredStewardshipEdit() async throws {
        let app = try launchFXHost(language: "zh-Hans", locale: "zh_CN", ax5: true)
        defer { app.terminate() }
        // This method never depends on another test's creation or store. The compile-isolated
        // fixture writes one fixed record through DataActor, revokes Pro and changes Settings.
        let existing = app.buttons["fx.testHost.existing"]
        XCTAssertTrue(existing.waitForExistence(timeout: 3) && existing.isHittable)
        existing.tap()
        XCTAssertTrue(app.buttons["expense.edit"].waitForExistence(timeout: 8))
        let amounts = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@", "3 EUR", "6 USD"
        )).firstMatch
        XCTAssertTrue(amounts.waitForExistence(timeout: 3))
        try exerciseForeignCurrencyStewardship(in: app, ax5: true)
    }

    @MainActor
    private func launchFXHost(language: String, locale: String, ax5: Bool) throws -> XCUIApplication {
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
        XCTAssertTrue(app.staticTexts["fx.testHost"].waitForExistence(timeout: 8),
                      "Normal AppBootstrap must never substitute for the compiled in-memory host")
        return app
    }

    @MainActor
    private func exerciseForeignCurrency(language: String, locale: String, ax5: Bool) async throws {
        let app = try launchFXHost(language: language, locale: locale, ax5: ax5)
        defer { app.terminate() }
        XCTAssertTrue(element("expense.form", in: app).waitForExistence(timeout: 5))
        if !ax5 {
            try verifyFreeCannotActivateFX(in: app)
        }
        XCTAssertEqual(app.buttons["fx.enable"].label,
                       ax5 ? "启用外币记账" : "Enable foreign-currency entry")
        let entryImage = XCTAttachment(screenshot: app.screenshot())
        entryImage.name = "FX explicit entry button - \(language) - AX5 \(ax5)"
        entryImage.lifetime = .keepAlways
        add(entryImage)
        try changeFXMode(.enable, in: app)
        if !ax5 {
            // Explicit cancellation followed by a fresh activation, never a failed-tap retry.
            try changeFXMode(.disable, in: app)
            XCTAssertFalse(app.textFields["fx.originalAmount"].exists)
            try changeFXMode(.enable, in: app)
        }
        XCTAssertLessThanOrEqual(app.scrollViews["expense.form"].frame.width,
                                 app.windows.firstMatch.frame.width + 1,
                                 "AX5 content must not force the form wider than the viewport")
        let currency = app.buttons["fx.originalCurrency"]
        try revealFX(currency, in: app)
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
            try revealFX(date, in: app)
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
        try enterFX("3", into: app.textFields["fx.originalAmount"], in: app)
        try enterFX("2", into: app.textFields["fx.rate"], in: app)
        XCTAssertEqual(app.textFields["fx.originalAmount"].label, ax5 ? "原币金额" : "Original amount")
        XCTAssertEqual(app.textFields["fx.originalAmount"].value as? String, "3")
        XCTAssertEqual(app.textFields["fx.rate"].value as? String, "2")
        XCTAssertEqual(app.textFields["fx.accountingAmount"].value as? String, "6")
        let direction = app.staticTexts["fx.direction"].label
        XCTAssertTrue(direction.contains("EUR") && direction.contains("USD"))
        if let original = direction.range(of: "EUR"), let accounting = direction.range(of: "USD") {
            XCTAssertLessThan(original.lowerBound, accounting.lowerBound)
        } else { XCTFail("Accessible rate direction lost a currency identity") }
        try dismissFXKeyboard(in: app)
        let preview = app.staticTexts["fx.preview"]
        try revealFX(preview, in: app)
        XCTAssertTrue(preview.waitForExistence(timeout: 3))
        XCTAssertTrue(preview.label.contains("USD"))
        XCTAssertTrue(preview.label.contains("6"))
        let formImage = XCTAttachment(screenshot: app.screenshot())
        formImage.name = "FX manual form - \(language) - AX5 \(ax5)"
        formImage.lifetime = .keepAlways
        add(formImage)
        let save = app.buttons["expense.save"]
        try revealFX(save, in: app)
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
        // Chinese AX5 stewardship has its own fresh-host method and fixed persisted fixture.
        // English retains the original create -> expire -> edit end-to-end sequence.
        if ax5 { return }
        // Actual stored FX remains editable after access expires and Settings changes to JPY.
        app.buttons["fx.testHost.revoke"].tap()
        try exerciseForeignCurrencyStewardship(in: app, ax5: false)
    }

    @MainActor
    private func exerciseForeignCurrencyStewardship(in app: XCUIApplication, ax5: Bool) throws {
        app.buttons["expense.edit"].tap()
        XCTAssertTrue(app.staticTexts["fx.active"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["fx.enable"].exists)
        XCTAssertFalse(app.buttons["fx.disable"].exists,
                       "Stored FX metadata must never have a cancellation action, even after Pro expires")
        if ax5 {
            XCTAssertTrue((app.buttons["fx.rateDate"].value as? String ?? "").contains("2024"))
        }
        try enterFX("3", into: app.textFields["fx.rate"], in: app)
        try dismissFXKeyboard(in: app)
        try revealFX(app.staticTexts["fx.preview"], in: app)
        XCTAssertTrue(app.staticTexts["fx.preview"].label.contains("USD"))
        XCTAssertTrue(app.staticTexts["fx.preview"].label.contains("9"))
        try revealFX(app.buttons["expense.save"], in: app)
        app.buttons["expense.save"].tap()
        XCTAssertTrue(app.buttons["expense.edit"].waitForExistence(timeout: 5))
        let updated = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "USD", "9")).firstMatch
        XCTAssertTrue(updated.waitForExistence(timeout: 5))
        if ax5 {
            let savedDate = element("fx.detail.rateDate", in: app)
            XCTAssertTrue((savedDate.label + (savedDate.value as? String ?? "")).contains("2024"))
        }
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "FX expired stewardship - AX5 \(ax5)"
        image.lifetime = .keepAlways
        add(image)
    }

    @MainActor
    private func dismissFXKeyboard(in app: XCUIApplication) throws {
        // Each observation is one immutable public snapshot. Never re-resolve a live Done
        // element between checking its geometry and the one activation, or use AX existence
        // alone as evidence that a keyboard still occupies the application's viewport.
        var observations: [String] = []
        let started = ContinuousClock.now
        func capture(_ phase: String) throws -> FXKeyboardSnapshot {
            let root = BudgetSnapshotNode(try app.snapshot())
            observations.append("\(phase) at \(started.duration(to: .now)): \(FXKeyboardSnapshot.describe(root))")
            return try FXKeyboardSnapshot(root: root)
        }
        defer {
            let attachment = XCTAttachment(string: observations.joined(separator: "\n\n"))
            attachment.name = "FX keyboard single-tap snapshot trace"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        var readySnapshot: FXKeyboardSnapshot?
        var readinessFailure: String?
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            do {
                let state = try capture("before tap")
                guard (try? state.doneTapOffset()) != nil else { return false }
                readySnapshot = state
                return true
            } catch {
                readinessFailure = String(describing: error)
                return true
            }
        }, object: nil)
        let readyResult = XCTWaiter.wait(for: [ready], timeout: 3)
        if let readinessFailure {
            throw BudgetGeometryError(description: "FX Done readiness observation failed: \(readinessFailure)")
        }
        guard readyResult == .completed, let before = readySnapshot else {
            throw BudgetGeometryError(description: "FX Done did not enter a safe snapshot frame; no tap sent")
        }
        let point = try before.doneTapOffset()
        observations.append("one Done tap at app offset \(point)")
        app.coordinate(withNormalizedOffset: .zero).withOffset(point).tap()
        var observationFailure: String?
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            do {
                let state = try capture("after tap")
                return state.isDismissed
            } catch {
                // End this wait on an unreadable/invalid snapshot, then throw below. Unknown
                // geometry is not permission to pan, Save, wait longer or send a second tap.
                observationFailure = String(describing: error)
                return true
            }
        }, object: nil)
        let result = XCTWaiter.wait(for: [dismissed], timeout: 3)
        if let observationFailure {
            throw BudgetGeometryError(description: "FX dismissal observation failed: \(observationFailure)")
        }
        guard result == .completed else {
            throw BudgetGeometryError(description: "FX Done or visible keyboard remained after one tap; no dependent pan or Save allowed")
        }
    }

    @MainActor
    private func enterFX(_ value: String, into field: XCUIElement, in app: XCUIApplication) throws {
        try revealFX(field, in: app)
        field.tap()
        if let existing = field.value as? String, existing != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        field.typeText(value)
    }

    @MainActor
    private func verifyFreeCannotActivateFX(in app: XCUIApplication) throws {
        app.buttons["fx.testHost.revoke"].tap()
        let blocked = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == false"),
                                               object: app.buttons["fx.enable"])
        guard XCTWaiter.wait(for: [blocked], timeout: 3) == .completed else {
            throw BudgetGeometryError(description: "Free must not enable new FX entry")
        }
        XCTAssertFalse(app.staticTexts["fx.active"].exists)
        app.buttons["fx.testHost.restore"].tap()
    }

    @MainActor
    private func changeFXMode(_ action: FXModeSnapshot.Action, in app: XCUIApplication) throws {
        let button = app.buttons[action.rawValue]
        guard button.waitForExistence(timeout: 5) else {
            throw BudgetGeometryError(description: "FX mode button did not appear: \(action)")
        }
        let granted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: button)
        guard XCTWaiter.wait(for: [granted], timeout: 10) == .completed else {
            throw BudgetGeometryError(description: "The isolated fixture did not reach the real Commerce access boundary")
        }
        try revealFX(button, in: app)
        // Capture the entire button and its surrounding state once. No native switch track,
        // live second query, extra tap, long press or synthetic model-state change.
        let before = try FXModeSnapshot(root: BudgetSnapshotNode(app.snapshot()))
        let offset = try before.tapOffset(for: action)
        var observations = ["before \(action): \(before); single center tap \(offset)"]
        defer {
            let attachment = XCTAttachment(string: observations.joined(separator: "\n"))
            attachment.name = "FX explicit mode transition \(action)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        app.coordinate(withNormalizedOffset: .zero).withOffset(offset).tap()
        var failure: String?
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            do {
                let state = try FXModeSnapshot(root: BudgetSnapshotNode(app.snapshot()))
                observations.append("after: \(state)")
                return state.active == (action == .enable)
            } catch {
                failure = String(describing: error)
                return true
            }
        }, object: nil)
        let result = XCTWaiter.wait(for: [changed], timeout: 3)
        guard result == .completed, failure == nil else {
            attachInputFailureSnapshot(in: app, reason: "FX explicit mode transition failed")
            throw BudgetGeometryError(description: "FX mode did not change after one tap: \(failure ?? observations.last ?? "no observation")")
        }
    }

    @MainActor
    private func revealFX(_ control: XCUIElement, in app: XCUIApplication) throws {
        for _ in 0..<14 {
            let navBottom = app.navigationBars.allElementsBoundByIndex.last(where: \.isHittable)?.frame.maxY ?? 0
            let window = app.windows.firstMatch.frame
            let sentinel = app.staticTexts["fx.testHost"]
            let hostTop = sentinel.exists && sentinel.isHittable && sentinel.frame.minY > navBottom
                ? sentinel.frame.minY : window.maxY
            let keyboard = try FXKeyboardSnapshot(root: BudgetSnapshotNode(app.snapshot()))
            let keyboardTop = min(keyboard.visibleKeyboards.map(\.minY).min() ?? hostTop, hostTop)
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
            guard height > 60 else { throw BudgetGeometryError(description: "No unobscured FX scroll viewport") }
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
            }) else { throw BudgetGeometryError(description: "No unobscured non-editor FX pan origin") }
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
        throw BudgetGeometryError(description: "FX control did not enter the unobscured viewport: \(control); frame=\(control.frame); \(app.debugDescription)")
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
        // Expansion and locating a deep, virtualized history row are separate outcomes.
        // Five whole-app swipes previously stopped in 0.9.2's long row before 0.9.1 existed.
        guard revealAboutHistoryText("settings.releaseNotes.history.0.9.8", in: app) else {
            return
        }
        guard revealAboutHistoryText("settings.releaseNotes.history.0.9.1", in: app) else {
            return
        }
        let previousRelease = element("settings.releaseNotes.history.0.9.1", in: app)
        XCTAssertTrue(previousRelease.waitForExistence(timeout: 2))
        XCTAssertEqual(previousRelease.label, "0.9.1")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "About expanded history reaches 0.9.1"
        attachment.lifetime = .keepAlways
        add(attachment)
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

            guard revealAndActivateNavigationTarget(
                "settings.pro",
                inList: "settings.view",
                towardEarlierContentWhenVirtualized: true,
                destination: app.collectionViews["commerce.pro.view"],
                in: app,
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
                let destinationView = element("commerce.pro.\(destination).view", in: app)
                guard revealAndActivateNavigationTarget(
                    "commerce.pro.\(destination)",
                    inList: "commerce.pro.view",
                    towardEarlierContentWhenVirtualized: false,
                    destination: destinationView,
                    in: app,
                    message: "Missing AX5 legal destination: \(destination) / \(skin)"
                ) else {
                    return
                }
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
    func testBudgetAmountLabelFocusesIncomeInEnglishAX5() throws {
        try exerciseBudgetAmountLabelFocus(language: "en", locale: "en_US")
    }

    @MainActor
    func testBudgetAmountLabelFocusesIncomeInChineseAX5() throws {
        try exerciseBudgetAmountLabelFocus(language: "zh-Hans", locale: "zh_CN")
    }

    @MainActor
    private func exerciseBudgetAmountLabelFocus(language: String, locale: String) throws {
        continueAfterFailure = false
        let app = launchApp(language: language, locale: locale, additionalArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ])
        defer { app.terminate() }
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))
        guard revealBudgetField("budget.monthlyIncome", in: app) != nil else { return }
        // The label, not the editor, must activate the real product FocusState in one tap.
        // Derive both from one final snapshot; reject any point that also hits the editor.
        let root = BudgetSnapshotNode(try app.snapshot())
        let geometry = try BudgetGeometry(targetIdentifier: "budget.monthlyIncome.label",
            targetType: .staticText, noKeyboardInset: 80) { root }
        let fields = root.flattened.filter { $0.type == .textField && $0.identifier == "budget.monthlyIncome" }
        guard geometry.keyboards.isEmpty, fields.count == 1, let label = geometry.target else {
            XCTFail("Label focus requires an unfocused visible budget form: \(geometry)")
            return
        }
        let lane = CGRect(x: geometry.application.minX, y: geometry.navigationBottom + 8,
                          width: geometry.application.width,
                          height: geometry.safeBottom - geometry.navigationBottom - 8)
        let visible = label.intersection(lane)
        guard !visible.isNull, visible.width > 16, visible.height > 16 else {
            XCTFail("Income label has no safe activation area: \(geometry)")
            return
        }
        let point = CGPoint(x: visible.midX, y: visible.midY)
        XCTAssertFalse(fields[0].frame.contains(point), "The regression must not tap the native editor")
        let before = XCTAttachment(screenshot: app.screenshot())
        before.name = "Budget AX5 label focus before - \(language)"
        before.lifetime = .keepAlways
        add(before)
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: point.x - geometry.application.minX,
            dy: point.y - geometry.application.minY
        )).tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5),
                      "One income-label tap must focus its editor; point=\(point); \(geometry)")
        app.textFields["budget.monthlyIncome"].typeText("3000")
        guard enterBudgetValue("2500", into: "budget.totalBudget", in: app),
              enterBudgetValue("500", into: "budget.savingGoal", in: app) else { return }
        saveAndVerifyBudgetSetup(in: app)
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
    private func revealAboutHistoryText(_ identifier: String, in app: XCUIApplication) -> Bool {
        let list = app.collectionViews.matching(identifier: "settings.about.view").firstMatch
        let target = list.staticTexts.matching(identifier: identifier).firstMatch
        guard list.waitForExistence(timeout: 3) else {
            XCTFail("About history list is unavailable")
            return false
        }
        for step in 0...20 {
            let before: AboutScrollGeometry
            do {
                before = try AboutScrollGeometry(targetIdentifier: identifier) {
                    BudgetSnapshotNode(try app.snapshot())
                }
            } catch {
                XCTFail("About history capture failed: \(error)")
                return false
            }
            if before.targetIsInLane && target.isHittable { return true }
            guard step < 20 else { break }
            guard !before.visibleAnchors.isEmpty else {
                XCTFail("About history has no unique visible content anchor: \(before)")
                return false
            }
            let towardEarlier = before.target.map { $0.minY < before.lane.minY } ?? false
            let startY = before.lane.minY + before.lane.height * (towardEarlier ? 0.2 : 0.8)
            let endY = before.lane.minY + before.lane.height * (towardEarlier ? 0.75 : 0.25)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: before.lane.midX - before.application.minX,
                                                   dy: startY - before.application.minY))
            let end = origin.withOffset(CGVector(dx: before.lane.midX - before.application.minX,
                                                 dy: endY - before.application.minY))
            XCTContext.runActivity(named: "Reveal \(identifier), bounded drag \(step + 1)") { _ in
                start.press(forDuration: 0.1, thenDragTo: end)
            }
            var after: AboutScrollGeometry?
            var captureError: String?
            let progress = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    do {
                        let sample = try AboutScrollGeometry(targetIdentifier: identifier) {
                            BudgetSnapshotNode(try app.snapshot())
                        }
                        after = sample
                        return (sample.targetIsInLane && target.isHittable)
                            || sample.progressed(from: before, towardEarlier: towardEarlier)
                    } catch {
                        // End this wait and fail below; a failed capture is never progress.
                        captureError = String(describing: error)
                        return true
                    }
                },
                object: list
            )
            let outcome = XCTWaiter.wait(for: [progress], timeout: 3)
            let diagnostic = XCTAttachment(string:
                "target=\(identifier), earlier=\(towardEarlier)\nbefore=\(before)\n"
                + "after=\(String(describing: after))\ncaptureError=\(String(describing: captureError))")
            diagnostic.name = "About scroll geometry - drag \(step + 1)"
            diagnostic.lifetime = .keepAlways
            add(diagnostic)
            guard captureError == nil, outcome == .completed else {
                XCTFail("About history made no observable scroll progress toward \(identifier); "
                        + "before=\(before); after=\(String(describing: after)); error=\(String(describing: captureError))")
                return false
            }
        }
        XCTFail("About history did not reveal \(identifier) within 20 bounded drags")
        return false
    }

    /// One immutable foreground-list sample. Never compare separately resolved XCUI frames.
    private struct AboutScrollGeometry: CustomStringConvertible {
        enum Anchor: Hashable {
            case heading(String)
            case uniqueText(XCUIElement.ElementType, String)
        }
        let application: CGRect
        let list: CGRect
        let lane: CGRect
        let target: CGRect?
        let anchors: [Anchor: CGRect]
        let contentDiagnostic: String

        init(targetIdentifier: String, snapshot: () throws -> BudgetSnapshotNode) throws {
            let root = try snapshot()
            func valid(_ frame: CGRect, emptyAllowed: Bool = false) -> Bool {
                !frame.isNull && !frame.isInfinite
                    && [frame.minX, frame.minY, frame.width, frame.height].allSatisfy(\.isFinite)
                    && frame.width >= 0 && frame.height >= 0 && (emptyAllowed || !frame.isEmpty)
            }
            guard root.type == .application, valid(root.frame) else {
                throw BudgetGeometryError(description: "Invalid About application snapshot")
            }
            application = root.frame
            let nodes = root.flattened
            let lists = nodes.filter { $0.type == .collectionView && $0.identifier == "settings.about.view" }
            guard lists.count == 1, let foreground = lists.first, valid(foreground.frame) else {
                throw BudgetGeometryError(description: "Missing, ambiguous or invalid About list")
            }
            list = foreground.frame
            contentDiagnostic = foreground.flattened.map {
                "type=\($0.type.rawValue) id=\($0.identifier) label=\($0.label) frame=\($0.frame)"
            }.joined(separator: "\n")
            let navigation = nodes.filter { $0.type == .navigationBar }
            guard navigation.allSatisfy({ valid($0.frame) }),
                  let navBottom = navigation.filter({ $0.frame.intersects(root.frame) }).map(\.frame.maxY).max() else {
                throw BudgetGeometryError(description: "Invalid About navigation snapshot")
            }
            let viewport = foreground.frame.intersection(root.frame)
            let top = max(viewport.minY, navBottom) + 16
            lane = CGRect(x: viewport.minX + 16, y: top,
                          width: viewport.width - 32, height: viewport.maxY - 24 - top)
            guard valid(lane), lane.height > 80 else {
                throw BudgetGeometryError(description: "About has no unobscured scrolling lane")
            }
            let rawTexts = foreground.flattened.filter { $0.type == .staticText }
            guard rawTexts.allSatisfy({ valid($0.frame, emptyAllowed: true) }) else {
                throw BudgetGeometryError(description: "Invalid About text frame")
            }
            // SwiftUI's combined Label exposes both a StaticText parent and its Text child
            // with the same public label, identifier and frame. Collapse only this exact
            // ancestor echo, never identical siblings or nodes with differing geometry.
            var texts: [BudgetSnapshotNode] = []
            func collect(_ node: BudgetSnapshotNode, ancestors: [BudgetSnapshotNode]) {
                if node.type == .staticText && !ancestors.contains(where: {
                    $0.type == node.type && $0.identifier == node.identifier
                        && $0.label == node.label && $0.frame == node.frame
                }) {
                    texts.append(node)
                }
                for child in node.children { collect(child, ancestors: ancestors + [node]) }
            }
            collect(foreground, ancestors: [])
            let targets = texts.filter { $0.identifier == targetIdentifier }
            guard targets.count <= 1 else {
                throw BudgetGeometryError(description: "Duplicate About target: \(targetIdentifier)")
            }
            target = targets.first.flatMap { $0.frame.isEmpty ? nil : $0.frame }

            var indexed: [Anchor: CGRect] = [:]
            let prefix = "settings.releaseNotes.history."
            for node in texts where node.identifier.hasPrefix(prefix) {
                let suffix = node.identifier.dropFirst(prefix.count)
                guard suffix.split(separator: ".").allSatisfy({ Int($0) != nil }), !suffix.isEmpty else { continue }
                let key = Anchor.heading(node.identifier)
                guard indexed[key] == nil else {
                    throw BudgetGeometryError(description: "Duplicate About heading: \(node.identifier)")
                }
                indexed[key] = node.frame
            }
            // A long release can fill the viewport without its heading. Use public text
            // only when unique in this foreground snapshot AND the next one. Duplicates,
            // virtualized indices, offscreen-only anchors and text changes cannot prove progress.
            let grouped = Dictionary(grouping: texts.filter { !$0.label.isEmpty }) {
                Anchor.uniqueText($0.type, $0.label)
            }
            for (key, matches) in grouped where matches.count == 1 {
                indexed[key] = matches[0].frame
            }
            anchors = indexed.filter { !$0.value.isEmpty }
        }

        var targetIsInLane: Bool { target.map { application.contains($0) && lane.contains($0) } ?? false }
        var visibleAnchors: [Anchor: CGRect] { anchors.filter { lane.intersects($0.value) } }

        func progressed(from before: Self, towardEarlier: Bool) -> Bool {
            before.visibleAnchors.contains { key, old in
                guard let next = anchors[key],
                      abs(next.width - old.width) <= 1, abs(next.height - old.height) <= 1 else { return false }
                // Relative coordinates reject movement of the sheet/list itself. Only a shared
                // identity moving in the requested direction counts; appearance/disappearance
                // alone, a stationary stale heading or sub-point jitter do not.
                let delta = (next.midY - list.minY) - (old.midY - before.list.minY)
                return towardEarlier ? delta > 1 : delta < -1
            }
        }

        var description: String {
            let positions = visibleAnchors.map { key, frame in "\(key):\(frame)" }.sorted().joined(separator: "; ")
            return "app=\(application), list=\(list), lane=\(lane), target=\(String(describing: target)), visible=[\(positions)]"
                + (visibleAnchors.isEmpty ? "\nforeground=\(contentDiagnostic)" : "")
        }
    }

    @MainActor
    func testAboutScrollProgressUsesVisibleUniqueAnchorsFromOneSnapshot() throws {
        func sample(_ rows: [BudgetSnapshotNode], offset: CGFloat = 0) throws -> AboutScrollGeometry {
            try AboutScrollGeometry(targetIdentifier: "settings.releaseNotes.history.0.9.1") {
                BudgetSnapshotNode(.application, CGRect(x: 0, y: 0, width: 400, height: 800), children: [
                    BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 40, width: 400, height: 60)),
                    BudgetSnapshotNode(.collectionView, CGRect(x: 0, y: offset, width: 400, height: 800 - offset),
                                       identifier: "settings.about.view", children: rows)
                ])
            }
        }
        let heading = BudgetSnapshotNode(.staticText, CGRect(x: 20, y: 160, width: 300, height: 30),
                                         identifier: "settings.releaseNotes.history.0.9.4")
        let body = BudgetSnapshotNode(.staticText, CGRect(x: 20, y: 320, width: 300, height: 100),
                                      identifier: "shared.body", label: "Unique body")
        let before = try sample([heading, body])
        let movedBody = BudgetSnapshotNode(.staticText, body.frame.offsetBy(dx: 0, dy: -90),
                                           identifier: body.identifier, label: body.label)
        let after = try sample([heading, movedBody])
        XCTAssertTrue(after.progressed(from: before, towardEarlier: false), "A stationary heading cannot hide real body movement")
        XCTAssertFalse(after.progressed(from: before, towardEarlier: true))
        XCTAssertFalse(before.progressed(from: before, towardEarlier: false))
        let translated = try sample([
            BudgetSnapshotNode(.staticText, heading.frame.offsetBy(dx: 0, dy: 20), identifier: heading.identifier),
            BudgetSnapshotNode(.staticText, body.frame.offsetBy(dx: 0, dy: 20), identifier: body.identifier, label: body.label)
        ], offset: 20)
        XCTAssertFalse(translated.progressed(from: before, towardEarlier: true), "Sheet translation is not scroll progress")
        let duplicated = try sample([heading, movedBody, movedBody])
        XCTAssertFalse(duplicated.progressed(from: before, towardEarlier: false), "Repeated labels cannot identify an anchor")
        let replaced = try sample([BudgetSnapshotNode(.staticText, movedBody.frame, label: "Different body")])
        XCTAssertFalse(replaced.progressed(from: before, towardEarlier: false), "Virtualization alone cannot prove progress")
        let jitter = try sample([heading, BudgetSnapshotNode(.staticText, body.frame.offsetBy(dx: 0, dy: -0.5), label: body.label)])
        XCTAssertFalse(jitter.progressed(from: before, towardEarlier: false))
        let offscreen = try sample([BudgetSnapshotNode(.staticText, CGRect(x: 20, y: 1000, width: 300, height: 100), label: body.label)])
        XCTAssertFalse(after.progressed(from: offscreen, towardEarlier: false), "Offscreen-only content is not an anchor")
        func combined(_ node: BudgetSnapshotNode, child: BudgetSnapshotNode) -> BudgetSnapshotNode {
            BudgetSnapshotNode(.staticText, node.frame, identifier: node.identifier,
                               label: node.label, children: [child])
        }
        let echoedBefore = try sample([combined(body, child: body)])
        let echoedAfter = try sample([combined(movedBody, child: movedBody)])
        XCTAssertEqual(echoedBefore.visibleAnchors.count, 1)
        XCTAssertTrue(echoedAfter.progressed(from: echoedBefore, towardEarlier: false),
                      "A combined Label's exact descendant echo is one logical text anchor")
        let mismatchedDescendant = try sample([combined(movedBody, child: body)])
        XCTAssertFalse(mismatchedDescendant.progressed(from: echoedBefore, towardEarlier: false),
                       "Different descendant geometry remains ambiguous")
        let duplicatedRows = try sample([combined(movedBody, child: movedBody), combined(movedBody, child: movedBody)])
        XCTAssertFalse(duplicatedRows.progressed(from: echoedBefore, towardEarlier: false),
                       "An ancestor echo rule must not coalesce duplicate rows or siblings")
        let target = BudgetSnapshotNode(.staticText, CGRect(x: 20, y: 240, width: 300, height: 30),
                                        identifier: "settings.releaseNotes.history.0.9.1")
        XCTAssertTrue(try sample([target]).targetIsInLane)
        XCTAssertFalse(try sample([BudgetSnapshotNode(.staticText, target.frame.offsetBy(dx: 0, dy: -150),
                                                    identifier: target.identifier)]).targetIsInLane)
        var captures = 0
        var root = BudgetSnapshotNode(.application, CGRect(x: 0, y: 0, width: 400, height: 800), children: [
            BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 40, width: 400, height: 60)),
            BudgetSnapshotNode(.collectionView, CGRect(x: 0, y: 0, width: 400, height: 800),
                               identifier: "settings.about.view", children: [target])
        ])
        let frozen = try AboutScrollGeometry(targetIdentifier: target.identifier) {
            captures += 1
            return root
        }
        root.children.removeAll()
        XCTAssertTrue(frozen.targetIsInLane)
        XCTAssertEqual(captures, 1)
    }

    @MainActor
    func testAboutScrollGeometryRejectsFailedAndAmbiguousSnapshots() {
        XCTAssertThrowsError(try AboutScrollGeometry(targetIdentifier: "target") {
            throw BudgetGeometryError(description: "capture failed")
        })
        let appFrame = CGRect(x: 0, y: 0, width: 400, height: 800)
        let nav = BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 40, width: 400, height: 60))
        let target = BudgetSnapshotNode(.staticText, CGRect(x: 20, y: 200, width: 300, height: 30), identifier: "target")
        let list = BudgetSnapshotNode(.collectionView, appFrame, identifier: "settings.about.view", children: [target])
        for children in [[nav], [list], [nav, list, list], [nav,
            BudgetSnapshotNode(.collectionView, appFrame, identifier: list.identifier, children: [target, target])]] {
            XCTAssertThrowsError(try AboutScrollGeometry(targetIdentifier: "target") {
                BudgetSnapshotNode(.application, appFrame, children: children)
            })
        }
        XCTAssertThrowsError(try AboutScrollGeometry(targetIdentifier: "target") {
            BudgetSnapshotNode(.application, .zero, children: [nav, list])
        })
        XCTAssertThrowsError(try AboutScrollGeometry(targetIdentifier: "target") {
            BudgetSnapshotNode(.application, appFrame, children: [nav,
                BudgetSnapshotNode(.collectionView, appFrame, identifier: list.identifier, children: [
                    BudgetSnapshotNode(.staticText, CGRect(x: 20, y: CGFloat.nan, width: 100, height: 40), identifier: "target")
                ])])
        })
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
    private func revealAndActivateNavigationTarget(
        _ targetIdentifier: String,
        inList listIdentifier: String,
        towardEarlierContentWhenVirtualized: Bool,
        destination: XCUIElement,
        in app: XCUIApplication,
        message: String
    ) -> Bool {
        var lastGeometry: NavigationTapGeometry?
        for step in 0...8 {
            let geometry: NavigationTapGeometry
            do {
                geometry = try NavigationTapGeometry(
                    listIdentifier: listIdentifier,
                    targetIdentifier: targetIdentifier
                ) {
                    BudgetSnapshotNode(try app.snapshot())
                }
            } catch {
                XCTFail("Unable to capture navigation geometry for \(targetIdentifier): \(error)")
                return false
            }
            lastGeometry = geometry
            if geometry.targetIsReady, let frame = geometry.target {
                let origin = app.coordinate(withNormalizedOffset: .zero)
                origin.withOffset(CGVector(
                    dx: frame.midX - geometry.application.minX,
                    dy: frame.midY - geometry.application.minY
                )).tap()
                if destination.waitForExistence(timeout: 5) {
                    return true
                }
                let attachment = XCTAttachment(string: "Single navigation tap did not settle. \(geometry)")
                attachment.name = "Navigation tap geometry - \(targetIdentifier)"
                attachment.lifetime = .keepAlways
                add(attachment)
                XCTFail(message)
                return false
            }
            if geometry.target != nil, !geometry.targetEnabled {
                XCTFail("Navigation target was disabled: \(geometry)")
                return false
            }
            guard step < 8 else { break }

            let towardEarlier = geometry.target.map { $0.minY < geometry.lane.minY }
                ?? towardEarlierContentWhenVirtualized
            let startY = geometry.lane.minY + geometry.lane.height * (towardEarlier ? 0.25 : 0.75)
            let endY = geometry.lane.minY + geometry.lane.height * (towardEarlier ? 0.70 : 0.30)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(
                dx: geometry.lane.midX - geometry.application.minX,
                dy: startY - geometry.application.minY
            ))
            let end = origin.withOffset(CGVector(
                dx: geometry.lane.midX - geometry.application.minX,
                dy: endY - geometry.application.minY
            ))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Navigation target never entered the unobscured lane: \(String(describing: lastGeometry))")
        return false
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
        // A setup failure must end this test, not continue typing into later fields.
        continueAfterFailure = false
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(element("budget.setup.view", in: app).waitForExistence(timeout: 5))
        let monthlyIncome = "budget.monthlyIncome"
        guard enterBudgetValue("3000", into: monthlyIncome, in: app) else { return }

        let totalBudget = "budget.totalBudget"
        guard enterBudgetValue("2500", into: totalBudget, in: app) else { return }

        let savingGoal = "budget.savingGoal"
        guard enterBudgetValue("500", into: savingGoal, in: app) else { return }

        saveAndVerifyBudgetSetup(in: app)
    }

    @MainActor
    private func saveAndVerifyBudgetSetup(in app: XCUIApplication) {
        // Keep the accepted product contract: Save Budget is the sole commit/dismiss action.
        // Do not double-tap income to "commit" saving or read the still-active editor as proof
        // of persistence. Verify all three exact amounts from a newly loaded Settings form below.
        let save = app.buttons["budget.save"]
        guard makeBudgetSaveReady(save, in: app) else { return }
        let dashboard = element("dashboard.view", in: app)
        do {
            let geometry = try NavigationTapGeometry(listIdentifier: "budget.setup.view", targetIdentifier: "budget.save") {
                BudgetSnapshotNode(try app.snapshot())
            }
            guard geometry.targetIsReady, let frame = geometry.target else {
                XCTFail("Budget Save lost its safe final geometry: \(geometry)")
                return
            }
            app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                dx: frame.midX - geometry.application.minX,
                dy: frame.midY - geometry.application.minY
            )).tap()
            XCTAssertTrue(dashboard.waitForExistence(timeout: 5), "Budget setup did not persist after one Save tap")
        } catch {
            XCTFail("Budget Save snapshot failed: \(error)")
            return
        }
        verifySavedBudget(in: app)
    }

    @MainActor
    private func verifySavedBudget(in app: XCUIApplication) {
        let settings = app.buttons["dashboard.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        let settingsView = app.collectionViews["settings.view"]
        XCTAssertTrue(settingsView.waitForExistence(timeout: 5))
        guard revealAndActivateNavigationTarget("settings.budget", inList: "settings.view",
            towardEarlierContentWhenVirtualized: true,
            destination: app.collectionViews["settings.budget.view"], in: app,
            message: "Saved budget verification did not open its independent Settings form") else { return }

        // BudgetSettingsView.load() calls DataActor.previewPlanCoverage and initializes new
        // strings from the stored plan. No editor focus, typing or Settings Save is permitted.
        // This proves exact amounts in the synthetic SwiftData store, not disk/relaunch durability.
        var observations: [String] = []
        defer {
            let attachment = XCTAttachment(string: observations.joined(separator: "\n"))
            attachment.name = "Saved budget independent Settings readback"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        for (field, expected) in [("monthlyIncome", "3000"), ("totalBudget", "2500"), ("savingGoal", "500")] {
            let identifier = "settings.budget.\(field)"
            guard revealBudgetField(identifier, in: app, formIdentifier: "settings.budget.view") != nil else { return }
            var failure: String?
            let correct = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                do {
                    let snapshot = try SavedBudgetFieldSnapshot(root: BudgetSnapshotNode(app.snapshot()), identifier: identifier)
                    observations.append("\(identifier)=\(String(reflecting: snapshot.value)); expected=\(expected)")
                    return snapshot.matches(expected)
                } catch {
                    failure = String(describing: error)
                    return true
                }
            }, object: nil)
            let result = XCTWaiter.wait(for: [correct], timeout: 5)
            guard result == .completed, failure == nil else {
                attachInputFailureSnapshot(in: app, reason: "Stored budget mismatch: \(identifier); \(failure ?? observations.last ?? "no observation")")
                XCTFail("Stored budget is not the exact intended amount: \(identifier)")
                return
            }
        }
        guard tapBudgetVerificationNavigation(in: app, returningToSettings: true) else { return }
        XCTAssertTrue(settingsView.waitForExistence(timeout: 5))
        guard tapBudgetVerificationNavigation(in: app, returningToSettings: false) else { return }
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: settingsView)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        XCTAssertTrue(element("dashboard.view", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    private func tapBudgetVerificationNavigation(in app: XCUIApplication, returningToSettings: Bool) -> Bool {
        do {
            let geometry = try BudgetVerificationNavigation(root: BudgetSnapshotNode(app.snapshot()), back: returningToSettings)
            app.coordinate(withNormalizedOffset: .zero).withOffset(geometry.offset).tap()
            return true
        } catch {
            attachInputFailureSnapshot(in: app, reason: "Budget verification navigation failed: \(error)")
            XCTFail("Budget verification cannot restore its destination: \(error)")
            return false
        }
    }

    private struct BudgetVerificationNavigation {
        let offset: CGVector

        init(root: BudgetSnapshotNode, back: Bool) throws {
            let formID = back ? "settings.budget.view" : "settings.view"
            let nodes = root.flattened
            let forms = nodes.filter { $0.type == .collectionView && $0.identifier == formID }
            guard root.type == .application, root.hasFinitePositiveFrame,
                  forms.count == 1, let form = forms.first, form.hasFinitePositiveFrame,
                  form.frame.intersects(root.frame),
                  !nodes.contains(where: { $0.type == .keyboard || $0.type == .menu || $0.type == .alert }) else {
                throw BudgetGeometryError(description: "Wrong/interrupted budget verification destination")
            }
            let rawButtons = nodes.filter { $0.type == .navigationBar }.flatMap(\.children).flatMap(\.flattened)
                .filter { $0.type == .button }
            guard rawButtons.allSatisfy(\.hasFinitePositiveFrame) else {
                throw BudgetGeometryError(description: "Invalid budget verification navigation geometry")
            }
            let buttons = rawButtons.filter { root.frame.contains($0.frame) }
            // The captured native budget child has BackButton. Settings root source has exactly
            // one toolbar action (dismiss), and no Back. Do not use boundBy:0 or localized labels:
            // pseudo-localization changes the text. Additional actions make this contract fail.
            let matches = back ? buttons.filter { $0.identifier == "BackButton" } : buttons
            guard matches.count == 1, let button = matches.first, button.enabled,
                  back ? button.frame.midX < root.frame.midX : button.frame.midX > root.frame.midX else {
                throw BudgetGeometryError(description: "Ambiguous/disabled budget verification navigation: \(buttons.map(\.identifier))")
            }
            offset = CGVector(dx: button.frame.midX - root.frame.minX, dy: button.frame.midY - root.frame.minY)
        }
    }

    private struct SavedBudgetFieldSnapshot {
        let value: String?

        init(root: BudgetSnapshotNode, identifier: String) throws {
            guard ["monthlyIncome", "totalBudget", "savingGoal"].map({ "settings.budget.\($0)" }).contains(identifier),
                  root.type == .application, root.hasFinitePositiveFrame,
                  !root.flattened.contains(where: { $0.type == .keyboard || $0.type == .menu || $0.type == .alert }) else {
                throw BudgetGeometryError(description: "Saved budget readback is interrupted or still editing")
            }
            let forms = root.flattened.filter { $0.type == .collectionView && $0.identifier == "settings.budget.view" }
            guard forms.count == 1, let form = forms.first, form.hasFinitePositiveFrame, form.frame.intersects(root.frame) else {
                throw BudgetGeometryError(description: "Missing or ambiguous saved-budget Settings form")
            }
            let matches = form.flattened.filter { $0.type == .textField && $0.identifier == identifier }
            guard matches.count == 1, let field = matches.first, field.enabled,
                  field.hasFinitePositiveFrame,
                  root.frame.contains(field.frame) else {
                throw BudgetGeometryError(description: "Missing, ambiguous or offscreen saved-budget field: \(identifier)")
            }
            value = field.value
        }

        func matches(_ expected: String) -> Bool { value == expected }
    }

    @MainActor
    func testBudgetSettingsReadbackRejectsIncorrectAmountsAndActiveEditors() throws {
        let frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        let id = "settings.budget.savingGoal"
        let field = BudgetSnapshotNode(.textField, CGRect(x: 30, y: 200, width: 340, height: 44), identifier: id, value: "500")
        func tree(_ fields: [BudgetSnapshotNode], formID: String = "settings.budget.view", extras: [BudgetSnapshotNode] = []) -> BudgetSnapshotNode {
            BudgetSnapshotNode(.application, frame, children: [BudgetSnapshotNode(.collectionView, frame, identifier: formID, children: fields)] + extras)
        }
        XCTAssertTrue(try SavedBudgetFieldSnapshot(root: tree([field]), identifier: id).matches("500"))
        for value in ["0", "5000", "2500", "", "500 "] {
            let wrong = BudgetSnapshotNode(.textField, field.frame, identifier: id, value: value)
            XCTAssertFalse(try SavedBudgetFieldSnapshot(root: tree([wrong]), identifier: id).matches("500"))
        }
        let absent = BudgetSnapshotNode(.textField, field.frame, identifier: id)
        XCTAssertFalse(try SavedBudgetFieldSnapshot(root: tree([absent]), identifier: id).matches("500"))
        XCTAssertThrowsError(try SavedBudgetFieldSnapshot(root: tree([]), identifier: id))
        XCTAssertThrowsError(try SavedBudgetFieldSnapshot(root: tree([field, field]), identifier: id))
        XCTAssertThrowsError(try SavedBudgetFieldSnapshot(root: tree([field], formID: "budget.setup.view"), identifier: id))
        for type in [XCUIElement.ElementType.keyboard, .menu, .alert] {
            XCTAssertThrowsError(try SavedBudgetFieldSnapshot(root: tree([field], extras: [BudgetSnapshotNode(type, frame)]), identifier: id))
        }
        for invalid in [CGRect.zero, .infinite, CGRect(x: 30, y: 200, width: -10, height: 44),
                        CGRect(x: CGFloat.nan, y: 200, width: 340, height: 44)] {
            XCTAssertThrowsError(try SavedBudgetFieldSnapshot(root: tree([BudgetSnapshotNode(.textField, invalid, identifier: id, value: "500")]), identifier: id))
        }
        XCTAssertThrowsError(try SavedBudgetFieldSnapshot(root: tree([BudgetSnapshotNode(.textField, field.frame, identifier: id, enabled: false, value: "500")]), identifier: id))
    }

    @MainActor
    func testBudgetSavedAmountsLoadIntoFreshSettingsWithoutEditing() {
        let app = launchApp(language: "zh-Hans", locale: "zh_CN")
        completeBudgetSetup(in: app)
    }

    @MainActor
    func testBudgetVerificationNavigationRejectsWrongSurfaceAndExtraActions() throws {
        let frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        let back = BudgetSnapshotNode(.button, CGRect(x: 16, y: 78, width: 44, height: 44), identifier: "BackButton")
        let done = BudgetSnapshotNode(.button, CGRect(x: 325, y: 78, width: 56, height: 36), label: "localized dismissal")
        func tree(_ id: String, _ buttons: [BudgetSnapshotNode]) -> BudgetSnapshotNode {
            BudgetSnapshotNode(.application, frame, children: [
                BudgetSnapshotNode(.collectionView, frame, identifier: id),
                BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 62, width: 402, height: 80), children: buttons)
            ])
        }
        XCTAssertEqual(try BudgetVerificationNavigation(root: tree("settings.budget.view", [back]), back: true).offset, CGVector(dx: 38, dy: 100))
        XCTAssertEqual(try BudgetVerificationNavigation(root: tree("settings.view", [done]), back: false).offset, CGVector(dx: 353, dy: 96))
        XCTAssertThrowsError(try BudgetVerificationNavigation(root: tree("settings.view", [back, done]), back: false))
        XCTAssertThrowsError(try BudgetVerificationNavigation(root: tree("settings.view", [back]), back: true))
        XCTAssertThrowsError(try BudgetVerificationNavigation(root: tree("settings.budget.view", [done]), back: true))
        XCTAssertThrowsError(try BudgetVerificationNavigation(root: tree("settings.view", []), back: false))
        for invalid in [CGRect.zero, .infinite, CGRect(x: 325, y: 78, width: -56, height: 36)] {
            XCTAssertThrowsError(try BudgetVerificationNavigation(root: tree("settings.view", [BudgetSnapshotNode(.button, invalid)]), back: false))
        }
        XCTAssertThrowsError(try BudgetVerificationNavigation(root: tree("settings.view", [BudgetSnapshotNode(.button, done.frame, enabled: false)]), back: false))
    }

    /// Failure-only public snapshots retain actual post-action values. They neither retry an
    /// interaction nor replace the original assertion. These UI fixtures contain synthetic data.
    @MainActor
    private func attachInputFailureSnapshot(in app: XCUIApplication, reason: String) {
        let text: String
        do {
            let root = BudgetSnapshotNode(try app.snapshot())
            let controls = root.flattened.filter {
                $0.type == .textField || $0.type == .switch || $0.type == .keyboard || $0.type == .menu
                    || $0.identifier == "fx.enable" || $0.identifier == "fx.disable" || $0.identifier == "fx.active"
            }
            text = ([reason, "app=\(root.frame)"] + controls.map {
                "type=\($0.type.rawValue), id=\($0.identifier), label=\($0.label), "
                    + "value=\(String(reflecting: $0.value)), enabled=\($0.enabled), frame=\($0.frame)"
            }).joined(separator: "\n")
        } catch {
            text = "\(reason)\nPublic post-failure snapshot failed: \(error)"
        }
        let trace = XCTAttachment(string: text)
        trace.name = "Actual post-failure input snapshot"
        trace.lifetime = .keepAlways
        add(trace)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Post-failure synthetic input screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    /// Value copy of one public XCUI snapshot, also usable by deterministic helper tests.
    private struct BudgetSnapshotNode {
        let type: XCUIElement.ElementType
        let identifier: String
        let label: String
        let frame: CGRect
        let enabled: Bool
        let value: String?
        var children: [BudgetSnapshotNode] = []

        @MainActor
        init(_ snapshot: any XCUIElementSnapshot) {
            type = snapshot.elementType
            identifier = snapshot.identifier
            label = snapshot.label
            frame = snapshot.frame
            enabled = snapshot.isEnabled
            value = snapshot.value as? String
            children = snapshot.children.map { BudgetSnapshotNode($0) }
        }

        init(_ type: XCUIElement.ElementType, _ frame: CGRect,
             identifier: String = "", label: String = "", enabled: Bool = true, value: String? = nil,
             children: [BudgetSnapshotNode] = []) {
            self.type = type
            self.identifier = identifier
            self.label = label
            self.frame = frame
            self.enabled = enabled
            self.value = value
            self.children = children
        }

        var flattened: [BudgetSnapshotNode] { [self] + children.flatMap(\.flattened) }

        var hasFinitePositiveFrame: Bool {
            !frame.isNull && !frame.isInfinite && frame.size.width > 0 && frame.size.height > 0
                && [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height].allSatisfy(\.isFinite)
        }
    }

    private struct BudgetGeometryError: Error, CustomStringConvertible {
        let description: String
    }

    /// Snapshot existence, enablement and viewport occupancy are different facts. Keep zero
    /// or offscreen keyboard nodes as observations; reject negative/non-finite geometry rather
    /// than guessing that a broken AX rectangle means the software keyboard has disappeared.
    private struct FXKeyboardSnapshot {
        let application: CGRect
        let doneButtons: [BudgetSnapshotNode]
        let visibleKeyboards: [CGRect]

        init(root: BudgetSnapshotNode) throws {
            func validate(_ frame: CGRect, allowEmpty: Bool = false) throws {
                // CGRect.width/height standardize negative sizes; inspect the stored size
                // before any intersection/standardization can disguise an invalid AX frame.
                guard !frame.isNull, !frame.isInfinite,
                      [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height].allSatisfy(\.isFinite),
                      frame.size.width >= 0, frame.size.height >= 0, allowEmpty || !frame.isEmpty else {
                    throw BudgetGeometryError(description: "Invalid FX keyboard observation frame: \(frame)")
                }
            }
            guard root.type == .application else {
                throw BudgetGeometryError(description: "FX keyboard observation requires an application snapshot")
            }
            try validate(root.frame)
            application = root.frame
            let nodes = root.flattened
            let forms = nodes.filter { $0.type == .scrollView && $0.identifier == "expense.form" }
            guard forms.count == 1, let form = forms.first else {
                throw BudgetGeometryError(description: "FX keyboard observation lost the foreground form")
            }
            try validate(form.frame)
            guard form.frame.intersects(application), !nodes.contains(where: { $0.type == .alert }) else {
                throw BudgetGeometryError(description: "FX form is offscreen or interrupted by an alert")
            }
            // The real toolbar has an `other` wrapper with the same identifier as its button.
            // Select the native button by type; duplicate actual buttons are still ambiguous.
            doneButtons = nodes.filter { $0.type == .button && $0.identifier == "fx.keyboard.done" }
            guard doneButtons.count <= 1 else {
                throw BudgetGeometryError(description: "Ambiguous FX keyboard Done buttons")
            }
            for button in doneButtons { try validate(button.frame, allowEmpty: true) }
            let keyboards = nodes.filter { $0.type == .keyboard }
            for keyboard in keyboards { try validate(keyboard.frame, allowEmpty: true) }
            visibleKeyboards = keyboards.compactMap {
                let overlap = $0.frame.intersection(root.frame)
                return overlap.isNull || overlap.isEmpty ? nil : overlap
            }
        }

        func doneTapOffset() throws -> CGVector {
            guard let done = doneButtons.first, done.enabled, !done.frame.isEmpty,
                  application.contains(done.frame), !visibleKeyboards.isEmpty,
                  !visibleKeyboards.contains(where: { $0.intersects(done.frame) }) else {
                throw BudgetGeometryError(description: "FX Done is missing, disabled, offscreen or keyboard-occluded")
            }
            return CGVector(dx: done.frame.midX - application.minX, dy: done.frame.midY - application.minY)
        }

        // A disappearing keyboard alone must not hide a lost tap: the conditional Done
        // toolbar must also be gone. A disabled but still onscreen keyboard still blocks.
        var isDismissed: Bool { doneButtons.isEmpty && visibleKeyboards.isEmpty }

        static func describe(_ root: BudgetSnapshotNode) -> String {
            "app=\(root.frame)\n" + root.flattened.filter {
                $0.type == .keyboard || $0.identifier == "fx.keyboard.done"
                    || $0.identifier == "expense.form"
                    || ($0.type == .textField && $0.identifier.hasPrefix("fx."))
            }.map {
                "\($0.type):\($0.identifier) frame=\($0.frame) enabled=\($0.enabled) value=\($0.value ?? "nil")"
            }.joined(separator: "\n")
        }
    }

    @MainActor
    func testFXKeyboardSnapshotRejectsLostTapAndUnknownGeometry() throws {
        // Captured local Chinese AX5 frames, not invented evidence for the cancelled runner.
        let doneFrame = CGRect(x: 318.6667, y: 524, width: 62.3333, height: 36)
        let keyboardFrame = CGRect(x: 0, y: 583, width: 402, height: 233)
        let done = BudgetSnapshotNode(.button, doneFrame, identifier: "fx.keyboard.done")
        let keyboard = BudgetSnapshotNode(.keyboard, keyboardFrame)
        func tree(_ children: [BudgetSnapshotNode]) -> BudgetSnapshotNode {
            BudgetSnapshotNode(.application, CGRect(x: 0, y: 0, width: 402, height: 874), children: [
                BudgetSnapshotNode(.scrollView, CGRect(x: 0, y: 62, width: 402, height: 740),
                                   identifier: "expense.form")
            ] + children)
        }
        var reads = 0
        func capture() -> BudgetSnapshotNode {
            reads += 1
            return tree([BudgetSnapshotNode(.other, doneFrame, identifier: "fx.keyboard.done", children: [done]), keyboard])
        }
        let before = try FXKeyboardSnapshot(root: capture())
        XCTAssertEqual(reads, 1)
        let offset = try before.doneTapOffset()
        XCTAssertEqual(offset.dx, doneFrame.midX)
        XCTAssertEqual(offset.dy, doneFrame.midY)
        XCTAssertEqual(reads, 1, "Activation must not re-resolve a live Done element")
        XCTAssertFalse(before.isDismissed, "One lost tap must stay non-pass")
        XCTAssertFalse(try FXKeyboardSnapshot(root: tree([keyboard])).isDismissed)
        XCTAssertFalse(try FXKeyboardSnapshot(root: tree([done])).isDismissed)
        XCTAssertFalse(try FXKeyboardSnapshot(root: tree([
            BudgetSnapshotNode(.keyboard, keyboardFrame, enabled: false)
        ])).isDismissed, "Enablement is not viewport occupancy")
        for frame in [CGRect.zero, CGRect(x: 0, y: 874, width: 402, height: 233),
                      CGRect(x: 403, y: 583, width: 402, height: 233)] {
            let hidden = try FXKeyboardSnapshot(root: tree([BudgetSnapshotNode(.keyboard, frame)]))
            XCTAssertTrue(hidden.isDismissed, "A finite non-occupying AX node alone cannot block the viewport")
            XCTAssertTrue(hidden.visibleKeyboards.isEmpty, "The pan helper must use the same classification")
        }
        XCTAssertTrue(try FXKeyboardSnapshot(root: tree([])).isDismissed)
        for frame in [CGRect(x: 0, y: 800, width: 402, height: 233),
                      CGRect(x: 0, y: 873, width: 402, height: 1)] {
            XCTAssertFalse(try FXKeyboardSnapshot(root: tree([BudgetSnapshotNode(.keyboard, frame)])).isDismissed)
        }
        for frame in [CGRect(x: 0, y: 583, width: -1, height: 233),
                      CGRect(x: 0, y: 583, width: 402, height: -1),
                      CGRect(x: 0, y: 583, width: 402, height: CGFloat.nan), CGRect.null, CGRect.infinite] {
            XCTAssertThrowsError(try FXKeyboardSnapshot(root: tree([BudgetSnapshotNode(.keyboard, frame)])), "raw size: \(frame.size)")
        }
        for buttons in [[], [done, done],
                        [BudgetSnapshotNode(.button, doneFrame, identifier: "fx.keyboard.done", enabled: false)],
                        [BudgetSnapshotNode(.button, .zero, identifier: "fx.keyboard.done")],
                        [BudgetSnapshotNode(.button, keyboardFrame, identifier: "fx.keyboard.done")],
                        [BudgetSnapshotNode(.button, CGRect(x: 400, y: 524, width: 60, height: 36), identifier: "fx.keyboard.done")]] {
            XCTAssertThrowsError(try FXKeyboardSnapshot(root: tree(buttons + [keyboard])).doneTapOffset())
        }
        XCTAssertThrowsError(try FXKeyboardSnapshot(root: tree([done])).doneTapOffset())
        XCTAssertThrowsError(try FXKeyboardSnapshot(root: tree([done, keyboard,
            BudgetSnapshotNode(.alert, CGRect(x: 0, y: 0, width: 300, height: 300))])))
        XCTAssertThrowsError(try FXKeyboardSnapshot(root: BudgetSnapshotNode(.application,
            CGRect(x: 0, y: 0, width: 402, height: 874))))
    }

    private struct FXModeSnapshot: CustomStringConvertible {
        enum Action: String { case enable = "fx.enable", disable = "fx.disable" }
        let root: BudgetSnapshotNode
        let form: BudgetSnapshotNode
        let active: Bool
        let button: BudgetSnapshotNode?

        init(root: BudgetSnapshotNode) throws {
            guard root.type == .application, root.hasFinitePositiveFrame else {
                throw BudgetGeometryError(description: "Invalid FX application snapshot")
            }
            let nodes = root.flattened
            let keyboard = try FXKeyboardSnapshot(root: root)
            guard keyboard.isDismissed,
                  !nodes.contains(where: { [.alert, .menu].contains($0.type) }),
                  !nodes.contains(where: { $0.identifier == "fx.enabled" }) else {
                throw BudgetGeometryError(description: "FX transition is occluded or still exposes a switch")
            }
            let forms = nodes.filter { $0.type == .scrollView && $0.identifier == "expense.form" }
            guard forms.count == 1, let form = forms.first, form.hasFinitePositiveFrame else {
                throw BudgetGeometryError(description: "Missing or ambiguous FX form")
            }
            let content = form.flattened
            let enable = content.filter { $0.identifier == Action.enable.rawValue }
            let disable = content.filter { $0.identifier == Action.disable.rawValue }
            let headings = content.filter { $0.identifier == "fx.active" }
            let identifiers = ["fx.originalAmount", "fx.rate", "fx.accountingAmount"]
            let fields = content.filter { identifiers.contains($0.identifier) }
            let active = headings.count == 1 && headings[0].type == .staticText
            if active {
                guard enable.isEmpty, disable.count <= 1, fields.count == 3,
                      identifiers.allSatisfy({ id in fields.filter {
                          $0.identifier == id && $0.type == .textField && $0.enabled && $0.hasFinitePositiveFrame
                      }.count == 1 }) else {
                    throw BudgetGeometryError(description: "Active FX must expose its three real editors and no Enable button")
                }
            } else {
                guard headings.isEmpty, enable.count == 1, disable.isEmpty, fields.isEmpty else {
                    throw BudgetGeometryError(description: "Inactive FX must expose only Enable, without stale FX fields")
                }
            }
            let button = active ? disable.first : enable.first
            guard button == nil || button?.type == .button else {
                throw BudgetGeometryError(description: "FX action is not a button")
            }
            self.root = root
            self.form = form
            self.active = active
            self.button = button
        }

        func tapOffset(for action: Action) throws -> CGVector {
            guard active == (action == .disable), let button,
                  button.identifier == action.rawValue, button.enabled, button.hasFinitePositiveFrame,
                  button.frame.width >= 44, button.frame.height >= 44 else {
                throw BudgetGeometryError(description: "Wrong, absent, disabled or undersized FX action")
            }
            let nodes = root.flattened
            let navigation = nodes.filter { $0.type == .navigationBar && $0.frame.intersects(root.frame) }
            let bottom = nodes.filter {
                ($0.type == .tabBar || $0.identifier == "expense.save" || $0.identifier == "fx.testHost")
                    && $0.frame.intersects(root.frame)
            }
            guard !navigation.isEmpty, (navigation + bottom).allSatisfy(\.hasFinitePositiveFrame) else {
                throw BudgetGeometryError(description: "Missing or invalid FX chrome")
            }
            let visible = form.frame.intersection(root.frame)
            let top = max(visible.minY, navigation.map(\.frame.maxY).max()!) + 8
            let end = min(visible.maxY, bottom.map(\.frame.minY).min() ?? visible.maxY) - 8
            guard end > top, visible.width > 16 else {
                throw BudgetGeometryError(description: "Contradictory FX viewport")
            }
            let lane = CGRect(x: visible.minX + 8, y: top, width: visible.width - 16, height: end - top)
            guard lane.contains(button.frame) else {
                throw BudgetGeometryError(description: "FX button is not wholly inside the safe viewport")
            }
            return CGVector(dx: button.frame.midX - root.frame.minX, dy: button.frame.midY - root.frame.minY)
        }

        var description: String {
            "active=\(active), action=\(button?.identifier ?? "none"), enabled=\(button?.enabled.description ?? "none"), frame=\(String(describing: button?.frame))"
        }
    }

    @MainActor
    func testFXModeButtonsRejectUnsafeStateAndObserveRealTransition() throws {
        let frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        let enable = BudgetSnapshotNode(.button, CGRect(x: 36, y: 132, width: 330, height: 48), identifier: "fx.enable")
        let disable = BudgetSnapshotNode(.button, CGRect(x: 36, y: 230, width: 330, height: 120), identifier: "fx.disable")
        let heading = BudgetSnapshotNode(.staticText, CGRect(x: 36, y: 132, width: 330, height: 88), identifier: "fx.active")
        let fields = ["fx.originalAmount", "fx.rate", "fx.accountingAmount"].enumerated().map {
            BudgetSnapshotNode(.textField, CGRect(x: 36, y: 400 + $0.offset * 60, width: 330, height: 44), identifier: $0.element)
        }
        func tree(_ content: [BudgetSnapshotNode], extra: [BudgetSnapshotNode] = [], formID: String = "expense.form") -> BudgetSnapshotNode {
            BudgetSnapshotNode(.application, frame, children: [
                BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 62, width: 402, height: 54)),
                BudgetSnapshotNode(.scrollView, frame, identifier: formID, children: content),
                BudgetSnapshotNode(.button, CGRect(x: 20, y: 750, width: 362, height: 50), identifier: "expense.save")
            ] + extra)
        }
        let off = try FXModeSnapshot(root: tree([enable]))
        XCTAssertFalse(off.active, "A lost tap must never satisfy Enable")
        XCTAssertEqual(try off.tapOffset(for: .enable), CGVector(dx: 201, dy: 156))
        XCTAssertThrowsError(try off.tapOffset(for: .disable))
        let on = try FXModeSnapshot(root: tree([heading, disable] + fields))
        XCTAssertTrue(on.active)
        XCTAssertEqual(try on.tapOffset(for: .disable), CGVector(dx: 201, dy: 290))
        XCTAssertThrowsError(try on.tapOffset(for: .enable))
        let stored = try FXModeSnapshot(root: tree([heading] + fields))
        XCTAssertTrue(stored.active)
        XCTAssertThrowsError(try stored.tapOffset(for: .disable), "Stored metadata cannot be removed")
        XCTAssertFalse(try FXModeSnapshot(root: tree([enable])).active, "Cancel must remove all FX editors")
        for invalid in [CGRect.zero, .null, .infinite,
                        CGRect(x: 36, y: 132, width: -330, height: 48),
                        CGRect(x: 36, y: 132, width: 330, height: CGFloat.nan),
                        CGRect(x: 36, y: 90, width: 330, height: 48),
                        CGRect(x: 36, y: 730, width: 330, height: 48),
                        CGRect(x: 36, y: 132, width: 330, height: 28)] {
            let value = BudgetSnapshotNode(.button, invalid, identifier: "fx.enable")
            XCTAssertThrowsError(try FXModeSnapshot(root: tree([value])).tapOffset(for: .enable))
        }
        let blocked = BudgetSnapshotNode(.button, enable.frame, identifier: "fx.enable", enabled: false)
        XCTAssertThrowsError(try FXModeSnapshot(root: tree([blocked])).tapOffset(for: .enable))
        for content in [[], [enable, enable], [enable, disable], [enable] + fields,
                        [heading, disable], [heading, disable, disable] + fields,
                        [heading, disable, fields[0], fields[0], fields[2]]] {
            XCTAssertThrowsError(try FXModeSnapshot(root: tree(content)))
        }
        XCTAssertThrowsError(try FXModeSnapshot(root: tree([enable], formID: "wrong.form")))
        for type in [XCUIElement.ElementType.alert, .menu, .keyboard] {
            XCTAssertThrowsError(try FXModeSnapshot(root: tree([enable], extra: [BudgetSnapshotNode(type, frame)])))
        }
        for invalid in [CGRect.null, .infinite, CGRect(x: 0, y: 500, width: 402, height: -1),
                        CGRect(x: 0, y: 500, width: 402, height: CGFloat.nan)] {
            XCTAssertThrowsError(try FXModeSnapshot(root: tree([enable], extra: [BudgetSnapshotNode(.keyboard, invalid)])))
        }
        let legacy = BudgetSnapshotNode(.switch, enable.frame, identifier: "fx.enabled", value: "0")
        XCTAssertThrowsError(try FXModeSnapshot(root: tree([legacy])))
        XCTAssertThrowsError(try FXModeSnapshot(root: tree([enable], extra: [
            BudgetSnapshotNode(.scrollView, frame, identifier: "expense.form")
        ])))
    }

    /// A single public accessibility snapshot is the authority for the source row, foreground
    /// list, navigation chrome and bottom occluders used by one navigation gesture. This avoids
    /// composing a hit point from independently refreshed XCUIElement queries while a SwiftUI
    /// List is being virtualized or its navigation stack is settling.
    private struct NavigationTapGeometry: CustomStringConvertible {
        let application: CGRect
        let list: CGRect
        let lane: CGRect
        let target: CGRect?
        let targetEnabled: Bool

        init(listIdentifier: String, targetIdentifier: String,
             snapshot: () throws -> BudgetSnapshotNode) throws {
            let root = try snapshot()
            func requireFrame(_ frame: CGRect, _ label: String, allowEmpty: Bool = false) throws {
                guard !frame.isNull, !frame.isInfinite,
                      [frame.minX, frame.minY, frame.width, frame.height].allSatisfy(\.isFinite),
                      frame.width >= 0, frame.height >= 0, allowEmpty || !frame.isEmpty else {
                    throw BudgetGeometryError(description: "Invalid navigation \(label) frame: \(frame)")
                }
            }
            guard root.type == .application else {
                throw BudgetGeometryError(description: "Navigation snapshot root is not the application")
            }
            try requireFrame(root.frame, "application")
            application = root.frame
            let nodes = root.flattened
            let lists = nodes.filter { $0.type == .collectionView && $0.identifier == listIdentifier }
            guard lists.count == 1, let foreground = lists.first else {
                throw BudgetGeometryError(description: "Missing or ambiguous foreground list: \(listIdentifier)")
            }
            try requireFrame(foreground.frame, listIdentifier)
            let visibleList = foreground.frame.intersection(root.frame)
            try requireFrame(visibleList, "visible foreground list")
            list = visibleList

            let navigation = nodes.filter { $0.type == .navigationBar && $0.frame.intersects(root.frame) }
            for node in navigation { try requireFrame(node.frame, "navigation bar") }
            guard let navigationBottom = navigation.map(\.frame.maxY).max() else {
                throw BudgetGeometryError(description: "Navigation snapshot has no visible navigation bar")
            }
            let bottomOccluders = nodes.filter {
                ($0.type == .tabBar || $0.type == .keyboard)
                    && $0.frame.intersects(visibleList)
            }
            for node in bottomOccluders { try requireFrame(node.frame, "bottom occluder") }
            let safeBottom = min(
                visibleList.maxY,
                bottomOccluders.map(\.frame.minY).min() ?? visibleList.maxY
            ) - 8
            let safeTop = max(visibleList.minY, navigationBottom) + 8
            lane = CGRect(
                x: visibleList.minX + 16,
                y: safeTop,
                width: visibleList.width - 32,
                height: safeBottom - safeTop
            )
            try requireFrame(lane, "interaction lane")
            guard lane.height > 80 else {
                throw BudgetGeometryError(description: "Navigation interaction lane is too small")
            }

            let targets = foreground.flattened.filter {
                $0.type == .button && $0.identifier == targetIdentifier
            }
            guard targets.count <= 1 else {
                throw BudgetGeometryError(description: "Duplicate navigation target: \(targetIdentifier)")
            }
            if let node = targets.first {
                try requireFrame(node.frame, targetIdentifier, allowEmpty: true)
                target = node.frame.isEmpty ? nil : node.frame
                targetEnabled = node.enabled
            } else {
                target = nil
                targetEnabled = false
            }
        }

        var targetIsReady: Bool {
            guard let target else { return false }
            return targetEnabled && application.contains(target) && lane.contains(target)
        }

        var description: String {
            "app=\(application), list=\(list), lane=\(lane), "
                + "target=\(String(describing: target)), enabled=\(targetEnabled)"
        }
    }

    @MainActor
    func testNavigationTapGeometryUsesOneSnapshotAndRejectsOcclusion() throws {
        let nav = BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 40, width: 400, height: 60))
        let tab = BudgetSnapshotNode(.tabBar, CGRect(x: 0, y: 720, width: 400, height: 80))
        let target = BudgetSnapshotNode(
            .button,
            CGRect(x: 32, y: 180, width: 336, height: 80),
            identifier: "settings.pro"
        )
        var list = BudgetSnapshotNode(
            .collectionView,
            CGRect(x: 0, y: 60, width: 400, height: 740),
            identifier: "settings.view",
            children: [target]
        )
        var root = BudgetSnapshotNode(
            .application,
            CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [nav, list, tab]
        )
        var captures = 0
        let captured = try NavigationTapGeometry(
            listIdentifier: "settings.view",
            targetIdentifier: "settings.pro"
        ) {
            captures += 1
            return root
        }
        list.children[0] = BudgetSnapshotNode(
            .button,
            CGRect(x: 32, y: 680, width: 336, height: 60),
            identifier: "settings.pro"
        )
        root.children[1] = list
        XCTAssertEqual(captures, 1)
        XCTAssertTrue(captured.targetIsReady)
        XCTAssertEqual(captured.target, target.frame)

        let covered = try NavigationTapGeometry(
            listIdentifier: "settings.view",
            targetIdentifier: "settings.pro"
        ) { root }
        XCTAssertFalse(covered.targetIsReady, "A row overlapping the tab bar cannot be tapped")
        list.children[0] = BudgetSnapshotNode(
            .button,
            target.frame,
            identifier: "settings.pro",
            enabled: false
        )
        root.children[1] = list
        let disabled = try NavigationTapGeometry(
            listIdentifier: "settings.view",
            targetIdentifier: "settings.pro"
        ) { root }
        XCTAssertFalse(disabled.targetIsReady)
        list.children.append(list.children[0])
        root.children[1] = list
        XCTAssertThrowsError(try NavigationTapGeometry(
            listIdentifier: "settings.view",
            targetIdentifier: "settings.pro"
        ) { root })
    }

    private struct BudgetGeometry: CustomStringConvertible {
        let application: CGRect
        let navigation: [CGRect]
        let keyboards: [CGRect]
        let target: CGRect?
        let navigationBottom: CGFloat
        let safeBottom: CGFloat

        init(targetIdentifier: String, targetType: XCUIElement.ElementType,
             noKeyboardInset: CGFloat, snapshot: () throws -> BudgetSnapshotNode) throws {
            // Capture errors must propagate: they are not evidence of keyboard absence.
            let root = try snapshot()
            func requireFrame(_ frame: CGRect, _ label: String, allowEmpty: Bool = false) throws {
                guard !frame.isNull, !frame.isInfinite,
                      [frame.origin.x, frame.origin.y, frame.width, frame.height].allSatisfy(\.isFinite),
                      frame.width >= 0, frame.height >= 0, allowEmpty || !frame.isEmpty else {
                    throw BudgetGeometryError(description: "Invalid \(label) frame: \(frame)")
                }
            }
            guard root.type == .application else {
                throw BudgetGeometryError(description: "Budget snapshot root is not the application")
            }
            try requireFrame(root.frame, "application")
            application = root.frame
            let nodes = root.flattened
            func visibleChrome(_ type: XCUIElement.ElementType) throws -> [CGRect] {
                try nodes.filter { $0.type == type }.compactMap { node in
                    try requireFrame(node.frame, "\(type)")
                    return node.frame.intersects(root.frame) ? node.frame : nil
                }
            }
            navigation = try visibleChrome(.navigationBar)
            keyboards = try visibleChrome(.keyboard)
            guard let navigationBottom = navigation.map(\.maxY).max() else {
                throw BudgetGeometryError(description: "Budget snapshot has no visible navigation bar")
            }
            self.navigationBottom = navigationBottom
            safeBottom = keyboards.map(\.minY).min().map { $0 - 8 }
                ?? (root.frame.maxY - noKeyboardInset)
            guard noKeyboardInset.isFinite, noKeyboardInset >= 0,
                  navigationBottom + 8 < safeBottom, safeBottom <= root.frame.maxY else {
                throw BudgetGeometryError(description: "Contradictory budget chrome: nav=\(navigation), keyboards=\(keyboards)")
            }
            let targets = nodes.filter { $0.identifier == targetIdentifier && $0.type == targetType }
            guard targets.count <= 1 else {
                throw BudgetGeometryError(description: "Duplicate budget target: \(targetIdentifier)")
            }
            // A virtualized/empty target needs a bounded reveal, never a permissive tap.
            if let frame = targets.first?.frame {
                try requireFrame(frame, targetIdentifier, allowEmpty: true)
                target = frame.isEmpty ? nil : frame
            } else {
                target = nil
            }
        }

        var targetIsInLane: Bool {
            guard let target else { return false }
            return application.contains(target)
                && target.minY > navigationBottom + 8 && target.maxY < safeBottom
        }

        var description: String {
            "app=\(application), nav=\(navigation), keyboards=\(keyboards), "
                + "target=\(String(describing: target)), lane=\(navigationBottom + 8)...\(safeBottom)"
        }
    }

    @MainActor
    func testBudgetGeometryUsesOneSnapshotAndConservativeChromeBounds() throws {
        let target = BudgetSnapshotNode(.textField, CGRect(x: 20, y: 180, width: 300, height: 40),
                                        identifier: "budget.test")
        let nav = BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 40, width: 400, height: 60))
        let keyboard = BudgetSnapshotNode(.keyboard, CGRect(x: 0, y: 500, width: 400, height: 300))
        var root = BudgetSnapshotNode(.application, CGRect(x: 0, y: 0, width: 400, height: 800),
                                      children: [nav, target, keyboard])
        var captures = 0
        let captured = try BudgetGeometry(targetIdentifier: "budget.test", targetType: .textField,
                                          noKeyboardInset: 80) {
            captures += 1
            return root
        }
        // Model a keyboard disappearing after capture. Existing geometry must not re-query it.
        root.children.removeLast()
        XCTAssertEqual(captures, 1)
        XCTAssertEqual(captured.safeBottom, 492)
        XCTAssertTrue(captured.targetIsInLane)
        XCTAssertEqual(captured.target, target.frame)
        XCTAssertFalse(captured.description.isEmpty)
        XCTAssertEqual(captures, 1)
        let absent = try BudgetGeometry(targetIdentifier: "budget.test", targetType: .textField,
                                       noKeyboardInset: 80) { root }
        XCTAssertEqual(absent.safeBottom, 720)
        XCTAssertTrue(absent.keyboards.isEmpty)
        root.children += [keyboard,
            BudgetSnapshotNode(.keyboard, CGRect(x: 0, y: 450, width: 400, height: 350)),
            BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 80, width: 400, height: 60))]
        let multiple = try BudgetGeometry(targetIdentifier: "budget.test", targetType: .textField,
                                         noKeyboardInset: 80) { root }
        XCTAssertEqual(multiple.navigationBottom, 140)
        XCTAssertEqual(multiple.safeBottom, 442)
        root.children.removeAll { $0.identifier == "budget.test" }
        let virtualized = try BudgetGeometry(targetIdentifier: "budget.test", targetType: .textField,
                                             noKeyboardInset: 80) { root }
        XCTAssertNil(virtualized.target)
        XCTAssertFalse(virtualized.targetIsInLane)
        let covered = BudgetSnapshotNode(.button, CGRect(x: 20, y: 430, width: 300, height: 50),
                                         identifier: "budget.save")
        root.children.append(covered)
        let save = try BudgetGeometry(targetIdentifier: "budget.save", targetType: .button,
                                     noKeyboardInset: 8) { root }
        XCTAssertFalse(save.targetIsInLane, "Partial overlap with the keyboard cannot accept Save")
    }

    @MainActor
    func testBudgetGeometryRejectsFailedCaptureAndInvalidSnapshots() {
        let nav = BudgetSnapshotNode(.navigationBar, CGRect(x: 0, y: 40, width: 400, height: 60))
        let target = BudgetSnapshotNode(.textField, CGRect(x: 20, y: 180, width: 300, height: 40),
                                        identifier: "budget.test")
        let good = BudgetSnapshotNode(.application, CGRect(x: 0, y: 0, width: 400, height: 800),
                                      children: [nav, target])
        var captures = 0
        XCTAssertThrowsError(try BudgetGeometry(targetIdentifier: "budget.test", targetType: .textField,
                                                noKeyboardInset: 80) {
            captures += 1
            throw BudgetGeometryError(description: "capture failed")
        })
        XCTAssertEqual(captures, 1, "A failed capture cannot retry or become keyboard absence")
        let invalidRoots: [BudgetSnapshotNode] = [
            BudgetSnapshotNode(.application, .zero, children: good.children),
            BudgetSnapshotNode(.other, good.frame, children: good.children),
            BudgetSnapshotNode(.application, good.frame, children: [target]),
            BudgetSnapshotNode(.application, good.frame, children: [nav, target, target]),
            BudgetSnapshotNode(.application, good.frame, children: [nav,
                BudgetSnapshotNode(.textField, CGRect(x: CGFloat.nan, y: 180, width: 300, height: 40),
                                   identifier: "budget.test")]),
            BudgetSnapshotNode(.application, good.frame, children: [target,
                BudgetSnapshotNode(.navigationBar, .zero)]),
            BudgetSnapshotNode(.application, good.frame, children: good.children + [
                BudgetSnapshotNode(.keyboard, .zero)]),
            BudgetSnapshotNode(.application, good.frame, children: good.children + [
                BudgetSnapshotNode(.keyboard, CGRect(x: 0, y: CGFloat.infinity, width: 400, height: 300))]),
            BudgetSnapshotNode(.application, good.frame, children: good.children + [
                BudgetSnapshotNode(.keyboard, CGRect(x: 0, y: 80, width: 400, height: 720))]),
        ]
        for (index, root) in invalidRoots.enumerated() {
            XCTAssertThrowsError(try BudgetGeometry(targetIdentifier: "budget.test", targetType: .textField,
                                                    noKeyboardInset: 80) { root }, "Invalid snapshot \(index)")
        }
    }

    @MainActor
    private func captureBudgetGeometry(
        targetIdentifier: String, targetType: XCUIElement.ElementType,
        noKeyboardInset: CGFloat, in app: XCUIApplication
    ) -> BudgetGeometry? {
        do {
            return try BudgetGeometry(targetIdentifier: targetIdentifier, targetType: targetType,
                                      noKeyboardInset: noKeyboardInset) {
                BudgetSnapshotNode(try app.snapshot())
            }
        } catch {
            XCTFail("Unable to capture budget geometry for \(targetIdentifier): \(error)")
            return nil
        }
    }

    @MainActor
    private func tapBudgetTarget(_ geometry: BudgetGeometry, in app: XCUIApplication) {
        // Use the captured center instead of resolving the target's frame again at tap time.
        guard let frame = geometry.target else {
            XCTFail("No budget target in captured geometry: \(geometry)")
            return
        }
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: frame.midX - geometry.application.minX,
            dy: frame.midY - geometry.application.minY
        )).tap()
    }

    @MainActor
    private func makeBudgetSaveReady(
        _ save: XCUIElement,
        in app: XCUIApplication
    ) -> Bool {
        let budgetForm = app.collectionViews["budget.setup.view"]
        var lastGeometry: BudgetGeometry?

        for _ in 0..<12 {
            guard let geometry = captureBudgetGeometry(targetIdentifier: "budget.save", targetType: .button,
                                                       noKeyboardInset: 8, in: app) else { return false }
            lastGeometry = geometry
            if geometry.targetIsInLane && save.isHittable {
                return true
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

        XCTFail("Budget Save did not enter the safe interaction lane; last snapshot: \(String(describing: lastGeometry))")
        return false
    }

    @MainActor
    private func enterBudgetValue(
        _ value: String,
        into identifier: String,
        in app: XCUIApplication
    ) -> Bool {
        guard prepareBudgetEditor(identifier, in: app) else { return false }
        // Type into the target exactly once. XCTest can still route targeted typeText to a stale
        // active editor, so the later three-field readback remains the fail-closed authority.
        // Never type through the application or correctively retype after a failed assertion.
        app.textFields[identifier].typeText(value)
        return true
    }

    @MainActor
    private func prepareBudgetEditor(
        _ identifier: String,
        in app: XCUIApplication,
        towardEarlierRow: Bool = false
    ) -> Bool {
        guard let initial = revealBudgetField(identifier, in: app, towardEarlierRow: towardEarlierRow) else { return false }

        tapBudgetTarget(initial, in: app)
        let keyboard = app.keyboards.firstMatch
        guard keyboard.waitForExistence(timeout: 5) else {
            XCTFail("Budget keyboard did not appear; last pre-tap snapshot: \(initial)")
            return false
        }

        // A second tap can open the native selection menu. Type once after one focus tap;
        // exact values must subsequently be reloaded from the saved budget, not inferred here.
        return true
    }

    @MainActor
    private func revealBudgetField(
        _ identifier: String,
        in app: XCUIApplication,
        towardEarlierRow: Bool = false,
        formIdentifier: String = "budget.setup.view"
    ) -> BudgetGeometry? {
        let budgetForm = app.collectionViews[formIdentifier]
        let field = app.textFields[identifier]
        var lastGeometry: BudgetGeometry?

        for _ in 0..<12 {
            guard let geometry = captureBudgetGeometry(targetIdentifier: identifier, targetType: .textField,
                                                       noKeyboardInset: 80, in: app) else { return nil }
            lastGeometry = geometry
            if let frame = geometry.target {
                if geometry.targetIsInLane && field.isHittable {
                    return geometry
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
                if frame.minY <= geometry.navigationBottom + 8 {
                    upperPoint.press(forDuration: 0.05, thenDragTo: lowerPoint)
                } else {
                    lowerPoint.press(forDuration: 0.05, thenDragTo: upperPoint)
                }
            } else {
                let upperPoint = budgetForm.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.5, dy: 0.38)
                )
                let lowerPoint = budgetForm.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)
                )
                if towardEarlierRow {
                    upperPoint.press(forDuration: 0.05, thenDragTo: lowerPoint)
                } else {
                    lowerPoint.press(forDuration: 0.05, thenDragTo: upperPoint)
                }
            }
        }

        XCTFail(
            "Budget field did not enter the safe interaction lane: \(identifier); "
                + "last snapshot: \(String(describing: lastGeometry))"
        )
        return nil
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
