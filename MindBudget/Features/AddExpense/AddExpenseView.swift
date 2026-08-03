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

@MainActor
final class ExpenseFormViewModel: ObservableObject {
    @Published var amountText = ""
    @Published var category: ExpenseCategory
    @Published var spentAt: Date
    @Published var merchantName = ""
    @Published var note = ""
    @Published var isPlanned: Bool
    @Published var emotionTag: EmotionTag?
    @Published var purchaseReason: PurchaseReason?
    @Published private(set) var inlineImpact: InlineBudgetImpact?
    @Published private(set) var budgetContext: ExpenseBudgetContext = .loading
    @Published private(set) var showsReasonablenessWarning = false
    @Published private(set) var error: ExpenseFormError?
    @Published private(set) var isSaving = false
    @Published private(set) var recentCategories: [ExpenseCategory] = []
    @Published private(set) var merchantSuggestions: [String] = []

    let existingExpense: ExpenseDetail?
    let wishlistSeed: WishlistExpenseSeed?
    private var configuredSnapshot: ConfiguredBudgetSnapshot?
    private var categoryBudgets: [CategoryBudgetSummary] = []
    private var dismissedWarningForMinorUnits: Int64?
    private var didPrepareInput = false
    private var latestContextRequestID = UUID()

    init(
        existingExpense: ExpenseDetail?,
        wishlistSeed: WishlistExpenseSeed? = nil,
        now: Date = Date()
    ) {
        self.existingExpense = existingExpense
        self.wishlistSeed = wishlistSeed
        let summary = existingExpense?.summary
        category = summary?.category ?? wishlistSeed?.category ?? .food
        spentAt = summary?.spentAt ?? now
        merchantName = summary?.merchantName ?? ""
        note = existingExpense?.note ?? ""
        isPlanned = summary?.isPlanned ?? (wishlistSeed != nil)
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

    func loadContext(
        dataActor: DataActor,
        currencyCode: String,
        cycleStartDay: Int,
        calendar: Calendar,
        referenceDate: Date,
        locale: Locale
    ) async {
        let requestID = UUID()
        latestContextRequestID = requestID
        do {
            async let fetchedExpenses = dataActor.fetchExpenseSummaries()
            async let fetchedMerchants = dataActor.fetchMerchantSummaries()
            let coverage = try await dataActor.previewPlanCoverage(
                date: referenceDate,
                futureCycleStartDay: cycleStartDay,
                calendar: calendar
            )
            let expenses = try await fetchedExpenses
            let merchants = try await fetchedMerchants
            guard requestID == latestContextRequestID else { return }
            recentCategories = uniqueCategories(
                expenses
                    .filter { $0.id != existingExpense?.summary.id }
                    .sorted { $0.spentAt > $1.spentAt }
                    .map(\.category)
            )
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
                budgetContext = context(for: coverage)
                recalculate(currencyCode: currencyCode, locale: locale)
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
                categoryBudgets = []
                budgetContext = .unavailable
                recalculate(currencyCode: currencyCode, locale: locale)
                return
            }
            configuredSnapshot = configured
            categoryBudgets = plan.categoryBudgets
            budgetContext = .configured
            recalculate(currencyCode: currencyCode, locale: locale)
        } catch {
            guard requestID == latestContextRequestID else { return }
            configuredSnapshot = nil
            categoryBudgets = []
            budgetContext = .unavailable
            recalculate(currencyCode: currencyCode, locale: locale)
        }
    }

    func recalculate(currencyCode: String, locale: Locale, bucket: BudgetBucket? = nil) {
        guard let amount = try? MoneyInputParser().money(
            from: amountText,
            currencyCode: currencyCode,
            locale: locale
        ) else {
            inlineImpact = nil
            showsReasonablenessWarning = false
            return
        }
        if let snapshot = configuredSnapshot {
            let selectedBucket = bucket ?? category.defaultBucket
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
            }
            showsReasonablenessWarning = snapshot.totalBudget.minorUnits > 0
                && amount.minorUnits > snapshot.totalBudget.minorUnits
                && dismissedWarningForMinorUnits != amount.minorUnits
        } else {
            inlineImpact = nil
            showsReasonablenessWarning = false
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
            bucket: bucket,
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
            isRecurring: existingSummary?.isRecurring ?? false,
            source: existingSummary?.source ?? (wishlistSeed == nil ? .manual : .wishlistConversion),
            allowMerchantIndexing: existingSummary?.allowMerchantIndexing ?? false
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

    private func uniqueCategories(_ categories: [ExpenseCategory]) -> [ExpenseCategory] {
        var seen: Set<ExpenseCategory> = []
        return categories.filter { seen.insert($0).inserted }.prefix(6).map { $0 }
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
    @FocusState private var amountFocused: Bool
    @State private var showsContextFields = false
    @State private var presentsWishlistConversion = false

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
        Form {
            if let wishlistSeed {
                Section("wishlist.item") {
                    Text(wishlistSeed.name)
                }
            }
            Section {
                HStack(alignment: .firstTextBaseline) {
                    Text(accountingCurrencyCode)
                        .foregroundStyle(.secondary)
                    TextField("money.amount.placeholder", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                        .focused($amountFocused)
                        .accessibilityLabel("expense.amount")
                        .accessibilityIdentifier("expense.amount")
                }
                impactView
            } header: {
                Text("expense.amount")
            }

            if viewModel.showsReasonablenessWarning {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("expense.amount.warning.title", systemImage: "checkmark.circle")
                            .font(.headline)
                        Text("expense.amount.warning.message")
                            .foregroundStyle(.secondary)
                        Button("expense.amount.warning.continue") {
                            viewModel.dismissReasonablenessWarning(
                                currencyCode: accountingCurrencyCode,
                                locale: locale
                            )
                        }
                    }
                    .accessibilityIdentifier("expense.amount.warning")
                }
            }

            Section("expense.category") {
                if !viewModel.recentCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.recentCategories) { category in
                                Button {
                                    viewModel.category = category
                                } label: {
                                    Label(
                                        LocalizedStringKey(category.localizedNameKey),
                                        systemImage: category.symbolName
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                Picker("expense.category", selection: $viewModel.category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(
                            LocalizedStringKey(category.localizedNameKey),
                            systemImage: category.symbolName
                        )
                        .tag(category)
                    }
                }
                .accessibilityIdentifier("expense.category")
            }

            Section("expense.date") {
                DatePicker(
                    "expense.date",
                    selection: $viewModel.spentAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
                HStack {
                    Button("expense.date.today") { viewModel.spentAt = Date() }
                    Spacer()
                    Button("expense.date.yesterday") {
                        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                            viewModel.spentAt = yesterday
                        }
                    }
                }
                .buttonStyle(.borderless)
            }

            Section("expense.optional") {
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
                TextField("expense.note", text: $viewModel.note, axis: .vertical)
                    .lineLimit(2...5)
                    .accessibilityIdentifier("expense.note")
                Toggle("expense.planned", isOn: $viewModel.isPlanned)
                    .disabled(wishlistSeed != nil)
            }

            Section {
                DisclosureGroup("expense.context", isExpanded: $showsContextFields) {
                    PurchaseReasonPicker(selection: $viewModel.purchaseReason)
                    EmotionTagPicker(selection: $viewModel.emotionTag)
                    Text("expense.emotion.disclaimer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if existingExpense == nil, wishlistSeed == nil {
                Section {
                    Button("expense.addToWishlist") {
                        amountFocused = false
                        presentsWishlistConversion = true
                    }
                    .accessibilityIdentifier("expense.addToWishlist")
                } footer: {
                    Text("expense.addToWishlist.help")
                }
            }

            if let error = viewModel.error {
                Section {
                    Label(errorKey(error), systemImage: "info.circle")
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("expense.error")
                }
            }
        }
        .navigationTitle(existingExpense == nil ? "expense.add.title" : "expense.edit.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("expense.form")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") {
                    Task {
                        let saved = await viewModel.save(
                            dataActor: dataActor,
                            currencyCode: accountingCurrencyCode,
                            bucket: settings.bucket(for: viewModel.category),
                            locale: locale,
                            now: Date(),
                            timeZone: .current,
                            cycleStartDay: settings.budgetCycleStartDay,
                            calendar: calendar
                        )
                        if saved { completed() }
                    }
                }
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("expense.save")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common.done") { amountFocused = false }
            }
        }
        .task {
            viewModel.prepareInput(locale: locale)
            if existingExpense == nil {
                amountFocused = true
            }
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
            bucket: settings.bucket(for: viewModel.category)
        )
    }

    private func loadContext(referenceDate: Date) async {
        await viewModel.loadContext(
            dataActor: dataActor,
            currencyCode: accountingCurrencyCode,
            cycleStartDay: settings.budgetCycleStartDay,
            calendar: calendar,
            referenceDate: referenceDate,
            locale: locale
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
