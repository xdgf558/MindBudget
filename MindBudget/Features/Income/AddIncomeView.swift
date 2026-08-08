import Foundation
import SwiftUI

enum IncomeFormError: Error, Equatable, Sendable {
    case amount(MoneyInputError)
    case invalidTimeZone
    case invalidAllocation
    case budgetCycleUnavailable
    case accountingCurrencyMismatch
    case invalidStoredData
    case persistence
}

enum IncomeBudgetCycleState: Equatable, Sendable {
    case loading
    case available(DateInterval)
    case unavailable
    case failed
}

@MainActor
final class IncomeFormViewModel: ObservableObject {
    @Published var amountText = ""
    @Published var category: IncomeCategory
    @Published var sourceName: String
    @Published var note: String
    @Published var allocatedToBudgetText = ""
    @Published var allocatedToSavingsText = ""
    @Published var receivedAt: Date
    @Published private(set) var budgetCycleState: IncomeBudgetCycleState = .loading
    @Published private(set) var error: IncomeFormError?
    @Published private(set) var isSaving = false

    let existingIncome: IncomeDetail?
    private var didPrepareInput = false

    init(existingIncome: IncomeDetail?, now: Date = Date()) {
        self.existingIncome = existingIncome
        category = existingIncome?.summary.category ?? .salary
        sourceName = existingIncome?.summary.sourceName ?? ""
        note = existingIncome?.note ?? ""
        receivedAt = existingIncome?.summary.receivedAt ?? now
    }

    func prepareInput(locale: Locale) {
        guard !didPrepareInput else { return }
        if let existingIncome {
            let parser = MoneyInputParser()
            amountText = parser.inputText(
                for: existingIncome.summary.amount,
                locale: locale
            )
            allocatedToBudgetText = parser.inputText(
                for: Money(
                    minorUnits: existingIncome.summary.allocatedToBudgetMinorUnits,
                    currencyCode: existingIncome.summary.amount.currencyCode
                ),
                locale: locale
            )
            allocatedToSavingsText = parser.inputText(
                for: Money(
                    minorUnits: existingIncome.summary.allocatedToSavingsMinorUnits,
                    currencyCode: existingIncome.summary.amount.currencyCode
                ),
                locale: locale
            )
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

    func loadBudgetCycle(dataActor: DataActor) async {
        let referenceDate = receivedAt
        budgetCycleState = .loading
        do {
            let plan = try await dataActor.fetchBudgetPlanCovering(date: referenceDate)
            guard receivedAt == referenceDate else { return }
            if let plan {
                budgetCycleState = .available(
                    DateInterval(start: plan.cycleStart, end: plan.cycleEnd)
                )
            } else {
                budgetCycleState = .unavailable
            }
        } catch {
            guard receivedAt == referenceDate else { return }
            budgetCycleState = .failed
        }
    }

    func save(
        dataActor: DataActor,
        currencyCode: String,
        locale: Locale,
        timeZone: TimeZone,
        now: Date
    ) async -> Bool {
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
        let allocatedToBudget: Int64
        let allocatedToSavings: Int64
        do {
            allocatedToBudget = try allocationMinorUnits(
                from: allocatedToBudgetText,
                currencyCode: currencyCode,
                locale: locale
            )
            allocatedToSavings = try allocationMinorUnits(
                from: allocatedToSavingsText,
                currencyCode: currencyCode,
                locale: locale
            )
            let (allocated, overflow) = allocatedToBudget.addingReportingOverflow(
                allocatedToSavings
            )
            guard !overflow, allocated <= amount.minorUnits else {
                error = .invalidAllocation
                return false
            }
        } catch {
            self.error = .invalidAllocation
            return false
        }

        isSaving = true
        defer { isSaving = false }
        let budgetPlanID: UUID?
        if allocatedToBudget > 0 {
            do {
                guard let plan = try await dataActor.fetchBudgetPlanCovering(date: receivedAt) else {
                    error = .budgetCycleUnavailable
                    budgetCycleState = .unavailable
                    return false
                }
                budgetPlanID = plan.id
                budgetCycleState = .available(
                    DateInterval(start: plan.cycleStart, end: plan.cycleEnd)
                )
            } catch {
                self.error = .budgetCycleUnavailable
                budgetCycleState = .failed
                return false
            }
        } else {
            budgetPlanID = nil
        }
        let summary = existingIncome?.summary
        let draft = IncomeDraft(
            id: summary?.id ?? UUID(),
            amount: amount,
            category: category,
            sourceName: optionalTrimmed(sourceName),
            note: optionalTrimmed(note),
            budgetPlanID: budgetPlanID,
            allocatedToBudgetMinorUnits: allocatedToBudget,
            allocatedToSavingsMinorUnits: allocatedToSavings,
            receivedAt: receivedAt,
            receivedTimeZoneIdentifier: timeZone.identifier,
            createdAt: summary?.createdAt ?? now,
            updatedAt: now
        )
        do {
            if let summary {
                _ = try await dataActor.updateIncome(id: summary.id, with: draft)
            } else {
                _ = try await dataActor.createIncome(draft)
            }
            error = nil
            return true
        } catch let validationError as DataValidationError {
            switch validationError {
            case .accountingCurrencyMismatch:
                error = .accountingCurrencyMismatch
            case .invalidAmount:
                error = .amount(.invalid)
            case .invalidTimeZone:
                error = .invalidTimeZone
            case .invalidIncomeAllocation:
                error = .invalidAllocation
            default:
                error = .persistence
            }
            return false
        } catch is PersistedModelError {
            error = .invalidStoredData
            return false
        } catch {
            self.error = .persistence
            return false
        }
    }

    private func optionalTrimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func allocationMinorUnits(
        from text: String,
        currencyCode: String,
        locale: Locale
    ) throws -> Int64 {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 0
        }
        return try MoneyInputParser().money(
            from: text,
            currencyCode: currencyCode,
            locale: locale,
            allowsZero: true
        ).minorUnits
    }
}

struct AddIncomeView: View {
    @Environment(\.mindBudgetTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    let dataActor: DataActor
    let accountingCurrencyCode: String
    let existingIncome: IncomeDetail?
    let completed: () -> Void

    @StateObject private var viewModel: IncomeFormViewModel
    @State private var showsDatePicker = false

    init(
        dataActor: DataActor,
        accountingCurrencyCode: String,
        existingIncome: IncomeDetail?,
        completed: @escaping () -> Void
    ) {
        self.dataActor = dataActor
        self.accountingCurrencyCode = accountingCurrencyCode
        self.existingIncome = existingIncome
        self.completed = completed
        _viewModel = StateObject(
            wrappedValue: IncomeFormViewModel(existingIncome: existingIncome)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                amountEntry
                keypad
                detailsCard

                if let error = viewModel.error {
                    Label(errorKey(error), systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(theme.attentionText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier("income.error")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .accessibilityIdentifier("income.form")
        .mindBudgetScreenBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("common.save") {
                Task {
                    if await viewModel.save(
                        dataActor: dataActor,
                        currencyCode: accountingCurrencyCode,
                        locale: locale,
                        timeZone: .current,
                        now: Date()
                    ) {
                        completed()
                    }
                }
            }
            .buttonStyle(MindBudgetPrimaryButtonStyle())
            .disabled(viewModel.isSaving)
            .accessibilityIdentifier("income.save")
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(theme.surface)
        }
        .navigationTitle(existingIncome == nil ? "income.add.title" : "income.edit.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
        }
        .task { viewModel.prepareInput(locale: locale) }
        .task(id: viewModel.receivedAt) {
            await viewModel.loadBudgetCycle(dataActor: dataActor)
        }
        .sheet(isPresented: $showsDatePicker) {
            NavigationStack {
                DatePicker(
                    "income.date",
                    selection: $viewModel.receivedAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("income.date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("common.done") { showsDatePicker = false }
                    }
                }
            }
        }
    }

    private var amountEntry: some View {
        VStack(spacing: 12) {
            Text("income.amount")
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
            .accessibilityLabel("income.amount")
            .accessibilityValue(viewModel.amountText.isEmpty ? "0" : viewModel.amountText)
            .accessibilityIdentifier("income.amount")
            Text("income.budget.independent")
                .font(.caption)
                .foregroundStyle(theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var keypad: some View {
        let decimalSeparator = locale.decimalSeparator ?? "."
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", decimalSeparator, "0"]
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
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
                .accessibilityIdentifier("income.keypad.\(key)")
            }
            Button { viewModel.deleteKeypadCharacter() } label: {
                Image(systemName: "delete.left")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(theme.ink)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("common.delete")
            .accessibilityIdentifier("income.keypad.delete")
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("income.category", selection: $viewModel.category) {
                ForEach(IncomeCategory.allCases) { category in
                    Label(
                        LocalizedStringKey(category.localizedNameKey),
                        systemImage: category.symbolName
                    )
                    .tag(category)
                }
            }
            Divider().overlay(theme.hairline)
            VStack(alignment: .leading, spacing: 10) {
                Text("income.allocation.title")
                    .font(.headline)
                Text("income.allocation.message")
                    .font(.footnote)
                    .foregroundStyle(theme.inkSecondary)
                budgetCycleStatus
                allocationField(
                    "income.allocation.budget",
                    text: $viewModel.allocatedToBudgetText,
                    identifier: "income.allocation.budget"
                )
                allocationField(
                    "income.allocation.savings",
                    text: $viewModel.allocatedToSavingsText,
                    identifier: "income.allocation.savings"
                )
            }
            Divider().overlay(theme.hairline)
            TextField("income.source.optional", text: $viewModel.sourceName)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("income.source")
            Divider().overlay(theme.hairline)
            TextField("income.note.optional", text: $viewModel.note, axis: .vertical)
                .lineLimit(2...5)
                .accessibilityIdentifier("income.note")
            Divider().overlay(theme.hairline)
            Button { showsDatePicker = true } label: {
                HStack {
                    Label("income.date", systemImage: "calendar")
                    Spacer()
                    Text(viewModel.receivedAt, format: .dateTime.year().month().day())
                        .foregroundStyle(theme.inkSecondary)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.ink)
        }
        .padding(18)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(theme.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var budgetCycleStatus: some View {
        switch viewModel.budgetCycleState {
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text("income.allocation.cycle.loading")
            }
            .font(.caption)
            .foregroundStyle(theme.inkSecondary)
        case let .available(interval):
            VStack(alignment: .leading, spacing: 4) {
                Text("income.allocation.cycle.target")
                    .font(.caption.weight(.semibold))
                HStack(spacing: 4) {
                    Text(interval.start, format: .dateTime.year().month().day())
                    Text(verbatim: "–")
                    Text(interval.end, format: .dateTime.year().month().day())
                }
                .font(.caption)
                .foregroundStyle(theme.inkSecondary)
            }
            .accessibilityIdentifier("income.allocation.cycle")
        case .unavailable:
            Label("income.allocation.cycle.unavailable", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(theme.attentionText)
                .accessibilityIdentifier("income.allocation.cycle.unavailable")
        case .failed:
            Label("income.allocation.cycle.failed", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(theme.attentionText)
        }
    }

    private func allocationField(
        _ key: LocalizedStringKey,
        text: Binding<String>,
        identifier: String
    ) -> some View {
        HStack {
            Text(key)
            Spacer()
            TextField("money.amount.placeholder", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
                .accessibilityIdentifier(identifier)
        }
    }

    private func errorKey(_ error: IncomeFormError) -> LocalizedStringKey {
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
        case .invalidAllocation: "income.error.allocation"
        case .budgetCycleUnavailable: "income.error.budgetCycleUnavailable"
        case .accountingCurrencyMismatch: "expense.error.currencyMismatch"
        case .invalidStoredData: "expense.error.invalidStoredData"
        case .persistence: "error.data.save"
        }
    }
}
