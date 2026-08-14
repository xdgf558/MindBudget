import Foundation
import StoreKit

enum StoreSubscriptionState: Equatable, Hashable, Sendable {
    case subscribed
    case inGracePeriod
    case inBillingRetryPeriod
    case expired
    case revoked
    case unknown
}

enum EffectiveStoreSubscriptionState: Equatable, Sendable {
    case none
    case subscribed
    case inGracePeriod
    case inBillingRetryPeriod
    case expired
    case revoked
    case unavailable
}

struct VerifiedStoreTransaction: Equatable, Sendable {
    let transactionID: UInt64
    let productID: String
    let environment: StoreRuntimeEnvironment
    let isPurchased: Bool
    let isRevoked: Bool
    let expirationDate: Date?
    let subscriptionState: StoreSubscriptionState
    let hasVerifiedStatusTransaction: Bool
    let hasVerifiedRenewalInfo: Bool
    let hasVerifiedAppBundle: Bool
}

struct FinishableStoreTransaction: Sendable {
    /// The transaction StoreKit expects this process to acknowledge.
    let acknowledgementID: UInt64
    /// The product on the verified transaction StoreKit expects this process to acknowledge.
    ///
    /// During a same-group crossgrade this can differ from `facts.productID`: the acknowledged
    /// transaction identifies the requested next product while the verified subscription status
    /// still identifies the product that remains active until the next renewal.
    let acknowledgementProductID: String
    let facts: VerifiedStoreTransaction
    private let finishAction: @Sendable () async -> Bool

    init(
        acknowledgementID: UInt64? = nil,
        acknowledgementProductID: String? = nil,
        facts: VerifiedStoreTransaction,
        finishAction: @Sendable @escaping () async -> Bool
    ) {
        self.acknowledgementID = acknowledgementID ?? facts.transactionID
        self.acknowledgementProductID = acknowledgementProductID ?? facts.productID
        self.facts = facts
        self.finishAction = finishAction
    }

    func finish() async -> Bool {
        await finishAction()
    }
}

struct StoreEntitlementRead: Equatable, Sendable {
    let transactions: [VerifiedStoreTransaction]
    let unverifiedCount: Int
    let isComplete: Bool
    /// Environment from the separately verified `AppTransaction` for this app bundle.
    /// A transaction environment is never allowed to select this value for itself.
    let appEnvironment: StoreRuntimeEnvironment?

    init(
        transactions: [VerifiedStoreTransaction],
        unverifiedCount: Int,
        isComplete: Bool = true,
        appEnvironment: StoreRuntimeEnvironment?
    ) {
        self.transactions = transactions
        self.unverifiedCount = unverifiedCount
        self.isComplete = isComplete
        self.appEnvironment = appEnvironment
    }
}

struct StoreUnfinishedTransactionRead: Sendable {
    let transactions: [FinishableStoreTransaction]
    let unverifiedCount: Int
}

/// Combines independently verified StoreKit reads without guessing which conflicting fact won a
/// race between two suspension points. Stable duplicates collapse; a changed fact for the same
/// transaction makes the whole read incomplete so the mapper fails closed.
struct StoreEntitlementReadMerger: Sendable {
    func merge(
        current: StoreEntitlementRead,
        supplemental: StoreEntitlementRead
    ) -> StoreEntitlementRead {
        var byID: [UInt64: VerifiedStoreTransaction] = [:]
        var hasConflict = false
        for transaction in supplemental.transactions + current.transactions {
            if let existing = byID[transaction.transactionID], existing != transaction {
                hasConflict = true
            } else {
                byID[transaction.transactionID] = transaction
            }
        }
        return StoreEntitlementRead(
            transactions: hasConflict ? [] : Array(byID.values),
            unverifiedCount: current.unverifiedCount + supplemental.unverifiedCount,
            isComplete: current.isComplete
                && supplemental.isComplete
                && !hasConflict
                && current.appEnvironment == supplemental.appEnvironment,
            appEnvironment: current.appEnvironment == supplemental.appEnvironment
                ? current.appEnvironment
                : nil
        )
    }
}

enum StoreTransactionSignal: Sendable {
    case verified(FinishableStoreTransaction)
    case unverified
    case changed
}

enum StorePurchaseResult: Sendable {
    case verified(FinishableStoreTransaction)
    case unverified
    case pending
    case userCancelled
}

enum StoreOperationFailure: Equatable, Sendable {
    case operationInProgress
    case productUnavailable
    case purchasesNotAllowed
    case verificationFailed
    case invalidStoreState
    case unavailable
}

enum StorePurchaseOutcome: Equatable, Sendable {
    case purchased
    case pending
    case cancelled
    case failed(StoreOperationFailure)
}

enum StoreRestoreOutcome: Equatable, Sendable {
    case restored
    case noActiveSubscription
    case failed(StoreOperationFailure)
}

protocol StoreEntitlementSourcing: Sendable {
    /// The separately verified `AppTransaction` environment for the expected app bundle.
    /// Purchase validation must use this authority instead of deriving an app environment from
    /// the transaction being validated.
    func currentAppEnvironment() async -> StoreRuntimeEnvironment?
    func currentEntitlements() async -> StoreEntitlementRead
    func unfinishedTransactions() async -> StoreUnfinishedTransactionRead
    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async

    @MainActor
    func purchase(_ productID: StoreProductID) async throws -> StorePurchaseResult

    func synchronizePurchases() async throws
}

struct StoreKitEntitlementSource: StoreEntitlementSourcing {
    private let expectedBundleID: String
    private let appEnvironmentProvider: any StoreAppEnvironmentProviding

    init(expectedBundleID: String = Bundle.main.bundleIdentifier ?? "") {
        self.expectedBundleID = expectedBundleID
        self.appEnvironmentProvider = StoreKitAppEnvironmentProvider(
            expectedBundleID: expectedBundleID
        )
    }

    func currentAppEnvironment() async -> StoreRuntimeEnvironment? {
        await appEnvironmentProvider.currentEnvironment()
    }

    func currentEntitlements() async -> StoreEntitlementRead {
        guard let appEnvironment = await appEnvironmentProvider.currentEnvironment() else {
            return StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                isComplete: false,
                appEnvironment: nil
            )
        }
        let current = await read(
            Transaction.currentEntitlements,
            appEnvironment: appEnvironment
        )
        let supplemental = await readSubscriptionStatuses(appEnvironment: appEnvironment)
        return StoreEntitlementReadMerger().merge(
            current: current,
            supplemental: supplemental
        )
    }

    func unfinishedTransactions() async -> StoreUnfinishedTransactionRead {
        var transactions: [FinishableStoreTransaction] = []
        var unverifiedCount = 0
        for await result in Transaction.unfinished {
            switch result {
            case let .verified(transaction):
                transactions.append(await finishableTransaction(from: transaction))
            case .unverified:
                unverifiedCount += 1
            }
        }
        return StoreUnfinishedTransactionRead(
            transactions: transactions,
            unverifiedCount: unverifiedCount
        )
    }

    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async {
        // One lifecycle owner supervises both StoreKit sequences. A failed renewal can move a
        // subscription into retry or expiry without producing a new transaction, so transaction
        // updates alone cannot revoke access promptly. Status changes are signals only: the actor
        // always performs a fresh, fully verified whole-authority reconciliation.
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { return }
                    switch result {
                    case let .verified(transaction):
                        await handler(.verified(await finishableTransaction(from: transaction)))
                    case .unverified:
                        await handler(.unverified)
                    }
                }
            }
            group.addTask {
                for await _ in Product.SubscriptionInfo.Status.updates {
                    guard !Task.isCancelled else { return }
                    await handler(.changed)
                }
            }
            await group.waitForAll()
        }
    }

    @MainActor
    func purchase(_ productID: StoreProductID) async throws -> StorePurchaseResult {
        guard await appEnvironmentProvider.currentEnvironment() != nil else {
            throw StoreCommerceSourceError.invalidEnvironment
        }
        guard AppStore.canMakePayments else {
            throw StoreCommerceSourceError.purchasesNotAllowed
        }
        let products = try await Product.products(for: StoreCatalogContract.expectedProductIDs)
        let records = products.map(StoreProductRecord.init(product:))
        do {
            _ = try StoreCatalogContract.validatedRecord(for: productID, in: records)
        } catch {
            throw StoreCommerceSourceError.invalidProduct
        }
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            throw StoreCommerceSourceError.invalidProduct
        }

        do {
            switch try await product.purchase() {
            case let .success(.verified(transaction)):
                guard transaction.productID == productID.rawValue else {
                    throw StoreCommerceSourceError.invalidProduct
                }
                return .verified(await finishableTransaction(from: transaction))
            case .success(.unverified):
                return .unverified
            case .pending:
                return .pending
            case .userCancelled:
                return .userCancelled
            @unknown default:
                throw StoreCommerceSourceError.invalidProduct
            }
        } catch Product.PurchaseError.productUnavailable {
            throw StoreCommerceSourceError.invalidProduct
        } catch Product.PurchaseError.purchaseNotAllowed {
            throw StoreCommerceSourceError.purchasesNotAllowed
        }
    }

    func synchronizePurchases() async throws {
        guard await appEnvironmentProvider.currentEnvironment() != nil else {
            throw StoreCommerceSourceError.invalidEnvironment
        }
        try await AppStore.sync()
    }

    private func read(
        _ transactions: Transaction.Transactions,
        appEnvironment: StoreRuntimeEnvironment
    ) async -> StoreEntitlementRead {
        var verified: [VerifiedStoreTransaction] = []
        var unverifiedCount = 0
        for await result in transactions {
            switch result {
            case let .verified(transaction):
                verified.append(await verifiedRecord(from: transaction))
            case .unverified:
                unverifiedCount += 1
            }
        }
        return StoreEntitlementRead(
            transactions: verified,
            unverifiedCount: unverifiedCount,
            isComplete: true,
            appEnvironment: appEnvironment
        )
    }

    /// Reads the full renewal-state surface so retry, expiry, and revocation remain visible after
    /// they leave `Transaction.currentEntitlements`. Catalog failure never invents a no-purchase
    /// answer; the mapper may still preserve an independently verified active entitlement.
    private func readSubscriptionStatuses(
        appEnvironment: StoreRuntimeEnvironment
    ) async -> StoreEntitlementRead {
        do {
            let products = try await Product.products(
                for: StoreCatalogContract.expectedProductIDs
            )
            let records = products.map(StoreProductRecord.init(product:))
            guard let validated = try? StoreCatalogContract.validate(records) else {
                return StoreEntitlementRead(
                    transactions: [],
                    unverifiedCount: 0,
                    isComplete: false,
                    appEnvironment: appEnvironment
                )
            }

            var byID: [UInt64: VerifiedStoreTransaction] = [:]
            var unverifiedCount = 0
            let subscriptionGroupIDs = Set(validated.values.compactMap(\.subscriptionGroupID))
            guard subscriptionGroupIDs.count == 1 else {
                return StoreEntitlementRead(
                    transactions: [],
                    unverifiedCount: 0,
                    isComplete: false,
                    appEnvironment: appEnvironment
                )
            }
            for groupID in subscriptionGroupIDs {
                for status in try await Product.SubscriptionInfo.status(for: groupID) {
                    switch status.transaction {
                    case let .verified(transaction):
                        let record = verifiedRecord(from: transaction, status: status)
                        if let existing = byID[record.transactionID], existing != record {
                            return StoreEntitlementRead(
                                transactions: [],
                                unverifiedCount: 0,
                                isComplete: false,
                                appEnvironment: appEnvironment
                            )
                        }
                        byID[record.transactionID] = record
                    case .unverified:
                        unverifiedCount += 1
                    }
                }
            }
            return StoreEntitlementRead(
                transactions: Array(byID.values),
                unverifiedCount: unverifiedCount,
                isComplete: true,
                appEnvironment: appEnvironment
            )
        } catch {
            return StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                isComplete: false,
                appEnvironment: appEnvironment
            )
        }
    }

    private func finishableTransaction(
        from transaction: Transaction
    ) async -> FinishableStoreTransaction {
        let facts = await verifiedRecord(from: transaction)
        return FinishableStoreTransaction(
            acknowledgementID: transaction.id,
            acknowledgementProductID: transaction.productID,
            facts: facts
        ) {
            await transaction.finish()
            return true
        }
    }

    private func verifiedRecord(from transaction: Transaction) async -> VerifiedStoreTransaction {
        guard let status = await transaction.subscriptionStatus else {
            return unverifiedRecord(from: transaction)
        }
        return verifiedRecord(from: transaction, status: status)
    }

    private func verifiedRecord(
        from handledTransaction: Transaction,
        status: Product.SubscriptionInfo.Status
    ) -> VerifiedStoreTransaction {
        let state = mappedState(status.state)
        let statusTransaction: Transaction?
        let hasVerifiedStatusTransaction: Bool
        let hasVerifiedRenewalInfo: Bool

        switch status.transaction {
        case let .verified(value):
            statusTransaction = value
            hasVerifiedStatusTransaction = StoreProductID(
                rawValue: handledTransaction.productID
            ) != nil
                && handledTransaction.appBundleID == expectedBundleID
                && handledTransaction.ownershipType == .purchased
                && value.originalID == handledTransaction.originalID
                && StoreProductID(rawValue: value.productID) != nil
                && value.appBundleID == expectedBundleID
                && value.environment == handledTransaction.environment
        case .unverified:
            statusTransaction = nil
            hasVerifiedStatusTransaction = false
        }

        switch status.renewalInfo {
        case let .verified(value):
            // A same-group crossgrade can remain on the current product until renewal. In that
            // case StoreKit proves the handled product through `autoRenewPreference` rather than
            // by replacing `currentProductID` immediately.
            let handledProductBelongsToVerifiedChain =
                value.currentProductID == handledTransaction.productID
                || value.autoRenewPreference == handledTransaction.productID
            hasVerifiedRenewalInfo = value.originalTransactionID == handledTransaction.originalID
                && value.environment == handledTransaction.environment
                && StoreProductID(rawValue: value.currentProductID) != nil
                && statusTransaction?.productID == value.currentProductID
                && handledProductBelongsToVerifiedChain
        case .unverified:
            hasVerifiedRenewalInfo = false
        }

        let authoritativeTransaction = statusTransaction ?? handledTransaction
        return VerifiedStoreTransaction(
            transactionID: authoritativeTransaction.id,
            productID: authoritativeTransaction.productID,
            environment: StoreRuntimeEnvironment(rawValue: authoritativeTransaction.environment.rawValue),
            isPurchased: authoritativeTransaction.ownershipType == .purchased,
            isRevoked: authoritativeTransaction.revocationDate != nil || state == .revoked,
            expirationDate: authoritativeTransaction.expirationDate,
            subscriptionState: state,
            hasVerifiedStatusTransaction: hasVerifiedStatusTransaction,
            hasVerifiedRenewalInfo: hasVerifiedRenewalInfo,
            hasVerifiedAppBundle: handledTransaction.appBundleID == expectedBundleID
                && authoritativeTransaction.appBundleID == expectedBundleID
        )
    }

    private func unverifiedRecord(from transaction: Transaction) -> VerifiedStoreTransaction {
        VerifiedStoreTransaction(
            transactionID: transaction.id,
            productID: transaction.productID,
            environment: StoreRuntimeEnvironment(rawValue: transaction.environment.rawValue),
            isPurchased: transaction.ownershipType == .purchased,
            isRevoked: transaction.revocationDate != nil,
            expirationDate: transaction.expirationDate,
            subscriptionState: .unknown,
            hasVerifiedStatusTransaction: false,
            hasVerifiedRenewalInfo: false,
            hasVerifiedAppBundle: false
        )
    }

    private func mappedState(
        _ state: Product.SubscriptionInfo.RenewalState
    ) -> StoreSubscriptionState {
        if state == .subscribed { return .subscribed }
        if state == .inGracePeriod { return .inGracePeriod }
        if state == .inBillingRetryPeriod { return .inBillingRetryPeriod }
        if state == .expired { return .expired }
        if state == .revoked { return .revoked }
        return .unknown
    }
}

enum StoreCommerceSourceError: Error, Equatable, Sendable {
    case invalidProduct
    case purchasesNotAllowed
    case invalidEnvironment
}

struct SubscriptionStatusResolution: Equatable, Sendable {
    let entitlements: EntitlementSet
    let environment: StoreRuntimeEnvironment?
    /// Whether this whole-snapshot decision is safe to act on.
    ///
    /// This does not mean every presentation/catalog input was complete. A separately verified
    /// active subscription remains actionable when only the supplemental Product read fails;
    /// incomplete Free or unverified authority still fails closed.
    let isActionable: Bool
    let effectiveState: EffectiveStoreSubscriptionState
    let observedStates: Set<StoreSubscriptionState>
    let activeTransactionIDs: Set<UInt64>

    static let failedClosed = SubscriptionStatusResolution(
        entitlements: .free,
        environment: nil,
        isActionable: false,
        effectiveState: .unavailable,
        observedStates: [],
        activeTransactionIDs: []
    )

    var hasActiveSubscription: Bool {
        !entitlements.isFree
    }
}

/// The sole interpreter of StoreKit subscription state.
///
/// Expiration is retained as a raw diagnostic fact. It never infers grace: only StoreKit's
/// verified renewal state can distinguish billing grace from retry or expiry.
struct SubscriptionStatusMapper: Sendable {
    func resolve(_ read: StoreEntitlementRead) -> SubscriptionStatusResolution {
        guard read.unverifiedCount == 0,
              let appEnvironment = read.appEnvironment,
              appEnvironment.isRecognizedStoreEnvironment else {
            return .failedClosed
        }

        var environments: Set<StoreRuntimeEnvironment> = []
        var grantedEntitlements: [EntitlementSet] = []
        var observedStates: [StoreSubscriptionState] = []
        var activeTransactionIDs: Set<UInt64> = []

        for transaction in read.transactions {
            guard transaction.environment.isRecognizedStoreEnvironment,
                  let productID = StoreProductID(rawValue: transaction.productID),
                  transaction.isPurchased,
                  transaction.hasVerifiedStatusTransaction,
                  transaction.hasVerifiedRenewalInfo,
                  transaction.hasVerifiedAppBundle,
                  transaction.environment == appEnvironment,
                  transaction.subscriptionState != .unknown else {
                return .failedClosed
            }
            environments.insert(transaction.environment)

            if transaction.isRevoked {
                observedStates.append(.revoked)
                continue
            }
            observedStates.append(transaction.subscriptionState)
            switch transaction.subscriptionState {
            case .subscribed, .inGracePeriod:
                grantedEntitlements.append(productID.entitlement)
                activeTransactionIDs.insert(transaction.transactionID)
            case .inBillingRetryPeriod, .expired, .revoked:
                break
            case .unknown:
                return .failedClosed
            }
        }

        guard environments.count <= 1 else { return .failedClosed }
        let entitlements = EntitlementSet.union(grantedEntitlements)
        guard read.isComplete || !entitlements.isFree else { return .failedClosed }
        return SubscriptionStatusResolution(
            entitlements: entitlements,
            environment: entitlements.isFree ? nil : environments.first,
            isActionable: true,
            effectiveState: effectiveState(for: observedStates),
            observedStates: Set(observedStates),
            activeTransactionIDs: activeTransactionIDs
        )
    }

    private func effectiveState(
        for states: [StoreSubscriptionState]
    ) -> EffectiveStoreSubscriptionState {
        if states.contains(.subscribed) { return .subscribed }
        if states.contains(.inGracePeriod) { return .inGracePeriod }
        if states.contains(.inBillingRetryPeriod) { return .inBillingRetryPeriod }
        if states.contains(.expired) { return .expired }
        if states.contains(.revoked) { return .revoked }
        return .none
    }
}

struct EntitlementLifecycleSnapshot: Equatable, Sendable {
    let premiumEntryAccess: ExistingPremiumEntryAccess
    let environment: StoreRuntimeEnvironment?
    let unverifiedCount: Int
    let effectiveState: EffectiveStoreSubscriptionState
    let observedStates: Set<StoreSubscriptionState>
}

/// The sole runtime authority for the StoreKit entitlement lifecycle.
///
/// It persists no commercial right, starts exactly one lifecycle task supervising StoreKit's
/// transaction and subscription-status sequences, and always reconciles current status with a
/// verified handled transaction before authorizing or finishing it.
actor EntitlementStore {
    typealias ChangeHandler = @MainActor @Sendable (EntitlementLifecycleSnapshot) async -> Void
    typealias TransactionBatchWaitHandler = @Sendable (Set<UInt64>) async -> Void

    private let source: any StoreEntitlementSourcing
    private let featureAccessAuthority: LiveFeatureAccessAuthority
    private let statusMapper: SubscriptionStatusMapper
    private let transactionBatchWaitHandler: TransactionBatchWaitHandler?
    private var listenerTask: Task<Void, Never>?

    // Concurrency invariants (all state below is actor-isolated):
    //
    // 1. Reconciliation generation is the whole-snapshot publication order. Starting a newer
    //    reconciliation invalidates an older return value; waiters may accept only the current
    //    generation's actionable resolution. Publishing Free/unavailable therefore cannot be
    //    overwritten by a suspended older read or purchase callback.
    // 2. At most one verified transaction batch owns acknowledgement IDs at a time. A conflicting
    //    identity invalidates that batch; a disjoint signal waits and then reconciles both sets of
    //    verified facts. An acknowledgement enters `finishedTransactionIDs` only after an
    //    actionable snapshot was published and `finish()` succeeded, so failure remains retryable.
    // 3. Transaction-signal sequence is restore provenance, not entitlement authority. Only a
    //    verified transaction signal that completed the same reconciliation/finish path may bridge
    //    the short post-`AppStore.sync()` current-read lag. Status-only/foreground refreshes never
    //    satisfy restore, and a newer revocation/unverified generation rejects stale bridge facts.
    // 4. Every continuation is resumed when its owned generation/signal completes or the store
    //    stops. `StoreLifecycleDomainTests` injects gates at publish, finish, sync, and active-batch
    //    wait points to exercise these cross-state-machine orderings rather than relying on random
    //    task scheduling. `StoreRuntimeTests` separately owns the out-of-order whole-read seam.
    private var reconciliationGeneration = 0
    private var inFlightReconciliationGenerations: Set<Int> = []
    private var reconciliationWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private var changeHandler: ChangeHandler?
    private var finishedTransactionIDs: Set<UInt64> = []
    private var activeTransactionBatch: ActiveTransactionBatch?
    private var invalidatedTransactionBatchTokens: Set<UUID> = []
    private var commerceOperationInProgress = false
    private var latestResolution: SubscriptionStatusResolution?
    private var latestResolutionGeneration: Int?
    private var transactionSignalSequence = 0
    private var completedTransactionSignalSequence = 0
    private var latestTransactionSignalEvidence: TransactionSignalEvidence?
    private var transactionSignalWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private var snapshot = EntitlementLifecycleSnapshot(
        premiumEntryAccess: ExistingPremiumEntryAccess(),
        environment: nil,
        unverifiedCount: 0,
        effectiveState: .none,
        observedStates: []
    )

    init(
        source: any StoreEntitlementSourcing = StoreKitEntitlementSource(),
        featureAccessAuthority: LiveFeatureAccessAuthority,
        statusMapper: SubscriptionStatusMapper = SubscriptionStatusMapper(),
        transactionBatchWaitHandler: TransactionBatchWaitHandler? = nil
    ) {
        self.source = source
        self.featureAccessAuthority = featureAccessAuthority
        self.statusMapper = statusMapper
        self.transactionBatchWaitHandler = transactionBatchWaitHandler
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
            await source.listenForUpdates { [weak self] signal in
                await self?.handle(signal)
            }
        }
        _ = await reconcile()
        _ = await processUnfinishedTransactions()
    }

    func stop() {
        listenerTask?.cancel()
        listenerTask = nil
        reconciliationGeneration += 1
        resumeAllReconciliationWaiters()
    }

    func currentSnapshot() -> EntitlementLifecycleSnapshot {
        snapshot
    }

    /// Revalidates StoreKit authority when the app returns to the foreground. Status/update
    /// sequences remain the primary live signal, while this fresh read closes any suspension gap
    /// without restoring from cache or presenting StoreKit UI.
    func refreshCurrentEntitlements() async {
        _ = await reconcile()
    }

    /// Performs a purchase only after an explicit caller action. No launch path calls this API.
    func purchase(_ productID: StoreProductID) async -> StorePurchaseOutcome {
        guard !commerceOperationInProgress else {
            return .failed(.operationInProgress)
        }
        commerceOperationInProgress = true
        defer { commerceOperationInProgress = false }

        // A live product catalog is presentation evidence, not entitlement authority. Re-read the
        // complete StoreKit authority before presenting a purchase so `.unavailable` can never be
        // treated as confirmed Free. The post-purchase reconciliation below remains the final
        // authority for granting access and acknowledging the transaction.
        guard let purchaseAuthority = await reconcile(), purchaseAuthority.isActionable else {
            return .failed(.invalidStoreState)
        }

        do {
            switch try await source.purchase(productID) {
            case let .verified(transaction):
                guard transaction.acknowledgementProductID == productID.rawValue else {
                    return .failed(.invalidStoreState)
                }
                guard let appEnvironment = await source.currentAppEnvironment() else {
                    return .failed(.invalidStoreState)
                }
                let handledResolution = statusMapper.resolve(
                    StoreEntitlementRead(
                        transactions: [transaction.facts],
                        unverifiedCount: 0,
                        appEnvironment: appEnvironment
                    )
                )
                guard handledResolution.hasActiveSubscription else {
                    return .failed(.invalidStoreState)
                }
                guard let resolution = await processVerifiedTransactions([transaction]),
                      resolution.activeTransactionIDs.contains(transaction.facts.transactionID) else {
                    return .failed(.invalidStoreState)
                }
                return .purchased
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            case .unverified:
                // The attempted transaction grants nothing. A separately verified existing
                // subscription remains governed by a fresh authoritative reconciliation.
                _ = await reconcile()
                return .failed(.verificationFailed)
            }
        } catch StoreCommerceSourceError.invalidProduct {
            return .failed(.productUnavailable)
        } catch StoreCommerceSourceError.purchasesNotAllowed {
            return .failed(.purchasesNotAllowed)
        } catch StoreCommerceSourceError.invalidEnvironment {
            return .failed(.verificationFailed)
        } catch {
            return .failed(.unavailable)
        }
    }

    /// Calls `AppStore.sync()` only from an explicit user-triggered restore action.
    func restorePurchases() async -> StoreRestoreOutcome {
        guard !commerceOperationInProgress else {
            return .failed(.operationInProgress)
        }
        commerceOperationInProgress = true
        defer { commerceOperationInProgress = false }

        do {
            let transactionSignalSequenceBeforeSynchronization = transactionSignalSequence
            try await source.synchronizePurchases()
            let resolution: SubscriptionStatusResolution
            switch await processUnfinishedTransactions() {
            case .failed:
                return .failed(.verificationFailed)
            case let .resolved(unfinishedResolution):
                resolution = unfinishedResolution
            case .none:
                let synchronizedTransaction = await transactionSignalEvidence(
                    after: transactionSignalSequenceBeforeSynchronization
                )
                if synchronizedTransaction.didObserve {
                    switch synchronizedTransaction.evidence {
                    case let .active(facts):
                        guard let synchronizedResolution = await reconcile(including: facts),
                              synchronizedResolution.isActionable else {
                            return .failed(.verificationFailed)
                        }
                        resolution = synchronizedResolution
                    case .noActiveBridge:
                        guard let currentResolution = await reconcile(),
                              currentResolution.isActionable else {
                            return .failed(.invalidStoreState)
                        }
                        resolution = currentResolution
                    case .failed, nil:
                        return .failed(.verificationFailed)
                    }
                } else {
                    guard let currentResolution = await reconcile(),
                          currentResolution.isActionable else {
                        return .failed(.invalidStoreState)
                    }
                    resolution = currentResolution
                }
            }
            return resolution.hasActiveSubscription ? .restored : .noActiveSubscription
        } catch StoreCommerceSourceError.invalidEnvironment {
            return .failed(.verificationFailed)
        } catch {
            return .failed(.unavailable)
        }
    }

    private func handle(_ signal: StoreTransactionSignal) async {
        switch signal {
        case let .verified(transaction):
            let sequence = beginTransactionSignal()
            let resolution = await processVerifiedTransactions([transaction])
            let evidence: TransactionSignalEvidence
            if let resolution,
               resolution.activeTransactionIDs.contains(transaction.facts.transactionID) {
                evidence = .active([transaction.facts])
            } else if resolution != nil {
                evidence = .noActiveBridge
            } else {
                evidence = .failed
            }
            completeTransactionSignal(
                sequence,
                evidence: evidence
            )
        case .unverified:
            let sequence = beginTransactionSignal()
            reconciliationGeneration += 1
            await publish(.failedClosed, unverifiedCount: 1)
            completeTransactionSignal(sequence, evidence: .failed)
        case .changed:
            _ = await reconcile()
        }
    }

    @discardableResult
    private func processUnfinishedTransactions() async -> UnfinishedTransactionResolution {
        let unfinished = await source.unfinishedTransactions()
        guard unfinished.unverifiedCount == 0 else {
            reconciliationGeneration += 1
            await publish(.failedClosed, unverifiedCount: unfinished.unverifiedCount)
            return .failed
        }
        guard !unfinished.transactions.isEmpty else { return .none }
        guard let resolution = await processVerifiedTransactions(unfinished.transactions) else {
            return .failed
        }
        return .resolved(resolution)
    }

    /// Publishes the fully reconciled authority before acknowledging each handled transaction.
    private func processVerifiedTransactions(
        _ transactions: [FinishableStoreTransaction]
    ) async -> SubscriptionStatusResolution? {
        var uniqueTransactions: [UInt64: FinishableStoreTransaction] = [:]
        for transaction in transactions {
            let id = transaction.acknowledgementID
            if let existing = uniqueTransactions[id],
               existing.acknowledgementProductID != transaction.acknowledgementProductID
                   || existing.facts != transaction.facts {
                reconciliationGeneration += 1
                await publish(.failedClosed, unverifiedCount: 0)
                return nil
            }
            uniqueTransactions[id] = transaction
        }

        // A single StoreKit delivery has no trustworthy ordering between distinct
        // acknowledgements. If two envelopes project different facts for the same subscription
        // transaction, reject the whole batch before publishing or finishing either one.
        let batchFacts = uniqueTransactions.values.map(\.facts)
        let batchRead = StoreEntitlementReadMerger().merge(
            current: StoreEntitlementRead(
                transactions: [],
                unverifiedCount: 0,
                appEnvironment: nil
            ),
            supplemental: StoreEntitlementRead(
                transactions: batchFacts,
                unverifiedCount: 0,
                appEnvironment: nil
            )
        )
        guard batchRead.isComplete else {
            reconciliationGeneration += 1
            await publish(.failedClosed, unverifiedCount: 0)
            return nil
        }

        var waitedForMatchingBatch = false
        var waitedResolution: SubscriptionStatusResolution?
        var bridgeFacts: [VerifiedStoreTransaction] = []
        while let activeTransactionBatch {
            let incomingIDs = Set(uniqueTransactions.keys)
            let activeIDs = Set(activeTransactionBatch.identityByAcknowledgementID.keys)
            let conflictingIDs: Set<UInt64> = Set(uniqueTransactions.compactMap { id, transaction in
                let incomingIdentity = StoreTransactionIdentity(transaction)
                guard let activeIdentity = activeTransactionBatch.identityByAcknowledgementID[id],
                      activeIdentity != incomingIdentity else {
                    return nil
                }
                return id
            })
            guard conflictingIDs.isEmpty else {
                // The same StoreKit acknowledgement cannot represent two different verified
                // fact sets. Invalidate the older batch before it can report success and wait for
                // a later authoritative read instead of briefly retaining stale Pro access.
                invalidatedTransactionBatchTokens.insert(activeTransactionBatch.token)
                reconciliationGeneration += 1
                await publish(.failedClosed, unverifiedCount: 0)
                return nil
            }
            let incomingBelongsToActiveBatch = incomingIDs.isSubset(of: activeIDs)
            await transactionBatchWaitHandler?(incomingIDs)
            let completedBatch = await activeTransactionBatch.task.value
            let activeResolution: SubscriptionStatusResolution?
            if let completedBatch {
                activeResolution = await validatedResolution(after: completedBatch)
            } else {
                activeResolution = nil
            }
            if self.activeTransactionBatch?.token == activeTransactionBatch.token {
                self.activeTransactionBatch = nil
            }
            if let activeResolution {
                if incomingBelongsToActiveBatch {
                    waitedForMatchingBatch = true
                    waitedResolution = activeResolution
                } else {
                    // The completed batch may not be visible in `currentEntitlements` yet. Keep
                    // its already-verified status facts in the next whole-authority reconciliation
                    // so an unrelated update cannot temporarily erase the just-published right.
                    guard mergeBridgeFacts(
                        activeTransactionBatch.reconciliationFacts,
                        into: &bridgeFacts
                    ) else {
                        reconciliationGeneration += 1
                        await publish(.failedClosed, unverifiedCount: 0)
                        return nil
                    }
                }
            } else {
                let overlappingIDs = incomingIDs.intersection(activeIDs)
                // A duplicate inherits the owning batch's failure. An unrelated transaction is
                // still allowed to start its own batch instead of waiting for StoreKit to redeliver.
                guard overlappingIDs.isEmpty else { return nil }
            }
        }

        let pending = uniqueTransactions.values.filter {
            !finishedTransactionIDs.contains($0.acknowledgementID)
        }
        guard !pending.isEmpty else {
            if waitedForMatchingBatch {
                return waitedResolution
            }
            // StoreKit can redeliver an already-finished verified transaction before
            // `currentEntitlements` catches up. Re-validate the fresh payload so the duplicate
            // cannot temporarily revoke a just-published Pro entitlement; acknowledgement still
            // remains exactly once because `pending` is empty.
            guard mergeBridgeFacts(
                uniqueTransactions.values.map(\.facts),
                into: &bridgeFacts
            ) else {
                reconciliationGeneration += 1
                await publish(.failedClosed, unverifiedCount: 0)
                return nil
            }
            return await reconcile(including: bridgeFacts)
        }

        // Independent StoreKit reads can resume at the actor in a different order than the facts
        // were observed by the framework. Preserve unrelated verified facts, but reject any
        // disagreement for one subscription transaction instead of guessing which state is newer.
        guard mergeBridgeFacts(
            uniqueTransactions.values.map(\.facts),
            into: &bridgeFacts
        ) else {
            reconciliationGeneration += 1
            await publish(.failedClosed, unverifiedCount: 0)
            return nil
        }
        let reconciliationFacts = bridgeFacts
        let token = UUID()
        let identityByAcknowledgementID = Dictionary(
            uniqueKeysWithValues: pending.map {
                ($0.acknowledgementID, StoreTransactionIdentity($0))
            }
        )
        let task = Task { [pending, reconciliationFacts] in
            await self.performVerifiedTransactionBatch(
                pending,
                reconciliationFacts: reconciliationFacts,
                token: token
            )
        }
        activeTransactionBatch = ActiveTransactionBatch(
            token: token,
            identityByAcknowledgementID: identityByAcknowledgementID,
            reconciliationFacts: reconciliationFacts,
            task: task
        )
        let completedBatch = await task.value
        invalidatedTransactionBatchTokens.remove(token)
        if activeTransactionBatch?.token == token {
            activeTransactionBatch = nil
        }
        guard let completedBatch else { return nil }
        return await validatedResolution(after: completedBatch)
    }

    /// Merges independently verified facts without treating actor arrival order as StoreKit fact
    /// order. Stable duplicates collapse; every disagreement for one transaction fails closed.
    private func mergeBridgeFacts<S: Sequence>(
        _ incoming: S,
        into accumulated: inout [VerifiedStoreTransaction]
    ) -> Bool where S.Element == VerifiedStoreTransaction {
        var byID = Dictionary(uniqueKeysWithValues: accumulated.map { ($0.transactionID, $0) })
        for facts in incoming {
            guard let existing = byID[facts.transactionID] else {
                byID[facts.transactionID] = facts
                continue
            }
            guard existing != facts else { continue }
            return false
        }
        accumulated = Array(byID.values)
        return true
    }

    private func performVerifiedTransactionBatch(
        _ transactions: [FinishableStoreTransaction],
        reconciliationFacts: [VerifiedStoreTransaction],
        token: UUID
    ) async -> CompletedTransactionBatch? {
        guard !invalidatedTransactionBatchTokens.contains(token) else { return nil }
        guard let resolution = await reconcile(including: reconciliationFacts),
              resolution.isActionable,
              !invalidatedTransactionBatchTokens.contains(token) else {
            return nil
        }
        let reconciledGeneration = reconciliationGeneration

        for transaction in transactions {
            let id = transaction.acknowledgementID
            guard !finishedTransactionIDs.contains(id) else { continue }
            let finished = await transaction.finish()
            guard finished else { return nil }
            finishedTransactionIDs.insert(id)
            guard !invalidatedTransactionBatchTokens.contains(token) else { return nil }
        }
        // A status signal can legitimately publish a newer whole-authority snapshot while
        // `finish()` is suspended. Return the completed generation and let validatedResolution
        // accept only a latest authoritative snapshot; purchase additionally verifies that the
        // handled subscription transaction remains active.
        return CompletedTransactionBatch(
            resolution: resolution,
            generation: reconciledGeneration
        )
    }

    @discardableResult
    private func reconcile(
        including additionalTransactions: [VerifiedStoreTransaction] = []
    ) async -> SubscriptionStatusResolution? {
        reconciliationGeneration += 1
        let generation = reconciliationGeneration
        inFlightReconciliationGenerations.insert(generation)
        defer { completeReconciliationGeneration(generation) }
        var read = await source.currentEntitlements()
        guard generation == reconciliationGeneration else { return nil }

        if !additionalTransactions.isEmpty {
            // A handled payload only bridges the short window before StoreKit's current read
            // catches up. Both surfaces must still agree on every transaction identity; the same
            // StoreKit transaction ID carrying different product or status facts is an authority
            // conflict and fails the complete snapshot closed.
            read = StoreEntitlementReadMerger().merge(
                current: read,
                supplemental: StoreEntitlementRead(
                    transactions: additionalTransactions,
                    unverifiedCount: 0,
                    isComplete: true,
                    appEnvironment: read.appEnvironment
                )
            )
        }

        let resolution = statusMapper.resolve(read)
        await publish(resolution, unverifiedCount: read.unverifiedCount)
        guard generation == reconciliationGeneration else { return nil }
        return resolution
    }

    private func publish(
        _ resolution: SubscriptionStatusResolution,
        unverifiedCount: Int
    ) async {
        latestResolution = resolution
        latestResolutionGeneration = reconciliationGeneration
        featureAccessAuthority.replaceEntitlements(resolution.entitlements)
        snapshot = EntitlementLifecycleSnapshot(
            premiumEntryAccess: ExistingPremiumEntryAccess(
                featureAccess: FeatureAccessService(entitlements: resolution.entitlements)
            ),
            environment: resolution.environment,
            unverifiedCount: unverifiedCount,
            effectiveState: resolution.effectiveState,
            observedStates: resolution.observedStates
        )
        if let changeHandler {
            await changeHandler(snapshot)
        }
    }

    /// Returns the batch result when no newer authority was published, otherwise the latest
    /// authoritative whole snapshot. This lets an unrelated verified status update coexist with a
    /// completed purchase while still rejecting unverified, invalidated, or stopped generations.
    private func validatedResolution(
        after completedBatch: CompletedTransactionBatch
    ) async -> SubscriptionStatusResolution? {
        while true {
            if completedBatch.generation == reconciliationGeneration {
                return completedBatch.resolution
            }
            if latestResolutionGeneration == reconciliationGeneration {
                guard let latestResolution, latestResolution.isActionable else {
                    return nil
                }
                return latestResolution
            }

            // A different verified signal can begin a whole-authority reconciliation after this
            // batch finishes but before its owner resumes. Wait for that already-running read
            // instead of reporting a false purchase failure or cancelling the newer decision.
            let generation = reconciliationGeneration
            guard inFlightReconciliationGenerations.contains(generation) else { return nil }
            await waitForReconciliationGeneration(generation)
        }
    }

    private func beginTransactionSignal() -> Int {
        transactionSignalSequence += 1
        return transactionSignalSequence
    }

    private func completeTransactionSignal(
        _ sequence: Int,
        evidence: TransactionSignalEvidence
    ) {
        guard sequence >= completedTransactionSignalSequence else { return }
        completedTransactionSignalSequence = sequence
        latestTransactionSignalEvidence = evidence
        let completedWaiters = transactionSignalWaiters.keys.filter { $0 <= sequence }
        for completedSequence in completedWaiters {
            let waiters = transactionSignalWaiters.removeValue(forKey: completedSequence) ?? []
            for waiter in waiters {
                waiter.resume()
            }
        }
    }

    /// Only a transaction signal can bridge StoreKit's short post-sync current-read lag. A
    /// foreground refresh or status-only publication is not evidence that `AppStore.sync()`
    /// restored anything, so it must never replace the mandatory post-sync reconciliation.
    private func transactionSignalEvidence(
        after earlierSequence: Int
    ) async -> (didObserve: Bool, evidence: TransactionSignalEvidence?) {
        guard transactionSignalSequence > earlierSequence else {
            return (false, nil)
        }
        let targetSequence = transactionSignalSequence
        if completedTransactionSignalSequence < targetSequence {
            await withCheckedContinuation { continuation in
                transactionSignalWaiters[targetSequence, default: []].append(continuation)
            }
        }
        guard completedTransactionSignalSequence >= targetSequence else {
            return (true, nil)
        }
        return (true, latestTransactionSignalEvidence)
    }

    private func waitForReconciliationGeneration(_ generation: Int) async {
        guard inFlightReconciliationGenerations.contains(generation) else { return }
        await withCheckedContinuation { continuation in
            reconciliationWaiters[generation, default: []].append(continuation)
        }
    }

    private func completeReconciliationGeneration(_ generation: Int) {
        inFlightReconciliationGenerations.remove(generation)
        let waiters = reconciliationWaiters.removeValue(forKey: generation) ?? []
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func resumeAllReconciliationWaiters() {
        let waiters = reconciliationWaiters.values.flatMap { $0 }
        reconciliationWaiters.removeAll()
        inFlightReconciliationGenerations.removeAll()
        for waiter in waiters {
            waiter.resume()
        }
        let transactionWaiters = transactionSignalWaiters.values.flatMap { $0 }
        transactionSignalWaiters.removeAll()
        for waiter in transactionWaiters {
            waiter.resume()
        }
    }
}

private struct ActiveTransactionBatch {
    let token: UUID
    let identityByAcknowledgementID: [UInt64: StoreTransactionIdentity]
    let reconciliationFacts: [VerifiedStoreTransaction]
    let task: Task<CompletedTransactionBatch?, Never>
}

private struct CompletedTransactionBatch: Sendable {
    let resolution: SubscriptionStatusResolution
    let generation: Int
}

private struct StoreTransactionIdentity: Equatable, Sendable {
    let acknowledgementProductID: String
    let facts: VerifiedStoreTransaction

    init(_ transaction: FinishableStoreTransaction) {
        acknowledgementProductID = transaction.acknowledgementProductID
        facts = transaction.facts
    }
}

private enum UnfinishedTransactionResolution {
    case none
    case resolved(SubscriptionStatusResolution)
    case failed
}

private enum TransactionSignalEvidence {
    case active([VerifiedStoreTransaction])
    case noActiveBridge
    case failed
}
