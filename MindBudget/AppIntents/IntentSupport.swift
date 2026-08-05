import AppIntents
import Foundation

enum IntentExecutionError: Error, Equatable, Sendable {
    case siriUnavailable(SystemIntegrationAvailability)
    case invalidAmount
    case invalidText
    case accountingCurrencyNotConfigured
    case accountingCurrencyMismatch(expected: String, actual: String)
    case budgetUnavailable
    case itemUnavailable
    case invalidStoredData

    var dialogKey: LocalizedStringResource {
        switch self {
        case .siriUnavailable: "intent.error.siriDisabled"
        case .invalidAmount: "intent.error.invalidAmount"
        case .invalidText: "intent.error.invalidText"
        case .accountingCurrencyNotConfigured: "intent.error.currencyNotConfigured"
        case .accountingCurrencyMismatch: "intent.error.currencyMismatch"
        case .budgetUnavailable: "intent.error.budgetUnavailable"
        case .itemUnavailable: "intent.error.itemUnavailable"
        case .invalidStoredData: "intent.error.data"
        }
    }
}

enum IntentStringSanitizer {
    static let maximumLength = 40

    static func sanitize(_ value: String?) -> String? {
        guard let value else { return nil }
        let scalars = value.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0)
        }
        let trimmed = String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maximumLength))
    }
}

enum MindBudgetNavigationRequest: Equatable, Sendable {
    case dashboard
    case expenses
    case wishlist
    case wishlistItem(UUID)
    case insights
}

actor MindBudgetNavigationRequestStore {
    private var pendingRequest: MindBudgetNavigationRequest?
    private var continuations: [
        UUID: AsyncStream<MindBudgetNavigationRequest>.Continuation
    ] = [:]

    func submit(_ request: MindBudgetNavigationRequest) {
        guard !continuations.isEmpty else {
            pendingRequest = request
            return
        }
        continuations.values.forEach { $0.yield(request) }
    }

    func requests() -> AsyncStream<MindBudgetNavigationRequest> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: MindBudgetNavigationRequest.self
        )
        continuations[id] = continuation
        if let pendingRequest {
            continuation.yield(pendingRequest)
            self.pendingRequest = nil
        }
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeContinuation(id: id) }
        }
        return stream
    }

    private func removeContinuation(id: UUID) {
        continuations[id] = nil
    }
}

struct IntentExpenseWriteResult: Equatable, Sendable {
    let expense: ExpenseSummary
    let wasDuplicate: Bool
}

struct IntentBudgetImpactResult: Equatable, Sendable {
    let impact: BudgetImpact
    let snapshot: ConfiguredBudgetSnapshot
}

struct IntentCoolingOffResult: Equatable, Sendable {
    let item: WishItemSummary
    let reviewAt: Date
    let notificationScheduled: Bool
}

struct MindBudgetIntentService: Sendable {
    let dataActor: DataActor
    let preferencesProvider: any SystemIntegrationPreferencesProviding
    let notificationScheduler: any NotificationScheduling
    let navigationStore: MindBudgetNavigationRequestStore
    let capability: SystemIntegrationCapability

    init(
        dataActor: DataActor,
        preferencesProvider: any SystemIntegrationPreferencesProviding,
        notificationScheduler: any NotificationScheduling = NotificationScheduler(),
        navigationStore: MindBudgetNavigationRequestStore = MindBudgetNavigationRequestStore(),
        capability: SystemIntegrationCapability = SystemIntegrationCapability()
    ) {
        self.dataActor = dataActor
        self.preferencesProvider = preferencesProvider
        self.notificationScheduler = notificationScheduler
        self.navigationStore = navigationStore
        self.capability = capability
    }

    func requireSiri() async throws -> SystemIntegrationPreferencesSnapshot {
        let preferences = await preferencesProvider.snapshot()
        let availability = capability.siriAvailability(userEnabled: preferences.siriEnabled)
        guard availability.isAvailable else {
            throw IntentExecutionError.siriUnavailable(availability)
        }
        guard Money.isSupported(preferences.accountingCurrencyCode) else {
            throw IntentExecutionError.accountingCurrencyNotConfigured
        }
        return preferences
    }

    func recordExpense(
        amount: Money,
        category: ExpenseCategory,
        bucket: BudgetBucket,
        merchantName: String?,
        requestedCurrencyCode: String?,
        now: Date,
        calendar: Calendar
    ) async throws -> IntentExpenseWriteResult {
        let preferences = try await requireSiri()
        try validateCurrency(
            requestedCurrencyCode,
            accountingCurrencyCode: preferences.accountingCurrencyCode
        )
        guard amount.currencyCode == preferences.accountingCurrencyCode,
              amount.minorUnits > 0 else {
            throw IntentExecutionError.invalidAmount
        }
        guard let dedupeSince = calendar.date(byAdding: .second, value: -5, to: now) else {
            throw IntentExecutionError.invalidStoredData
        }
        let sanitizedMerchant = IntentStringSanitizer.sanitize(merchantName)
        let draft = ExpenseDraft(
            id: UUID(),
            amount: amount,
            category: category,
            bucket: bucket,
            merchantName: sanitizedMerchant,
            note: nil,
            spentAt: now,
            spentTimeZoneIdentifier: calendar.timeZone.identifier,
            createdAt: now,
            updatedAt: now,
            paymentMethod: nil,
            emotionTag: nil,
            purchaseReason: nil,
            isPlanned: false,
            isRecurring: false,
            source: .siriIntent,
            allowMerchantIndexing: false
        )
        return try await dataActor.createIntentExpense(draft, dedupeSince: dedupeSince)
    }

    func addWishlistItem(
        name: String,
        estimatedPrice: Money?,
        category: ExpenseCategory,
        requestedCurrencyCode: String?,
        now: Date
    ) async throws -> WishItemSummary {
        let preferences = try await requireSiri()
        try validateCurrency(
            requestedCurrencyCode,
            accountingCurrencyCode: preferences.accountingCurrencyCode
        )
        guard let name = IntentStringSanitizer.sanitize(name) else {
            throw IntentExecutionError.invalidText
        }
        if let estimatedPrice {
            guard estimatedPrice.currencyCode == preferences.accountingCurrencyCode,
                  estimatedPrice.minorUnits > 0 else {
                throw IntentExecutionError.invalidAmount
            }
        }
        return try await dataActor.createWishItem(
            WishItemDraft(
                id: UUID(),
                name: name,
                estimatedPrice: estimatedPrice,
                currencyCode: preferences.accountingCurrencyCode,
                category: category,
                reason: nil,
                emotionTag: nil,
                sourceContextLabel: nil,
                createdAt: now,
                updatedAt: now,
                coolingOffHours: 24,
                targetReviewDate: nil,
                status: .active,
                notes: nil,
                purchasedExpenseId: nil
            )
        )
    }

    func checkBudgetImpact(
        amount: Money,
        category: ExpenseCategory,
        bucket: BudgetBucket,
        candidateName: String?,
        requestedCurrencyCode: String?,
        now: Date,
        calendar: Calendar
    ) async throws -> IntentBudgetImpactResult {
        let preferences = try await requireSiri()
        try validateCurrency(
            requestedCurrencyCode,
            accountingCurrencyCode: preferences.accountingCurrencyCode
        )
        guard amount.currencyCode == preferences.accountingCurrencyCode,
              amount.minorUnits > 0 else {
            throw IntentExecutionError.invalidAmount
        }
        // The sanitized candidate name is deliberately ephemeral and never crosses
        // a persistence API. It is accepted only so Siri can resolve natural phrases.
        _ = IntentStringSanitizer.sanitize(candidateName)
        let context = try await currentBudgetContext(
            preferences: preferences,
            now: now,
            calendar: calendar
        )
        let impact = try BudgetEngine().impact(
            of: amount,
            category: category,
            bucket: bucket,
            snapshot: context.snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        return IntentBudgetImpactResult(impact: impact, snapshot: context.snapshot)
    }

    func createCoolingOff(
        wishItemID: UUID,
        durationHours: Int,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> IntentCoolingOffResult {
        let preferences = try await requireSiri()
        guard durationHours > 0 else { throw IntentExecutionError.invalidAmount }
        let detail: WishItemDetail
        do {
            detail = try await dataActor.startCoolingOff(
                wishItemId: wishItemID,
                durationHours: durationHours,
                startedAt: now,
                calendar: calendar
            )
        } catch DataValidationError.modelNotFound {
            throw IntentExecutionError.itemUnavailable
        } catch {
            throw IntentExecutionError.invalidStoredData
        }
        guard let reviewAt = detail.summary.targetReviewDate else {
            throw IntentExecutionError.invalidStoredData
        }

        var scheduled = false
        if preferences.notificationPreferences.notificationsEnabled {
            do {
                let candidates = try await dataActor.fetchCoolingNotificationCandidates()
                let result = try await notificationScheduler.reconcile(
                    candidates: candidates.candidates,
                    preferences: preferences.notificationPreferences,
                    now: now,
                    calendar: calendar,
                    locale: locale
                )
                try await dataActor.updateCoolingNotificationIdentifiers(
                    result.identifierUpdates
                )
                scheduled = result.scheduledCount > 0
            } catch {
                // The local cooling-off period is the user data. Notification failure
                // must never roll it back or misreport that it was not created.
                scheduled = false
            }
        }
        return IntentCoolingOffResult(
            item: detail.summary,
            reviewAt: reviewAt,
            notificationScheduled: scheduled
        )
    }

    func emotionalSpendingCount(
        tag: EmotionTag?,
        now: Date,
        calendar: Calendar
    ) async throws -> Int {
        _ = try await requireSiri()
        guard let start = calendar.date(byAdding: .day, value: -30, to: now) else {
            throw IntentExecutionError.invalidStoredData
        }
        return try await dataActor.fetchExpenseSummaries().filter { expense in
            start <= expense.spentAt && expense.spentAt <= now
                && (tag.map { expense.emotionTag == $0 }
                    ?? (expense.emotionTag != nil || expense.purchaseReason != nil))
        }.count
    }

    func recentSpendingPattern(
        now: Date,
        calendar: Calendar
    ) async throws -> SpendingInsightType? {
        _ = try await requireSiri()
        guard let start = calendar.date(byAdding: .day, value: -30, to: now) else {
            throw IntentExecutionError.invalidStoredData
        }
        return try await dataActor.fetchSpendingInsightSummaries().first {
            start <= $0.periodEnd && $0.periodStart <= now
        }?.type
    }

    func validateEphemeralCandidateName(_ name: String?) async throws -> String? {
        _ = try await requireSiri()
        return IntentStringSanitizer.sanitize(name)
    }

    func expenseEntities(identifiers: [UUID]? = nil) async throws -> [ExpenseEntity] {
        _ = try await requireSiri()
        let allowed = identifiers.map(Set.init)
        let summaries = try await dataActor.fetchExpenseSummaries()
        let plans = try await dataActor.fetchBudgetPlanSummaries()
        return summaries.compactMap { summary in
            guard allowed?.contains(summary.id) ?? true else { return nil }
            let plan = plans.first {
                $0.cycleStart <= summary.spentAt && summary.spentAt < $0.cycleEnd
            }
            return ExpenseEntity(summary: summary, plan: plan)
        }
    }

    func wishlistEntities(identifiers: [UUID]? = nil) async throws -> [WishlistItemEntity] {
        _ = try await requireSiri()
        let allowed = identifiers.map(Set.init)
        return try await dataActor.fetchWishItemSummaries().compactMap { summary in
            guard allowed?.contains(summary.id) ?? true else { return nil }
            return WishlistItemEntity(summary: summary)
        }
    }

    func coolingOffEntities(identifiers: [UUID]? = nil) async throws -> [CoolingOffPlanEntity] {
        _ = try await requireSiri()
        let allowed = identifiers.map(Set.init)
        return try await dataActor.fetchCoolingOffPlanSummaries().compactMap { summary in
            guard allowed?.contains(summary.id) ?? true else { return nil }
            return CoolingOffPlanEntity(summary: summary)
        }
    }

    func merchantEntities(identifiers: [UUID]? = nil) async throws -> [MerchantEntity] {
        let preferences = try await requireSiri()
        guard preferences.spotlightEnabled, preferences.merchantNamesEnabled,
              capability.spotlightAvailability(userEnabled: true).isAvailable else {
            return []
        }
        let eligibleKeys = try await dataActor.fetchMerchantIndexingEligibleNormalizedNames()
        let allowed = identifiers.map(Set.init)
        return try await dataActor.fetchMerchantSummaries().compactMap { summary in
            guard eligibleKeys.contains(summary.normalizedName),
                  allowed?.contains(summary.id) ?? true else { return nil }
            return MerchantEntity(summary: summary)
        }
    }

    func insightEntities(identifiers: [UUID]? = nil) async throws -> [SpendingInsightEntity] {
        _ = try await requireSiri()
        let allowed = identifiers.map(Set.init)
        return try await dataActor.fetchSpendingInsightSummaries().compactMap { summary in
            guard allowed?.contains(summary.id) ?? true else { return nil }
            return SpendingInsightEntity(summary: summary)
        }
    }

    func budgetSnapshotEntities() async throws -> [BudgetSnapshotEntity] {
        let preferences = try await requireSiri()
        let now = Date()
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        guard let context = try? await currentBudgetContext(
            preferences: preferences,
            now: now,
            calendar: calendar
        ) else { return [] }
        return [BudgetSnapshotEntity(snapshot: context.snapshot)]
    }

    func emotionTagEntities(identifiers: [String]? = nil) async throws -> [EmotionTagEntity] {
        _ = try await requireSiri()
        let allowed = identifiers.map(Set.init)
        return EmotionTag.allCases.compactMap { tag in
            guard allowed?.contains(tag.rawValue) ?? true else { return nil }
            return EmotionTagEntity(tag: tag)
        }
    }

    private func currentBudgetContext(
        preferences: SystemIntegrationPreferencesSnapshot,
        now: Date,
        calendar: Calendar
    ) async throws -> (plan: BudgetPlanSummary, snapshot: ConfiguredBudgetSnapshot) {
        let coverage = try await dataActor.previewPlanCoverage(
            date: now,
            futureCycleStartDay: preferences.budgetCycleStartDay,
            calendar: calendar
        )
        guard case let .covered(plan) = coverage else {
            throw IntentExecutionError.budgetUnavailable
        }
        let expenses = try await dataActor.fetchExpenseSummaries()
        let snapshot = try BudgetEngine().snapshot(
            cycle: DateInterval(start: plan.cycleStart, end: plan.cycleEnd),
            currencyCode: plan.currencyCode,
            expenses: expenses,
            plan: plan,
            now: now,
            calendar: calendar
        )
        guard case let .configured(configured) = snapshot else {
            throw IntentExecutionError.budgetUnavailable
        }
        return (plan, configured)
    }

    private func validateCurrency(
        _ requestedCurrencyCode: String?,
        accountingCurrencyCode: String
    ) throws {
        guard let requested = requestedCurrencyCode?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased(), !requested.isEmpty else { return }
        guard requested == accountingCurrencyCode else {
            throw IntentExecutionError.accountingCurrencyMismatch(
                expected: accountingCurrencyCode,
                actual: requested
            )
        }
    }
}

enum MindBudgetAppIntentDependencies {
    static func register(_ service: MindBudgetIntentService) {
        AppDependencyManager.shared.add(dependency: service)
    }
}
