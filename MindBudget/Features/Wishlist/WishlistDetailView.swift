import Foundation
import SwiftUI

struct WishlistBudgetImpact: Equatable, Sendable {
    let remainingTotalAfter: Money
    let remainingFreeAfter: Money
    let willExceedTotalBudget: Bool
    let willExceedFreeBudget: Bool
}

enum WishlistActionError: Error, Equatable, Sendable {
    case stateChanged
    case invalidStoredData
    case persistence

    static func mapped(from error: Error) -> WishlistActionError {
        if error is WishItemTransitionError {
            return .stateChanged
        }
        if let validationError = error as? DataValidationError {
            switch validationError {
            case .invalidWishItem, .invalidCoolingOffPlan, .identityMismatch, .modelNotFound:
                return .stateChanged
            default:
                return .persistence
            }
        }
        if error is PersistedModelError {
            return .invalidStoredData
        }
        return .persistence
    }
}

@MainActor
final class WishlistDetailViewModel: ObservableObject {
    @Published private(set) var detail: WishItemDetail?
    @Published private(set) var budgetImpact: WishlistBudgetImpact?
    @Published private(set) var failed = false
    @Published private(set) var isWorking = false
    @Published private(set) var actionError: WishlistActionError?

    func load(
        id: UUID,
        dataActor: DataActor,
        cycleStartDay: Int,
        calendar: Calendar,
        bucketMapping: [ExpenseCategory: BudgetBucket],
        now: Date = Date()
    ) async {
        do {
            _ = try await dataActor.refreshExpiredCoolingOffPlans(at: now)
            guard let loaded = try await dataActor.fetchWishItemDetail(id: id) else {
                failed = true
                return
            }
            detail = loaded
            budgetImpact = try await impact(
                for: loaded,
                dataActor: dataActor,
                cycleStartDay: cycleStartDay,
                calendar: calendar,
                bucket: bucketMapping[loaded.summary.category]
                    ?? loaded.summary.category.defaultBucket,
                now: now
            )
            failed = false
            actionError = nil
        } catch {
            failed = true
        }
    }

    func decide(
        id: UUID,
        outcome: CoolingOffOutcome,
        dataActor: DataActor,
        now: Date = Date()
    ) async -> Bool {
        await perform {
            try await dataActor.decideWishItem(id: id, outcome: outcome, at: now)
        }
    }

    func archive(id: UUID, dataActor: DataActor, now: Date = Date()) async -> Bool {
        await perform {
            try await dataActor.archiveWishItem(id: id, at: now)
        }
    }

    func reactivate(id: UUID, dataActor: DataActor, now: Date = Date()) async -> Bool {
        await perform {
            let summary = try await dataActor.transitionWishItem(id: id, to: .active, at: now)
            guard let loaded = try await dataActor.fetchWishItemDetail(id: summary.id) else {
                throw DataValidationError.modelNotFound
            }
            return loaded
        }
    }

    private func perform(_ operation: () async throws -> WishItemDetail) async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do {
            detail = try await operation()
            actionError = nil
            failed = false
            return true
        } catch {
            actionError = WishlistActionError.mapped(from: error)
            return false
        }
    }

    func reportActionError(_ error: Error) {
        actionError = WishlistActionError.mapped(from: error)
    }

    func clearActionError() {
        actionError = nil
    }

    private func impact(
        for detail: WishItemDetail,
        dataActor: DataActor,
        cycleStartDay: Int,
        calendar: Calendar,
        bucket: BudgetBucket,
        now: Date
    ) async throws -> WishlistBudgetImpact? {
        guard let price = detail.summary.estimatedPrice else { return nil }
        let coverage = try await dataActor.previewPlanCoverage(
            date: now,
            futureCycleStartDay: cycleStartDay,
            calendar: calendar
        )
        guard case let .covered(plan) = coverage else { return nil }
        let expenses = try await dataActor.fetchExpenseSummaries()
        let snapshot = try BudgetEngine().snapshot(
            cycle: DateInterval(start: plan.cycleStart, end: plan.cycleEnd),
            currencyCode: plan.currencyCode,
            expenses: expenses,
            plan: plan,
            now: now,
            calendar: calendar
        )
        guard case let .configured(configured) = snapshot else { return nil }
        let impact = try BudgetEngine().impact(
            of: price,
            category: detail.summary.category,
            bucket: bucket,
            snapshot: configured,
            categoryBudgets: plan.categoryBudgets
        )
        return WishlistBudgetImpact(
            remainingTotalAfter: impact.remainingTotalAfter,
            remainingFreeAfter: impact.remainingFreeAfter,
            willExceedTotalBudget: impact.willExceedTotalBudget,
            willExceedFreeBudget: impact.willExceedFreeBudget
        )
    }
}
struct WishlistDetailView: View {
    @ObservedObject var session: AppSession
    let wishItemID: UUID

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WishlistDetailViewModel()
    @State private var presentsEdit = false
    @State private var presentsCoolingOff = false
    @State private var presentsPurchaseOptions = false
    @State private var presentsExpenseConversion = false
    @State private var presentsDeleteConfirmation = false

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                detailList(detail)
            } else if viewModel.failed {
                ErrorStateView(messageKey: "error.data.load") {
                    Task { await reload() }
                }
            } else {
                ProgressView().accessibilityLabel("common.loading")
            }
        }
        .navigationTitle(viewModel.detail?.summary.name ?? "tab.wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.detail != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("common.edit") { presentsEdit = true }
                }
            }
        }
        .task(id: session.revision) { await reload() }
        .sheet(isPresented: $presentsEdit) {
            if let detail = viewModel.detail {
                NavigationStack {
                    AddWishItemView(
                        dataActor: session.dataActor,
                        accountingCurrencyCode: settings.currencyCode,
                        existingItem: detail
                    ) {
                        presentsEdit = false
                        session.dataDidChange()
                    }
                }
            }
        }
        .sheet(isPresented: $presentsCoolingOff) {
            if let detail = viewModel.detail {
                NavigationStack {
                    CoolingOffView(
                        session: session,
                        wishItem: detail.summary,
                        wantsNotification: settings.enableLocalNotifications
                            || session.notificationAuthorizationState == .notDetermined
                    ) {
                        presentsCoolingOff = false
                        session.dataDidChange()
                    }
                }
            }
        }
        .sheet(isPresented: $presentsExpenseConversion) {
            if let detail = viewModel.detail {
                NavigationStack {
                    AddExpenseView(
                        dataActor: session.dataActor,
                        accountingCurrencyCode: settings.currencyCode,
                        existingExpense: nil,
                        wishlistSeed: WishlistExpenseSeed(
                            wishItemId: detail.summary.id,
                            name: detail.summary.name,
                            estimatedPrice: detail.summary.estimatedPrice,
                            category: detail.summary.category,
                            emotionTag: detail.emotionTag,
                            purchaseReason: detail.reason
                        )
                    ) {
                        presentsExpenseConversion = false
                        session.dataDidChange()
                    }
                }
            }
        }
        .confirmationDialog(
            "wishlist.purchase.title",
            isPresented: $presentsPurchaseOptions,
            titleVisibility: .visible
        ) {
            Button("wishlist.purchase.recordExpense") {
                presentsExpenseConversion = true
            }
            Button("wishlist.purchase.markOnly") {
                Task {
                    if await viewModel.decide(
                        id: wishItemID,
                        outcome: .purchased,
                        dataActor: session.dataActor
                    ) {
                        await reconcileAfterWishlistChange()
                    }
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("wishlist.purchase.message")
        }
        .alert("wishlist.delete.title", isPresented: $presentsDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                Task {
                    do {
                        try await session.dataActor.deleteWishItem(id: wishItemID)
                        await reconcileAfterWishlistChange()
                        dismiss()
                    } catch {
                        viewModel.reportActionError(error)
                    }
                }
            }
        } message: {
            Text("wishlist.delete.message")
        }
        .alert(
            "wishlist.action.error.title",
            isPresented: Binding(
                get: { viewModel.actionError != nil },
                set: { isPresented in
                    if !isPresented { viewModel.clearActionError() }
                }
            )
        ) {
            Button("common.retry") {
                viewModel.clearActionError()
                Task { await reload() }
            }
            Button("common.done", role: .cancel) { viewModel.clearActionError() }
        } message: {
            if let actionError = viewModel.actionError {
                Text(actionErrorKey(actionError))
            }
        }
    }

    private func detailList(_ detail: WishItemDetail) -> some View {
        List {
            if detail.summary.status == .coolingOff,
               let reviewAt = detail.summary.targetReviewDate {
                Section("wishlist.cooling.title") {
                    CoolingOffCountdownLabel(reviewAt: reviewAt, calendar: calendar)
                        .font(.title3.weight(.semibold))
                        .accessibilityIdentifier("wishlist.cooling.countdown")
                    LabeledContent("wishlist.reviewAt") {
                        Text(reviewAt, format: .dateTime.month().day().hour().minute())
                    }
                }
            }

            Section("wishlist.details") {
                if let price = detail.summary.estimatedPrice {
                    LabeledContent("wishlist.price") { MoneyText(money: price) }
                }
                LabeledContent("expense.category") {
                    Label(
                        LocalizedStringKey(detail.summary.category.localizedNameKey),
                        systemImage: detail.summary.category.symbolName
                    )
                }
                LabeledContent("wishlist.addedAt") {
                    Text(detail.summary.createdAt, style: .date)
                }
                LabeledContent("wishlist.status") {
                    Text(LocalizedStringKey(detail.summary.status.localizedNameKey))
                }
                if let reason = detail.reason {
                    LabeledContent("expense.reason") {
                        Text(LocalizedStringKey(reason.localizedNameKey))
                    }
                }
                if let emotion = detail.emotionTag {
                    LabeledContent("expense.emotion") {
                        Text(LocalizedStringKey(emotion.localizedNameKey))
                    }
                }
                if let notes = detail.notes {
                    LabeledContent("wishlist.notes") { Text(notes) }
                }
            }

            budgetImpactSection
            actionSection(detail)

            if !detail.coolingOffPlans.isEmpty {
                Section("wishlist.cooling.history") {
                    ForEach(detail.coolingOffPlans) { plan in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(plan.startedAt, style: .date)
                            Text(coolingPlanDescription(plan))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .disabled(viewModel.isWorking)
    }

    @ViewBuilder
    private var budgetImpactSection: some View {
        Section("wishlist.impact.title") {
            if let impact = viewModel.budgetImpact {
                HStack {
                    Text(impactMessageKey(impact))
                    Spacer()
                    MoneyText(
                        money: impact.willExceedFreeBudget
                            ? impact.remainingFreeAfter
                            : impact.remainingTotalAfter,
                        weight: .semibold
                    )
                }
                .accessibilityElement(children: .combine)
            } else {
                Text("wishlist.impact.unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func actionSection(_ detail: WishItemDetail) -> some View {
        Section("wishlist.actions") {
            switch detail.summary.status {
            case .active, .readyToReview:
                Button(detail.summary.status == .readyToReview
                    ? "wishlist.action.coolAgain"
                    : "wishlist.action.startCooling") {
                    presentsCoolingOff = true
                }
                .accessibilityIdentifier("wishlist.startCooling")
                decisionButtons
                archiveButton
            case .coolingOff:
                decisionButtons
                archiveButton
            case .skipped, .archived:
                Button("wishlist.action.reactivate") {
                    Task {
                        if await viewModel.reactivate(
                            id: wishItemID,
                            dataActor: session.dataActor
                        ) {
                            session.dataDidChange()
                        }
                    }
                }
                if detail.summary.status == .skipped { archiveButton }
            case .purchased:
                if detail.summary.purchasedExpenseId != nil {
                    Text("wishlist.purchase.linked")
                        .foregroundStyle(.secondary)
                }
                archiveButton
            }
            Button("common.delete", role: .destructive) {
                presentsDeleteConfirmation = true
            }
        }
    }

    private var decisionButtons: some View {
        Group {
            Button("wishlist.action.purchased") { presentsPurchaseOptions = true }
            Button("wishlist.action.skipped") {
                Task {
                    if await viewModel.decide(
                        id: wishItemID,
                        outcome: .skipped,
                        dataActor: session.dataActor
                    ) {
                        await reconcileAfterWishlistChange()
                    }
                }
            }
        }
    }

    private var archiveButton: some View {
        Button("wishlist.action.archive") {
            Task {
                if await viewModel.archive(id: wishItemID, dataActor: session.dataActor) {
                    await reconcileAfterWishlistChange()
                    dismiss()
                }
            }
        }
    }

    private func coolingPlanDescription(_ plan: CoolingOffPlanSummary) -> LocalizedStringKey {
        if let outcome = plan.outcome {
            return LocalizedStringKey("wishlist.outcome.\(outcome.rawValue)")
        }
        return LocalizedStringKey("wishlist.coolingStatus.\(plan.status.rawValue)")
    }

    private func impactMessageKey(_ impact: WishlistBudgetImpact) -> LocalizedStringKey {
        if impact.willExceedTotalBudget { return "wishlist.impact.exceedsTotal" }
        if impact.willExceedFreeBudget { return "wishlist.impact.exceedsFree" }
        return "wishlist.impact.remaining"
    }

    private func actionErrorKey(_ error: WishlistActionError) -> LocalizedStringKey {
        switch error {
        case .stateChanged: "wishlist.action.error.stateChanged"
        case .invalidStoredData: "wishlist.action.error.invalidStoredData"
        case .persistence: "wishlist.action.error.persistence"
        }
    }

    private func reload() async {
        await viewModel.load(
            id: wishItemID,
            dataActor: session.dataActor,
            cycleStartDay: settings.budgetCycleStartDay,
            calendar: calendar,
            bucketMapping: Dictionary(
                uniqueKeysWithValues: ExpenseCategory.allCases.map {
                    ($0, settings.bucket(for: $0))
                }
            )
        )
    }

    private func reconcileAfterWishlistChange() async {
        session.dataDidChange()
        await session.reconcileNotifications(
            settings: settings,
            locale: locale,
            calendar: calendar
        )
    }
}
