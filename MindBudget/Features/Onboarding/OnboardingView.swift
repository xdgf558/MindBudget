import Foundation
import SwiftUI

enum BudgetSetupError: Error, Equatable, Sendable {
    case invalidIncome(MoneyInputError)
    case invalidTotalBudget(MoneyInputError)
    case invalidSavingGoal(MoneyInputError)
    case persistence
}

struct BudgetPlanDraftBuilder: Sendable {
    private let parser = MoneyInputParser()

    private struct ParsedAmounts {
        let income: Money
        let totalBudget: Money
        let savingGoal: Money
    }

    func makeDraft(
        currencyCode: String,
        cycle: DateInterval,
        monthlyIncomeText: String,
        totalBudgetText: String,
        savingGoalText: String,
        locale: Locale,
        timestamp: Date
    ) throws -> BudgetPlanDraft {
        let amounts = try parsedAmounts(
            currencyCode: currencyCode,
            monthlyIncomeText: monthlyIncomeText,
            totalBudgetText: totalBudgetText,
            savingGoalText: savingGoalText,
            locale: locale
        )

        return BudgetPlanDraft(
            id: UUID(),
            cycleStart: cycle.start,
            cycleEnd: cycle.end,
            currencyCode: currencyCode,
            monthlyIncomeMinorUnits: amounts.income.minorUnits,
            totalBudgetMinorUnits: amounts.totalBudget.minorUnits,
            fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: amounts.savingGoal.minorUnits,
            createdAt: timestamp,
            updatedAt: timestamp,
            categoryBudgets: []
        )
    }

    func makeCurrentUpdate(
        planID: UUID,
        currencyCode: String,
        monthlyIncomeText: String,
        totalBudgetText: String,
        legacyFixedExpensesMinorUnits: Int64,
        savingGoalText: String,
        locale: Locale,
        referenceDate: Date,
        timestamp: Date
    ) throws -> CurrentBudgetPlanUpdate {
        let amounts = try parsedAmounts(
            currencyCode: currencyCode,
            monthlyIncomeText: monthlyIncomeText,
            totalBudgetText: totalBudgetText,
            savingGoalText: savingGoalText,
            locale: locale
        )
        return CurrentBudgetPlanUpdate(
            id: planID,
            currencyCode: currencyCode,
            monthlyIncomeMinorUnits: amounts.income.minorUnits,
            totalBudgetMinorUnits: amounts.totalBudget.minorUnits,
            fixedExpensesMinorUnits: legacyFixedExpensesMinorUnits,
            savingGoalMinorUnits: amounts.savingGoal.minorUnits,
            referenceDate: referenceDate,
            updatedAt: timestamp
        )
    }

    private func parsedAmounts(
        currencyCode: String,
        monthlyIncomeText: String,
        totalBudgetText: String,
        savingGoalText: String,
        locale: Locale
    ) throws -> ParsedAmounts {
        let income: Money
        let totalBudget: Money
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
            savingGoal = try parser.money(
                from: savingGoalText,
                currencyCode: currencyCode,
                locale: locale,
                allowsZero: true
            )
        } catch let error as MoneyInputError {
            throw BudgetSetupError.invalidSavingGoal(error)
        }

        return ParsedAmounts(
            income: income,
            totalBudget: totalBudget,
            savingGoal: savingGoal
        )
    }
}

@MainActor
final class BudgetSetupViewModel: ObservableObject {
    @Published var currencyCode: String
    @Published var cycleStartDay: Int
    @Published var monthlyIncomeText = ""
    @Published var totalBudgetText = ""
    @Published var savingGoalText = ""
    @Published private(set) var error: BudgetSetupError?
    @Published private(set) var isSaving = false

    init(currencyCode: String, cycleStartDay: Int) {
        self.currencyCode = currencyCode
        self.cycleStartDay = cycleStartDay
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
    @Environment(\.mindBudgetTheme) private var theme
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
                Image(systemName: "circle.dotted")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 76, height: 76)
                    .background(theme.accentGradient, in: RoundedRectangle(cornerRadius: 22))
                    .shadow(color: theme.accent.opacity(0.24), radius: 10, y: 6)
                    .accessibilityHidden(true)
                Text("onboarding.title")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.ink)
                    .accessibilityIdentifier("onboarding.title")
                Text("onboarding.message")
                    .font(.title3)
                    .foregroundStyle(theme.inkSecondary)
                VStack(alignment: .leading, spacing: 10) {
                    OnboardingBenefit(symbol: "square.and.pencil", key: "onboarding.benefit.record")
                    OnboardingBenefit(symbol: "gauge.with.dots.needle.50percent", key: "onboarding.benefit.understand")
                    OnboardingBenefit(symbol: "lock.shield", key: "onboarding.benefit.private")
                }
                Spacer()
                Button("onboarding.continue") {
                    showsBudgetSetup = true
                }
                .buttonStyle(MindBudgetPrimaryButtonStyle())
                .accessibilityIdentifier("onboarding.continue")
            }
            .padding(24)
            .background(MindBudgetThemeBackground())
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
    @Environment(\.mindBudgetTheme) private var theme
    let symbol: String
    let key: LocalizedStringKey

    var body: some View {
        Label(key, systemImage: symbol)
            .font(.body.weight(.medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
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
                amountField(
                    "budget.totalBudget",
                    text: $viewModel.totalBudgetText,
                    field: .total,
                    identifier: "budget.totalBudget"
                )
                amountField(
                    "budget.savingGoal",
                    text: $viewModel.savingGoalText,
                    field: .saving,
                    identifier: "budget.savingGoal"
                )

                if let allocationPreview {
                    Divider()
                    LabeledContent("settings.budget.flexiblePreview") {
                        MoneyText(
                            money: allocationPreview.flexibleBudget,
                            weight: .semibold
                        )
                    }
                    .accessibilityIdentifier("budget.flexiblePreview")

                    if let warningKey = allocationWarningKey(allocationPreview.status) {
                        Label(warningKey, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("budget.allocationWarning")
                    }
                }
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
                    focusedField = nil
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
                .buttonStyle(MindBudgetPrimaryButtonStyle())
                .accessibilityIdentifier("budget.save")
            }
        }
        .mindBudgetScreenBackground()
        .navigationTitle("budget.setup.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("budget.setup.view")
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
        case .invalidSavingGoal: "budget.error.saving"
        case .persistence: "error.data.save"
        }
    }

    private var allocationPreview: BudgetAllocationSummary? {
        let parser = MoneyInputParser()
        guard let monthlyIncome = try? parser.money(
            from: viewModel.monthlyIncomeText,
            currencyCode: viewModel.currencyCode,
            locale: locale,
            allowsZero: true
        ), let savingGoal = try? parser.money(
            from: viewModel.savingGoalText,
            currencyCode: viewModel.currencyCode,
            locale: locale,
            allowsZero: true
        ) else {
            return nil
        }
        return try? BudgetEngine().allocation(
            baseTotalBudget: monthlyIncome,
            additionalBudget: Money(
                minorUnits: 0,
                currencyCode: viewModel.currencyCode
            ),
            fixedForecast: Money(minorUnits: 0, currencyCode: viewModel.currencyCode),
            savingGoal: savingGoal
        )
    }

    private func allocationWarningKey(
        _ status: BudgetAllocationSummary.Status
    ) -> LocalizedStringKey? {
        switch status {
        case .available:
            nil
        case .zeroBudget:
            "settings.budget.allocation.zeroBudget"
        case .fullyAllocated:
            "settings.budget.allocation.fullyAllocated"
        case .overcommitted:
            "settings.budget.allocation.overcommitted"
        }
    }

    private enum Field: Hashable {
        case income, total, saving
    }
}
