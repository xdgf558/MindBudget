import Foundation
import SwiftUI

enum BudgetSetupError: Error, Equatable, Sendable {
    case invalidIncome(MoneyInputError)
    case invalidTotalBudget(MoneyInputError)
    case invalidFixedExpenses(MoneyInputError)
    case invalidSavingGoal(MoneyInputError)
    case persistence
}

struct BudgetPlanDraftBuilder: Sendable {
    private let parser = MoneyInputParser()

    func makeDraft(
        currencyCode: String,
        cycle: DateInterval,
        monthlyIncomeText: String,
        totalBudgetText: String,
        fixedExpensesText: String,
        savingGoalText: String,
        locale: Locale,
        timestamp: Date
    ) throws -> BudgetPlanDraft {
        let income: Money
        let totalBudget: Money
        let fixedExpenses: Money
        let savingGoal: Money
        do {
            income = try parser.money(
                from: monthlyIncomeText,
                currencyCode: currencyCode,
                locale: locale,
                allowsZero: true
            )
        } catch let error as MoneyInputError {
            throw BudgetSetupError.invalidIncome(error)
        }
        do {
            totalBudget = try parser.money(
                from: totalBudgetText,
                currencyCode: currencyCode,
                locale: locale,
                allowsZero: true
            )
        } catch let error as MoneyInputError {
            throw BudgetSetupError.invalidTotalBudget(error)
        }
        do {
            fixedExpenses = try parser.money(
                from: fixedExpensesText,
                currencyCode: currencyCode,
                locale: locale,
                allowsZero: true
            )
        } catch let error as MoneyInputError {
            throw BudgetSetupError.invalidFixedExpenses(error)
        }
        do {
            savingGoal = try parser.money(
                from: savingGoalText,
                currencyCode: currencyCode,
                locale: locale,
                allowsZero: true
            )
        } catch let error as MoneyInputError {
            throw BudgetSetupError.invalidSavingGoal(error)
        }

        return BudgetPlanDraft(
            id: UUID(),
            cycleStart: cycle.start,
            cycleEnd: cycle.end,
            currencyCode: currencyCode,
            monthlyIncomeMinorUnits: income.minorUnits,
            totalBudgetMinorUnits: totalBudget.minorUnits,
            fixedExpensesMinorUnits: fixedExpenses.minorUnits,
            savingGoalMinorUnits: savingGoal.minorUnits,
            createdAt: timestamp,
            updatedAt: timestamp,
            categoryBudgets: []
        )
    }
}

@MainActor
final class BudgetSetupViewModel: ObservableObject {
    @Published var currencyCode: String
    @Published var cycleStartDay: Int
    @Published var monthlyIncomeText = ""
    @Published var totalBudgetText = ""
    @Published var fixedExpensesText = ""
    @Published var savingGoalText = ""
    @Published private(set) var error: BudgetSetupError?
    @Published private(set) var isSaving = false

    private var lastMirroredIncomeText = ""

    init(currencyCode: String, cycleStartDay: Int) {
        self.currencyCode = currencyCode
        self.cycleStartDay = cycleStartDay
    }

    func incomeChanged() {
        guard totalBudgetText.isEmpty || totalBudgetText == lastMirroredIncomeText else {
            return
        }
        totalBudgetText = monthlyIncomeText
        lastMirroredIncomeText = monthlyIncomeText
    }

    func save(
        dataActor: DataActor,
        locale: Locale,
        calendar: Calendar,
        now: Date
    ) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            let cycle = try BudgetCycleCalculator().interval(
                containing: now,
                startDay: cycleStartDay,
                calendar: calendar
            )
            let draft = try BudgetPlanDraftBuilder().makeDraft(
                currencyCode: currencyCode,
                cycle: cycle,
                monthlyIncomeText: monthlyIncomeText,
                totalBudgetText: totalBudgetText,
                fixedExpensesText: fixedExpensesText,
                savingGoalText: savingGoalText,
                locale: locale,
                timestamp: now
            )
            _ = try await dataActor.createBudgetPlan(draft)
            error = nil
            return true
        } catch let setupError as BudgetSetupError {
            error = setupError
            return false
        } catch {
            self.error = .persistence
            return false
        }
    }
}

struct OnboardingView: View {
    let dataActor: DataActor
    let didComplete: () -> Void

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @State private var showsBudgetSetup = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("onboarding.title")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("onboarding.title")
                Text("onboarding.message")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 14) {
                    OnboardingBenefit(symbol: "square.and.pencil", key: "onboarding.benefit.record")
                    OnboardingBenefit(symbol: "gauge.with.dots.needle.50percent", key: "onboarding.benefit.understand")
                    OnboardingBenefit(symbol: "lock.shield", key: "onboarding.benefit.private")
                }
                Spacer()
                Button("onboarding.continue") {
                    showsBudgetSetup = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("onboarding.continue")
            }
            .padding(24)
            .navigationDestination(isPresented: $showsBudgetSetup) {
                BudgetSetupView(
                    dataActor: dataActor,
                    initialCurrencyCode: preferredCurrencyCode,
                    initialCycleStartDay: settings.budgetCycleStartDay
                ) { currencyCode, cycleStartDay in
                    settings.currencyCode = currencyCode
                    settings.budgetCycleStartDay = cycleStartDay
                    settings.firstLaunchCompleted = true
                    didComplete()
                }
            }
        }
        .accessibilityIdentifier("onboarding.view")
    }

    private var preferredCurrencyCode: String {
        if Money.isSupported(settings.currencyCode) {
            return settings.currencyCode
        }
        if let localeCurrencyCode = locale.currency?.identifier,
           Money.isSupported(localeCurrencyCode) {
            return localeCurrencyCode
        }
        return "USD"
    }
}

private struct OnboardingBenefit: View {
    let symbol: String
    let key: LocalizedStringKey

    var body: some View {
        Label(key, systemImage: symbol)
            .font(.body)
            .symbolRenderingMode(.hierarchical)
    }
}

struct BudgetSetupView: View {
    let dataActor: DataActor
    let completed: (String, Int) -> Void

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @StateObject private var viewModel: BudgetSetupViewModel
    @FocusState private var focusedField: Field?

    init(
        dataActor: DataActor,
        initialCurrencyCode: String,
        initialCycleStartDay: Int,
        completed: @escaping (String, Int) -> Void
    ) {
        self.dataActor = dataActor
        self.completed = completed
        _viewModel = StateObject(
            wrappedValue: BudgetSetupViewModel(
                currencyCode: initialCurrencyCode,
                cycleStartDay: initialCycleStartDay
            )
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("budget.currency", selection: $viewModel.currencyCode) {
                    ForEach(Money.supportedCurrencyCodes, id: \.self) { code in
                        Text(currencyLabel(code)).tag(code)
                    }
                }
                .accessibilityIdentifier("budget.currency")

                Stepper(value: $viewModel.cycleStartDay, in: 1...31) {
                    LabeledContent("budget.cycleStartDay") {
                        Text(viewModel.cycleStartDay, format: .number)
                    }
                }
                .accessibilityIdentifier("budget.cycleStartDay")
            } header: {
                Text("budget.setup.basics")
            } footer: {
                Text("budget.currency.footer")
            }

            Section("budget.setup.amounts") {
                amountField(
                    "budget.monthlyIncome",
                    text: $viewModel.monthlyIncomeText,
                    field: .income,
                    identifier: "budget.monthlyIncome"
                )
                .onChange(of: viewModel.monthlyIncomeText) { _, _ in
                    viewModel.incomeChanged()
                }
                amountField(
                    "budget.totalBudget",
                    text: $viewModel.totalBudgetText,
                    field: .total,
                    identifier: "budget.totalBudget"
                )
                amountField(
                    "budget.fixedExpenses",
                    text: $viewModel.fixedExpensesText,
                    field: .fixed,
                    identifier: "budget.fixedExpenses"
                )
                amountField(
                    "budget.savingGoal",
                    text: $viewModel.savingGoalText,
                    field: .saving,
                    identifier: "budget.savingGoal"
                )
            }

            if let error = viewModel.error {
                Section {
                    Label(errorKey(error), systemImage: "info.circle")
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("budget.error")
                }
            }

            Section {
                Button {
                    Task {
                        let saved = await viewModel.save(
                            dataActor: dataActor,
                            locale: locale,
                            calendar: calendar,
                            now: Date()
                        )
                        if saved {
                            completed(viewModel.currencyCode, viewModel.cycleStartDay)
                        }
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("budget.save")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("budget.save")
            }
        }
        .navigationTitle("budget.setup.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("budget.setup.view")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common.done") { focusedField = nil }
            }
        }
    }

    private func amountField(
        _ key: LocalizedStringKey,
        text: Binding<String>,
        field: Field,
        identifier: String
    ) -> some View {
        HStack {
            Text(key)
            Spacer()
            TextField("money.amount.placeholder", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
                .accessibilityIdentifier(identifier)
        }
    }

    private func currencyLabel(_ code: String) -> String {
        let name = locale.localizedString(forCurrencyCode: code) ?? code
        return "\(code) · \(name)"
    }

    private func errorKey(_ error: BudgetSetupError) -> LocalizedStringKey {
        switch error {
        case .invalidIncome: "budget.error.income"
        case .invalidTotalBudget: "budget.error.total"
        case .invalidFixedExpenses: "budget.error.fixed"
        case .invalidSavingGoal: "budget.error.saving"
        case .persistence: "error.data.save"
        }
    }

    private enum Field: Hashable {
        case income, total, fixed, saving
    }
}
