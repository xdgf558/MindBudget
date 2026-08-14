import StoreKit
import SwiftUI

struct ProSubscriptionView: View {
    @ObservedObject var session: AppSession
    @Environment(\.mindBudgetTheme) private var theme
    @State private var selectedProductID: StoreProductID = .proAnnual
    @State private var isPerformingOperation = false
    @State private var notice: ProCommerceNotice?
    @State private var presentsManageSubscriptions = false

    private var snapshot: StoreCatalogSnapshot? {
        session.storeCatalogAvailability.snapshot
    }

    private var products: [StoreProductPresentation] {
        snapshot?.products.sorted { lhs, rhs in
            StoreProductID.allCases.firstIndex(of: lhs.id) ?? 0
                < StoreProductID.allCases.firstIndex(of: rhs.id) ?? 0
        } ?? []
    }

    private var selectedProduct: StoreProductPresentation? {
        products.first { $0.id == selectedProductID }
    }

    private var hasLiveCatalog: Bool {
        if case .live = session.storeCatalogAvailability { true } else { false }
    }

    private var hasActiveSubscription: Bool {
        switch session.commerceSubscriptionState {
        case .subscribed, .inGracePeriod: true
        case .none, .inBillingRetryPeriod, .expired, .revoked, .unavailable: false
        }
    }

    var body: some View {
        List {
            heroSection
            featureSection
            planSection
            purchaseSection
            accountSection
            legalSection
        }
        .settingsListPresentation()
        .navigationTitle("commerce.pro.title")
        .navigationBarTitleDisplayMode(.inline)
        .task { await session.refreshCommerceCatalog() }
        .manageSubscriptionsSheet(isPresented: $presentsManageSubscriptions)
        .accessibilityIdentifier("commerce.pro.view")
    }

    private var heroSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("commerce.pro.title", systemImage: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(theme.accent)
                Text("commerce.pro.subtitle")
                    .foregroundStyle(theme.inkSecondary)
                if hasActiveSubscription {
                    Label("commerce.pro.active", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("commerce.pro.active")
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var featureSection: some View {
        Section("commerce.pro.includes") {
            featureRow("commerce.pro.feature.ai", icon: "text.sparkle")
            featureRow("commerce.pro.feature.cooling", icon: "hourglass")
            featureRow("commerce.pro.feature.siri", icon: "waveform")
            Text("commerce.pro.localFirst")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var planSection: some View {
        Section("commerce.pro.plans") {
            if products.isEmpty {
                ContentUnavailableView {
                    Label("commerce.pro.catalog.unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("commerce.pro.catalog.unavailable.detail")
                } actions: {
                    Button("common.retry") {
                        Task { await session.refreshCommerceCatalog() }
                    }
                    .accessibilityIdentifier("commerce.pro.catalog.retry")
                }
            } else {
                ForEach(products, id: \.id) { product in
                    planButton(product)
                }
                if case .cached = session.storeCatalogAvailability {
                    Label("commerce.pro.catalog.cached", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("common.retry") {
                        Task { await session.refreshCommerceCatalog() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        Section {
            if let selectedProduct {
                Text(ProCommerceCopy.renewalDisclosure(for: selectedProduct))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("commerce.pro.renewalDisclosure")
            }

            Button {
                Task { await purchaseSelectedProduct() }
            } label: {
                HStack {
                    Spacer()
                    if isPerformingOperation {
                        ProgressView()
                    } else {
                        Text(primaryButtonTitle)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .frame(minHeight: 30)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                isPerformingOperation
                    || !hasLiveCatalog
                    || selectedProduct == nil
                    || hasActiveSubscription
            )
            .accessibilityIdentifier("commerce.pro.purchase")

            if let notice {
                Label(notice.localizedKey, systemImage: notice.systemImage)
                    .font(.footnote)
                    .foregroundStyle(notice.isFailure ? Color.orange : theme.inkSecondary)
                    .accessibilityIdentifier("commerce.pro.notice")
            }
        } footer: {
            Text("commerce.pro.purchase.footer")
        }
    }

    private var accountSection: some View {
        Section("commerce.pro.account") {
            Button("commerce.pro.restore") {
                Task { await restorePurchases() }
            }
            .disabled(isPerformingOperation)
            .accessibilityIdentifier("commerce.pro.restore")

            Button("commerce.pro.manage") {
                presentsManageSubscriptions = true
            }
            .disabled(isPerformingOperation)
            .accessibilityIdentifier("commerce.pro.manage")
        }
    }

    private var legalSection: some View {
        Section {
            NavigationLink("commerce.pro.terms.title") {
                ProSubscriptionTermsView(products: products)
            }
            NavigationLink("commerce.pro.privacy.title") {
                ProSubscriptionPrivacyView()
            }
        } header: {
            Text("commerce.pro.legal")
        } footer: {
            Text("commerce.pro.testTerms")
        }
    }

    private func featureRow(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .accessibilityElement(children: .combine)
    }

    private func planButton(_ product: StoreProductPresentation) -> some View {
        let isSelected = selectedProductID == product.id
        return Button {
            selectedProductID = product.id
            notice = nil
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? theme.accent : theme.inkTertiary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.id == .proMonthly ? "commerce.pro.monthly" : "commerce.pro.annual")
                        .font(.headline)
                    if product.isEligibleForIntroductoryOffer,
                       product.introductoryOffer == StoreCatalogContract.expectedIntroductoryOffer {
                        Text("commerce.pro.trial.eligible")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accent)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline.monospacedDigit())
                    Text(product.id == .proMonthly ? "commerce.pro.perMonth" : "commerce.pro.perYear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("commerce.pro.plan.\(product.id.rawValue)")
    }

    private var primaryButtonTitle: LocalizedStringKey {
        if hasActiveSubscription { return "commerce.pro.active" }
        if selectedProduct?.isEligibleForIntroductoryOffer == true,
           selectedProduct?.introductoryOffer == StoreCatalogContract.expectedIntroductoryOffer {
            return "commerce.pro.startTrial"
        }
        return "commerce.pro.continue"
    }

    private func purchaseSelectedProduct() async {
        guard let selectedProduct, hasLiveCatalog else { return }
        isPerformingOperation = true
        notice = nil
        let outcome = await session.purchasePro(selectedProduct.id)
        notice = ProCommerceNotice(purchaseOutcome: outcome)
        isPerformingOperation = false
    }

    private func restorePurchases() async {
        isPerformingOperation = true
        notice = nil
        let outcome = await session.restoreProPurchases()
        notice = ProCommerceNotice(restoreOutcome: outcome)
        isPerformingOperation = false
    }
}

enum ProCommerceNotice: Equatable, Sendable {
    case purchased
    case pending
    case cancelled
    case restored
    case noActiveSubscription
    case operationInProgress
    case productUnavailable
    case purchasesNotAllowed
    case verificationFailed
    case invalidStoreState
    case unavailable

    init(purchaseOutcome: StorePurchaseOutcome) {
        switch purchaseOutcome {
        case .purchased: self = .purchased
        case .pending: self = .pending
        case .cancelled: self = .cancelled
        case let .failed(failure): self = Self(failure: failure)
        }
    }

    init(restoreOutcome: StoreRestoreOutcome) {
        switch restoreOutcome {
        case .restored: self = .restored
        case .noActiveSubscription: self = .noActiveSubscription
        case let .failed(failure): self = Self(failure: failure)
        }
    }

    private init(failure: StoreOperationFailure) {
        switch failure {
        case .operationInProgress: self = .operationInProgress
        case .productUnavailable: self = .productUnavailable
        case .purchasesNotAllowed: self = .purchasesNotAllowed
        case .verificationFailed: self = .verificationFailed
        case .invalidStoreState: self = .invalidStoreState
        case .unavailable: self = .unavailable
        }
    }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .purchased: "commerce.pro.notice.purchased"
        case .pending: "commerce.pro.notice.pending"
        case .cancelled: "commerce.pro.notice.cancelled"
        case .restored: "commerce.pro.notice.restored"
        case .noActiveSubscription: "commerce.pro.notice.noActive"
        case .operationInProgress: "commerce.pro.notice.inProgress"
        case .productUnavailable: "commerce.pro.notice.productUnavailable"
        case .purchasesNotAllowed: "commerce.pro.notice.purchasesNotAllowed"
        case .verificationFailed: "commerce.pro.notice.verificationFailed"
        case .invalidStoreState: "commerce.pro.notice.invalidState"
        case .unavailable: "commerce.pro.notice.unavailable"
        }
    }

    var systemImage: String {
        switch self {
        case .purchased, .restored: "checkmark.circle.fill"
        case .pending: "clock"
        case .cancelled, .noActiveSubscription: "info.circle"
        case .operationInProgress, .productUnavailable, .purchasesNotAllowed,
             .verificationFailed, .invalidStoreState, .unavailable:
            "exclamationmark.triangle"
        }
    }

    var isFailure: Bool {
        switch self {
        case .operationInProgress, .productUnavailable, .purchasesNotAllowed,
             .verificationFailed, .invalidStoreState, .unavailable:
            true
        case .purchased, .pending, .cancelled, .restored, .noActiveSubscription:
            false
        }
    }
}

enum ProCommerceCopy {
    static func renewalDisclosure(for product: StoreProductPresentation) -> String {
        let eligible = product.isEligibleForIntroductoryOffer
            && product.introductoryOffer == StoreCatalogContract.expectedIntroductoryOffer
        let key: String
        switch (product.id, eligible) {
        case (.proMonthly, true): key = "commerce.pro.disclosure.monthlyTrial"
        case (.proAnnual, true): key = "commerce.pro.disclosure.annualTrial"
        case (.proMonthly, false): key = "commerce.pro.disclosure.monthly"
        case (.proAnnual, false): key = "commerce.pro.disclosure.annual"
        }
        return String(
            format: NSLocalizedString(key, comment: "StoreKit subscription renewal disclosure"),
            locale: Locale.current,
            product.displayPrice
        )
    }
}

private struct ProSubscriptionTermsView: View {
    let products: [StoreProductPresentation]

    var body: some View {
        List {
            Section("commerce.pro.terms.subscription") {
                ForEach(products, id: \.id) { product in
                    LabeledContent(
                        product.id == .proMonthly ? "commerce.pro.monthly" : "commerce.pro.annual",
                        value: product.displayPrice
                    )
                }
                Text("commerce.pro.terms.renewal")
                Text("commerce.pro.terms.trial")
            }
            Section("commerce.pro.terms.control") {
                Text("commerce.pro.terms.control.detail")
            }
        }
        .settingsListPresentation()
        .navigationTitle("commerce.pro.terms.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProSubscriptionPrivacyView: View {
    var body: some View {
        List {
            Section("commerce.pro.privacy.storekit") {
                Text("commerce.pro.privacy.storekit.detail")
            }
            Section("commerce.pro.privacy.local") {
                Text("commerce.pro.privacy.local.detail")
            }
        }
        .settingsListPresentation()
        .navigationTitle("commerce.pro.privacy.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}
