import Foundation
import StoreKit

/// The complete owner-approved StoreKit catalog. Customer terms never live in source code.
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
    case month
    case year
}

struct StoreSubscriptionPeriod: Codable, Equatable, Sendable {
    let value: Int
    let unit: StoreSubscriptionPeriodUnit
}

/// StoreKit-owned display metadata only. It can make a failed product load less abrupt, but it
/// can never authorize a paid feature.
struct StoreProductPresentation: Codable, Equatable, Sendable {
    let id: StoreProductID
    let displayName: String
    let description: String
    let displayPrice: String
    let subscriptionPeriod: StoreSubscriptionPeriod
}

struct StoreCatalogSnapshot: Codable, Equatable, Sendable {
    let context: StoreCatalogContext
    let products: [StoreProductPresentation]
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

    init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String,
        isAutoRenewable: Bool,
        isFamilyShareable: Bool,
        subscriptionGroupID: String?,
        subscriptionPeriod: StoreSubscriptionPeriod?
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.isAutoRenewable = isAutoRenewable
        self.isFamilyShareable = isFamilyShareable
        self.subscriptionGroupID = subscriptionGroupID
        self.subscriptionPeriod = subscriptionPeriod
    }

    init(product: Product) {
        let period: StoreSubscriptionPeriod?
        if let subscription = product.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .month:
                period = StoreSubscriptionPeriod(
                    value: subscription.subscriptionPeriod.value,
                    unit: .month
                )
            case .year:
                period = StoreSubscriptionPeriod(
                    value: subscription.subscriptionPeriod.value,
                    unit: .year
                )
            case .day, .week:
                period = nil
            @unknown default:
                period = nil
            }
        } else {
            period = nil
        }

        self.init(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            isAutoRenewable: product.type == .autoRenewable,
            isFamilyShareable: product.isFamilyShareable,
            subscriptionGroupID: product.subscription?.subscriptionGroupID,
            subscriptionPeriod: period
        )
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
        try await Product.products(for: identifiers).map(StoreProductRecord.init(product:))
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
            await presentationCache.save(snapshot)
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
                subscriptionPeriod: identifier.expectedPeriod
            )
        }
        return StoreCatalogSnapshot(context: context, products: products)
    }
}
