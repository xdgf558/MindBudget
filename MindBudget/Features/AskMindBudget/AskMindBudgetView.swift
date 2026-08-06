import SwiftUI

@MainActor
final class AskMindBudgetViewModel: ObservableObject {
    @Published var question = ""
    @Published var amountText = ""
    @Published var category: ExpenseCategory?
    @Published private(set) var response: AskMindBudgetResponse?
    @Published private(set) var isAnswering = false
    @Published private(set) var amountError = false

    private let classifier = IntentClassifier()

    var classifiedIntent: AskIntentKey {
        classifier.classify(question)
    }

    func useSuggestion(_ value: String) {
        question = value
        response = nil
    }

    func submit(
        snapshot: ConfiguredBudgetSnapshot,
        expenses: [ExpenseSummary],
        wishItems: [WishItemSummary],
        currencyCode: String,
        locale: Locale,
        calendar: Calendar,
        tone: ReminderTone,
        enhancementEnabled: Bool,
        bucket: (ExpenseCategory) -> BudgetBucket
    ) async {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !isAnswering else { return }
        isAnswering = true
        amountError = false
        defer { isAnswering = false }

        let intent = classifier.classify(question, locale: locale)
        let amount: Money?
        if intent == .canIAfford, !amountText.isEmpty {
            do {
                amount = try MoneyInputParser().money(
                    from: amountText,
                    currencyCode: currencyCode,
                    locale: locale
                )
            } catch {
                amountError = true
                return
            }
        } else {
            amount = nil
        }

        response = await AskMindBudgetService().answer(
            AskMindBudgetRequest(
                question: question,
                purchaseAmount: amount,
                purchaseCategory: category,
                purchaseBucket: category.map(bucket),
                snapshot: snapshot,
                expenses: expenses,
                wishItems: wishItems,
                locale: locale,
                calendar: calendar,
                tone: tone,
                enhancementEnabled: enhancementEnabled
            )
        )
    }
}

struct AskMindBudgetView: View {
    let snapshot: ConfiguredBudgetSnapshot
    let expenses: [ExpenseSummary]
    let wishItems: [WishItemSummary]

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @StateObject private var viewModel = AskMindBudgetViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.mbAccent)
                        .frame(width: 64, height: 64)
                        .background(Color.mbAccentSoft, in: Circle())
                    Text("ask.question.section")
                        .font(.title2.bold())
                        .foregroundStyle(Color.mbInk)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 14) {
                TextField("ask.question.placeholder", text: $viewModel.question, axis: .vertical)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("ask.question")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        suggestion("ask.suggestion.remaining")
                        suggestion("ask.suggestion.stress")
                        suggestion("ask.suggestion.wishlist")
                    }
                }
                }
                .budgetCard(cornerRadius: 20, contentPadding: 18)

                if viewModel.classifiedIntent == .canIAfford {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ask.purchase.section")
                            .font(.headline)
                    TextField("ask.purchase.amount", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                    Picker("ask.purchase.category", selection: $viewModel.category) {
                        Text("common.notSet").tag(ExpenseCategory?.none)
                        ForEach(ExpenseCategory.allCases) { category in
                            Text(LocalizedStringKey(category.localizedNameKey))
                                .tag(Optional(category))
                        }
                    }
                    if viewModel.amountError {
                        Text("ask.purchase.amountError")
                            .foregroundStyle(.red)
                    }
                    Text("ask.purchase.clarification")
                        .font(.footnote)
                        .foregroundStyle(Color.mbInkSecondary)
                    }
                    .budgetCard(cornerRadius: 20, contentPadding: 18)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if viewModel.isAnswering {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label("ask.submit", systemImage: "sparkle.magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(
                    viewModel.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || viewModel.isAnswering
                )
                .buttonStyle(MindBudgetPrimaryButtonStyle())
                .accessibilityIdentifier("ask.submit")

                if let response = viewModel.response {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ask.answer.section")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.mbInkSecondary)
                        HStack {
                            Text(response.answer.title).font(.headline)
                            Spacer()
                            if response.source == .model {
                                Label("ask.answer.enhanced", systemImage: "apple.intelligence")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(response.answer.body)
                            .textSelection(.enabled)
                        ForEach(response.answer.actionIdentifiers, id: \.self) { action in
                            Label(
                                LocalizedStringKey("ask.action.\(action)"),
                                systemImage: "arrow.right.circle"
                            )
                            .font(.subheadline)
                        }
                    }
                    .budgetCard(cornerRadius: 20, contentPadding: 18)
                    .accessibilityIdentifier("ask.answer")
                }

                Label("ask.privacy", systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(Color.mbInkSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .mindBudgetScreenBackground()
        .navigationTitle("ask.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.done") { dismiss() }
            }
        }
    }

    private func suggestion(_ key: String) -> some View {
        Button(LocalizedStringKey(key)) {
            viewModel.useSuggestion(LocalizedCatalog.string(key, locale: locale))
        }
        .font(.caption.weight(.medium))
        .buttonStyle(.bordered)
        .tint(Color.mbAccent)
    }

    private func submit() async {
        await viewModel.submit(
            snapshot: snapshot,
            expenses: expenses,
            wishItems: wishItems,
            currencyCode: snapshot.currencyCode,
            locale: locale,
            calendar: calendar,
            tone: settings.reminderTone,
            enhancementEnabled: settings.enableAIEnhancement,
            bucket: settings.bucket(for:)
        )
    }
}
