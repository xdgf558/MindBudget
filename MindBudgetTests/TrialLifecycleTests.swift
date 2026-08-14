import Foundation
import Testing
@testable import MindBudget

@Suite("Trial lifecycle", .serialized)
struct TrialLifecycleTests {
    @Test
    func verifiedActiveTrialProjectsActualRenewalFacts() {
        let renewalDate = Date(timeIntervalSince1970: 2_000_000_000)
        let transaction = verifiedTransaction(
            trial: TrialLifecycleProjection(
                currentTrialProductID: .proMonthly,
                renewalProductID: .proMonthly,
                renewalDate: renewalDate,
                willAutoRenew: true
            )
        )

        let resolution = SubscriptionStatusMapper().resolve(
            StoreEntitlementRead(
                transactions: [transaction],
                unverifiedCount: 0,
                appEnvironment: .xcode
            )
        )

        #expect(resolution.isActionable)
        #expect(resolution.trialLifecycle?.currentTrialProductID == .proMonthly)
        #expect(resolution.trialLifecycle?.renewalProductID == .proMonthly)
        #expect(resolution.trialLifecycle?.renewalDate == renewalDate)
        #expect(resolution.trialLifecycle?.willAutoRenew == true)
    }

    @Test
    func renewalPreferenceChangeUpdatesProjectionAndUsesTheRenewalPlanPrice() throws {
        let renewalDate = Date(timeIntervalSince1970: 2_000_000_000)
        let monthlyRenewal = try #require(
            TrialLifecycleProjection.fromVerifiedStoreKitFacts(
                currentTrialProductID: .proMonthly,
                autoRenewPreference: StoreProductID.proMonthly.rawValue,
                renewalDate: renewalDate,
                willAutoRenew: true
            )
        )
        let annualRenewal = try #require(
            TrialLifecycleProjection.fromVerifiedStoreKitFacts(
                currentTrialProductID: .proMonthly,
                autoRenewPreference: StoreProductID.proAnnual.rawValue,
                renewalDate: renewalDate,
                willAutoRenew: true
            )
        )
        let missingPreferenceFallback = try #require(
            TrialLifecycleProjection.fromVerifiedStoreKitFacts(
                currentTrialProductID: .proMonthly,
                autoRenewPreference: nil,
                renewalDate: renewalDate,
                willAutoRenew: true
            )
        )
        let catalog = StoreCatalogAvailability.live(
            StoreCatalogSnapshot(
                context: StoreCatalogContext(
                    environment: .xcode,
                    storefrontCountryCode: "USA"
                ),
                products: [
                    trialProduct(id: .proMonthly, displayPrice: "MONTHLY_PRICE"),
                    trialProduct(id: .proAnnual, displayPrice: "ANNUAL_PRICE"),
                ]
            )
        )
        let resolution = SubscriptionStatusMapper().resolve(
            StoreEntitlementRead(
                transactions: [verifiedTransaction(trial: annualRenewal)],
                unverifiedCount: 0,
                appEnvironment: .xcode
            )
        )

        #expect(monthlyRenewal.currentTrialProductID == .proMonthly)
        #expect(annualRenewal.currentTrialProductID == .proMonthly)
        #expect(monthlyRenewal.renewalProductID == .proMonthly)
        #expect(annualRenewal.renewalProductID == .proAnnual)
        #expect(missingPreferenceFallback.renewalProductID == .proMonthly)
        #expect(monthlyRenewal != annualRenewal)
        #expect(resolution.trialLifecycle == annualRenewal)
        #expect(
            TrialLifecyclePresentation.liveDisplayPrice(
                for: try #require(resolution.trialLifecycle),
                catalog: catalog
            ) == "ANNUAL_PRICE"
        )
        #expect(
            TrialLifecycleProjection.fromVerifiedStoreKitFacts(
                currentTrialProductID: .proMonthly,
                autoRenewPreference: "future.unknown.product",
                renewalDate: renewalDate,
                willAutoRenew: true
            ) == nil
        )
    }

    @Test
    func inconsistentTrialProjectionFailsClosed() {
        let transaction = VerifiedStoreTransaction(
            transactionID: 9,
            productID: StoreProductID.proMonthly.rawValue,
            environment: .xcode,
            isPurchased: true,
            isRevoked: false,
            expirationDate: nil,
            subscriptionState: .inGracePeriod,
            hasVerifiedStatusTransaction: true,
            hasVerifiedRenewalInfo: true,
            hasVerifiedAppBundle: true,
            trialLifecycle: TrialLifecycleProjection(
                currentTrialProductID: .proAnnual,
                renewalProductID: .proAnnual,
                renewalDate: Date(timeIntervalSince1970: 2_000_000_000),
                willAutoRenew: true
            )
        )

        let resolution = SubscriptionStatusMapper().resolve(
            StoreEntitlementRead(
                transactions: [transaction],
                unverifiedCount: 0,
                appEnvironment: .xcode
            )
        )

        #expect(resolution == .failedClosed)
    }

    @Test
    func schedulesExactlyFiveCalendarDaysBeforeVerifiedRenewal() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()
        let now = date(2027, 1, 1, 12, calendar: calendar)
        let renewalDate = date(2027, 1, 10, 9, calendar: calendar)

        let result = try await scheduler.reconcile(
            trial: TrialLifecycleProjection(
                currentTrialProductID: .proMonthly,
                renewalProductID: .proMonthly,
                renewalDate: renewalDate,
                willAutoRenew: true
            ),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        let request = try #require(await center.requests().last)
        let scheduledDate = try #require(calendar.date(from: request.dateComponents))
        #expect(result.delivery == .scheduled(date(2027, 1, 5, 9, calendar: calendar)))
        #expect(scheduledDate == date(2027, 1, 5, 9, calendar: calendar))
        #expect(request.identifier == TrialRenewalReminderIdentifier.requestID)
        #expect(!request.body.contains("1.99"))
        #expect(!request.body.contains("5 days"))
        #expect(!request.body.contains("2027"))
        #expect(request.body.contains("ends soon"))
        #expect(!request.body.contains("will renew"))
    }

    @Test
    func deniedAuthorizationKeepsInAppFallbackWithoutRequestingPermission() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .denied)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()

        let result = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: true,
            now: date(2027, 1, 1, 12, calendar: calendar),
            calendar: calendar,
            locale: Locale(identifier: "zh-Hans")
        )

        #expect(result.delivery == .inAppOnly)
        #expect(await center.requests().isEmpty)
        #expect(await center.removedIdentifiers() == [TrialRenewalReminderIdentifier.requestID])
    }

    @Test
    func undeterminedAuthorizationKeepsInAppFallbackWithoutRequestingPermission() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .notDetermined)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()

        let result = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: true,
            now: date(2027, 1, 1, 12, calendar: calendar),
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        #expect(result.authorizationState == .notDetermined)
        #expect(result.delivery == .inAppOnly)
        #expect(await center.requests().isEmpty)
    }

    @Test
    func calendarSchedulingPreservesLocalHourAcrossDaylightSavingChange() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let now = date(2027, 3, 1, 12, calendar: calendar)
        let renewalDate = date(2027, 3, 15, 9, calendar: calendar)

        let result = try await scheduler.reconcile(
            trial: TrialLifecycleProjection(
                currentTrialProductID: .proMonthly,
                renewalProductID: .proMonthly,
                renewalDate: renewalDate,
                willAutoRenew: true
            ),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        let scheduledFor = try #require(result.scheduledDate)
        #expect(scheduledFor == date(2027, 3, 10, 9, calendar: calendar))
        // The DST boundary makes this 119 elapsed hours, proving this is not 5 * 86,400 seconds.
        #expect(renewalDate.timeIntervalSince(scheduledFor) == 119 * 60 * 60)
    }

    @Test
    func genericChineseCopyContainsNoBillingDetails() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()

        _ = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: true,
            now: date(2027, 1, 1, 12, calendar: calendar),
            calendar: calendar,
            locale: Locale(identifier: "zh-Hans")
        )

        let request = try #require(await center.requests().last)
        #expect(request.title.contains("试用"))
        #expect(!request.body.contains("1.99"))
        #expect(!request.body.contains("5"))
        #expect(!request.body.contains("2027"))
        #expect(!request.body.contains(StoreProductID.proMonthly.rawValue))
        #expect(request.body.contains("即将结束"))
        #expect(!request.body.contains("即将续订"))
    }

    @Test
    func missingRenewalDateCancelsInsteadOfInventingTrialLength() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()

        let result = try await scheduler.reconcile(
            trial: TrialLifecycleProjection(
                currentTrialProductID: .proAnnual,
                renewalProductID: .proAnnual,
                renewalDate: nil,
                willAutoRenew: true
            ),
            notificationsEnabled: true,
            now: date(2027, 1, 1, 12, calendar: calendar),
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        #expect(result.delivery == .inactive)
        #expect(await center.requests().isEmpty)
        #expect(await center.removedIdentifiers() == [TrialRenewalReminderIdentifier.requestID])
    }

    @Test
    func notificationDisabledOrReminderWindowPassedUsesInAppFallback() async throws {
        let calendar = utcCalendar()
        let now = date(2027, 1, 8, 12, calendar: calendar)
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)

        let disabled = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: false,
            now: date(2027, 1, 1, 12, calendar: calendar),
            calendar: calendar,
            locale: Locale(identifier: "en")
        )
        let late = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        #expect(disabled.delivery == .inAppOnly)
        #expect(late.delivery == .inAppOnly)
        #expect(await center.requests().isEmpty)
    }

    @Test
    func cancellationRevocationAndAutoRenewOffRemoveTheStableRequest() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()
        let now = date(2027, 1, 1, 12, calendar: calendar)

        _ = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )
        let stopped = try await scheduler.reconcile(
            trial: TrialLifecycleProjection(
                currentTrialProductID: .proMonthly,
                renewalProductID: .proMonthly,
                renewalDate: date(2027, 1, 10, 9, calendar: calendar),
                willAutoRenew: false
            ),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )
        let revoked = try await scheduler.reconcile(
            trial: nil,
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        #expect(stopped.delivery == .inactive)
        #expect(revoked.delivery == .inactive)
        // One defensive removal precedes the initial add; the following two removals are the
        // auto-renew-off and revoked/absent reconciliations.
        #expect(await center.removedIdentifiers().count == 3)
    }

    @Test
    func changedRenewalDateReplacesTheSameStableRequest() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()
        let now = date(2027, 1, 1, 12, calendar: calendar)

        _ = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )
        let changed = try await scheduler.reconcile(
            trial: TrialLifecycleProjection(
                currentTrialProductID: .proMonthly,
                renewalProductID: .proAnnual,
                renewalDate: date(2027, 1, 20, 18, calendar: calendar),
                willAutoRenew: true
            ),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        let requests = await center.requests()
        #expect(requests.count == 2)
        #expect(Set(requests.map(\.identifier)) == [TrialRenewalReminderIdentifier.requestID])
        #expect(changed.delivery == .scheduled(date(2027, 1, 15, 18, calendar: calendar)))
    }

    @Test
    func failedReplacementRemovesThePreviouslyPendingReminder() async throws {
        let center = TrialNotificationCenterFixture(authorizationState: .authorized)
        let scheduler = TrialLifecycleScheduler(center: center)
        let calendar = utcCalendar()
        let now = date(2027, 1, 1, 12, calendar: calendar)

        _ = try await scheduler.reconcile(
            trial: activeTrial(calendar: calendar),
            notificationsEnabled: true,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )
        await center.failNextAdd()

        await #expect(throws: TrialNotificationCenterFixture.Failure.self) {
            try await scheduler.reconcile(
                trial: TrialLifecycleProjection(
                    currentTrialProductID: .proMonthly,
                    renewalProductID: .proAnnual,
                    renewalDate: date(2027, 1, 20, 18, calendar: calendar),
                    willAutoRenew: true
                ),
                notificationsEnabled: true,
                now: now,
                calendar: calendar,
                locale: Locale(identifier: "en")
            )
        }

        #expect(await center.pendingRequests().isEmpty)
    }

    private func verifiedTransaction(
        trial: TrialLifecycleProjection?
    ) -> VerifiedStoreTransaction {
        VerifiedStoreTransaction(
            transactionID: 7,
            productID: StoreProductID.proMonthly.rawValue,
            environment: .xcode,
            isPurchased: true,
            isRevoked: false,
            expirationDate: trial?.renewalDate,
            subscriptionState: .subscribed,
            hasVerifiedStatusTransaction: true,
            hasVerifiedRenewalInfo: true,
            hasVerifiedAppBundle: true,
            trialLifecycle: trial
        )
    }

    private func activeTrial(calendar: Calendar) -> TrialLifecycleProjection {
        TrialLifecycleProjection(
            currentTrialProductID: .proMonthly,
            renewalProductID: .proMonthly,
            renewalDate: date(2027, 1, 10, 9, calendar: calendar),
            willAutoRenew: true
        )
    }

    private func trialProduct(
        id: StoreProductID,
        displayPrice: String
    ) -> StoreProductPresentation {
        StoreProductPresentation(
            id: id,
            displayName: id.rawValue,
            description: id.rawValue,
            displayPrice: displayPrice,
            subscriptionPeriod: StoreSubscriptionPeriod(
                value: 1,
                unit: id == .proMonthly ? .month : .year
            ),
            introductoryOffer: nil,
            isEligibleForIntroductoryOffer: false
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
}

private extension TrialRenewalReminderReconciliation {
    var scheduledDate: Date? {
        guard case let .scheduled(date) = delivery else { return nil }
        return date
    }
}

private actor TrialNotificationCenterFixture: TrialRenewalNotificationCenterClient {
    enum Failure: Error {
        case addRejected
    }

    private let state: NotificationAuthorizationState
    private var addedRequests: [TrialRenewalNotificationRequest] = []
    private var pendingRequestsByID: [String: TrialRenewalNotificationRequest] = [:]
    private var removed: [String] = []
    private var rejectsNextAdd = false

    init(authorizationState: NotificationAuthorizationState) {
        state = authorizationState
    }

    func authorizationState() async -> NotificationAuthorizationState {
        state
    }

    func add(_ request: TrialRenewalNotificationRequest) async throws {
        if rejectsNextAdd {
            rejectsNextAdd = false
            throw Failure.addRejected
        }
        addedRequests.append(request)
        pendingRequestsByID[request.identifier] = request
    }

    func removePendingRequest(withIdentifier identifier: String) async {
        removed.append(identifier)
        pendingRequestsByID[identifier] = nil
    }

    func requests() -> [TrialRenewalNotificationRequest] {
        addedRequests
    }

    func removedIdentifiers() -> [String] {
        removed
    }

    func pendingRequests() -> [TrialRenewalNotificationRequest] {
        Array(pendingRequestsByID.values)
    }

    func failNextAdd() {
        rejectsNextAdd = true
    }
}
