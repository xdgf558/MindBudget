import Foundation
import StoreKit

struct VerifiedStoreTransaction: Equatable, Sendable {
    let productID: String
    let environment: StoreRuntimeEnvironment
    let isPurchased: Bool
    let isRevoked: Bool
    let expirationDate: Date?
}

struct StoreEntitlementRead: Equatable, Sendable {
    let transactions: [VerifiedStoreTransaction]
    let unverifiedCount: Int
}

enum StoreTransactionSignal: Sendable {
    case changed
}

protocol StoreEntitlementSourcing: Sendable {
    func currentEntitlements() async -> StoreEntitlementRead
    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async
}

struct StoreKitEntitlementSource: StoreEntitlementSourcing {
    func currentEntitlements() async -> StoreEntitlementRead {
        var transactions: [VerifiedStoreTransaction] = []
        var unverifiedCount = 0
        for await result in Transaction.currentEntitlements {
            switch result {
            case let .verified(transaction):
                transactions.append(verifiedRecord(from: transaction))
            case .unverified:
                unverifiedCount += 1
            }
        }
        return StoreEntitlementRead(
            transactions: transactions,
            unverifiedCount: unverifiedCount
        )
    }

    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async {
        for await _ in Transaction.updates {
            guard !Task.isCancelled else { return }
            // C2-02 treats the sequence only as a re-read signal. C2-03 owns verified
            // purchase/restore handling and the exact point at which a transaction is finished.
            await handler(.changed)
        }
    }

    private func verifiedRecord(from transaction: Transaction) -> VerifiedStoreTransaction {
        VerifiedStoreTransaction(
            productID: transaction.productID,
            environment: StoreRuntimeEnvironment(rawValue: transaction.environment.rawValue),
            isPurchased: transaction.ownershipType == .purchased,
            isRevoked: transaction.revocationDate != nil,
            expirationDate: transaction.expirationDate
        )
    }
}

struct EntitlementLifecycleSnapshot: Equatable, Sendable {
    let premiumEntryAccess: ExistingPremiumEntryAccess
    let environment: StoreRuntimeEnvironment?
    let unverifiedCount: Int
}

/// The sole runtime authority for the StoreKit entitlement lifecycle.
///
/// It persists no commercial right, starts exactly one updates task, and always re-reads current
/// verified StoreKit state after a signal instead of trusting the signal as an authorization.
actor EntitlementStore {
    typealias ChangeHandler = @MainActor @Sendable (EntitlementLifecycleSnapshot) -> Void

    private let source: any StoreEntitlementSourcing
    private let featureAccessAuthority: LiveFeatureAccessAuthority
    private var listenerTask: Task<Void, Never>?
    private var reconciliationGeneration = 0
    private var changeHandler: ChangeHandler?
    private var snapshot = EntitlementLifecycleSnapshot(
        premiumEntryAccess: ExistingPremiumEntryAccess(),
        environment: nil,
        unverifiedCount: 0
    )

    init(
        source: any StoreEntitlementSourcing = StoreKitEntitlementSource(),
        featureAccessAuthority: LiveFeatureAccessAuthority
    ) {
        self.source = source
        self.featureAccessAuthority = featureAccessAuthority
    }

    deinit {
        listenerTask?.cancel()
    }

    func start(onChange: ChangeHandler? = nil) async {
        if let onChange {
            changeHandler = onChange
        }
        guard listenerTask == nil else { return }
        let source = source
        listenerTask = Task { [weak self] in
            await source.listenForUpdates { [weak self] _ in
                await self?.reconcile()
            }
        }
        await reconcile()
    }

    func stop() {
        listenerTask?.cancel()
        listenerTask = nil
        reconciliationGeneration += 1
    }

    func currentSnapshot() -> EntitlementLifecycleSnapshot {
        snapshot
    }

    private func reconcile() async {
        reconciliationGeneration += 1
        let generation = reconciliationGeneration
        let read = await source.currentEntitlements()
        guard generation == reconciliationGeneration else { return }
        // `currentEntitlements` can include a subscription in billing grace after its last
        // successful renewal expiration date. C2-02 therefore preserves expiration as an input
        // fact but must not decide subscription status here. C2-03 owns the complete
        // subscribed/grace/retry/expired mapping.
        let purchasedUnrevoked = read.transactions.filter { transaction in
            transaction.isPurchased && !transaction.isRevoked
        }
        let hasUnacceptedAuthorityInput = read.unverifiedCount > 0
            || purchasedUnrevoked.contains { transaction in
                !transaction.environment.isRecognizedStoreEnvironment
                    || StoreProductID(rawValue: transaction.productID) == nil
            }
        let accepted = hasUnacceptedAuthorityInput ? [] : purchasedUnrevoked
        let environments = Set(accepted.map(\.environment))
        let environment = environments.count == 1 ? environments.first : nil
        let entitlements: EntitlementSet
        if let environment {
            entitlements = EntitlementSet.union(
                accepted
                    .filter { $0.environment == environment }
                    .compactMap { StoreProductID(rawValue: $0.productID)?.entitlement }
            )
        } else {
            entitlements = .free
        }

        featureAccessAuthority.replaceEntitlements(entitlements)
        snapshot = EntitlementLifecycleSnapshot(
            premiumEntryAccess: ExistingPremiumEntryAccess(
                featureAccess: FeatureAccessService(entitlements: entitlements)
            ),
            environment: environment,
            unverifiedCount: read.unverifiedCount
        )
        if let changeHandler {
            await changeHandler(snapshot)
        }
    }
}
