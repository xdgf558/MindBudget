import Foundation
import SwiftUI

@MainActor
final class WishlistViewModel: ObservableObject {
    @Published private(set) var items: [WishItemSummary] = []
    @Published private(set) var isLoading = true
    @Published private(set) var failed = false

    var openItemCount: Int {
        items.filter { $0.status.countsTowardOpenLimit }.count
    }

    var isAtOpenItemLimit: Bool {
        openItemCount >= WishlistPolicy.maximumOpenItems
    }

    func load(dataActor: DataActor, now: Date = Date()) async {
        do {
            _ = try await dataActor.refreshExpiredCoolingOffPlans(at: now)
            items = try await dataActor.fetchWishItemSummaries()
            failed = false
        } catch {
            failed = true
        }
        isLoading = false
    }
}
struct WishlistView: View {
    @Environment(\.mindBudgetTheme) private var theme
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.calendar) private var calendar
    @StateObject private var viewModel = WishlistViewModel()
    @State private var presentsAddItem = false

    var body: some View {
        NavigationStack(path: $session.wishlistNavigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView().accessibilityLabel("common.loading")
                } else if viewModel.failed {
                    ErrorStateView(messageKey: "error.data.load") {
                        Task { await reload() }
                    }
                } else if viewModel.items.isEmpty {
                    EmptyStateView(
                        symbolName: "heart.text.square",
                        titleKey: "wishlist.empty.title",
                        messageKey: "wishlist.empty.message",
                        actionTitleKey: "wishlist.add.title",
                        actionAccessibilityIdentifier: "wishlist.empty.add"
                    ) {
                        presentsAddItem = true
                    }
                } else {
                    wishlistList
                }
            }
            .navigationDestination(for: UUID.self) { itemID in
                WishlistDetailView(session: session, wishItemID: itemID)
            }
            .navigationTitle("tab.wishlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentsAddItem = true
                    } label: {
                        Label("wishlist.add.title", systemImage: "plus")
                    }
                    .accessibilityIdentifier("wishlist.add")
                    .disabled(viewModel.isAtOpenItemLimit)
                }
            }
            .sheet(isPresented: $presentsAddItem) {
                NavigationStack {
                    AddWishItemView(
                        dataActor: session.dataActor,
                        accountingCurrencyCode: settings.currencyCode,
                        existingItem: nil
                    ) {
                        presentsAddItem = false
                        session.dataDidChange()
                    }
                }
            }
        }
        .mindBudgetScreenBackground()
        .task(id: session.revision) { await reload() }
        .mindBudgetOnscreenListSelection(
            nil,
            userEnabled: settings.enableSiriIntegration
        )
    }

    private var wishlistList: some View {
        List {
            Section {
                HStack(alignment: .firstTextBaseline) {
                    Label(
                        viewModel.isAtOpenItemLimit
                            ? "wishlist.limit.reached"
                            : "wishlist.limit.available",
                        systemImage: viewModel.isAtOpenItemLimit
                            ? "checkmark.circle"
                            : "bookmark"
                    )
                    Spacer()
                    Text("\(viewModel.openItemCount)/\(WishlistPolicy.maximumOpenItems)")
                        .monospacedDigit()
                }
                .font(.subheadline)
                .foregroundStyle(
                    viewModel.isAtOpenItemLimit ? theme.inkSecondary : theme.accentDeep
                )
                .accessibilityIdentifier("wishlist.limit.status")
            }
            let current = viewModel.items.filter { !$0.status.isWishlistHistory }
            let history = viewModel.items.filter(\.status.isWishlistHistory)
            if !current.isEmpty {
                Section("wishlist.section.current") {
                    ForEach(current) { item in
                        wishlistLink(item)
                    }
                }
            }
            if !history.isEmpty {
                Section("wishlist.section.history") {
                    ForEach(history) { item in
                        wishlistLink(item)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.canvas)
        .safeAreaPadding(.bottom, 84)
        .accessibilityIdentifier("wishlist.list")
    }

    private func wishlistLink(_ item: WishItemSummary) -> some View {
        NavigationLink(value: item.id) {
            WishlistRow(item: item, calendar: calendar)
        }
        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func reload() async {
        await viewModel.load(dataActor: session.dataActor)
    }
}
private extension WishItemStatus {
    var isWishlistHistory: Bool {
        self == .purchased || self == .skipped || self == .archived
    }
}

private struct WishlistRow: View {
    @Environment(\.mindBudgetTheme) private var theme
    let item: WishItemSummary
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(item.name).font(.headline)
                Spacer()
                if let price = item.estimatedPrice {
                    MoneyText(money: price, weight: .semibold)
                }
            }
            Label(
                LocalizedStringKey(item.category.localizedNameKey),
                systemImage: item.category.symbolName
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            HStack {
                Text(LocalizedStringKey(item.status.localizedNameKey))
                Spacer()
                Text(item.createdAt, style: .date)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if item.status == .coolingOff, let reviewAt = item.targetReviewDate {
                CoolingOffCountdownLabel(reviewAt: reviewAt, calendar: calendar)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(16)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
