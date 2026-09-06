import Foundation
import Testing
@testable import MindBudget

@MainActor
struct ForeignCurrencyFormTests {
    private let locale = Locale(identifier: "en_US")
    private let pro = FeatureAccessService(entitlements: .proSubscription)
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "America/New_York")!
        return value
    }
    private var date: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 14))!
    }
    private func state() -> ForeignCurrencyFormState {
        var value = ForeignCurrencyFormState(
            accountingCurrencyCode: "USD", selectedDate: date, calendar: calendar, locale: locale
        )
        value.selectCurrency("EUR")
        value.setOriginalAmount("3")
        value.setRate("2")
        return value
    }
    private func model(writer: ReminderEventWriter = .live) -> ExpenseFormViewModel {
        let value = ExpenseFormViewModel(existingExpense: nil, now: date, reminderEventWriter: writer)
        value.prepareInput(locale: locale, calendar: calendar)
        value.setForeignCurrencyEnabled(true, access: ExistingPremiumEntryAccess(featureAccess: pro),
                                        accountingCurrency: "USD", locale: locale, calendar: calendar)
        value.updateForeignCurrency({
            $0.selectCurrency("EUR")
            $0.setOriginalAmount("3")
            $0.setRate("2")
        }, locale: locale)
        return value
    }
    private func draft(id: UUID = UUID(), amount: Int64 = 600, foreign: ExpenseForeignCurrency? = nil) -> ExpenseDraft {
        ExpenseDraft(id: id, amount: Money(minorUnits: amount, currencyCode: "USD"), category: .food,
                     bucket: .discretionary, merchantName: nil, note: nil, spentAt: date,
                     spentTimeZoneIdentifier: calendar.timeZone.identifier, createdAt: date, updatedAt: date,
                     paymentMethod: nil, emotionTag: nil, purchaseReason: nil, isPlanned: false,
                     isRecurring: false, source: .manual, allowMerchantIndexing: false, foreignCurrency: foreign)
    }
    private func save(_ value: ExpenseFormViewModel, actor: DataActor,
                      access: any FeatureAccessChecking = FeatureAccessService()) async -> Bool {
        await value.save(dataActor: actor, featureAccess: access, currencyCode: "USD", bucket: .discretionary,
                         locale: locale, now: date, timeZone: calendar.timeZone, cycleStartDay: 1, calendar: calendar)
    }

    @Test func explicitCurrencySelectionIsRequiredAndSameCurrencyIsRejected() throws {
        var value = ForeignCurrencyFormState(
            accountingCurrencyCode: "USD", selectedDate: date, calendar: calendar, locale: locale
        )
        value.setOriginalAmount("3")
        value.setRate("2")
        #expect(value.originalCurrencyCode == nil)
        #expect(throws: ForeignCurrencyError.currencyMismatch) { try value.resolve() }
        value.selectCurrency("USD")
        #expect(throws: ForeignCurrencyError.currencyMismatch) { try value.resolve() }
        value.selectCurrency("EUR")
        #expect(try value.resolve().accounting.minorUnits == 600)
    }

    @Test func rateTextNormalizesWithHalfEvenWithoutRewritingUserInput() throws {
        var value = state()
        value.setRate("1.000000025")
        #expect(value.rateText == "1.000000025")
        #expect(try value.resolve().foreign.rate == ForeignCurrencyRate(numerator: 50_000_001, denominator: 50_000_000))
        #expect(try value.resolve().accounting.minorUnits == 300)
    }

    @Test func overrideKeepsExactNonterminatingFractionAcrossReopenAndLocale() throws {
        var value = state()
        value.setAccountingAmount("1")
        let first = try value.resolve()
        #expect(first.foreign.rate == (try ForeignCurrencyRate(numerator: 1, denominator: 3)))
        #expect(value.rateText == "0.33333333")
        let reopened = try ForeignCurrencyFormState(existing: first.foreign, accounting: first.accounting,
                                                     calendar: calendar, locale: Locale(identifier: "de_DE"))
        #expect(reopened.rateText == "0,33333333")
        #expect(try reopened.resolve() == first)
    }

    @Test func explicitRateEditExitsOverrideAndOriginalEditPreservesChosenMode() throws {
        var value = state()
        value.setAccountingAmount("1")
        value.setOriginalAmount("6")
        #expect(try value.resolve().accounting.minorUnits == 100)
        #expect(try value.resolve().foreign.rate.denominator == 6)
        value.setRate("2")
        #expect(try value.resolve().foreign.source == .manualRate)
        #expect(try value.resolve().accounting.minorUnits == 1_200)
        value.setOriginalAmount("3")
        #expect(try value.resolve().accounting.minorUnits == 600)
    }

    @Test func invalidInputNeverReturnsPriorPreviewAndPreservesAllFields() throws {
        var value = state()
        let day = value.rateDate
        value.setRate("2oops")
        #expect(throws: ForeignCurrencyError.invalidRateText) { try value.resolve() }
        #expect(value.rateText == "2oops")
        #expect(value.originalAmountText == "3")
        #expect(value.originalCurrencyCode == "EUR")
        #expect(value.accountingAmountText == "6")
        #expect(value.rateDate == day)
        value.setRate("2")
        #expect(try value.resolve().accounting.minorUnits == 600)
    }

    @Test func savedRateDayAndZoneDoNotFollowCurrentDeviceCalendar() throws {
        let first = try state().resolve()
        var other = Calendar(identifier: .buddhist)
        other.timeZone = TimeZone(identifier: "Asia/Bangkok")!
        var reopened = try ForeignCurrencyFormState(existing: first.foreign, accounting: first.accounting,
                                                    calendar: other, locale: locale)
        #expect(try reopened.resolve().foreign.rateDate == first.foreign.rateDate)
        #expect(reopened.rateTimeZoneIdentifier == "America/New_York")
        let next = calendar.date(byAdding: .day, value: 1, to: date)!
        reopened.setRateDate(next)
        #expect(try reopened.resolve().foreign.rateDate == calendar.startOfDay(for: next))
        #expect(try reopened.resolve().foreign.rateTimeZoneIdentifier == "America/New_York")
    }

    @Test func zeroTwoAndThreeDigitAmountsUseTheirOwnCurrencyExponents() throws {
        for (code, text, rate, expected) in [
            ("JPY", "150", "0.01", Int64(150)), ("EUR", "3.50", "2", 700),
            ("KWD", "1.234", "3", 370)
        ] {
            var value = state()
            value.selectCurrency(code)
            value.setOriginalAmount(text)
            value.setRate(rate)
            #expect(try value.resolve().accounting.minorUnits == expected)
        }
        var invalid = state()
        invalid.selectCurrency("JPY")
        invalid.setOriginalAmount("1.2")
        #expect(throws: MoneyInputError.tooManyFractionDigits) { try invalid.resolve() }
    }

    @Test func freeDeniesNewAndConversionButAllowsOrdinaryRecording() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let foreign = try state().resolve().foreign
        await #expect(throws: ForeignCurrencyError.requiresProAccess) {
            try await actor.createExpense(draft(foreign: foreign))
        }
        #expect(try await actor.fetchExpenseSummaries().isEmpty)
        let ordinary = try await actor.createExpense(draft())
        await #expect(throws: ForeignCurrencyError.requiresProAccess) {
            try await actor.updateExpense(id: ordinary.id, with: draft(id: ordinary.id, foreign: foreign))
        }
        #expect(try await actor.fetchExpenseDetail(id: ordinary.id)?.foreignCurrency == nil)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 0)
    }

    @Test func proCreatesAndConvertsButExpiredAccessCannotDuplicateExistingFX() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let foreign = try state().resolve().foreign
        let ordinary = try await actor.createExpense(draft())
        _ = try await actor.updateExpense(id: ordinary.id, with: draft(id: ordinary.id, foreign: foreign), featureAccess: pro)
        _ = try await actor.createExpense(draft(foreign: foreign), featureAccess: pro)
        await #expect(throws: ForeignCurrencyError.requiresProAccess) {
            try await actor.createExpense(draft(foreign: foreign))
        }
        #expect(try await actor.fetchExpenseSummaries().count == 2)
    }

    @Test func expiredStewardshipUsesPersistedCompanionNotCallerClaimAndCannotRevalueCurrency() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let first = try state().resolve()
        let saved = try await actor.createExpense(draft(foreign: first.foreign), featureAccess: pro)
        let existing = try #require(try await actor.fetchExpenseDetail(id: saved.id))
        let editor = ExpenseFormViewModel(existingExpense: existing, now: date)
        editor.prepareInput(locale: locale, calendar: calendar)
        editor.updateForeignCurrency({ $0.setAccountingAmount("1") }, locale: locale)
        editor.setForeignCurrencyEnabled(false, access: ExistingPremiumEntryAccess(),
                                         accountingCurrency: "JPY", locale: locale, calendar: calendar)
        #expect(editor.foreignCurrencyForm != nil)
        #expect(await editor.save(dataActor: actor, currencyCode: "JPY", bucket: .discretionary,
                                 locale: locale, now: date, timeZone: calendar.timeZone,
                                 cycleStartDay: 1, calendar: calendar))
        let detail = try #require(try await actor.fetchExpenseDetail(id: saved.id))
        #expect(detail.summary.amount == Money(minorUnits: 100, currencyCode: "USD"))
        #expect(detail.foreignCurrency?.rate.denominator == 3)
        #expect(detail.foreignCurrency?.rateTimeZoneIdentifier == first.foreign.rateTimeZoneIdentifier)
    }

    @Test func invalidFormDoesNotSaveStaleAmountAndKeepsOriginalUserInput() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let value = model()
        #expect(value.amountText == "6")
        value.updateForeignCurrency({ $0.setRate("broken") }, locale: locale)
        #expect(value.amountText.isEmpty)
        #expect(!(await save(value, actor: actor, access: pro)))
        #expect(value.foreignCurrencyForm?.rateText == "broken")
        #expect(value.foreignCurrencyForm?.originalAmountText == "3")
        #expect(try await actor.fetchExpenseSummaries().isEmpty)
        value.updateForeignCurrency({ $0.setRate("2") }, locale: locale)
        #expect(await save(value, actor: actor, access: pro))
        #expect(try await actor.fetchExpenseSummaries().first?.amount.minorUnits == 600)
    }

    @Test func liveRevocationAfterAdvisoryAwaitDeniesNewFXWithoutDiscardingInput() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let authority = LiveFeatureAccessAuthority()
        authority.replaceEntitlements(.proSubscription)
        let writer = ReminderEventWriter(create: ReminderEventWriter.live.create, updateResponse: { _, _, _, _ in
            authority.replaceEntitlements(.free)
            throw DataValidationError.modelNotFound
        })
        let value = model(writer: writer)
        #expect(!(await value.continueAfterReminder(
            eventID: UUID(), dataActor: actor, featureAccess: authority, currencyCode: "USD",
            bucket: .discretionary, locale: locale, now: date, timeZone: calendar.timeZone,
            cycleStartDay: 1, calendar: calendar
        )))
        #expect(value.error == .foreignCurrency(.requiresProAccess))
        #expect(value.foreignCurrencyForm?.originalAmountText == "3")
        #expect(try await actor.fetchExpenseSummaries().isEmpty)
        authority.replaceEntitlements(.proSubscription)
        #expect(await save(value, actor: actor, access: authority))
    }

    @Test func togglingNewModeOffRestoresOrdinaryAmountAndFreeCannotEnableIt() throws {
        let value = ExpenseFormViewModel(existingExpense: nil, now: date)
        value.prepareInput(locale: locale, calendar: calendar)
        value.updateAmountTextFromUser("12.34")
        value.setForeignCurrencyEnabled(true, access: ExistingPremiumEntryAccess(),
                                        accountingCurrency: "USD", locale: locale, calendar: calendar)
        #expect(value.foreignCurrencyForm == nil)
        #expect(value.amountText == "12.34")
        value.setForeignCurrencyEnabled(true, access: ExistingPremiumEntryAccess(featureAccess: pro),
                                        accountingCurrency: "USD", locale: locale, calendar: calendar)
        value.setForeignCurrencyEnabled(false, access: ExistingPremiumEntryAccess(),
                                        accountingCurrency: "USD", locale: locale, calendar: calendar)
        #expect(value.amountText == "12.34")
    }

    @Test func recurringAndWishlistCannotEnterForeignModeAndForgedRecurringFailsSave() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let value = model()
        value.isRecurring = true
        #expect(!(await save(value, actor: actor, access: pro)))
        #expect(value.error == .foreignCurrency(.unsupportedSource))
        #expect(try await actor.fetchExpenseSummaries().isEmpty)
        let recurring = ExpenseFormViewModel(existingExpense: nil, now: date)
        recurring.isRecurring = true
        recurring.setForeignCurrencyEnabled(true, access: ExistingPremiumEntryAccess(featureAccess: pro),
                                             accountingCurrency: "USD", locale: locale, calendar: calendar)
        #expect(recurring.foreignCurrencyForm == nil)
        let wishlist = ExpenseFormViewModel(existingExpense: nil, wishlistSeed: WishlistExpenseSeed(
            wishItemId: UUID(), name: "Synthetic item", estimatedPrice: nil, category: .food,
            emotionTag: nil, purchaseReason: nil
        ), now: date)
        wishlist.setForeignCurrencyEnabled(true, access: ExistingPremiumEntryAccess(featureAccess: pro),
                                           accountingCurrency: "USD", locale: locale, calendar: calendar)
        #expect(wishlist.foreignCurrencyForm == nil)
        #expect(!wishlist.offersForeignCurrencyMode)
    }

    @Test func localizedAmountPresentationAlwaysKeepsBothCurrencyIdentities() throws {
        let stored = try state().resolve().foreign
        var elsewhere = calendar
        elsewhere.timeZone = TimeZone(identifier: "Pacific/Honolulu")!
        #expect(ForeignCurrencyPresentation.rateDate(stored, calendar: elsewhere, locale: locale) == "3/8/2026")
        for language in ["en_US", "zh_Hans_CN"] {
            let locale = Locale(identifier: language)
            let value = try state().resolve()
            #expect(ForeignCurrencyPresentation.amount(value.foreign.original, locale: locale).contains("EUR"))
            let accounting = ForeignCurrencyPresentation.accountingAmount(value.accounting, locale: locale)
            #expect(accounting.contains("USD"))
            #expect(!accounting.contains("fx.accounting.format"))
            for key in ["fx.mode", "fx.error.pro", "fx.help.locked", "fx.help.stewardship"] {
                #expect(LocalizedCatalog.string(key, locale: locale) != key)
            }
        }
    }
}
