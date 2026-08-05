import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    enum State {
        case loading
        case unconfigured
        case configured(ConfiguredBudgetSnapshot, [ExpenseSummary], [WishItemSummary])
        case transitionRequired(BudgetPlanTransitionRequirement)
        case firstRegularRequired(BudgetPlanFirstRegularRequirement)
        case failed
    }

    @Published private(set) var state: State = .loading

    func load(
        dataActor: DataActor,
        currencyCode: String,
        cycleStartDay: Int,
        calendar: Calendar,
        now: Date
    ) async {
        state = .loading
        guard Money.isSupported(currencyCode) else {
            state = .failed
            return
        }
        do {
            let coverage = try await dataActor.ensurePlanCovering(
                date: now,
                futureCycleStartDay: cycleStartDay,
                calendar: calendar,
                timestamp: now
            )
            switch coverage {
            case .unconfigured:
                state = .unconfigured
            case let .covered(plan):
                _ = try await dataActor.refreshExpiredCoolingOffPlans(at: now)
                async let fetchedExpenses = dataActor.fetchExpenseSummaries()
                async let fetchedWishItems = dataActor.fetchWishItemSummaries()
                let expenses = try await fetchedExpenses
                let wishItems = try await fetchedWishItems
                let snapshot = try BudgetEngine().snapshot(
                    cycle: DateInterval(start: plan.cycleStart, end: plan.cycleEnd),
                    currencyCode: plan.currencyCode,
                    expenses: expenses,
                    plan: plan,
                    now: now,
                    calendar: calendar
                )
                guard case let .configured(configured) = snapshot else {
                    state = .unconfigured
                    return
                }
                state = .configured(configured, expenses, wishItems)
            case let .transitionPlanRequired(requirement):
                state = .transitionRequired(requirement)
            case let .firstRegularPlanRequired(requirement):
                state = .firstRegularRequired(requirement)
            case .historicalPlanRequired:
                state = .failed
            }
        } catch {
            state = .failed
        }
    }
}

struct DashboardView: View {
    @ObservedObject var session: AppSession

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.calendar) private var calendar
    @StateObject private var viewModel = DashboardViewModel()
    @State private var presentedSetup: PresentedSetup?
    @State private var presentsAsk = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .accessibilityLabel("common.loading")
                case .unconfigured:
                    EmptyStateView(
                        symbolName: "chart.pie",
                        titleKey: "dashboard.noBudget.title",
                        messageKey: "dashboard.noBudget.message",
                        actionTitleKey: "dashboard.noBudget.action"
                    ) {
                        presentedSetup = .initial
                    }
                case let .configured(snapshot, expenses, wishItems):
                    configuredContent(
                        snapshot: snapshot,
                        expenses: expenses,
                        wishItems: wishItems
                    )
                case let .transitionRequired(requirement):
                    budgetConfirmationState(
                        titleKey: "budget.transition.title",
                        messageKey: "budget.transition.message"
                    ) {
                        presentedSetup = .transition(requirement)
                    }
                case let .firstRegularRequired(requirement):
                    budgetConfirmationState(
                        titleKey: "budget.firstRegular.title",
                        messageKey: "budget.firstRegular.message"
                    ) {
                        presentedSetup = .firstRegular(requirement)
                    }
                case .failed:
                    ErrorStateView(messageKey: "error.data.load", retry: reload)
                }
            }
            .navigationTitle("dashboard.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ExpenseListView(session: session)
                    } label: {
                        Label("expenses.title", systemImage: "list.bullet")
                    }
                    .accessibilityIdentifier("dashboard.expenses")
                }
            }
        }
        .accessibilityIdentifier("dashboard.view")
        .mindBudgetOnscreenEntity(
            onscreenBudgetReference,
            userEnabled: settings.enableSiriIntegration
        )
        .navigationDestination(isPresented: $session.presentsExpenseList) {
            ExpenseListView(session: session)
        }
        .task(id: session.revision) {
            await viewModel.load(
                dataActor: session.dataActor,
                currencyCode: settings.currencyCode,
                cycleStartDay: settings.budgetCycleStartDay,
                calendar: calendar,
                now: Date()
            )
        }
        .sheet(item: $presentedSetup) { setup in
            NavigationStack {
                switch setup {
                case .initial:
                    BudgetSetupView(
                        dataActor: session.dataActor,
                        initialCurrencyCode: settings.currencyCode,
                        initialCycleStartDay: settings.budgetCycleStartDay
                    ) { currencyCode, cycleStartDay in
                        settings.currencyCode = currencyCode
                        settings.budgetCycleStartDay = cycleStartDay
                        session.dataDidChange()
                        presentedSetup = nil
                    }
                case let .transition(requirement):
                    BudgetConfirmationView(
                        dataActor: session.dataActor,
                        currencyCode: settings.currencyCode,
                        context: .transition(requirement)
                    ) {
                        session.dataDidChange()
                        presentedSetup = nil
                    }
                case let .firstRegular(requirement):
                    BudgetConfirmationView(
                        dataActor: session.dataActor,
                        currencyCode: settings.currencyCode,
                        context: .firstRegular(requirement)
                    ) {
                        session.dataDidChange()
                        presentedSetup = nil
                    }
                }
            }
        }
        .sheet(isPresented: $presentsAsk) {
            if case let .configured(snapshot, expenses, wishItems) = viewModel.state {
                NavigationStack {
                    AskMindBudgetView(
                        snapshot: snapshot,
                        expenses: expenses,
                        wishItems: wishItems
                    )
                }
            }
        }
    }

    private var onscreenBudgetReference: OnscreenEntityReference? {
        guard case .configured = viewModel.state else { return nil }
        return .budgetCurrent
    }

    @ViewBuilder
    private func configuredContent(
        snapshot: ConfiguredBudgetSnapshot,
        expenses: [ExpenseSummary],
        wishItems: [WishItemSummary]
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if settings.enableAskMindBudget {
                    Button {
                        presentsAsk = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkle.magnifyingglass")
                            Text("ask.dashboard.prompt")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(.background, in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.quaternary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dashboard.ask")
                }
                TodaySpendableCard(snapshot: snapshot)
                BudgetSummaryCard(snapshot: snapshot)

                let pendingWishItems = wishItems.filter {
                    $0.status == .coolingOff || $0.status == .readyToReview
                }
                if !pendingWishItems.isEmpty {
                    Button {
                        session.selectedTab = .wishlist
                    } label: {
                        PendingWishlistCard(
                            items: Array(pendingWishItems.prefix(2)),
                            calendar: calendar
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dashboard.coolingOff")
                }

                Button {
                    session.presentExpenseEntry()
                } label: {
                    Label("expense.quickAdd", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("dashboard.quickAdd")

                if expenses.isEmpty {
                    EmptyStateView(
                        symbolName: "square.and.pencil",
                        titleKey: "expenses.empty.title",
                        messageKey: "expenses.empty.message",
                        actionTitleKey: "expense.quickAdd"
                    ) {
                        session.presentExpenseEntry()
                    }
                    .frame(minHeight: 240)
                } else {
                    RecentExpensesCard(expenses: Array(expenses.prefix(3)))
                }
            }
            .padding()
        }
        .refreshable {
            reload()
        }
    }

    private func budgetConfirmationState(
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        EmptyStateView(
            symbolName: "calendar.badge.clock",
            titleKey: titleKey,
            messageKey: messageKey,
            actionTitleKey: "budget.confirm.action",
            action: action
        )
    }

    private func reload() {
        session.dataDidChange()
    }

    private enum PresentedSetup: Identifiable {
        case initial
        case transition(BudgetPlanTransitionRequirement)
        case firstRegular(BudgetPlanFirstRegularRequirement)

        var id: String {
            switch self {
            case .initial: "initial"
            case let .transition(requirement): "transition-\(requirement.interval.start.timeIntervalSinceReferenceDate)"
            case let .firstRegular(requirement): "regular-\(requirement.interval.start.timeIntervalSinceReferenceDate)"
            }
        }
    }
}

private struct PendingWishlistCard: View {
    let items: [WishItemSummary]
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("dashboard.coolingOff.title", systemImage: "hourglass")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).fontWeight(.semibold)
                    if item.status == .readyToReview {
                        Text("wishlist.cooling.ready")
                            .foregroundStyle(.secondary)
                    } else if let reviewAt = item.targetReviewDate {
                        CoolingOffCountdownLabel(reviewAt: reviewAt, calendar: calendar)
                    }
                }
                .font(.subheadline)
            }
        }
        .budgetCard()
        .contentShape(Rectangle())
    }
}

private struct TodaySpendableCard: View {
    let snapshot: ConfiguredBudgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                Text("dashboard.available.title")
                    .font(.headline)
                MoneyText(
                    money: snapshot.availableRightNow,
                    font: .system(.largeTitle, design: .rounded).bold(),
                    weight: .bold
                )
                .foregroundStyle(snapshot.availableRightNow.minorUnits < 0 ? .orange : .primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("dashboard.available")
            Text(LocalizedStringKey(
                snapshot.availableRightNow.minorUnits < 0
                    ? "dashboard.available.negative"
                    : "dashboard.available.message"
            ))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
            HStack {
                Text("dashboard.safeDaily")
                Spacer()
                MoneyText(money: snapshot.safeDailySpend, weight: .semibold)
            }
            .accessibilityElement(children: .combine)
        }
        .budgetCard()
    }
}

private struct BudgetSummaryCard: View {
    let snapshot: ConfiguredBudgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("dashboard.period.title")
                .font(.headline)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    MoneyText(money: snapshot.spentTotal, weight: .semibold)
                    Text("dashboard.period.of")
                        .foregroundStyle(.secondary)
                    MoneyText(money: snapshot.totalBudget)
                }
                VStack(alignment: .leading, spacing: 4) {
                    MoneyText(money: snapshot.spentTotal, weight: .semibold)
                    MoneyText(money: snapshot.totalBudget)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: progress)
                .tint(.accentColor)
                .accessibilityLabel("dashboard.period.progress")
                .accessibilityValue(progressAccessibilityValue)

            if snapshot.remainingFree.minorUnits < 0 {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "info.circle")
                        .accessibilityHidden(true)
                    Text("dashboard.freeBudget.over")
                    MoneyText(money: overspentFreeBudget, weight: .semibold)
                }
                .accessibilityElement(children: .combine)
                .foregroundStyle(.orange)
            }
        }
        .budgetCard()
    }

    private var progress: CGFloat {
        guard snapshot.totalBudget.minorUnits > 0 else { return 0 }
        let ratio = Decimal(max(0, snapshot.spentTotal.minorUnits))
            / Decimal(snapshot.totalBudget.minorUnits)
        return min(1, CGFloat(truncating: NSDecimalNumber(decimal: ratio)))
    }

    private var progressAccessibilityValue: Text {
        Text("dashboard.period.progress.value \(progressPercent)")
    }

    private var progressPercent: Int {
        guard snapshot.totalBudget.minorUnits > 0 else { return 0 }
        let ratio = Decimal(max(0, snapshot.spentTotal.minorUnits))
            / Decimal(snapshot.totalBudget.minorUnits)
        var percent = ratio * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &percent, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }

    private var overspentFreeBudget: Money {
        Money(
            minorUnits: -snapshot.remainingFree.minorUnits,
            currencyCode: snapshot.currencyCode
        )
    }
}

private struct RecentExpensesCard: View {
    let expenses: [ExpenseSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("expenses.recent")
                .font(.headline)
            ForEach(expenses, id: \.id) { expense in
                HStack(spacing: 12) {
                    Image(systemName: expense.category.symbolName)
                        .frame(width: 28)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(expense.category.localizedNameKey))
                        Text(expense.spentAt, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    MoneyText(money: expense.amount, weight: .semibold)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .budgetCard()
    }
}

enum BudgetConfirmationContext {
    case transition(BudgetPlanTransitionRequirement)
    case firstRegular(BudgetPlanFirstRegularRequirement)
}

private struct BudgetAmountFields {
    var income = ""
    var total = ""
    var fixed = ""
    var saving = ""
}

struct BudgetConfirmationView: View {
    let dataActor: DataActor
    let currencyCode: String
    let context: BudgetConfirmationContext
    let completed: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var transitionFields = BudgetAmountFields()
    @State private var regularFields = BudgetAmountFields()
    @State private var errorKey: LocalizedStringKey?
    @State private var isSaving = false
    @FocusState private var amountFieldFocused: Bool

    var body: some View {
        Form {
            switch context {
            case let .transition(requirement):
                Section {
                    periodRange(requirement.interval)
                } header: {
                    Text("budget.transition.shortPeriod")
                } footer: {
                    Text("budget.transition.independent.footer")
                }
                amountSection(
                    title: "budget.transition.amounts",
                    fields: $transitionFields,
                    identifierPrefix: "budget.transition"
                )
                Section("budget.firstRegular.period") {
                    periodRange(requirement.firstRegularInterval)
                }
                amountSection(
                    title: "budget.firstRegular.amounts",
                    fields: $regularFields,
                    identifierPrefix: "budget.firstRegular"
                )
            case let .firstRegular(requirement):
                Section("budget.firstRegular.period") {
                    Text("budget.firstRegular.recovery.message")
                    periodRange(requirement.interval)
                }
                amountSection(
                    title: "budget.firstRegular.amounts",
                    fields: $regularFields,
                    identifierPrefix: "budget.firstRegular"
                )
            }

            if let errorKey {
                Section {
                    Label(errorKey, systemImage: "info.circle")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Button("budget.confirm.save") {
                    Task { await save() }
                }
                .disabled(isSaving)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("budget.confirm.save")
            }
        }
        .navigationTitle("budget.confirm.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common.done") { amountFieldFocused = false }
            }
        }
        .onAppear(perform: populateDefaults)
    }

    private func amountSection(
        title: LocalizedStringKey,
        fields: Binding<BudgetAmountFields>,
        identifierPrefix: String
    ) -> some View {
        Section(title) {
            confirmationAmountField(
                "budget.monthlyIncome",
                text: fields.income,
                identifier: "\(identifierPrefix).income"
            )
            confirmationAmountField(
                "budget.totalBudget",
                text: fields.total,
                identifier: "\(identifierPrefix).total"
            )
            confirmationAmountField(
                "budget.fixedExpenses",
                text: fields.fixed,
                identifier: "\(identifierPrefix).fixed"
            )
            confirmationAmountField(
                "budget.savingGoal",
                text: fields.saving,
                identifier: "\(identifierPrefix).saving"
            )
        }
    }

    private func periodRange(_ interval: DateInterval) -> some View {
        Group {
            LabeledContent("budget.period.start") {
                Text(interval.start, format: .dateTime.year().month().day())
            }
            LabeledContent("budget.period.end") {
                Text(interval.end, format: .dateTime.year().month().day())
            }
        }
    }

    private func confirmationAmountField(
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
                .focused($amountFieldFocused)
                .accessibilityIdentifier(identifier)
        }
    }

    private func populateDefaults() {
        guard case let .transition(requirement) = context,
              transitionFields.total.isEmpty,
              regularFields.total.isEmpty else { return }
        let parser = MoneyInputParser()
        let plan = requirement.precedingPlan
        let income = Money(minorUnits: plan.monthlyIncomeMinorUnits, currencyCode: plan.currencyCode)
        let total = Money(minorUnits: plan.totalBudgetMinorUnits, currencyCode: plan.currencyCode)
        let fixed = Money(minorUnits: plan.fixedExpensesMinorUnits, currencyCode: plan.currencyCode)
        let saving = Money(minorUnits: plan.savingGoalMinorUnits, currencyCode: plan.currencyCode)
        let fields = BudgetAmountFields(
            income: parser.inputText(for: income, locale: locale),
            total: parser.inputText(for: total, locale: locale),
            fixed: parser.inputText(for: fixed, locale: locale),
            saving: parser.inputText(for: saving, locale: locale)
        )
        transitionFields = fields
        regularFields = fields
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let builder = BudgetPlanDraftBuilder()
            let timestamp = Date()
            switch context {
            case let .transition(requirement):
                let transition = try builder.makeDraft(
                    currencyCode: currencyCode,
                    cycle: requirement.interval,
                    monthlyIncomeText: transitionFields.income,
                    totalBudgetText: transitionFields.total,
                    fixedExpensesText: transitionFields.fixed,
                    savingGoalText: transitionFields.saving,
                    locale: locale,
                    timestamp: timestamp
                )
                let firstRegular = try builder.makeDraft(
                    currencyCode: currencyCode,
                    cycle: requirement.firstRegularInterval,
                    monthlyIncomeText: regularFields.income,
                    totalBudgetText: regularFields.total,
                    fixedExpensesText: regularFields.fixed,
                    savingGoalText: regularFields.saving,
                    locale: locale,
                    timestamp: timestamp
                )
                _ = try await dataActor.createBudgetPlanTransition(
                    transition: transition,
                    firstRegular: firstRegular
                )
            case let .firstRegular(requirement):
                let firstRegular = try builder.makeDraft(
                    currencyCode: currencyCode,
                    cycle: requirement.interval,
                    monthlyIncomeText: regularFields.income,
                    totalBudgetText: regularFields.total,
                    fixedExpensesText: regularFields.fixed,
                    savingGoalText: regularFields.saving,
                    locale: locale,
                    timestamp: timestamp
                )
                _ = try await dataActor.createBudgetPlan(firstRegular)
            }
            errorKey = nil
            completed()
        } catch let error as BudgetSetupError {
            errorKey = setupErrorKey(error)
        } catch {
            errorKey = "error.data.save"
        }
    }

    private func setupErrorKey(_ error: BudgetSetupError) -> LocalizedStringKey {
        switch error {
        case .invalidIncome: "budget.error.income"
        case .invalidTotalBudget: "budget.error.total"
        case .invalidFixedExpenses: "budget.error.fixed"
        case .invalidSavingGoal: "budget.error.saving"
        case .persistence: "error.data.save"
        }
    }
}
