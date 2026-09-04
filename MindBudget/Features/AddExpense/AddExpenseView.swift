import Foundation
import SwiftUI

struct InlineBudgetImpact: Equatable, Sendable {
    let remainingTotalAfter: Money
    let remainingFreeAfter: Money
    let willExceedTotalBudget: Bool
    let willExceedFreeBudget: Bool
}

enum ExpenseFormError: Error, Equatable, Sendable {
    case amount(MoneyInputError)
    case foreignCurrency(ForeignCurrencyError)
    case invalidTimeZone
    case accountingCurrencyMismatch
    case invalidStoredData
    case budgetGenerationLimit
    case persistence
}

enum ExpenseBudgetContext: Equatable, Sendable {
    case loading
    case configured
    case unconfigured
    case historicalPlanRequired
    case transitionPlanRequired
    case firstRegularPlanRequired
    case unavailable
}

struct WishlistExpenseSeed: Sendable {
    let wishItemId: UUID
    let name: String
    let estimatedPrice: Money?
    let category: ExpenseCategory
    let emotionTag: EmotionTag?
    let purchaseReason: PurchaseReason?
}

struct ExpenseReminderPresentation: Identifiable, Sendable {
    let id: UUID
    let message: ReminderMessage
}

enum ExpenseSubmitResult: Sendable {
    case saved
    case reminder(ExpenseReminderPresentation)
    case failed
}

private enum ReceiptEditableField: Hashable, Sendable {
    case amount
    case merchant
    case date
}

struct ReminderEventWriter: Sendable {
    let create: @Sendable (DataActor, ReminderEventDraft) async throws -> ReminderEventSummary
    let updateResponse: @Sendable (
        DataActor,
        UUID,
        ReminderResponse,
        Date
    ) async throws -> ReminderEventSummary

    static let live = ReminderEventWriter(
        create: { dataActor, draft in
            try await dataActor.createReminderEvent(draft)
        },
        updateResponse: { dataActor, id, response, date in
            try await dataActor.updateReminderEventResponse(
                id: id,
                response: response,
                at: date
            )
        }
    )
}

@MainActor
final class ExpenseFormViewModel: ObservableObject {
    @Published private(set) var amountText = ""
    @Published var category: ExpenseCategory
    @Published private(set) var spentAt: Date
    @Published private(set) var merchantName = ""
    @Published var note = ""
    @Published var isPlanned: Bool
    @Published var isRecurring: Bool
    @Published var emotionTag: EmotionTag?
    @Published var purchaseReason: PurchaseReason?
    @Published private(set) var inlineImpact: InlineBudgetImpact?
    @Published private(set) var budgetContext: ExpenseBudgetContext = .loading
    @Published private(set) var showsReasonablenessWarning = false
    @Published private(set) var error: ExpenseFormError?
    @Published private(set) var isSaving = false
    @Published private(set) var merchantSuggestions: [String] = []
    @Published private(set) var inlineInsight: InsightDraft?
    @Published private(set) var importedReceiptDuplicateCount = 0
    @Published private(set) var hasImportedReceipt = false
    @Published private(set) var receiptRecognitionPhase: ReceiptRecognitionPhase = .none
    @Published private(set) var receiptThumbnailData: Data?
    @Published private(set) var foreignCurrencyForm: ForeignCurrencyFormState?
    private var ordinaryAmountBeforeForeignCurrency = ""

    let existingExpense: ExpenseDetail?
    let wishlistSeed: WishlistExpenseSeed?
    private let reminderEventWriter: ReminderEventWriter
    private let receiptProcessor: any ReceiptLocalProcessing
    private var configuredSnapshot: ConfiguredBudgetSnapshot?
    private var budgetSnapshot: BudgetSnapshot?
    private var categoryBudgets: [CategoryBudgetSummary] = []
    private var expenses: [ExpenseSummary] = []
    private var historicalCycles: [CycleAggregate] = []
    private var reminderHistory: [ReminderEventSummary] = []
    private var ruleConfiguration = RuleConfiguration.defaults(currencyCode: "USD")
    private var preferences = PreferencesSnapshot(
        reminderTone: .soft,
        gentleRemindersEnabled: true,
        notificationsEnabled: false,
        quietHours: nil,
        maxDailyInterruptions: 2
    )
    private var pendingDrafts: [InsightDraft] = []
    private var pendingCandidate: PurchaseCandidate?
    private var pendingImpact: BudgetImpact?
    private var recordedInlineDedupeKeys: Set<String> = []
    private var dismissedWarningForMinorUnits: Int64?
    private var didPrepareInput = false
    private var latestContextRequestID = UUID()
    private var receiptRecognitionGeneration = 0
    private var receiptRecognitionTask: Task<Void, Never>?
    /// Monotonic user ownership for one recognition generation. Returning a value to its starting
    /// representation never makes the field eligible for a late recognition overwrite again.
    private var editedFieldsDuringReceiptRecognition: Set<ReceiptEditableField> = []

    init(
        existingExpense: ExpenseDetail?,
        wishlistSeed: WishlistExpenseSeed? = nil,
        now: Date = Date(),
        reminderEventWriter: ReminderEventWriter = .live,
        receiptProcessor: any ReceiptLocalProcessing = ReceiptLocalProcessingService()
    ) {
        self.existingExpense = existingExpense
        self.wishlistSeed = wishlistSeed
        self.reminderEventWriter = reminderEventWriter
        self.receiptProcessor = receiptProcessor
        let summary = existingExpense?.summary
        category = summary?.category ?? wishlistSeed?.category ?? .food
        spentAt = summary?.spentAt ?? now
        merchantName = summary?.merchantName ?? ""
        note = existingExpense?.note ?? ""
        isPlanned = summary?.isPlanned ?? (wishlistSeed != nil)
        isRecurring = summary?.isRecurring ?? false
        emotionTag = summary?.emotionTag ?? wishlistSeed?.emotionTag
        purchaseReason = summary?.purchaseReason ?? wishlistSeed?.purchaseReason
    }

    func prepareInput(locale: Locale, calendar: Calendar = .current) {
        guard !didPrepareInput else { return }
        if let existingExpense {
            amountText = MoneyInputParser().inputText(
                for: existingExpense.summary.amount,
                locale: locale
            )
        } else if let estimatedPrice = wishlistSeed?.estimatedPrice {
            amountText = MoneyInputParser().inputText(for: estimatedPrice, locale: locale)
        }
        if let existingExpense, let foreign = existingExpense.foreignCurrency {
            do {
                foreignCurrencyForm = try ForeignCurrencyFormState(
                    existing: foreign, accounting: existingExpense.summary.amount,
                    calendar: calendar, locale: locale
                )
            } catch {
                self.error = .foreignCurrency(.unreadableMetadata)
            }
        }
        didPrepareInput = true
    }

    var offersForeignCurrencyMode: Bool {
        wishlistSeed == nil && !hasImportedReceipt && !isRecurring
            && (existingExpense == nil || existingExpense?.summary.source == .manual)
            && receiptRecognitionPhase == .none
    }

    func setForeignCurrencyEnabled(
        _ enabled: Bool, access: ExistingPremiumEntryAccess,
        accountingCurrency: String, locale: Locale, calendar: Calendar
    ) {
        if enabled {
            guard foreignCurrencyForm == nil else { return }
            guard offersForeignCurrencyMode else {
                error = .foreignCurrency(.unsupportedSource)
                return
            }
            guard access.permitsNewForeignCurrency else {
                error = .foreignCurrency(.requiresProAccess)
                return
            }
            ordinaryAmountBeforeForeignCurrency = amountText
            foreignCurrencyForm = ForeignCurrencyFormState(
                accountingCurrencyCode: existingExpense?.summary.amount.currencyCode ?? accountingCurrency,
                selectedDate: spentAt, calendar: calendar, locale: locale
            )
            amountText = ""
        } else {
            guard existingExpense?.foreignCurrency == nil else { return }
            foreignCurrencyForm = nil
            amountText = ordinaryAmountBeforeForeignCurrency
        }
        error = nil
    }

    func updateForeignCurrency(_ change: (inout ForeignCurrencyFormState) -> Void, locale: Locale) {
        guard var state = foreignCurrencyForm else { return }
        change(&state)
        foreignCurrencyForm = state
        // Blank authority prevents stale valid amounts feeding reminders or Save.
        amountText = (try? state.resolve()).map {
            MoneyInputParser().inputText(for: $0.accounting, locale: locale)
        } ?? ""
        error = nil
    }

    func enterKeypad(_ key: String, decimalSeparator: String) {
        guard amountText.count < 24 else { return }
        markReceiptFieldEdited(.amount)
        if key == decimalSeparator {
            guard !amountText.contains(decimalSeparator) else { return }
            amountText = amountText.isEmpty ? "0\(decimalSeparator)" : amountText + key
        } else if amountText == "0" {
            amountText = key
        } else {
            amountText += key
        }
    }

    func deleteKeypadCharacter() {
        guard !amountText.isEmpty else { return }
        markReceiptFieldEdited(.amount)
        amountText.removeLast()
    }

    func updateAmountTextFromUser(_ value: String) {
        markReceiptFieldEdited(.amount)
        amountText = value
    }

    func updateMerchantNameFromUser(_ value: String) {
        markReceiptFieldEdited(.merchant)
        merchantName = value
    }

    func updateSpentAtFromUser(_ value: Date) {
        markReceiptFieldEdited(.date)
        spentAt = value
    }

    var blocksSaveForReceiptRecognition: Bool {
        receiptRecognitionPhase == .recognizing
            && !editedFieldsDuringReceiptRecognition.contains(.amount)
    }

    func startReceiptRecognition(
        _ input: ReceiptImageInput,
        dataActor: DataActor,
        lifecycle: any ReceiptImageLifecycleHandling,
        baseline: LocalReceiptRecognitionBaseline,
        currencyCode: String,
        locale: Locale,
        calendar: Calendar
    ) {
        receiptRecognitionGeneration &+= 1
        let acceptedGeneration = receiptRecognitionGeneration
        receiptRecognitionTask?.cancel()
        editedFieldsDuringReceiptRecognition.removeAll()
        receiptThumbnailData = ReceiptImageThumbnail.make(from: input.data)
        receiptRecognitionPhase = .recognizing
        let processor = receiptProcessor

        receiptRecognitionTask = Task { [weak self] in
            var artifact: ReceiptTemporaryImageArtifact?
            do {
                let expenses = try await dataActor.fetchExpenseSummaries()
                try Task.checkCancellation()
                let preparedArtifact = try await lifecycle.prepare(input)
                artifact = preparedArtifact
                let context = ReceiptExtractionContext(
                    expectedCurrencyCode: currencyCode,
                    dateOrder: ReceiptImportContextBuilder.dateOrder(for: locale),
                    calendar: calendar,
                    localeIdentifier: locale.identifier,
                    duplicateReferences: ReceiptImportContextBuilder.duplicateReferences(
                        from: expenses,
                        calendar: calendar
                    )
                )
                let result = try await processor.process(
                    artifact: preparedArtifact,
                    baseline: baseline,
                    context: context
                )
                await lifecycle.discardTemporaryImage(matching: preparedArtifact.id)
                try Task.checkCancellation()
                guard let self,
                      acceptedGeneration == self.receiptRecognitionGeneration else { return }
                self.receiptRecognitionTask = nil
                self.applyRecognizedReceiptRespectingUserEdits(
                    result,
                    locale: locale,
                    calendar: calendar
                )
                self.receiptRecognitionPhase = .review(result)
            } catch is CancellationError {
                if let artifact {
                    await lifecycle.discardTemporaryImage(matching: artifact.id)
                }
            } catch {
                if let artifact {
                    await lifecycle.discardTemporaryImage(matching: artifact.id)
                }
                guard let self,
                      acceptedGeneration == self.receiptRecognitionGeneration else { return }
                self.receiptRecognitionTask = nil
                self.receiptRecognitionPhase = .failed(
                    ReceiptImportDiagnostics.failure(for: error)
                )
            }
        }
    }

    func confirmReceiptReview() {
        guard case .review = receiptRecognitionPhase else { return }
        receiptRecognitionPhase = .none
        receiptThumbnailData = nil
        editedFieldsDuringReceiptRecognition.removeAll()
    }

    func dismissReceiptFailure() {
        guard case .failed = receiptRecognitionPhase else { return }
        receiptRecognitionPhase = .none
        receiptThumbnailData = nil
        editedFieldsDuringReceiptRecognition.removeAll()
    }

    func prepareForReceiptRescan() {
        cancelReceiptRecognition()
    }

    func cancelReceiptRecognition() {
        receiptRecognitionGeneration &+= 1
        receiptRecognitionTask?.cancel()
        receiptRecognitionTask = nil
        receiptRecognitionPhase = .none
        receiptThumbnailData = nil
        editedFieldsDuringReceiptRecognition.removeAll()
    }

    /// This is the production application boundary. It copies only validated fields that the user
    /// has not edited since recognition began and performs no write; the existing explicit Save action remains the sole persistence boundary.
    private func applyRecognizedReceiptRespectingUserEdits(
        _ result: ReceiptStructuredExtractionResult,
        locale: Locale,
        calendar: Calendar
    ) {
        var acceptedAnyField = false
        if !editedFieldsDuringReceiptRecognition.contains(.merchant),
           let merchant = result.fields.merchantName.acceptedValue {
            merchantName = merchant
            acceptedAnyField = true
        }
        if !editedFieldsDuringReceiptRecognition.contains(.amount),
           let amount = result.fields.total.acceptedValue {
            amountText = MoneyInputParser().inputText(for: amount, locale: locale)
            acceptedAnyField = true
        }
        if !editedFieldsDuringReceiptRecognition.contains(.date),
           let receiptDate = result.fields.purchaseDate.acceptedValue {
            var components = DateComponents()
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            components.year = receiptDate.year
            components.month = receiptDate.month
            components.day = receiptDate.day
            components.hour = 12
            if let date = calendar.date(from: components) {
                spentAt = date
                acceptedAnyField = true
            }
        }
        if acceptedAnyField {
            hasImportedReceipt = true
            if case let .exactMatches(ids) = result.duplicateResolution {
                importedReceiptDuplicateCount = ids.count
            } else {
                importedReceiptDuplicateCount = 0
            }
            error = nil
        }
    }

    private func markReceiptFieldEdited(_ field: ReceiptEditableField) {
        guard receiptRecognitionPhase == .recognizing else { return }
        editedFieldsDuringReceiptRecognition.insert(field)
    }

    func loadContext(
        dataActor: DataActor,
        currencyCode: String,
        cycleStartDay: Int,
        calendar: Calendar,
        referenceDate: Date,
        locale: Locale,
        ruleConfiguration: RuleConfiguration? = nil,
        preferences: PreferencesSnapshot = PreferencesSnapshot(
            reminderTone: .soft,
            gentleRemindersEnabled: true,
            notificationsEnabled: false,
            quietHours: nil,
            maxDailyInterruptions: 2
        )
    ) async {
        let requestID = UUID()
        latestContextRequestID = requestID
        do {
            async let fetchedExpenses = dataActor.fetchExpenseSummaries()
            async let fetchedMerchants = dataActor.fetchMerchantSummaries()
            async let fetchedPlans = dataActor.fetchBudgetPlanSummaries()
            async let fetchedReminderHistory = dataActor.fetchReminderEventSummaries()
            let coverage = try await dataActor.previewPlanCoverage(
                date: referenceDate,
                futureCycleStartDay: cycleStartDay,
                calendar: calendar
            )
            let expenses = try await fetchedExpenses
            let merchants = try await fetchedMerchants
            let plans = try await fetchedPlans
            let reminderHistory = try await fetchedReminderHistory
            guard requestID == latestContextRequestID else { return }
            self.expenses = expenses.filter { $0.id != existingExpense?.summary.id }
            self.reminderHistory = reminderHistory
            self.ruleConfiguration = ruleConfiguration
                ?? RuleConfiguration.defaults(currencyCode: currencyCode)
            self.preferences = preferences
            merchantSuggestions = merchants
                .sorted { lhs, rhs in
                    if lhs.visitCount == rhs.visitCount {
                        return (lhs.lastVisitedAt ?? .distantPast) > (rhs.lastVisitedAt ?? .distantPast)
                    }
                    return lhs.visitCount > rhs.visitCount
                }
                .prefix(8)
                .map(\.displayName)

            guard case let .covered(plan) = coverage else {
                configuredSnapshot = nil
                categoryBudgets = []
                let interval = try BudgetCycleCalculator().interval(
                    containing: referenceDate,
                    startDay: cycleStartDay,
                    calendar: calendar
                )
                budgetSnapshot = .unconfigured(
                    cycle: interval,
                    currencyCode: currencyCode
                )
                historicalCycles = try CycleAggregateBuilder().build(
                    plans: plans,
                    expenses: self.expenses,
                    before: interval.start
                )
                budgetContext = context(for: coverage)
                recalculate(
                    currencyCode: currencyCode,
                    locale: locale,
                    bucket: nil,
                    calendar: calendar
                )
                return
            }
            let expensesWithoutEditedRecord = expenses.filter {
                $0.id != existingExpense?.summary.id
            }
            let snapshot = try BudgetEngine().snapshot(
                cycle: DateInterval(start: plan.cycleStart, end: plan.cycleEnd),
                currencyCode: plan.currencyCode,
                expenses: expensesWithoutEditedRecord,
                plan: plan,
                now: referenceDate,
                calendar: calendar
            )
            guard case let .configured(configured) = snapshot else {
                configuredSnapshot = nil
                budgetSnapshot = snapshot
                categoryBudgets = []
                budgetContext = .unavailable
                recalculate(
                    currencyCode: currencyCode,
                    locale: locale,
                    bucket: nil,
                    calendar: calendar
                )
                return
            }
            configuredSnapshot = configured
            budgetSnapshot = snapshot
            categoryBudgets = plan.categoryBudgets
            historicalCycles = try CycleAggregateBuilder().build(
                plans: plans,
                expenses: self.expenses,
                before: configured.cycle.start
            )
            budgetContext = .configured
            recalculate(
                currencyCode: currencyCode,
                locale: locale,
                bucket: nil,
                calendar: calendar
            )
        } catch {
            guard requestID == latestContextRequestID else { return }
            configuredSnapshot = nil
            budgetSnapshot = nil
            categoryBudgets = []
            budgetContext = .unavailable
            recalculate(
                currencyCode: currencyCode,
                locale: locale,
                bucket: nil,
                calendar: calendar
            )
        }
    }

    func recalculate(
        currencyCode: String,
        locale: Locale,
        bucket: BudgetBucket? = nil,
        calendar: Calendar
    ) {
        pendingImpact = nil
        guard let amount = try? MoneyInputParser().money(
            from: amountText,
            currencyCode: currencyCode,
            locale: locale
        ) else {
            inlineImpact = nil
            showsReasonablenessWarning = false
            clearRulePreview()
            return
        }
        let selectedBucket = bucket ?? category.defaultBucket
        if let snapshot = configuredSnapshot {
            if let impact = try? BudgetEngine().impact(
                of: amount,
                category: category,
                bucket: selectedBucket,
                snapshot: snapshot,
                categoryBudgets: categoryBudgets
            ) {
                inlineImpact = InlineBudgetImpact(
                    remainingTotalAfter: impact.remainingTotalAfter,
                    remainingFreeAfter: impact.remainingFreeAfter,
                    willExceedTotalBudget: impact.willExceedTotalBudget,
                    willExceedFreeBudget: impact.willExceedFreeBudget
                )
                pendingImpact = impact
            }
            showsReasonablenessWarning = snapshot.expectedExpenses.minorUnits > 0
                && amount.minorUnits > snapshot.expectedExpenses.minorUnits
                && dismissedWarningForMinorUnits != amount.minorUnits
        } else {
            inlineImpact = nil
            showsReasonablenessWarning = false
            pendingImpact = nil
        }
        evaluateRulePreview(
            amount: amount,
            bucket: selectedBucket,
            calendar: calendar
        )
    }

    func submit(
        dataActor: DataActor,
        currencyCode: String,
        bucket: BudgetBucket,
        aiEnhancementEnabled: Bool = false,
        premiumEntryAccess: ExistingPremiumEntryAccess = ExistingPremiumEntryAccess(),
        featureAccess: any FeatureAccessChecking = FeatureAccessService(),
        locale: Locale,
        now: Date,
        timeZone: TimeZone,
        cycleStartDay: Int,
        calendar: Calendar
    ) async -> ExpenseSubmitResult {
        guard !isSaving else { return .failed }
        if let state = foreignCurrencyForm, (try? state.resolve()) == nil {
            error = .foreignCurrency(.invalidRateText)
            return .failed
        }
        guard existingExpense == nil, wishlistSeed == nil,
              let snapshot = budgetSnapshot, let candidate = pendingCandidate else {
            return await save(
                dataActor: dataActor,
                featureAccess: featureAccess,
                currencyCode: currencyCode,
                bucket: bucket,
                locale: locale,
                now: now,
                timeZone: timeZone,
                cycleStartDay: cycleStartDay,
                calendar: calendar
            ) ? .saved : .failed
        }

        isSaving = true
        defer { isSaving = false }
        let sheetDrafts = pendingDrafts.filter { draft in
            let decision = ReminderThrottle().decide(
                for: ReminderRequest(
                    kind: .behavioralInsight,
                    draft: draft,
                    requestedChannel: nil,
                    requestedDeliveryDate: nil
                ),
                history: reminderHistory,
                preferences: preferences,
                now: now,
                calendar: calendar
            )
            return decision.shouldShowNow && decision.channel == .sheet
        }

        if !sheetDrafts.isEmpty {
            let reminderEngine = ReminderEngine(
                aiEnhancementEnabled: aiEnhancementEnabled,
                premiumEntryAccess: premiumEntryAccess
            )
            let context = reminderEngine.buildContext(
                candidate: candidate,
                impact: pendingImpact,
                snapshot: snapshot,
                drafts: sheetDrafts,
                tone: preferences.reminderTone
            )
            if let message = await reminderEngine.generateReminder(
                context: context,
                channel: .sheet,
                locale: locale
            ), let primary = sheetDrafts.first {
                let eventID = UUID()
                // Advisory history is best effort. If it cannot be recorded, skip the
                // sheet and continue to the authoritative expense save below.
                if let event = try? await reminderEventWriter.create(
                    dataActor,
                    ReminderEventDraft(
                        id: eventID,
                        insightType: primary.type,
                        scopeKey: primary.throttleMetadata.scopeKey,
                        channel: .sheet,
                        shownAt: now,
                        categoryRiskBasisPoints: primary.throttleMetadata
                            .categoryRiskBasisPoints,
                        isInterrupting: true,
                        response: nil,
                        respondedAt: nil
                    )
                ) {
                    reminderHistory.insert(event, at: 0)
                    return .reminder(
                        ExpenseReminderPresentation(id: eventID, message: message)
                    )
                }
            }
        }

        let saved = await save(
            dataActor: dataActor,
            featureAccess: featureAccess,
            currencyCode: currencyCode,
            bucket: isRecurring ? .fixed : bucket,
            locale: locale,
            now: now,
            timeZone: timeZone,
            cycleStartDay: cycleStartDay,
            calendar: calendar
        )
        guard saved else { return .failed }
        await persistPreparedAnalysis(dataActor: dataActor, at: now)
        return .saved
    }

    func continueAfterReminder(
        eventID: UUID,
        dataActor: DataActor,
        featureAccess: any FeatureAccessChecking = FeatureAccessService(),
        currencyCode: String,
        bucket: BudgetBucket,
        locale: Locale,
        now: Date,
        timeZone: TimeZone,
        cycleStartDay: Int,
        calendar: Calendar
    ) async -> Bool {
        // A response-log failure must not veto the user's financial record.
        _ = try? await reminderEventWriter.updateResponse(
            dataActor,
            eventID,
            .acted,
            now
        )
        let saved = await save(
            dataActor: dataActor,
            featureAccess: featureAccess,
            currencyCode: currencyCode,
            bucket: isRecurring ? .fixed : bucket,
            locale: locale,
            now: now,
            timeZone: timeZone,
            cycleStartDay: cycleStartDay,
            calendar: calendar
        )
        if saved {
            await persistPreparedAnalysis(dataActor: dataActor, at: now)
        }
        return saved
    }

    func recordReminderResponse(
        eventID: UUID,
        response: ReminderResponse,
        dataActor: DataActor,
        at date: Date
    ) async {
        _ = try? await reminderEventWriter.updateResponse(
            dataActor,
            eventID,
            response,
            date
        )
    }

    func recordInlinePresentationIfNeeded(
        dataActor: DataActor,
        at date: Date
    ) async {
        guard let inlineInsight,
              recordedInlineDedupeKeys.insert(inlineInsight.dedupeKey).inserted else {
            return
        }
        let event = ReminderEventDraft(
            id: UUID(),
            insightType: inlineInsight.type,
            scopeKey: inlineInsight.throttleMetadata.scopeKey,
            channel: .inline,
            shownAt: date,
            categoryRiskBasisPoints: inlineInsight.throttleMetadata.categoryRiskBasisPoints,
            isInterrupting: false,
            response: nil,
            respondedAt: nil
        )
        if let summary = try? await reminderEventWriter.create(dataActor, event) {
            reminderHistory.insert(summary, at: 0)
        }
    }

    func dismissReasonablenessWarning(currencyCode: String, locale: Locale) {
        guard let amount = try? MoneyInputParser().money(
            from: amountText,
            currencyCode: currencyCode,
            locale: locale
        ) else { return }
        dismissedWarningForMinorUnits = amount.minorUnits
        showsReasonablenessWarning = false
    }

    func save(
        dataActor: DataActor,
        featureAccess: any FeatureAccessChecking = FeatureAccessService(),
        currencyCode: String,
        bucket: BudgetBucket,
        locale: Locale,
        now: Date,
        timeZone: TimeZone,
        cycleStartDay: Int,
        calendar: Calendar
    ) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        let amount: Money
        let foreign: ExpenseForeignCurrency?
        do {
            if let foreignCurrencyForm {
                let resolved = try foreignCurrencyForm.resolve()
                amount = resolved.accounting
                foreign = resolved.foreign
                guard !isRecurring, !hasImportedReceipt, wishlistSeed == nil else {
                    throw ForeignCurrencyError.unsupportedSource
                }
            } else {
                amount = try MoneyInputParser().money(
                    from: amountText,
                    currencyCode: existingExpense?.summary.amount.currencyCode ?? currencyCode,
                    locale: locale
                )
                foreign = nil
            }
        } catch let foreignError as ForeignCurrencyError {
            error = .foreignCurrency(foreignError)
            return false
        } catch let inputError as MoneyInputError {
            error = .amount(inputError)
            return false
        } catch {
            self.error = .amount(.invalid)
            return false
        }
        guard TimeZone(identifier: timeZone.identifier) != nil else {
            error = .invalidTimeZone
            return false
        }

        let existingSummary = existingExpense?.summary
        let draft = ExpenseDraft(
            id: existingSummary?.id ?? UUID(),
            amount: amount,
            category: category,
            bucket: isRecurring ? .fixed : bucket,
            merchantName: optionalTrimmed(merchantName),
            note: optionalTrimmed(note),
            spentAt: spentAt,
            spentTimeZoneIdentifier: timeZone.identifier,
            createdAt: existingSummary?.createdAt ?? now,
            updatedAt: now,
            paymentMethod: existingSummary?.paymentMethod,
            emotionTag: emotionTag,
            purchaseReason: purchaseReason,
            isPlanned: wishlistSeed == nil ? isPlanned : true,
            isRecurring: isRecurring,
            source: existingSummary?.source
                ?? (wishlistSeed != nil ? .wishlistConversion : (hasImportedReceipt ? .receiptImport : .manual)),
            allowMerchantIndexing: existingSummary?.allowMerchantIndexing ?? false,
            recurrenceCalendarIdentifier: calendar.identifier,
            foreignCurrency: foreign
        )
        do {
            let coverage = try await dataActor.ensurePlanCovering(
                date: spentAt,
                futureCycleStartDay: cycleStartDay,
                calendar: calendar,
                timestamp: now
            )
            // Recording remains available without inventing a budget. Pending transition
            // states are surfaced explicitly, while Dashboard owns budget confirmation.
            budgetContext = context(for: coverage)
            if let wishlistSeed {
                _ = try await dataActor.convertWishItemToExpense(
                    wishItemId: wishlistSeed.wishItemId,
                    expense: draft,
                    at: now
                )
            } else if let existingSummary {
                _ = try await dataActor.updateExpense(id: existingSummary.id, with: draft, featureAccess: featureAccess)
            } else {
                _ = try await dataActor.createExpense(draft, featureAccess: featureAccess)
            }
            error = nil
            return true
        } catch {
            self.error = formError(from: error)
            return false
        }
    }

    private func evaluateRulePreview(
        amount: Money,
        bucket: BudgetBucket,
        calendar: Calendar
    ) {
        guard existingExpense == nil, wishlistSeed == nil, let budgetSnapshot else {
            clearRulePreview()
            return
        }
        let candidate = PurchaseCandidate(
            name: optionalTrimmed(merchantName),
            amount: amount,
            category: category,
            bucket: bucket,
            reason: purchaseReason,
            emotionTag: emotionTag
        )
        pendingCandidate = candidate
        pendingDrafts = SpendingPatternDetector().evaluatePotentialPurchase(
            candidate: candidate,
            expenses: expenses,
            snapshot: budgetSnapshot,
            categoryBudgets: categoryBudgets,
            historicalCycles: historicalCycles,
            config: ruleConfiguration,
            now: spentAt,
            calendar: calendar
        )
        if let inlineInsight,
           pendingDrafts.contains(where: { $0.dedupeKey == inlineInsight.dedupeKey }) {
            return
        }
        inlineInsight = pendingDrafts.first { draft in
            let decision = ReminderThrottle().decide(
                for: ReminderRequest(
                    kind: .behavioralInsight,
                    draft: draft,
                    requestedChannel: nil,
                    requestedDeliveryDate: nil
                ),
                history: reminderHistory,
                preferences: preferences,
                now: spentAt,
                calendar: calendar
            )
            return decision.shouldShowNow && decision.channel == .inline
        }
    }

    private func clearRulePreview() {
        pendingCandidate = nil
        pendingDrafts = []
        pendingImpact = nil
        inlineInsight = nil
    }

    private func persistPreparedAnalysis(dataActor: DataActor, at date: Date) async {
        _ = try? await dataActor.upsertSpendingInsights(pendingDrafts, createdAt: date)
    }

    private func optionalTrimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func context(for coverage: BudgetPlanCoverage) -> ExpenseBudgetContext {
        switch coverage {
        case .unconfigured: .unconfigured
        case .covered: .configured
        case .transitionPlanRequired: .transitionPlanRequired
        case .firstRegularPlanRequired: .firstRegularPlanRequired
        case .historicalPlanRequired: .historicalPlanRequired
        }
    }

    private func formError(from error: Error) -> ExpenseFormError {
        if let foreignError = error as? ForeignCurrencyError {
            return .foreignCurrency(foreignError)
        }
        if let validationError = error as? DataValidationError {
            switch validationError {
            case .accountingCurrencyMismatch:
                return .accountingCurrencyMismatch
            case .invalidAmount:
                return .amount(.invalid)
            case .invalidTimeZone:
                return .invalidTimeZone
            default:
                return .persistence
            }
        }
        if error is PersistedModelError {
            return .invalidStoredData
        }
        if let cycleError = error as? BudgetCycleError,
           case .generationLimitExceeded = cycleError {
            return .budgetGenerationLimit
        }
        return .persistence
    }
}

struct AddExpenseView: View {
    @Environment(\.mindBudgetTheme) private var theme
    let dataActor: DataActor
    let accountingCurrencyCode: String
    let existingExpense: ExpenseDetail?
    let wishlistSeed: WishlistExpenseSeed?
    let completed: () -> Void

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.existingPremiumEntryAccess) private var premiumEntryAccess
    @Environment(\.featureAccessAuthority) private var featureAccessAuthority
    @Environment(\.receiptImageLifecycle) private var receiptImageLifecycle
    @Environment(\.telemetryEventRecorder) private var telemetryEventRecorder
    @StateObject private var viewModel: ExpenseFormViewModel
    @State private var showsContextFields = false
    @State private var showsDatePicker = false
    @State private var presentsWishlistConversion = false
    @State private var presentsReceiptImport = false
    @State private var activeReminder: ExpenseReminderPresentation?
    @State private var opensWishlistAfterReminder = false

    init(
        dataActor: DataActor,
        accountingCurrencyCode: String,
        existingExpense: ExpenseDetail?,
        wishlistSeed: WishlistExpenseSeed? = nil,
        completed: @escaping () -> Void
    ) {
        self.dataActor = dataActor
        // Editing uses the persisted row's authority, even if Settings changed after creation.
        self.accountingCurrencyCode = existingExpense?.summary.amount.currencyCode ?? accountingCurrencyCode
        self.existingExpense = existingExpense
        self.wishlistSeed = wishlistSeed
        self.completed = completed
        _viewModel = StateObject(
            wrappedValue: ExpenseFormViewModel(
                existingExpense: existingExpense,
                wishlistSeed: wishlistSeed
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let wishlistSeed {
                    Label(wishlistSeed.name, systemImage: "bookmark.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.accentDeep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
                }

                receiptRecognitionSurface

                if viewModel.offersForeignCurrencyMode || viewModel.foreignCurrencyForm != nil {
                    ForeignCurrencyEntrySection(model: viewModel, accountingCurrency: accountingCurrencyCode)
                }
                if viewModel.foreignCurrencyForm == nil {
                    amountEntry
                } else {
                    impactView
                }

                if receiptRecognitionBaseline != .unavailable,
                   viewModel.receiptRecognitionPhase == .none {
                    receiptEntryCard
                }

                if viewModel.hasImportedReceipt,
                   viewModel.receiptRecognitionPhase == .none {
                    importedReceiptNotice
                }

                if viewModel.foreignCurrencyForm == nil { keypad }

                if viewModel.showsReasonablenessWarning {
                    reasonablenessWarning
                }
                if let insight = viewModel.inlineInsight {
                    inlineInsight(insight)
                }

                categoryEntry
                dateEntry
                optionalFields
                contextFields

                if existingExpense == nil, wishlistSeed == nil, viewModel.foreignCurrencyForm == nil {
                    Button("expense.addToWishlist") {
                        presentsWishlistConversion = true
                    }
                    .buttonStyle(MindBudgetSecondaryButtonStyle())
                    .accessibilityIdentifier("expense.addToWishlist")
                    Text("expense.addToWishlist.help")
                        .font(.caption)
                        .foregroundStyle(theme.inkSecondary)
                }

                if let error = viewModel.error {
                    Label(errorKey(error), systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(theme.attentionText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier("expense.error")
                }

            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .accessibilityIdentifier("expense.form")
        .mindBudgetScreenBackground()
        .overlay(alignment: .top) {
            if viewModel.receiptRecognitionPhase == .recognizing {
                ReceiptRecognitionProgressBar()
                    .accessibilityHidden(true)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("common.save") {
                submit()
            }
            .buttonStyle(MindBudgetPrimaryButtonStyle())
            .disabled(viewModel.isSaving || viewModel.blocksSaveForReceiptRecognition)
            .opacity(viewModel.blocksSaveForReceiptRecognition ? 0.38 : 1)
            .accessibilityIdentifier("expense.save")
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(theme.surface)
            .overlay(alignment: .top) {
                Rectangle().fill(theme.hairline).frame(height: 1)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(existingExpense == nil ? "expense.add.title" : "expense.edit.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") {
                    viewModel.cancelReceiptRecognition()
                    dismiss()
                }
            }
        }
        .task {
            viewModel.prepareInput(locale: locale, calendar: calendar)
        }
        .task(id: viewModel.spentAt) {
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await loadContext(referenceDate: viewModel.spentAt)
        }
        .onChange(of: viewModel.amountText) { _, _ in recalculate() }
        .onChange(of: viewModel.category) { _, _ in recalculate() }
        .onChange(of: viewModel.emotionTag) { _, _ in recalculate() }
        .onChange(of: viewModel.purchaseReason) { _, _ in recalculate() }
        .onChange(of: viewModel.isRecurring) { _, _ in recalculate() }
        .onChange(of: viewModel.receiptRecognitionPhase) { _, phase in
            switch phase {
            case .review:
                settings.hasCompletedReceiptImport = true
                telemetryEventRecorder.capture(.receipt(.reviewed, .completed))
            case .failed:
                telemetryEventRecorder.capture(.receipt(.reviewed, .failed))
            case .none, .recognizing:
                break
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background,
                  viewModel.receiptRecognitionPhase == .recognizing else { return }
            viewModel.cancelReceiptRecognition()
        }
        .task(id: viewModel.inlineInsight?.dedupeKey) {
            guard viewModel.inlineInsight != nil else { return }
            await viewModel.recordInlinePresentationIfNeeded(
                dataActor: dataActor,
                at: Date()
            )
        }
        .fullScreenCover(item: $activeReminder, onDismiss: {
            if opensWishlistAfterReminder {
                opensWishlistAfterReminder = false
                presentsWishlistConversion = true
            }
        }) { presentation in
            ExpenseReminderSheet(
                presentation: presentation,
                permitsWishlist: viewModel.foreignCurrencyForm == nil,
                continuePurchase: {
                    Task {
                        let saved = await viewModel.continueAfterReminder(
                            eventID: presentation.id,
                            dataActor: dataActor,
                            featureAccess: featureAccessAuthority,
                            currencyCode: accountingCurrencyCode,
                            bucket: viewModel.isRecurring
                                ? .fixed
                                : settings.bucket(for: viewModel.category),
                            locale: locale,
                            now: Date(),
                            timeZone: .current,
                            cycleStartDay: settings.budgetCycleStartDay,
                            calendar: calendar
                        )
                        if saved {
                            activeReminder = nil
                            completeSuccessfulExpense()
                        }
                    }
                },
                addToWishlist: {
                    Task {
                        await viewModel.recordReminderResponse(
                            eventID: presentation.id,
                            response: .acted,
                            dataActor: dataActor,
                            at: Date()
                        )
                        opensWishlistAfterReminder = true
                        activeReminder = nil
                    }
                },
                close: {
                    Task {
                        await viewModel.recordReminderResponse(
                            eventID: presentation.id,
                            response: .dismissed,
                            dataActor: dataActor,
                            at: Date()
                        )
                        activeReminder = nil
                    }
                }
            )
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showsDatePicker) {
            NavigationStack {
                DatePicker(
                    "expense.date",
                    selection: spentAtUserBinding,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("expense.date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("common.done") { showsDatePicker = false }
                    }
                }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $presentsWishlistConversion) {
            NavigationStack {
                AddWishItemView(
                    dataActor: dataActor,
                    accountingCurrencyCode: accountingCurrencyCode,
                    existingItem: nil,
                    seed: WishItemFormSeed(
                        name: viewModel.merchantName,
                        estimatedPriceText: viewModel.amountText,
                        category: viewModel.category,
                        reason: viewModel.purchaseReason,
                        emotionTag: viewModel.emotionTag
                    )
                ) {
                    presentsWishlistConversion = false
                    completed()
                }
            }
        }
        .fullScreenCover(isPresented: $presentsReceiptImport) {
            ReceiptImportView(
                baseline: receiptRecognitionBaseline,
                showsIntroduction: !settings.hasCompletedReceiptImport
            ) { input in
                presentsReceiptImport = false
                telemetryEventRecorder.capture(.receipt(.acquired, .completed))
                viewModel.startReceiptRecognition(
                    input,
                    dataActor: dataActor,
                    lifecycle: receiptImageLifecycle,
                    baseline: receiptRecognitionBaseline,
                    currencyCode: accountingCurrencyCode,
                    locale: locale,
                    calendar: calendar
                )
            }
        }
        .onDisappear {
            viewModel.cancelReceiptRecognition()
        }
        .overlay {
            if scenePhase == .inactive,
               viewModel.receiptRecognitionPhase != .none {
                ReceiptInactivePrivacyShield()
            }
        }
    }

    private var merchantNameUserBinding: Binding<String> {
        Binding(
            get: { viewModel.merchantName },
            set: { viewModel.updateMerchantNameFromUser($0) }
        )
    }

    private var spentAtUserBinding: Binding<Date> {
        Binding(
            get: { viewModel.spentAt },
            set: { viewModel.updateSpentAtFromUser($0) }
        )
    }

    private var receiptRecognitionBaseline: LocalReceiptRecognitionBaseline {
        guard existingExpense == nil, wishlistSeed == nil, viewModel.foreignCurrencyForm == nil else { return .unavailable }
        return premiumEntryAccess.receiptRecognitionBaseline(
            productScopeEnabled: FeatureFlags.enableReceiptImport,
            localModelAvailable: settings.enableAIEnhancement
                && ReceiptLocalModelAvailability.isAvailable
        )
    }

    private var importedReceiptNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("receipt.imported.title", systemImage: "checkmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.accentDeep)
            Text("receipt.imported.detail")
                .font(.footnote)
                .foregroundStyle(theme.inkSecondary)
            if viewModel.importedReceiptDuplicateCount > 0 {
                Text(
                    String.localizedStringWithFormat(
                        LocalizedCatalog.string("receipt.duplicate.warning", locale: locale),
                        viewModel.importedReceiptDuplicateCount
                    )
                )
                .font(.footnote)
                .foregroundStyle(theme.attentionText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("expense.receiptImported")
    }

    @ViewBuilder
    private var receiptRecognitionSurface: some View {
        switch viewModel.receiptRecognitionPhase {
        case .none:
            EmptyView()
        case .recognizing:
            HStack(spacing: 12) {
                ProgressView()
                    .tint(theme.accentDeep)
                    .controlSize(.small)
                Text("receipt.processing")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.ink)
                Spacer(minLength: 8)
                ReceiptThumbnailView(
                    data: viewModel.receiptThumbnailData,
                    width: 34,
                    height: 44
                )
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 64)
            .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("receipt.processing.inline")
        case let .review(result):
            ReceiptReviewCard(
                result: result,
                thumbnailData: viewModel.receiptThumbnailData,
                confirm: { viewModel.confirmReceiptReview() },
                rescan: {
                    viewModel.prepareForReceiptRescan()
                    presentsReceiptImport = true
                }
            )
        case let .failed(failure):
            receiptFailureCard(failure)
        }
    }

    private var receiptEntryCard: some View {
        Button {
            telemetryEventRecorder.capture(.receipt(.opened, .completed))
            presentsReceiptImport = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(theme.accentDeep)
                    .frame(width: 44, height: 44)
                    .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("receipt.entry.title")
                        .font(.headline)
                        .foregroundStyle(theme.ink)
                    Text("receipt.entry.detail")
                        .font(.caption)
                        .foregroundStyle(theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.inkQuaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(theme.surface.opacity(0.98), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(theme.hairlineStrong, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("expense.receiptImport")
    }

    private func receiptFailureCard(_ failure: ReceiptImportFailure) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(failure.titleKey))
                .font(.headline)
                .foregroundStyle(theme.attentionText)
            Text(LocalizedStringKey(failure.detailKey))
                .font(.subheadline)
                .foregroundStyle(theme.inkSecondary)

            HStack(spacing: 10) {
                if failure.allowsCaptureRetry {
                    Button("receipt.failure.retake") {
                        viewModel.prepareForReceiptRescan()
                        presentsReceiptImport = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.hairlineStrong, lineWidth: 1)
                    }
                }

                Button("receipt.failure.manual") {
                    viewModel.dismissReceiptFailure()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.attentionText)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.attentionBorder, lineWidth: 1)
        }
        .accessibilityIdentifier("receipt.failure.inline")
    }

    private var amountEntry: some View {
        VStack(spacing: 12) {
            Text("expense.amount")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.inkSecondary)
                .textCase(.uppercase)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(accountingCurrencyCode)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.inkSecondary)
                if viewModel.receiptRecognitionPhase == .recognizing,
                   viewModel.amountText.isEmpty {
                    ReceiptRecognitionSkeleton(width: 132, height: 18)
                        .accessibilityLabel("receipt.processing")
                } else {
                    Text(viewModel.amountText.isEmpty ? "0" : viewModel.amountText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("expense.amount")
            .accessibilityValue(viewModel.amountText.isEmpty ? "0" : viewModel.amountText)
            .accessibilityIdentifier("expense.amount")
            impactView
        }
        .padding(.top, 8)
    }

    private var keypad: some View {
        let decimalSeparator = locale.decimalSeparator ?? "."
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", decimalSeparator, "0"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(keys, id: \.self) { key in
                Button {
                    viewModel.enterKeypad(key, decimalSeparator: decimalSeparator)
                } label: {
                    Text(key)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundStyle(theme.ink)
                        .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("expense.keypad.\(key)")
            }
            Button {
                viewModel.deleteKeypadCharacter()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(theme.ink)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("common.delete")
            .accessibilityIdentifier("expense.keypad.delete")
        }
    }

    private var categoryEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("expense.category")
                .font(.headline)
                .foregroundStyle(theme.ink)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Button {
                                viewModel.category = category
                            } label: {
                                Label(
                                    LocalizedStringKey(category.localizedNameKey),
                                    systemImage: category.symbolName
                                )
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 13)
                                .frame(minHeight: 42)
                                .foregroundStyle(
                                    viewModel.category == category
                                        ? Color.white
                                        : theme.inkSecondary
                                )
                                .background(
                                    viewModel.category == category ? theme.accent : theme.surface,
                                    in: Capsule()
                                )
                                .overlay {
                                    if viewModel.category != category {
                                        Capsule().stroke(theme.hairlineStrong, lineWidth: 1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(
                                viewModel.category == category ? .isSelected : []
                            )
                            .accessibilityIdentifier("expense.category.\(category.rawValue)")
                            .id(category)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: viewModel.category) { _, category in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(category, anchor: .center)
                    }
                }
                .task {
                    proxy.scrollTo(viewModel.category, anchor: .center)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("expense.category")
            .accessibilityIdentifier("expense.category.scroll")
        }
    }

    private var dateEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("expense.date")
                .font(.headline)
                .foregroundStyle(theme.ink)
            HStack(spacing: 8) {
                dateButton("expense.date.today", selected: calendar.isDateInToday(viewModel.spentAt)) {
                    viewModel.updateSpentAtFromUser(Date())
                }
                dateButton("expense.date.yesterday", selected: calendar.isDateInYesterday(viewModel.spentAt)) {
                    if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                        viewModel.updateSpentAtFromUser(yesterday)
                    }
                }
                Button {
                    showsDatePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(theme.surface, in: Capsule())
                        .overlay { Capsule().stroke(theme.hairlineStrong, lineWidth: 1) }
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.inkSecondary)
                .accessibilityLabel("expense.date")
            }
            Text(viewModel.spentAt, format: .dateTime.year().month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(theme.inkSecondary)
        }
    }

    private func dateButton(
        _ key: LocalizedStringKey,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(key)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 42)
                .foregroundStyle(selected ? Color.white : theme.inkSecondary)
                .background(selected ? theme.accent : theme.surface, in: Capsule())
                .overlay {
                    if !selected { Capsule().stroke(theme.hairlineStrong, lineWidth: 1) }
                }
        }
        .buttonStyle(.plain)
    }

    private var optionalFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("expense.optional")
                .font(.headline)
                .foregroundStyle(theme.ink)
            TextField("expense.merchant", text: merchantNameUserBinding)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("expense.merchant")
            if !viewModel.merchantSuggestions.isEmpty {
                Menu("expense.merchant.suggestions") {
                    ForEach(viewModel.merchantSuggestions, id: \.self) { merchant in
                        Button(merchant) { viewModel.updateMerchantNameFromUser(merchant) }
                    }
                }
            }
            Divider().overlay(theme.hairline)
            TextField("expense.note", text: $viewModel.note, axis: .vertical)
                .lineLimit(2...5)
                .accessibilityIdentifier("expense.note")
            Toggle("expense.planned", isOn: $viewModel.isPlanned)
                .disabled(wishlistSeed != nil)
                .tint(theme.accent)
            Toggle("expense.recurring.monthly", isOn: $viewModel.isRecurring)
                .disabled(wishlistSeed != nil || viewModel.foreignCurrencyForm != nil)
                .tint(theme.accent)
                .accessibilityIdentifier("expense.recurring.monthly")
            if viewModel.isRecurring {
                Text("expense.recurring.monthly.help")
                    .font(.footnote)
                    .foregroundStyle(theme.inkSecondary)
            }
        }
        .budgetCard(cornerRadius: 18, contentPadding: 16)
    }

    private var contextFields: some View {
        DisclosureGroup("expense.context", isExpanded: $showsContextFields) {
            VStack(alignment: .leading, spacing: 16) {
                PurchaseReasonPicker(selection: $viewModel.purchaseReason)
                EmotionTagPicker(selection: $viewModel.emotionTag)
                Text("expense.emotion.disclaimer")
                    .font(.footnote)
                    .foregroundStyle(theme.inkSecondary)
            }
            .padding(.top, 14)
        }
        .tint(theme.accent)
        .budgetCard(cornerRadius: 18, contentPadding: 16)
    }

    private var reasonablenessWarning: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("expense.amount.warning.title", systemImage: "checkmark.circle")
                .font(.headline)
            Text("expense.amount.warning.message")
                .foregroundStyle(theme.inkSecondary)
            Button("expense.amount.warning.continue") {
                viewModel.dismissReasonablenessWarning(
                    currencyCode: accountingCurrencyCode,
                    locale: locale
                )
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("expense.amount.warning")
    }

    private func inlineInsight(_ insight: InsightDraft) -> some View {
        let wording = AdviceTemplateGenerator().wording(
            for: insight,
            tone: settings.reminderTone,
            locale: locale
        )
        return VStack(alignment: .leading, spacing: 8) {
            Label(wording.title, systemImage: "lightbulb")
                .font(.headline)
            Text(wording.body)
                .foregroundStyle(theme.inkSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("expense.inlineInsight")
    }

    private func submit() {
        if viewModel.receiptRecognitionPhase == .recognizing {
            viewModel.cancelReceiptRecognition()
        }
        Task {
            let result = await viewModel.submit(
                dataActor: dataActor,
                currencyCode: accountingCurrencyCode,
                bucket: viewModel.isRecurring
                    ? .fixed
                    : settings.bucket(for: viewModel.category),
                aiEnhancementEnabled: settings.enableAIEnhancement,
                premiumEntryAccess: premiumEntryAccess,
                featureAccess: featureAccessAuthority,
                locale: locale,
                now: Date(),
                timeZone: .current,
                cycleStartDay: settings.budgetCycleStartDay,
                calendar: calendar
            )
            switch result {
            case .saved:
                completeSuccessfulExpense()
            case let .reminder(presentation):
                activeReminder = presentation
            case .failed:
                break
            }
        }
    }

    private func completeSuccessfulExpense() {
        if viewModel.hasImportedReceipt {
            settings.hasCompletedReceiptImport = true
            telemetryEventRecorder.capture(.receipt(.saved, .completed))
        }
        completed()
    }

    @ViewBuilder
    private var impactView: some View {
        if let impact = viewModel.inlineImpact {
            HStack(alignment: .firstTextBaseline) {
                Text(impactKey(impact))
                    .foregroundStyle(.secondary)
                Spacer()
                MoneyText(
                    money: impact.willExceedFreeBudget
                        ? impact.remainingFreeAfter
                        : impact.remainingTotalAfter,
                    weight: .semibold
                )
            }
            .font(.subheadline)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("expense.impact")
        } else {
            switch viewModel.budgetContext {
            case .loading, .configured:
                EmptyView()
            case .unconfigured:
                budgetContextMessage("expense.impact.unconfigured")
            case .historicalPlanRequired:
                budgetContextMessage("expense.impact.historical")
            case .transitionPlanRequired:
                budgetContextMessage("expense.impact.transition")
            case .firstRegularPlanRequired:
                budgetContextMessage("expense.impact.firstRegular")
            case .unavailable:
                budgetContextMessage("expense.impact.unavailable")
            }
        }
    }

    private func budgetContextMessage(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("expense.impact.context")
    }

    private func recalculate() {
        viewModel.recalculate(
            currencyCode: accountingCurrencyCode,
            locale: locale,
            bucket: viewModel.isRecurring
                ? .fixed
                : settings.bucket(for: viewModel.category),
            calendar: calendar
        )
    }

    private func loadContext(referenceDate: Date) async {
        await viewModel.loadContext(
            dataActor: dataActor,
            currencyCode: accountingCurrencyCode,
            cycleStartDay: settings.budgetCycleStartDay,
            calendar: calendar,
            referenceDate: referenceDate,
            locale: locale,
            ruleConfiguration: settings.ruleConfiguration(),
            preferences: settings.preferencesSnapshot
        )
    }

    private func impactKey(_ impact: InlineBudgetImpact) -> LocalizedStringKey {
        if impact.willExceedTotalBudget { return "expense.impact.exceedsTotal" }
        if impact.willExceedFreeBudget { return "expense.impact.exceedsFree" }
        return "expense.impact.remaining"
    }

    private func errorKey(_ error: ExpenseFormError) -> LocalizedStringKey {
        switch error {
        case let .foreignCurrency(foreignError):
            switch foreignError {
            case .requiresProAccess: "fx.error.pro"
            case .unsupportedSource: "fx.error.manualOnly"
            case .syncRequiresCompanionProtocol: "fx.error.sync"
            case .currencyMismatch: "fx.error.currency"
            case .unreadableMetadata: "expense.error.invalidStoredData"
            case .overflow: "expense.error.amount.range"
            case .invalidRate, .invalidRateText, .invalidAmount: "fx.error.input"
            }
        case let .amount(inputError):
            switch inputError {
            case .empty: "expense.error.amount.empty"
            case .invalid: "expense.error.amount.invalid"
            case .tooManyFractionDigits: "expense.error.amount.precision"
            case .nonPositive, .negative: "expense.error.amount.positive"
            case .amountOutOfRange: "expense.error.amount.range"
            }
        case .invalidTimeZone: "expense.error.timeZone"
        case .accountingCurrencyMismatch: "expense.error.currencyMismatch"
        case .invalidStoredData: "expense.error.invalidStoredData"
        case .budgetGenerationLimit: "expense.error.dateTooFar"
        case .persistence: "error.data.save"
        }
    }
}

private struct ReceiptRecognitionProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mindBudgetTheme) private var theme
    @State private var offset: CGFloat = -0.62

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                theme.track.opacity(0.42)
                LinearGradient(
                    colors: [theme.accent, theme.accentDeep],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: proxy.size.width * 0.62)
                .offset(x: reduceMotion ? 0 : proxy.size.width * offset)
            }
        }
        .frame(height: 2)
        .clipped()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                offset = 0.62
            }
        }
    }
}

private struct ReceiptRecognitionSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mindBudgetTheme) private var theme
    let width: CGFloat
    let height: CGFloat
    @State private var highlightOffset: CGFloat = -1

    var body: some View {
        Capsule()
            .fill(theme.track)
            .frame(width: width, height: height)
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        colors: [.clear, theme.surface.opacity(0.95), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: width * highlightOffset)
                    .mask(Capsule())
                }
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    highlightOffset = 1
                }
            }
    }
}

private struct ExpenseReminderSheet: View {
    @Environment(\.mindBudgetTheme) private var theme
    let presentation: ExpenseReminderPresentation
    let permitsWishlist: Bool
    let continuePurchase: () -> Void
    let addToWishlist: () -> Void
    let close: () -> Void

    var body: some View {
        ZStack {
            theme.dark.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(theme.onDark)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.09), in: Circle())
                    }
                    .accessibilityLabel("common.close")
                }

                Spacer(minLength: 8)
                Image(systemName: "pause.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(theme.attentionOnDark)
                    .frame(width: 82, height: 82)
                    .background(theme.attentionOnDark.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
                Text("reminder.sheet.title")
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.accentOnDark)
                Text(presentation.message.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.onDark)
                Text(presentation.message.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.onDark.opacity(0.72))
                if !presentation.message.supportingDetails.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("reminder.sheet.alsoNoticed")
                            .font(.subheadline.weight(.semibold))
                        ForEach(presentation.message.supportingDetails, id: \.self) { detail in
                            Label(detail, systemImage: "circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(theme.onDark.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                }
                Spacer()
                Button(
                    permitsWishlist ? "reminder.action.addToWishlist" : "common.close",
                    action: permitsWishlist ? addToWishlist : close
                )
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(theme.dark)
                    .background(theme.attentionOnDark, in: RoundedRectangle(cornerRadius: 14))
                Button("reminder.action.continuePurchase", action: continuePurchase)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(theme.onDark)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .accessibilityIdentifier("expense.reminder.sheet")
        }
    }
}
