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
    let hasSubscriptionGroup: Bool
    let subscriptionPeriod: StoreSubscriptionPeriod?
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
    func currentContext() async -> StoreCatalogContext {
        let environment: StoreRuntimeEnvironment
        do {
            switch try await AppTransaction.shared {
            case let .verified(transaction):
                environment = StoreRuntimeEnvironment(rawValue: transaction.environment.rawValue)
            case .unverified:
                environment = StoreRuntimeEnvironment(rawValue: "Unknown")
            }
        } catch {
            environment = StoreRuntimeEnvironment(rawValue: "Unknown")
        }

        return StoreCatalogContext(
            environment: environment,
            storefrontCountryCode: await Storefront.current?.countryCode ?? ""
        )
    }
}

struct StoreKitProductLoader: StoreProductLoading {
    func loadProducts(identifiedBy identifiers: Set<String>) async throws -> [StoreProductRecord] {
        try await Product.products(for: identifiers).map { product in
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

            return StoreProductRecord(
                id: product.id,
                displayName: product.displayName,
                description: product.description,
                displayPrice: product.displayPrice,
                isAutoRenewable: product.type == .autoRenewable,
                isFamilyShareable: product.isFamilyShareable,
                hasSubscriptionGroup: product.subscription != nil,
                subscriptionPeriod: period
            )
        }
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
            let requestedIDs = Set(StoreProductID.allCases.map(\.rawValue))
            let records = try await productLoader.loadProducts(identifiedBy: requestedIDs)
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
        let grouped = Dictionary(grouping: records, by: \.id)
        let expectedIDs = Set(StoreProductID.allCases.map(\.rawValue))
        guard Set(grouped.keys) == expectedIDs,
              grouped.values.allSatisfy({ $0.count == 1 }) else {
            throw StoreCatalogValidationError.productSetMismatch
        }

        let products = try StoreProductID.allCases.map { identifier in
            guard let record = grouped[identifier.rawValue]?.first,
                  record.isAutoRenewable,
                  !record.isFamilyShareable,
                  record.hasSubscriptionGroup,
                  record.subscriptionPeriod == identifier.expectedPeriod else {
                throw StoreCatalogValidationError.invalidSubscription(identifier.rawValue)
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
