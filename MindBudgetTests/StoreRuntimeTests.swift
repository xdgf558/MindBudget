import Foundation
import Testing
@testable import MindBudget

@Suite(.serialized)
struct StoreRuntimeTests {
    @Test
    func productFailureUsesOnlyAnExactEnvironmentAndStorefrontPresentationCache() async {
        let china = StoreCatalogContext(environment: .xcode, storefrontCountryCode: "CHN")
        let usa = StoreCatalogContext(environment: .xcode, storefrontCountryCode: "USA")
        let sandboxChina = StoreCatalogContext(environment: .sandbox, storefrontCountryCode: "CHN")
        let cache = TestStorePresentationCache()
        let liveCatalog = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: china),
            productLoader: TestStoreProductLoader(result: .success(validRecords())),
            presentationCache: cache
        )

        let live = await liveCatalog.refresh()
        #expect(live.snapshot?.context == china)
        #expect(live.snapshot?.products.count == 2)

        let failedSameContext = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: china),
            productLoader: TestStoreProductLoader(result: .failure(.loadFailed)),
            presentationCache: cache
        )
        guard case let .cached(cached) = await failedSameContext.refresh() else {
            Issue.record("An exact-context presentation cache should soften a product-load failure")
            return
        }
        #expect(cached.context == china)

        let failedOtherStorefront = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: usa),
            productLoader: TestStoreProductLoader(result: .failure(.loadFailed)),
            presentationCache: cache
        )
        #expect(await failedOtherStorefront.refresh() == .unavailable)

        let failedOtherEnvironment = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: sandboxChina),
            productLoader: TestStoreProductLoader(result: .failure(.loadFailed)),
            presentationCache: cache
        )
        #expect(await failedOtherEnvironment.refresh() == .unavailable)

        await liveCatalog.clearPresentationCache()
        #expect(await cache.load(for: china) == nil)
    }

    @Test
    func catalogRejectsPartialOrMalformedProductsInsteadOfInventingTerms() async {
        let context = StoreCatalogContext(environment: .xcode, storefrontCountryCode: "CHN")
        let cache = TestStorePresentationCache()
        let partial = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: context),
            productLoader: TestStoreProductLoader(
                result: .success(Array(validRecords().prefix(1)))
            ),
            presentationCache: cache
        )
        #expect(await partial.refresh() == .unavailable)

        var malformed = validRecords()
        malformed[0] = StoreProductRecord(
            id: malformed[0].id,
            displayName: malformed[0].displayName,
            description: malformed[0].description,
            displayPrice: malformed[0].displayPrice,
            isAutoRenewable: true,
            isFamilyShareable: true,
            hasSubscriptionGroup: true,
            subscriptionPeriod: malformed[0].subscriptionPeriod
        )
        let familyShared = StoreCatalog(
            contextProvider: FixedStoreContextProvider(context: context),
            productLoader: TestStoreProductLoader(result: .success(malformed)),
            presentationCache: cache
        )
        #expect(await familyShared.refresh() == .unavailable)
    }

    @Test
    func launchReconciliationUsesVerifiedCurrentStateAndNeverThePresentationCache() async {
        let authority = LiveFeatureAccessAuthority()
        let source = TestStoreEntitlementSource(
            read: paidRead(environment: .xcode)
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await store.start()
        #expect(authority.decision(for: .advancedSiri) == .allowed)
        #expect((await store.currentSnapshot()).environment == .xcode)
        await store.stop()
    }

    @Test
    func concurrentStartsOwnOneListenerAndUpdatesReconcileFromCurrentState() async {
        let authority = LiveFeatureAccessAuthority()
        let source = TestStoreEntitlementSource(
            read: StoreEntitlementRead(transactions: [], unverifiedCount: 0)
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<24 {
                group.addTask { await store.start() }
            }
        }
        await waitUntil { await source.listenerStartCount() == 1 }
        #expect(await source.listenerStartCount() == 1)
        #expect(authority.decision(for: .appleOnDeviceAI) == .requiresProSubscription)

        await source.setRead(paidRead(environment: .sandbox))
        source.sendUpdate()
        await waitUntil {
            authority.decision(for: .appleOnDeviceAI) == .allowed
        }
        #expect(authority.decision(for: .appleOnDeviceAI) == .allowed)
        #expect((await store.currentSnapshot()).environment == .sandbox)
        await store.stop()
    }

    @Test
    func mixedOrUnverifiedRuntimeStateFailsClosed() async {
        let authority = LiveFeatureAccessAuthority()
        let mixed = StoreEntitlementRead(
            transactions: [
                verifiedTransaction(environment: .sandbox),
                verifiedTransaction(environment: .production),
            ],
            unverifiedCount: 1
        )
        let source = TestStoreEntitlementSource(read: mixed)
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).environment == nil)
        #expect((await store.currentSnapshot()).unverifiedCount == 1)
        await store.stop()
    }

    @Test
    func unknownProductOrEnvironmentCannotHideBesideAnAcceptedTransaction() async {
        let authority = LiveFeatureAccessAuthority()
        let accepted = verifiedTransaction(environment: .production)
        let unknownProduct = VerifiedStoreTransaction(
            productID: "unapproved.product",
            environment: .production,
            isPurchased: true,
            isActive: true
        )
        let source = TestStoreEntitlementSource(
            read: StoreEntitlementRead(
                transactions: [accepted, unknownProduct],
                unverifiedCount: 0
            )
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        await store.start()
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)

        let unknownEnvironment = VerifiedStoreTransaction(
            productID: StoreProductID.proMonthly.rawValue,
            environment: StoreRuntimeEnvironment(rawValue: "Unknown"),
            isPurchased: true,
            isActive: true
        )
        await source.setRead(
            StoreEntitlementRead(
                transactions: [accepted, unknownEnvironment],
                unverifiedCount: 0
            )
        )
        source.sendUpdate()
        await waitUntil {
            (await store.currentSnapshot()).environment == nil
        }
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        await store.stop()
    }

    @Test
    func anOlderSuspendedReadCannotOverwriteANewerEntitlementSnapshot() async {
        let authority = LiveFeatureAccessAuthority()
        let source = OutOfOrderStoreEntitlementSource(
            firstRead: paidRead(environment: .sandbox),
            laterRead: StoreEntitlementRead(transactions: [], unverifiedCount: 0)
        )
        let store = EntitlementStore(source: source, featureAccessAuthority: authority)

        let startup = Task { await store.start() }
        await waitUntil {
            let reads = await source.readCount()
            let listeners = await source.listenerStartCount()
            return reads == 1 && listeners == 1
        }
        source.sendUpdate()
        await waitUntil { await source.readCount() == 2 }
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)

        await source.releaseFirstRead()
        await startup.value
        #expect(authority.decision(for: .advancedSiri) == .requiresProSubscription)
        #expect((await store.currentSnapshot()).environment == nil)
        await store.stop()
    }

    @Test
    func synchronousFeatureReadsRemainWholeDuringConcurrentReplacement() async {
        let authority = LiveFeatureAccessAuthority()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<200 {
                group.addTask {
                    authority.replaceEntitlements(index.isMultiple(of: 2) ? .free : .proSubscription)
                }
                group.addTask {
                    let result = authority.decision(for: .cloudCoach)
                    #expect(result == .allowed || result == .requiresProSubscription)
                }
            }
        }
    }

    private func validRecords() -> [StoreProductRecord] {
        [
            StoreProductRecord(
                id: StoreProductID.proMonthly.rawValue,
                displayName: "花有数 Pro 月付（本地测试）",
                description: "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
                displayPrice: "CN¥0.99",
                isAutoRenewable: true,
                isFamilyShareable: false,
                hasSubscriptionGroup: true,
                subscriptionPeriod: StoreSubscriptionPeriod(value: 1, unit: .month)
            ),
            StoreProductRecord(
                id: StoreProductID.proAnnual.rawValue,
                displayName: "花有数 Pro 年付（本地测试）",
                description: "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
                displayPrice: "CN¥9.99",
                isAutoRenewable: true,
                isFamilyShareable: false,
                hasSubscriptionGroup: true,
                subscriptionPeriod: StoreSubscriptionPeriod(value: 1, unit: .year)
            ),
        ]
    }

    private func paidRead(environment: StoreRuntimeEnvironment) -> StoreEntitlementRead {
        StoreEntitlementRead(
            transactions: [verifiedTransaction(environment: environment)],
            unverifiedCount: 0
        )
    }

    private func verifiedTransaction(
        environment: StoreRuntimeEnvironment
    ) -> VerifiedStoreTransaction {
        VerifiedStoreTransaction(
            productID: StoreProductID.proMonthly.rawValue,
            environment: environment,
            isPurchased: true,
            isActive: true
        )
    }

    private func waitUntil(
        _ predicate: @escaping @Sendable () async -> Bool
    ) async {
        for _ in 0..<200 {
            if await predicate() { return }
            await Task.yield()
        }
    }
}

private struct FixedStoreContextProvider: StoreCatalogContextProviding {
    let context: StoreCatalogContext

    func currentContext() async -> StoreCatalogContext { context }
}

private enum TestStoreFailure: Error, Sendable {
    case loadFailed
}

private struct TestStoreProductLoader: StoreProductLoading {
    let result: Result<[StoreProductRecord], TestStoreFailure>

    func loadProducts(identifiedBy identifiers: Set<String>) async throws -> [StoreProductRecord] {
        try result.get()
    }
}

private actor TestStorePresentationCache: StorePresentationCaching {
    private var snapshots: [StoreCatalogContext: StoreCatalogSnapshot] = [:]

    func load(for context: StoreCatalogContext) -> StoreCatalogSnapshot? {
        snapshots[context]
    }

    func save(_ snapshot: StoreCatalogSnapshot) {
        snapshots[snapshot.context] = snapshot
    }

    func clear() {
        snapshots = [:]
    }
}

private final class TestUpdateChannel: @unchecked Sendable {
    let stream: AsyncStream<StoreTransactionSignal>
    let continuation: AsyncStream<StoreTransactionSignal>.Continuation

    init() {
        var captured: AsyncStream<StoreTransactionSignal>.Continuation?
        stream = AsyncStream { captured = $0 }
        continuation = captured!
    }
}

private struct TestStoreEntitlementSource: StoreEntitlementSourcing {
    private let state: TestEntitlementState
    private let channel = TestUpdateChannel()

    init(read: StoreEntitlementRead) {
        state = TestEntitlementState(read: read)
    }

    func currentEntitlements() async -> StoreEntitlementRead {
        await state.currentRead()
    }

    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async {
        await state.listenerStarted()
        for await signal in channel.stream {
            guard !Task.isCancelled else { return }
            await handler(signal)
        }
    }

    func setRead(_ read: StoreEntitlementRead) async {
        await state.setRead(read)
    }

    func listenerStartCount() async -> Int {
        await state.startCount()
    }

    func sendUpdate() {
        channel.continuation.yield(.changed)
    }
}

private actor TestEntitlementState {
    private var read: StoreEntitlementRead
    private var listeners = 0

    init(read: StoreEntitlementRead) {
        self.read = read
    }

    func currentRead() -> StoreEntitlementRead { read }
    func setRead(_ read: StoreEntitlementRead) { self.read = read }
    func listenerStarted() { listeners += 1 }
    func startCount() -> Int { listeners }
}

private final class OutOfOrderStoreEntitlementSource: StoreEntitlementSourcing, @unchecked Sendable {
    private let state: OutOfOrderEntitlementState
    private let channel = TestUpdateChannel()

    init(firstRead: StoreEntitlementRead, laterRead: StoreEntitlementRead) {
        state = OutOfOrderEntitlementState(firstRead: firstRead, laterRead: laterRead)
    }

    func currentEntitlements() async -> StoreEntitlementRead {
        await state.read()
    }

    func listenForUpdates(
        _ handler: @Sendable @escaping (StoreTransactionSignal) async -> Void
    ) async {
        await state.listenerStarted()
        for await signal in channel.stream {
            guard !Task.isCancelled else { return }
            await handler(signal)
        }
    }

    func readCount() async -> Int { await state.readCount() }
    func listenerStartCount() async -> Int { await state.listenerStartCount() }
    func releaseFirstRead() async { await state.releaseFirstRead() }
    func sendUpdate() { channel.continuation.yield(.changed) }
}

private actor OutOfOrderEntitlementState {
    private let firstRead: StoreEntitlementRead
    private let laterRead: StoreEntitlementRead
    private var reads = 0
    private var listeners = 0
    private var firstReadContinuation: CheckedContinuation<StoreEntitlementRead, Never>?

    init(firstRead: StoreEntitlementRead, laterRead: StoreEntitlementRead) {
        self.firstRead = firstRead
        self.laterRead = laterRead
    }

    func read() async -> StoreEntitlementRead {
        reads += 1
        guard reads == 1 else { return laterRead }
        return await withCheckedContinuation { continuation in
            firstReadContinuation = continuation
        }
    }

    func listenerStarted() { listeners += 1 }
    func readCount() -> Int { reads }
    func listenerStartCount() -> Int { listeners }

    func releaseFirstRead() {
        firstReadContinuation?.resume(returning: firstRead)
        firstReadContinuation = nil
    }
}
