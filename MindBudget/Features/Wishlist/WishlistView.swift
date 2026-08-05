import Foundation
import SwiftUI

@MainActor
final class WishlistViewModel: ObservableObject {
    @Published private(set) var items: [WishItemSummary] = []
    @Published private(set) var isLoading = true
    @Published private(set) var failed = false

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
                        actionTitleKey: "wishlist.add.title"
                    ) {
                        presentsAddItem = true
                    }
                    .accessibilityIdentifier("wishlist.empty")
                } else {
                    wishlistList
                }
            }
            .navigationDestination(for: UUID.self) { itemID in
                WishlistDetailView(session: session, wishItemID: itemID)
            }
            .navigationTitle("tab.wishlist")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentsAddItem = true
                    } label: {
                        Label("wishlist.add.title", systemImage: "plus")
                    }
                    .accessibilityIdentifier("wishlist.add")
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
        .task(id: session.revision) { await reload() }
        .mindBudgetOnscreenListSelection(
            nil,
            userEnabled: settings.enableSiriIntegration
        )
    }

    private var wishlistList: some View {
        List {
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
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("wishlist.list")
    }

    private func wishlistLink(_ item: WishItemSummary) -> some View {
        NavigationLink(value: item.id) {
            WishlistRow(item: item, calendar: calendar)
        }
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
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
