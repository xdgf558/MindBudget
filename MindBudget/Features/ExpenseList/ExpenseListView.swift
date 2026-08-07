import SwiftUI

struct ExpenseFilter: Equatable, Sendable {
    var category: ExpenseCategory?
    var bucket: BudgetBucket?
}

@MainActor
final class ExpenseListViewModel: ObservableObject {
    @Published private(set) var expenses: [ExpenseSummary] = []
    @Published private(set) var noteMatchingExpenseIDs: Set<UUID> = []
    @Published private(set) var failed = false
    @Published private(set) var noteSearchFailed = false
    @Published var filter = ExpenseFilter()
    @Published var searchText = ""

    var filteredExpenses: [ExpenseSummary] {
        expenses.filter { expense in
            let matchesCategory = filter.category == nil || expense.category == filter.category
            let matchesBucket = filter.bucket == nil || expense.bucket == filter.bucket
            let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let categoryName = Bundle.main.localizedString(
                forKey: expense.category.localizedNameKey,
                value: expense.category.rawValue,
                table: nil
            )
            let matchesSearch = needle.isEmpty
                || expense.merchantName?.localizedCaseInsensitiveContains(needle) == true
                || noteMatchingExpenseIDs.contains(expense.id)
                || categoryName.localizedCaseInsensitiveContains(needle)
            return matchesCategory && matchesBucket && matchesSearch
        }
    }

    func loadNoteMatches(dataActor: DataActor) async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            noteMatchingExpenseIDs = []
            noteSearchFailed = false
            return
        }
        do {
            let matchingIDs = try await dataActor.fetchExpenseIDsWithNotes(matching: query)
            guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return
            }
            noteMatchingExpenseIDs = matchingIDs
            noteSearchFailed = false
        } catch {
            guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return
            }
            noteMatchingExpenseIDs = []
            noteSearchFailed = true
        }
    }

    func load(dataActor: DataActor) async {
        do {
            expenses = try await dataActor.fetchExpenseSummaries()
            failed = false
        } catch {
            failed = true
        }
    }

    func delete(_ expense: ExpenseSummary, dataActor: DataActor) async -> Bool {
        do {
            try await dataActor.deleteExpense(id: expense.id)
            expenses.removeAll { $0.id == expense.id }
            noteMatchingExpenseIDs.remove(expense.id)
            failed = false
            return true
        } catch {
            failed = true
            return false
        }
    }
}

struct ExpenseListView: View {
    @Environment(\.mindBudgetTheme) private var theme
    @ObservedObject var session: AppSession
    @Environment(\.calendar) private var calendar
    @StateObject private var viewModel = ExpenseListViewModel()
    @State private var showsFilters = false

    var body: some View {
        Group {
            if viewModel.failed || viewModel.noteSearchFailed {
                ErrorStateView(messageKey: "error.data.load") {
                    Task {
                        await viewModel.load(dataActor: session.dataActor)
                        await viewModel.loadNoteMatches(dataActor: session.dataActor)
                    }
                }
            } else if viewModel.filteredExpenses.isEmpty {
                EmptyStateView(
                    symbolName: "square.and.pencil",
                    titleKey: viewModel.expenses.isEmpty
                        ? "expenses.empty.title"
                        : "expenses.filter.empty.title",
                    messageKey: viewModel.expenses.isEmpty
                        ? "expenses.empty.message"
                        : "expenses.filter.empty.message",
                    actionTitleKey: viewModel.expenses.isEmpty ? "expense.quickAdd" : nil
                ) {
                    session.presentExpenseEntry()
                }
            } else {
                List {
                    ForEach(dayGroups) { group in
                        Section {
                            ForEach(group.expenses, id: \.id) { expense in
                                NavigationLink {
                                    ExpenseDetailView(expense: expense, session: session)
                                } label: {
                                    ExpenseRow(expense: expense)
                                }
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions {
                                    Button("common.delete", role: .destructive) {
                                        Task {
                                            if await viewModel.delete(expense, dataActor: session.dataActor) {
                                                session.dataDidChange()
                                            }
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text(group.day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.inkSecondary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(theme.canvas)
                .safeAreaPadding(.bottom, 84)
            }
        }
        .mindBudgetScreenBackground()
        .navigationTitle("tab.log")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "expenses.search")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showsFilters = true
                } label: {
                    Label("expenses.filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                .accessibilityIdentifier("expenses.filter")
            }
        }
        .sheet(isPresented: $showsFilters) {
            NavigationStack {
                ExpenseFiltersView(filter: $viewModel.filter)
            }
            .presentationDetents([.medium, .large])
        }
        .task(id: session.revision) {
            await viewModel.load(dataActor: session.dataActor)
        }
        .task(id: viewModel.searchText) {
            await viewModel.loadNoteMatches(dataActor: session.dataActor)
        }
        .accessibilityIdentifier("expenses.list")
    }

    private var dayGroups: [ExpenseDayGroup] {
        let grouped = Dictionary(grouping: viewModel.filteredExpenses) {
            calendar.startOfDay(for: $0.spentAt)
        }
        return grouped
            .map { ExpenseDayGroup(day: $0.key, expenses: $0.value) }
            .sorted { $0.day > $1.day }
    }
}

private struct ExpenseDayGroup: Identifiable {
    var id: Date { day }
    let day: Date
    let expenses: [ExpenseSummary]
}

private struct ExpenseRow: View {
    @Environment(\.mindBudgetTheme) private var theme
    let expense: ExpenseSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.symbolName)
                .frame(width: 32, height: 32)
                .background(.tint.opacity(0.12), in: Circle())
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(expense.category.localizedNameKey))
                    .font(.headline)
                Text(expense.merchantName ?? expense.spentAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            MoneyText(money: expense.amount, weight: .semibold)
        }
        .padding(14)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ExpenseFiltersView: View {
    @Binding var filter: ExpenseFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("expenses.filter.category") {
                Picker("expenses.filter.category", selection: $filter.category) {
                    Text("common.all").tag(nil as ExpenseCategory?)
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(LocalizedStringKey(category.localizedNameKey))
                            .tag(category as ExpenseCategory?)
                    }
                }
            }
            Section("expenses.filter.bucket") {
                Picker("expenses.filter.bucket", selection: $filter.bucket) {
                    Text("common.all").tag(nil as BudgetBucket?)
                    ForEach(BudgetBucket.allCases) { bucket in
                        Text(LocalizedStringKey("bucket.\(bucket.rawValue)"))
                            .tag(bucket as BudgetBucket?)
                    }
                }
            }
            Section {
                Button("expenses.filter.clear") {
                    filter = ExpenseFilter()
                }
            }
        }
        .navigationTitle("expenses.filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("common.done") { dismiss() }
            }
        }
    }
}

struct ExpenseDetailView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var expense: ExpenseSummary
    @State private var detail: ExpenseDetail?
    @State private var showsEdit = false
    @State private var showsDeleteConfirmation = false
    @State private var deleteFailed = false
    @State private var detailLoadFailed = false

    init(expense: ExpenseSummary, session: AppSession) {
        _expense = State(initialValue: expense)
        self.session = session
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    MoneyText(
                        money: expense.amount,
                        font: .system(.largeTitle, design: .rounded),
                        weight: .bold
                    )
                    Label(
                        LocalizedStringKey(expense.category.localizedNameKey),
                        systemImage: expense.category.symbolName
                    )
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
            }

            Section("expense.details") {
                LabeledContent("expense.date") {
                    Text(expense.spentAt, format: .dateTime.year().month().day().hour().minute())
                }
                LabeledContent("expense.bucket") {
                    Text(LocalizedStringKey("bucket.\(expense.bucket.rawValue)"))
                }
                if let merchantName = expense.merchantName {
                    LabeledContent("expense.merchant") { Text(merchantName) }
                }
                if let note = detail?.note {
                    LabeledContent("expense.note") { Text(note) }
                }
                LabeledContent("expense.planned") {
                    Text(LocalizedStringKey(expense.isPlanned ? "common.yes" : "common.no"))
                }
            }

            if deleteFailed {
                Section {
                    Label("error.data.delete", systemImage: "info.circle")
                        .foregroundStyle(.orange)
                }
            }

            if detailLoadFailed {
                Section {
                    Label("error.data.load", systemImage: "info.circle")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Button("common.delete", role: .destructive) {
                    showsDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("expense.detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("common.edit") { showsEdit = true }
                    .disabled(detail == nil)
                    .accessibilityIdentifier("expense.edit")
            }
        }
        .sheet(isPresented: $showsEdit) {
            NavigationStack {
                AddExpenseView(
                    dataActor: session.dataActor,
                    accountingCurrencyCode: settings.currencyCode,
                    existingExpense: detail
                ) {
                    Task {
                        if let updated = try? await session.dataActor.fetchExpenseDetail(
                            id: expense.id
                        ) {
                            detail = updated
                            expense = updated.summary
                        }
                        session.dataDidChange()
                        showsEdit = false
                    }
                }
            }
        }
        .confirmationDialog(
            "expense.delete.title",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("common.delete", role: .destructive) {
                Task {
                    do {
                        try await session.dataActor.deleteExpense(id: expense.id)
                        session.dataDidChange()
                        dismiss()
                    } catch {
                        deleteFailed = true
                    }
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("expense.delete.message")
        }
        .task {
            do {
                detail = try await session.dataActor.fetchExpenseDetail(id: expense.id)
                detailLoadFailed = detail == nil
            } catch {
                detailLoadFailed = true
            }
        }
        .accessibilityIdentifier("expense.detail")
        .mindBudgetOnscreenEntity(
            .expense(expense.id),
            userEnabled: settings.enableSiriIntegration
        )
    }
}
