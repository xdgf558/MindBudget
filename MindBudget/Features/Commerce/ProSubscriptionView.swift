import StoreKit
import SwiftUI

struct ProSubscriptionView: View {
    @ObservedObject var session: AppSession
    @Environment(\.mindBudgetTheme) private var theme
    @Environment(\.locale) private var locale
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

    private var hasConfirmedPurchaseAuthority: Bool {
        ProCommercePurchaseGate.hasConfirmedAuthority(
            session.commerceSubscriptionState
        )
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
                Text(ProCommerceCopy.renewalDisclosure(for: selectedProduct, locale: locale))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("commerce.pro.renewalDisclosure")
            }

            if !hasConfirmedPurchaseAuthority {
                Label(
                    "commerce.pro.status.unavailable",
                    systemImage: "exclamationmark.arrow.triangle.2.circlepath"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
                .accessibilityIdentifier("commerce.pro.status.unavailable")

                Button("commerce.pro.status.recheck") {
                    Task { await session.refreshCommerceEntitlements() }
                }
                .disabled(isPerformingOperation)
                .accessibilityIdentifier("commerce.pro.status.recheck")
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
                    || !hasConfirmedPurchaseAuthority
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
                    if ProCommerceCopy.hasPresentableFreeTrial(product) {
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
        if selectedProduct.map(ProCommerceCopy.hasPresentableFreeTrial) == true {
            return "commerce.pro.startTrial"
        }
        return "commerce.pro.continue"
    }

    private func purchaseSelectedProduct() async {
        guard let selectedProduct,
              hasLiveCatalog,
              hasConfirmedPurchaseAuthority else { return }
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

enum ProCommercePurchaseGate {
    static func hasConfirmedAuthority(_ state: EffectiveStoreSubscriptionState) -> Bool {
        state != .unavailable
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
    static func hasPresentableFreeTrial(_ product: StoreProductPresentation) -> Bool {
        guard product.isEligibleForIntroductoryOffer,
              let offer = product.introductoryOffer else { return false }
        return trialDurationComponents(offer) != nil
    }

    static func renewalDisclosure(
        for product: StoreProductPresentation,
        locale: Locale
    ) -> String {
        let trialDuration = product.isEligibleForIntroductoryOffer
            ? product.introductoryOffer.flatMap { localizedTrialDuration($0, locale: locale) }
            : nil
        let key: String
        switch (product.id, trialDuration != nil) {
        case (.proMonthly, true): key = "commerce.pro.disclosure.monthlyTrial"
        case (.proAnnual, true): key = "commerce.pro.disclosure.annualTrial"
        case (.proMonthly, false): key = "commerce.pro.disclosure.monthly"
        case (.proAnnual, false): key = "commerce.pro.disclosure.annual"
        }
        if let trialDuration {
            return LocalizedCatalog.format(
                key,
                locale: locale,
                trialDuration,
                product.displayPrice
            )
        }
        return LocalizedCatalog.format(
            key,
            locale: locale,
            product.displayPrice
        )
    }

    private static func localizedTrialDuration(
        _ offer: StoreIntroductoryOfferTerms,
        locale: Locale
    ) -> String? {
        guard let components = trialDurationComponents(offer) else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        return formatter.string(from: components)
    }

    private static func trialDurationComponents(
        _ offer: StoreIntroductoryOfferTerms
    ) -> DateComponents? {
        guard offer.isFreeTrial,
              offer.period.value > 0,
              offer.periodCount > 0 else { return nil }
        let multiplied = offer.period.value.multipliedReportingOverflow(
            by: offer.periodCount
        )
        guard !multiplied.overflow else { return nil }

        var components = DateComponents()
        switch offer.period.unit {
        case .day:
            components.day = multiplied.partialValue
        case .week:
            let days = multiplied.partialValue.multipliedReportingOverflow(by: 7)
            guard !days.overflow else { return nil }
            components.day = days.partialValue
        case .month:
            components.month = multiplied.partialValue
        case .year:
            components.year = multiplied.partialValue
        }
        return components
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
