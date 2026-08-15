import StoreKit
import SwiftUI

struct ProSubscriptionView: View {
    @ObservedObject var session: AppSession
    @Environment(\.mindBudgetTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
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

    private var selectedProductSupportsPurchase: Bool {
        selectedProduct.map(ProCommercePurchaseGate.supportsIntroductoryOffer) ?? false
    }

    var body: some View {
        List {
            heroSection
            subscriptionStatusSection
            trialLifecycleSection
            featureSection
            planSection
            purchaseSection
            accountSection
            legalSection
        }
        .settingsListPresentation()
        // Keep the StoreKit disclosure surface synchronized with the selected skin even when
        // the enclosing navigation stack is still applying its previous color-scheme update.
        // Without this local preference, a rapid dark↔light skin change can briefly pair the
        // new list background with stale system text colors and produce unreadable rows.
        .preferredColorScheme(theme.preferredColorScheme)
        .navigationTitle("commerce.pro.title")
        .navigationBarTitleDisplayMode(.inline)
        .task { await session.refreshCommerceCatalog() }
        .manageSubscriptionsSheet(isPresented: $presentsManageSubscriptions)
        .accessibilityIdentifier("commerce.pro.view")
    }

    @ViewBuilder
    private var subscriptionStatusSection: some View {
        if let guidance = ProSubscriptionStatusGuidance(
            state: session.commerceSubscriptionState
        ) {
            Section("commerce.pro.status.section") {
                ProSubscriptionStatusSummaryView(guidance: guidance)

                Button("commerce.pro.manage") {
                    presentsManageSubscriptions = true
                }
                .disabled(isPerformingOperation)
                .accessibilityIdentifier("commerce.pro.status.manage")

                Button("commerce.pro.status.recheck") {
                    Task { await session.refreshCommerceEntitlements() }
                }
                .disabled(isPerformingOperation)
                .accessibilityIdentifier("commerce.pro.status.recheckGuidance")
            }
        }
    }

    @ViewBuilder
    private var trialLifecycleSection: some View {
        if let trial = session.trialLifecycle {
            Section("commerce.pro.trial.lifecycle.section") {
                TrialLifecycleSummaryView(
                    trial: trial,
                    displayPrice: session.trialRenewalDisplayPrice,
                    reminder: session.trialRenewalReminder,
                    reminderFailed: session.trialRenewalReminderFailed,
                    locale: locale,
                    calendar: calendar
                )
            }
        }
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
            if let selectedProduct, selectedProductSupportsPurchase {
                Text(ProCommerceCopy.renewalDisclosure(for: selectedProduct, locale: locale))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("commerce.pro.renewalDisclosure")
            }

            if selectedProduct != nil, !selectedProductSupportsPurchase {
                Label(
                    "commerce.pro.offer.unsupported",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
                .accessibilityIdentifier("commerce.pro.offer.unsupported")
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
                    || !ProCommercePurchaseGate.permitsNewPurchase(
                        session.commerceSubscriptionState
                    )
                    || !hasConfirmedPurchaseAuthority
                    || !selectedProductSupportsPurchase
            )
            .accessibilityLabel(Text(primaryButtonTitle))
            .accessibilityHint("commerce.pro.purchase.hint")
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
            ProPlanOptionLabel(
                product: product,
                isSelected: isSelected
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(
            Text(ProCommerceCopy.planAccessibilityLabel(for: product, locale: locale))
        )
        .accessibilityValue(isSelected ? Text("commerce.pro.plan.selected") : Text(""))
        .accessibilityHint("commerce.pro.plan.selectHint")
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
              hasConfirmedPurchaseAuthority,
              ProCommercePurchaseGate.supportsIntroductoryOffer(selectedProduct) else { return }
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

struct TrialLifecycleSummaryView: View {
    let trial: TrialLifecycleProjection
    let displayPrice: String?
    let reminder: TrialRenewalReminderReconciliation
    let reminderFailed: Bool
    let locale: Locale
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("commerce.pro.trial.lifecycle.active", systemImage: "clock.badge.checkmark")
                .font(.headline)
            Text(renewalSummary)
                .font(.subheadline)
            Text(reminderSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("commerce.pro.trial.lifecycle")
    }

    private var renewalSummary: String {
        guard trial.willAutoRenew else {
            return LocalizedCatalog.string(
                "commerce.pro.trial.lifecycle.notRenewing",
                locale: locale
            )
        }
        guard let renewalDate = trial.renewalDate else {
            return LocalizedCatalog.string(
                "commerce.pro.trial.lifecycle.dateUnavailable",
                locale: locale
            )
        }
        let formattedDate = Self.dateFormatter(locale: locale, calendar: calendar)
            .string(from: renewalDate)
        guard let displayPrice, !displayPrice.isEmpty else {
            return LocalizedCatalog.format(
                "commerce.pro.trial.lifecycle.renewsDateOnly",
                locale: locale,
                formattedDate
            )
        }
        return LocalizedCatalog.format(
            "commerce.pro.trial.lifecycle.renews",
            locale: locale,
            formattedDate,
            displayPrice
        )
    }

    private var reminderSummary: String {
        if reminderFailed {
            return LocalizedCatalog.string(
                "commerce.pro.trial.lifecycle.reminderFailed",
                locale: locale
            )
        }
        switch reminder.delivery {
        case .scheduled:
            return LocalizedCatalog.string(
                "commerce.pro.trial.lifecycle.reminderScheduled",
                locale: locale
            )
        case .inAppOnly:
            return LocalizedCatalog.string(
                "commerce.pro.trial.lifecycle.inAppOnly",
                locale: locale
            )
        case .inactive:
            return LocalizedCatalog.string(
                "commerce.pro.trial.lifecycle.noReminder",
                locale: locale
            )
        }
    }

    private static func dateFormatter(locale: Locale, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

enum ProCommercePurchaseGate {
    static func hasConfirmedAuthority(_ state: EffectiveStoreSubscriptionState) -> Bool {
        state != .unavailable
    }

    static func supportsIntroductoryOffer(_ product: StoreProductPresentation) -> Bool {
        StoreIntroductoryOfferPurchasePolicy.permitsPurchase(product)
    }

    /// Billing grace retains Pro, while billing retry must direct the person to Apple rather than
    /// starting a second purchase flow. An expired or revoked subscription may choose a new plan.
    static func permitsNewPurchase(_ state: EffectiveStoreSubscriptionState) -> Bool {
        switch state {
        case .none, .expired, .revoked:
            true
        case .subscribed, .inGracePeriod, .inBillingRetryPeriod, .unavailable:
            false
        }
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
    case unsupportedIntroductoryOffer
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
        case .unsupportedIntroductoryOffer: self = .unsupportedIntroductoryOffer
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
        case .unsupportedIntroductoryOffer: "commerce.pro.offer.unsupported"
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
        case .operationInProgress, .productUnavailable, .unsupportedIntroductoryOffer,
             .purchasesNotAllowed,
             .verificationFailed, .invalidStoreState, .unavailable:
            "exclamationmark.triangle"
        }
    }

    var isFailure: Bool {
        switch self {
        case .operationInProgress, .productUnavailable, .unsupportedIntroductoryOffer,
             .purchasesNotAllowed,
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

    static func planAccessibilityLabel(
        for product: StoreProductPresentation,
        locale: Locale
    ) -> String {
        LocalizedCatalog.format(
            product.id == .proMonthly
                ? "commerce.pro.plan.accessibility.monthly"
                : "commerce.pro.plan.accessibility.annual",
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

enum ProSubscriptionStatusGuidance: String, Equatable, Sendable {
    case grace
    case billingRetry
    case expired
    case revoked

    init?(state: EffectiveStoreSubscriptionState) {
        switch state {
        case .inGracePeriod:
            self = .grace
        case .inBillingRetryPeriod:
            self = .billingRetry
        case .expired:
            self = .expired
        case .revoked:
            self = .revoked
        case .none, .subscribed, .unavailable:
            return nil
        }
    }

    var titleKey: String {
        switch self {
        case .grace: "commerce.pro.status.grace.title"
        case .billingRetry: "commerce.pro.status.retry.title"
        case .expired: "commerce.pro.status.expired.title"
        case .revoked: "commerce.pro.status.revoked.title"
        }
    }

    var detailKey: String {
        switch self {
        case .grace: "commerce.pro.status.grace.detail"
        case .billingRetry: "commerce.pro.status.retry.detail"
        case .expired: "commerce.pro.status.expired.detail"
        case .revoked: "commerce.pro.status.revoked.detail"
        }
    }

    var systemImage: String {
        switch self {
        case .grace: "creditcard.trianglebadge.exclamationmark"
        case .billingRetry: "exclamationmark.arrow.triangle.2.circlepath"
        case .expired: "clock.badge.xmark"
        case .revoked: "xmark.shield"
        }
    }

    var usesWarningTint: Bool {
        self == .grace || self == .billingRetry || self == .revoked
    }
}

struct ProSubscriptionStatusSummaryView: View {
    let guidance: ProSubscriptionStatusGuidance

    @Environment(\.mindBudgetTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey(guidance.titleKey), systemImage: guidance.systemImage)
                .font(.headline)
                .foregroundStyle(guidance.usesWarningTint ? Color.orange : theme.ink)
            Text(LocalizedStringKey(guidance.detailKey))
                .font(.subheadline)
                .foregroundStyle(theme.inkSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("commerce.pro.status.\(guidance.rawValue)")
    }
}

private struct ProPlanOptionLabel: View {
    let product: StoreProductPresentation
    let isSelected: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.mindBudgetTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? theme.accent : theme.inkTertiary)
                .padding(.top, 2)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    planIdentity
                    price
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    planIdentity
                    Spacer(minLength: 8)
                    price
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planIdentity: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.id == .proMonthly ? "commerce.pro.monthly" : "commerce.pro.annual")
                .font(.headline)
            if ProCommerceCopy.hasPresentableFreeTrial(product) {
                Text("commerce.pro.trial.eligible")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var price: some View {
        VStack(
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
            spacing: 2
        ) {
            Text(product.displayPrice)
                .font(.headline.monospacedDigit())
            Text(product.id == .proMonthly ? "commerce.pro.perMonth" : "commerce.pro.perYear")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
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
