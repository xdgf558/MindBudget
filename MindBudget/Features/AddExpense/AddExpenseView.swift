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
    @Published var amountText = ""
    @Published var category: ExpenseCategory
    @Published var spentAt: Date
    @Published var merchantName = ""
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

    let existingExpense: ExpenseDetail?
    let wishlistSeed: WishlistExpenseSeed?
    private let reminderEventWriter: ReminderEventWriter
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

    init(
        existingExpense: ExpenseDetail?,
        wishlistSeed: WishlistExpenseSeed? = nil,
        now: Date = Date(),
        reminderEventWriter: ReminderEventWriter = .live
    ) {
        self.existingExpense = existingExpense
        self.wishlistSeed = wishlistSeed
        self.reminderEventWriter = reminderEventWriter
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

    func prepareInput(locale: Locale) {
        guard !didPrepareInput else { return }
        if let existingExpense {
            amountText = MoneyInputParser().inputText(
                for: existingExpense.summary.amount,
                locale: locale
            )
        } else if let estimatedPrice = wishlistSeed?.estimatedPrice {
            amountText = MoneyInputParser().inputText(for: estimatedPrice, locale: locale)
        }
        didPrepareInput = true
    }

    func enterKeypad(_ key: String, decimalSeparator: String) {
        guard amountText.count < 24 else { return }
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
        amountText.removeLast()
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
        locale: Locale,
        now: Date,
        timeZone: TimeZone,
        cycleStartDay: Int,
        calendar: Calendar
    ) async -> ExpenseSubmitResult {
        guard !isSaving else { return .failed }
        guard existingExpense == nil, wishlistSeed == nil,
              let snapshot = budgetSnapshot, let candidate = pendingCandidate else {
            return await save(
                dataActor: dataActor,
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
                aiEnhancementEnabled: aiEnhancementEnabled
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
        do {
            amount = try MoneyInputParser().money(
                from: amountText,
                currencyCode: currencyCode,
                locale: locale
            )
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
            source: existingSummary?.source ?? (wishlistSeed == nil ? .manual : .wishlistConversion),
            allowMerchantIndexing: existingSummary?.allowMerchantIndexing ?? false,
            recurrenceCalendarIdentifier: calendar.identifier
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
                _ = try await dataActor.updateExpense(id: existingSummary.id, with: draft)
            } else {
                _ = try await dataActor.createExpense(draft)
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
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @StateObject private var viewModel: ExpenseFormViewModel
    @State private var showsContextFields = false
    @State private var showsDatePicker = false
    @State private var presentsWishlistConversion = false
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
        self.accountingCurrencyCode = accountingCurrencyCode
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

                amountEntry
                keypad

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

                if existingExpense == nil, wishlistSeed == nil {
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("common.save") {
                submit()
            }
            .buttonStyle(MindBudgetPrimaryButtonStyle())
            .disabled(viewModel.isSaving)
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
                Button("common.cancel") { dismiss() }
            }
        }
        .task {
            viewModel.prepareInput(locale: locale)
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
                continuePurchase: {
                    Task {
                        let saved = await viewModel.continueAfterReminder(
                            eventID: presentation.id,
                            dataActor: dataActor,
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
                            completed()
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
                    selection: $viewModel.spentAt,
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
                Text(viewModel.amountText.isEmpty ? "0" : viewModel.amountText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
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
                    viewModel.spentAt = Date()
                }
                dateButton("expense.date.yesterday", selected: calendar.isDateInYesterday(viewModel.spentAt)) {
                    if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                        viewModel.spentAt = yesterday
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
            TextField("expense.merchant", text: $viewModel.merchantName)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("expense.merchant")
            if !viewModel.merchantSuggestions.isEmpty {
                Menu("expense.merchant.suggestions") {
                    ForEach(viewModel.merchantSuggestions, id: \.self) { merchant in
                        Button(merchant) { viewModel.merchantName = merchant }
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
                .disabled(wishlistSeed != nil)
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
        Task {
            let result = await viewModel.submit(
                dataActor: dataActor,
                currencyCode: accountingCurrencyCode,
                bucket: viewModel.isRecurring
                    ? .fixed
                    : settings.bucket(for: viewModel.category),
                aiEnhancementEnabled: settings.enableAIEnhancement,
                locale: locale,
                now: Date(),
                timeZone: .current,
                cycleStartDay: settings.budgetCycleStartDay,
                calendar: calendar
            )
            switch result {
            case .saved:
                completed()
            case let .reminder(presentation):
                activeReminder = presentation
            case .failed:
                break
            }
        }
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

private struct ExpenseReminderSheet: View {
    @Environment(\.mindBudgetTheme) private var theme
    let presentation: ExpenseReminderPresentation
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
                Button("reminder.action.addToWishlist", action: addToWishlist)
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
