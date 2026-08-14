import Foundation
import StoreKit

/// The complete owner-approved StoreKit technical catalog. Customer-facing prices and optional
/// promotional offers always come from StoreKit; only stable subscription identity and structure
/// participate in this production contract.
enum StoreProductID: String, CaseIterable, Codable, Sendable {
    case proMonthly = "com.xdgf558.mindbudget.pro.monthly"
    case proAnnual = "com.xdgf558.mindbudget.pro.annual"

    var entitlement: EntitlementSet {
        .proSubscription
    }

    fileprivate var expectedPeriod: StoreSubscriptionPeriod {
        switch self {
        case .proMonthly:
            StoreSubscriptionPeriod(value: 1, unit: .month)
        case .proAnnual:
            StoreSubscriptionPeriod(value: 1, unit: .year)
        }
    }
}

struct StoreRuntimeEnvironment: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    let rawValue: String

    static let xcode = StoreRuntimeEnvironment(rawValue: "Xcode")
    static let sandbox = StoreRuntimeEnvironment(rawValue: "Sandbox")
    static let production = StoreRuntimeEnvironment(rawValue: "Production")

    var isRecognizedStoreEnvironment: Bool {
        self == .xcode || self == .sandbox || self == .production
    }
}

struct StoreAppIdentity: Equatable, Sendable {
    let bundleID: String
    let environment: StoreRuntimeEnvironment
}

/// The verified app transaction is the environment authority for a whole StoreKit read.
/// Build configuration is deliberately not consulted: TestFlight uses Apple's Sandbox
/// environment, while an App Store install uses Production.
struct StoreAppIdentityPolicy: Sendable {
    let expectedBundleID: String

    func acceptedEnvironment(for identity: StoreAppIdentity) -> StoreRuntimeEnvironment? {
        guard !expectedBundleID.isEmpty,
              identity.bundleID == expectedBundleID,
              identity.environment.isRecognizedStoreEnvironment else {
            return nil
        }
        return identity.environment
    }
}

protocol StoreAppEnvironmentProviding: Sendable {
    func currentEnvironment() async -> StoreRuntimeEnvironment?
}

struct StoreKitAppEnvironmentProvider: StoreAppEnvironmentProviding {
    let expectedBundleID: String

    func currentEnvironment() async -> StoreRuntimeEnvironment? {
        do {
            switch try await AppTransaction.shared {
            case let .verified(transaction):
                return StoreAppIdentityPolicy(expectedBundleID: expectedBundleID)
                    .acceptedEnvironment(
                        for: StoreAppIdentity(
                            bundleID: transaction.bundleID,
                            environment: StoreRuntimeEnvironment(
                                rawValue: transaction.environment.rawValue
                            )
                        )
                    )
            case .unverified:
                return nil
            }
        } catch {
            return nil
        }
    }
}

struct StoreCatalogContext: Codable, Equatable, Hashable, Sendable {
    let environment: StoreRuntimeEnvironment
    let storefrontCountryCode: String

    var permitsPresentationCaching: Bool {
        environment.isRecognizedStoreEnvironment && !storefrontCountryCode.isEmpty
    }
}

enum StoreSubscriptionPeriodUnit: String, Codable, Equatable, Sendable {
    case day
    case week
    case month
    case year
}

struct StoreSubscriptionPeriod: Codable, Equatable, Sendable {
    let value: Int
    let unit: StoreSubscriptionPeriodUnit
}

/// StoreKit's complete introductory-offer payment-mode identity.
///
/// The raw value is preserved so a future StoreKit mode cannot be mistaken for a free trial.
/// C3-01 only presents and purchases `.freeTrial`; paid or unknown modes fail closed at the
/// purchase-presentation boundary without entering the entitlement contract.
struct StoreIntroductoryOfferPaymentMode: RawRepresentable, Codable, Equatable, Sendable {
    let rawValue: String

    static let freeTrial = Self(
        rawValue: Product.SubscriptionOffer.PaymentMode.freeTrial.rawValue
    )
    static let payAsYouGo = Self(
        rawValue: Product.SubscriptionOffer.PaymentMode.payAsYouGo.rawValue
    )
    static let payUpFront = Self(
        rawValue: Product.SubscriptionOffer.PaymentMode.payUpFront.rawValue
    )
}

struct StoreIntroductoryOfferTerms: Codable, Equatable, Sendable {
    let period: StoreSubscriptionPeriod
    let periodCount: Int
    let displayPrice: String
    let paymentMode: StoreIntroductoryOfferPaymentMode

    var isFreeTrial: Bool { paymentMode == .freeTrial }
}

enum StoreIntroductoryOfferPurchasePolicy {
    static func permitsPurchase(
        introductoryOffer: StoreIntroductoryOfferTerms?,
        isEligibleForIntroductoryOffer: Bool
    ) -> Bool {
        guard isEligibleForIntroductoryOffer else { return true }
        guard let introductoryOffer else { return false }
        return introductoryOffer.paymentMode == .freeTrial
            && introductoryOffer.period.value > 0
            && introductoryOffer.periodCount > 0
            && !introductoryOffer.displayPrice.isEmpty
    }

    static func permitsPurchase(_ product: StoreProductPresentation) -> Bool {
        permitsPurchase(
            introductoryOffer: product.introductoryOffer,
            isEligibleForIntroductoryOffer: product.isEligibleForIntroductoryOffer
        )
    }

    static func permitsPurchase(_ record: StoreProductRecord) -> Bool {
        permitsPurchase(
            introductoryOffer: record.introductoryOffer,
            isEligibleForIntroductoryOffer: record.isEligibleForIntroductoryOffer
        )
    }
}

/// StoreKit-owned display metadata only. It can make a failed product load less abrupt, but it
/// can never authorize a paid feature.
struct StoreProductPresentation: Codable, Equatable, Sendable {
    let id: StoreProductID
    let displayName: String
    let description: String
    let displayPrice: String
    let subscriptionPeriod: StoreSubscriptionPeriod
    let introductoryOffer: StoreIntroductoryOfferTerms?
    let isEligibleForIntroductoryOffer: Bool

    var cacheSafe: StoreProductPresentation {
        StoreProductPresentation(
            id: id,
            displayName: displayName,
            description: description,
            displayPrice: displayPrice,
            subscriptionPeriod: subscriptionPeriod,
            introductoryOffer: introductoryOffer,
            isEligibleForIntroductoryOffer: false
        )
    }
}

struct StoreCatalogSnapshot: Codable, Equatable, Sendable {
    let context: StoreCatalogContext
    let products: [StoreProductPresentation]

    var cacheSafe: StoreCatalogSnapshot {
        StoreCatalogSnapshot(context: context, products: products.map(\.cacheSafe))
    }
}

enum StoreCatalogAvailability: Equatable, Sendable {
    case live(StoreCatalogSnapshot)
    case cached(StoreCatalogSnapshot)
    case unavailable

    var snapshot: StoreCatalogSnapshot? {
        switch self {
        case let .live(snapshot), let .cached(snapshot): snapshot
        case .unavailable: nil
        }
    }
}

struct StoreProductRecord: Equatable, Sendable {
    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
    let isAutoRenewable: Bool
    let isFamilyShareable: Bool
    let subscriptionGroupID: String?
    let subscriptionPeriod: StoreSubscriptionPeriod?
    let introductoryOffer: StoreIntroductoryOfferTerms?
    let isEligibleForIntroductoryOffer: Bool

    init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String,
        isAutoRenewable: Bool,
        isFamilyShareable: Bool,
        subscriptionGroupID: String?,
        subscriptionPeriod: StoreSubscriptionPeriod?,
        introductoryOffer: StoreIntroductoryOfferTerms?,
        isEligibleForIntroductoryOffer: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.isAutoRenewable = isAutoRenewable
        self.isFamilyShareable = isFamilyShareable
        self.subscriptionGroupID = subscriptionGroupID
        self.subscriptionPeriod = subscriptionPeriod
        self.introductoryOffer = introductoryOffer
        self.isEligibleForIntroductoryOffer = isEligibleForIntroductoryOffer
    }

    init(product: Product) {
        self.init(product: product, isEligibleForIntroductoryOffer: false)
    }

    static func presentationRecord(product: Product) async -> StoreProductRecord {
        let isEligible = if let subscription = product.subscription,
                            subscription.introductoryOffer != nil {
            await subscription.isEligibleForIntroOffer
        } else {
            false
        }
        return StoreProductRecord(
            product: product,
            isEligibleForIntroductoryOffer: isEligible
        )
    }

    private init(product: Product, isEligibleForIntroductoryOffer: Bool) {
        let subscriptionPeriod = product.subscription.flatMap {
            Self.period(from: $0.subscriptionPeriod)
        }
        let introductoryOffer: StoreIntroductoryOfferTerms? = product.subscription?
            .introductoryOffer.flatMap { offer in
            guard let period = Self.period(from: offer.period) else { return nil }
            return StoreIntroductoryOfferTerms(
                period: period,
                periodCount: offer.periodCount,
                displayPrice: offer.displayPrice,
                paymentMode: StoreIntroductoryOfferPaymentMode(
                    rawValue: offer.paymentMode.rawValue
                )
            )
        }

        self.init(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            isAutoRenewable: product.type == .autoRenewable,
            isFamilyShareable: product.isFamilyShareable,
            subscriptionGroupID: product.subscription?.subscriptionGroupID,
            subscriptionPeriod: subscriptionPeriod,
            introductoryOffer: introductoryOffer,
            isEligibleForIntroductoryOffer: isEligibleForIntroductoryOffer
        )
    }

    private static func period(
        from period: Product.SubscriptionPeriod
    ) -> StoreSubscriptionPeriod? {
        let unit: StoreSubscriptionPeriodUnit
        switch period.unit {
        case .day: unit = .day
        case .week: unit = .week
        case .month: unit = .month
        case .year: unit = .year
        @unknown default: return nil
        }
        return StoreSubscriptionPeriod(value: period.value, unit: unit)
    }
}

protocol StoreCatalogContextProviding: Sendable {
    func currentContext() async -> StoreCatalogContext
}

protocol StoreProductLoading: Sendable {
    func loadProducts(identifiedBy identifiers: Set<String>) async throws -> [StoreProductRecord]
}

protocol StorePresentationCaching: Sendable {
    func load(for context: StoreCatalogContext) async -> StoreCatalogSnapshot?
    func save(_ snapshot: StoreCatalogSnapshot) async
    func clear() async
}

struct StoreKitCatalogContextProvider: StoreCatalogContextProviding {
    private let appEnvironmentProvider: any StoreAppEnvironmentProviding

    init(
        expectedBundleID: String = Bundle.main.bundleIdentifier ?? "",
        appEnvironmentProvider: (any StoreAppEnvironmentProviding)? = nil
    ) {
        self.appEnvironmentProvider = appEnvironmentProvider
            ?? StoreKitAppEnvironmentProvider(expectedBundleID: expectedBundleID)
    }

    func currentContext() async -> StoreCatalogContext {
        // An unavailable app environment may still partition non-authoritative product
        // presentation under an explicit Unknown cache key. Unlike entitlement reads, this
        // context can display StoreKit metadata but can never grant or preserve paid access.
        let environment = await appEnvironmentProvider.currentEnvironment()
            ?? StoreRuntimeEnvironment(rawValue: "Unknown")

        return StoreCatalogContext(
            environment: environment,
            storefrontCountryCode: await Storefront.current?.countryCode ?? ""
        )
    }
}

struct StoreKitProductLoader: StoreProductLoading {
    func loadProducts(identifiedBy identifiers: Set<String>) async throws -> [StoreProductRecord] {
        let products = try await Product.products(for: identifiers)
        var records: [StoreProductRecord] = []
        records.reserveCapacity(products.count)
        for product in products {
            records.append(await StoreProductRecord.presentationRecord(product: product))
        }
        return records
    }
}

actor UserDefaultsStorePresentationCache: StorePresentationCaching {
    private static let keyPrefix = "commerce.storePresentation.v1"
    private let defaults: UserDefaults

    init(suiteName: String?) {
        if let suiteName, let defaults = UserDefaults(suiteName: suiteName) {
            self.defaults = defaults
        } else {
            defaults = .standard
        }
    }

    func load(for context: StoreCatalogContext) -> StoreCatalogSnapshot? {
        guard context.permitsPresentationCaching,
              let data = defaults.data(forKey: key(for: context)),
              let snapshot = try? JSONDecoder().decode(StoreCatalogSnapshot.self, from: data),
              snapshot.context == context else {
            return nil
        }
        return snapshot
    }

    func save(_ snapshot: StoreCatalogSnapshot) {
        guard snapshot.context.permitsPresentationCaching,
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: key(for: snapshot.context))
    }

    func clear() {
        for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix(Self.keyPrefix + ".") {
            defaults.removeObject(forKey: key)
        }
    }

    private func key(for context: StoreCatalogContext) -> String {
        [Self.keyPrefix, context.environment.rawValue, context.storefrontCountryCode]
            .joined(separator: ".")
    }
}

enum StoreCatalogValidationError: Error, Equatable, Sendable {
    case productSetMismatch
    case invalidSubscription(String)
    case subscriptionGroupMismatch
}

/// A pure, fail-closed contract for the complete owner-approved subscription catalog.
/// Presentation and purchase paths share this validator so a single individually valid product
/// can never be offered before the Monthly/Annual pair has been verified as one coherent group.
enum StoreCatalogContract {
    static let expectedProductIDs = Set(StoreProductID.allCases.map(\.rawValue))

    static func validate(
        _ records: [StoreProductRecord]
    ) throws -> [StoreProductID: StoreProductRecord] {
        let grouped = Dictionary(grouping: records, by: \.id)
        guard Set(grouped.keys) == expectedProductIDs,
              grouped.values.allSatisfy({ $0.count == 1 }) else {
            throw StoreCatalogValidationError.productSetMismatch
        }

        var validated: [StoreProductID: StoreProductRecord] = [:]
        var subscriptionGroupIDs = Set<String>()
        for identifier in StoreProductID.allCases {
            guard let record = grouped[identifier.rawValue]?.first,
                  record.isAutoRenewable,
                  !record.isFamilyShareable,
                  record.subscriptionPeriod == identifier.expectedPeriod else {
                throw StoreCatalogValidationError.invalidSubscription(identifier.rawValue)
            }
            guard let subscriptionGroupID = record.subscriptionGroupID,
                  !subscriptionGroupID.isEmpty else {
                throw StoreCatalogValidationError.subscriptionGroupMismatch
            }
            subscriptionGroupIDs.insert(subscriptionGroupID)
            validated[identifier] = record
        }

        guard subscriptionGroupIDs.count == 1 else {
            throw StoreCatalogValidationError.subscriptionGroupMismatch
        }
        return validated
    }

    static func validatedRecord(
        for requestedProductID: StoreProductID,
        in records: [StoreProductRecord]
    ) throws -> StoreProductRecord {
        let validated = try validate(records)
        guard let record = validated[requestedProductID] else {
            throw StoreCatalogValidationError.productSetMismatch
        }
        return record
    }
}

actor StoreCatalog {
    private let contextProvider: any StoreCatalogContextProviding
    private let productLoader: any StoreProductLoading
    private let presentationCache: any StorePresentationCaching

    init(
        contextProvider: any StoreCatalogContextProviding = StoreKitCatalogContextProvider(),
        productLoader: any StoreProductLoading = StoreKitProductLoader(),
        presentationCache: any StorePresentationCaching
    ) {
        self.contextProvider = contextProvider
        self.productLoader = productLoader
        self.presentationCache = presentationCache
    }

    func refresh() async -> StoreCatalogAvailability {
        let context = await contextProvider.currentContext()
        do {
            let records = try await productLoader.loadProducts(
                identifiedBy: StoreCatalogContract.expectedProductIDs
            )
            let snapshot = try validatedSnapshot(context: context, records: records)
            // Introductory-offer eligibility is account-specific and can change after redemption.
            // Cached StoreKit metadata may soften a load failure, but it must never advertise a
            // trial without a fresh eligibility result.
            await presentationCache.save(snapshot.cacheSafe)
            return .live(snapshot)
        } catch {
            if let cached = await presentationCache.load(for: context) {
                return .cached(cached)
            }
            return .unavailable
        }
    }

    func clearPresentationCache() async {
        await presentationCache.clear()
    }

    private func validatedSnapshot(
        context: StoreCatalogContext,
        records: [StoreProductRecord]
    ) throws -> StoreCatalogSnapshot {
        let validated = try StoreCatalogContract.validate(records)

        let products = try StoreProductID.allCases.map { identifier in
            guard let record = validated[identifier] else {
                throw StoreCatalogValidationError.productSetMismatch
            }
            return StoreProductPresentation(
                id: identifier,
                displayName: record.displayName,
                description: record.description,
                displayPrice: record.displayPrice,
                subscriptionPeriod: identifier.expectedPeriod,
                introductoryOffer: record.introductoryOffer,
                isEligibleForIntroductoryOffer: record.isEligibleForIntroductoryOffer
            )
        }
        return StoreCatalogSnapshot(context: context, products: products)
    }
}
