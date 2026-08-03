import Foundation
import SwiftUI

struct WishItemFormSeed: Sendable {
    let name: String
    let estimatedPriceText: String
    let category: ExpenseCategory
    let reason: PurchaseReason?
    let emotionTag: EmotionTag?
}

enum WishItemFormError: Error, Equatable, Sendable {
    case nameRequired
    case amount(MoneyInputError)
    case accountingCurrencyMismatch
    case invalidStoredData
    case persistence
}

@MainActor
final class WishItemFormViewModel: ObservableObject {
    @Published var name: String
    @Published var estimatedPriceText: String
    @Published var category: ExpenseCategory
    @Published var reason: PurchaseReason?
    @Published var emotionTag: EmotionTag?
    @Published var notes: String
    @Published var coolingOffHours: Int
    @Published private(set) var error: WishItemFormError?
    @Published private(set) var isSaving = false

    let existingItem: WishItemDetail?
    private var didPreparePrice = false

    init(existingItem: WishItemDetail?, seed: WishItemFormSeed?) {
        self.existingItem = existingItem
        name = existingItem?.summary.name ?? seed?.name ?? ""
        estimatedPriceText = seed?.estimatedPriceText ?? ""
        category = existingItem?.summary.category ?? seed?.category ?? .shopping
        reason = existingItem?.reason ?? seed?.reason
        emotionTag = existingItem?.emotionTag ?? seed?.emotionTag
        notes = existingItem?.notes ?? ""
        coolingOffHours = existingItem?.summary.coolingOffHours ?? 24
    }

    func preparePrice(locale: Locale) {
        guard !didPreparePrice else { return }
        if let price = existingItem?.summary.estimatedPrice {
            estimatedPriceText = MoneyInputParser().inputText(for: price, locale: locale)
        }
        didPreparePrice = true
    }

    func save(
        dataActor: DataActor,
        currencyCode: String,
        locale: Locale,
        now: Date
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            error = .nameRequired
            return false
        }

        let price: Money?
        if estimatedPriceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            price = nil
        } else {
            do {
                price = try MoneyInputParser().money(
                    from: estimatedPriceText,
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
        }

        isSaving = true
        defer { isSaving = false }
        do {
            if let existingItem {
                _ = try await dataActor.updateWishItem(
                    id: existingItem.summary.id,
                    with: WishItemUpdate(
                        id: existingItem.summary.id,
                        name: trimmedName,
                        estimatedPrice: price,
                        currencyCode: currencyCode,
                        category: category,
                        reason: reason,
                        emotionTag: emotionTag,
                        sourceContextLabel: existingItem.sourceContextLabel,
                        updatedAt: now,
                        coolingOffHours: coolingOffHours,
                        notes: optionalTrimmed(notes)
                    )
                )
            } else {
                _ = try await dataActor.createWishItem(
                    WishItemDraft(
                        id: UUID(),
                        name: trimmedName,
                        estimatedPrice: price,
                        currencyCode: currencyCode,
                        category: category,
                        reason: reason,
                        emotionTag: emotionTag,
                        sourceContextLabel: nil,
                        createdAt: now,
                        updatedAt: now,
                        coolingOffHours: coolingOffHours,
                        targetReviewDate: nil,
                        status: .active,
                        notes: optionalTrimmed(notes),
                        purchasedExpenseId: nil
                    )
                )
            }
            error = nil
            return true
        } catch let validationError as DataValidationError {
            switch validationError {
            case .accountingCurrencyMismatch:
                error = .accountingCurrencyMismatch
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
}
struct AddWishItemView: View {
    let dataActor: DataActor
    let accountingCurrencyCode: String
    let existingItem: WishItemDetail?
    let seed: WishItemFormSeed?
    let completed: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @StateObject private var viewModel: WishItemFormViewModel
    @State private var showsContextFields = false
    @FocusState private var nameFocused: Bool

    init(
        dataActor: DataActor,
        accountingCurrencyCode: String,
        existingItem: WishItemDetail?,
        seed: WishItemFormSeed? = nil,
        completed: @escaping () -> Void
    ) {
        self.dataActor = dataActor
        self.accountingCurrencyCode = accountingCurrencyCode
        self.existingItem = existingItem
        self.seed = seed
        self.completed = completed
        _viewModel = StateObject(
            wrappedValue: WishItemFormViewModel(existingItem: existingItem, seed: seed)
        )
    }

    var body: some View {
        Form {
            Section("wishlist.item") {
                TextField("wishlist.name", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .focused($nameFocused)
                    .accessibilityIdentifier("wishlist.name")
                HStack(alignment: .firstTextBaseline) {
                    Text(accountingCurrencyCode)
                        .foregroundStyle(.secondary)
                    TextField("wishlist.price.optional", text: $viewModel.estimatedPriceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("wishlist.price")
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
                TextField("wishlist.notes.optional", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section {
                DisclosureGroup("expense.context", isExpanded: $showsContextFields) {
                    PurchaseReasonPicker(selection: $viewModel.reason)
                    EmotionTagPicker(selection: $viewModel.emotionTag)
                    Text("expense.emotion.disclaimer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("wishlist.defaultCooling") {
                Picker("wishlist.defaultCooling", selection: $viewModel.coolingOffHours) {
                    Text("wishlist.duration.24h").tag(24)
                    Text("wishlist.duration.72h").tag(72)
                }
                .pickerStyle(.segmented)
            }

            if let error = viewModel.error {
                Section {
                    Label(errorKey(error), systemImage: "info.circle")
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("wishlist.form.error")
                }
            }
        }
        .navigationTitle(existingItem == nil ? "wishlist.add.title" : "wishlist.edit.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") {
                    Task {
                        if await viewModel.save(
                            dataActor: dataActor,
                            currencyCode: accountingCurrencyCode,
                            locale: locale,
                            now: Date()
                        ) {
                            completed()
                        }
                    }
                }
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("wishlist.save")
            }
        }
        .task {
            viewModel.preparePrice(locale: locale)
            if existingItem == nil { nameFocused = true }
        }
    }

    private func errorKey(_ error: WishItemFormError) -> LocalizedStringKey {
        switch error {
        case .nameRequired: "wishlist.error.name"
        case let .amount(inputError):
            switch inputError {
            case .empty: "expense.error.amount.empty"
            case .invalid: "expense.error.amount.invalid"
            case .tooManyFractionDigits: "expense.error.amount.precision"
            case .nonPositive, .negative: "expense.error.amount.positive"
            case .amountOutOfRange: "expense.error.amount.range"
            }
        case .accountingCurrencyMismatch: "expense.error.currencyMismatch"
        case .invalidStoredData: "expense.error.invalidStoredData"
        case .persistence: "error.data.save"
        }
    }
}
