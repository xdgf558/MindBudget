import Foundation

enum InsightValue: Codable, Equatable, Sendable {
    case integer(Int)
    case money(Money)
    case basisPoints(Int)
    case category(ExpenseCategory)
}

/// Integer-only evidence attached to every newly generated deterministic rule result.
///
/// `confidenceBasisPoints` is the exact supporting-sample ratio, not a statistical probability
/// or an AI score. Keeping both counts makes the displayed percentage independently verifiable.
struct RuleEvidence: Equatable, Sendable {
    let sampleCount: Int
    let supportingSampleCount: Int
    let confidenceBasisPoints: Int

    init?(
        sampleCount: Int,
        supportingSampleCount: Int,
        confidenceBasisPoints: Int
    ) {
        guard sampleCount > 0,
              (0...sampleCount).contains(supportingSampleCount),
              (0...10_000).contains(confidenceBasisPoints),
              confidenceBasisPoints == Self.confidenceBasisPoints(
                supportingSampleCount: supportingSampleCount,
                sampleCount: sampleCount
              ) else {
            return nil
        }
        self.sampleCount = sampleCount
        self.supportingSampleCount = supportingSampleCount
        self.confidenceBasisPoints = confidenceBasisPoints
    }

    static func measured(sampleCount: Int, supportingSampleCount: Int) -> RuleEvidence? {
        guard sampleCount > 0, (0...sampleCount).contains(supportingSampleCount) else {
            return nil
        }
        return RuleEvidence(
            sampleCount: sampleCount,
            supportingSampleCount: supportingSampleCount,
            confidenceBasisPoints: confidenceBasisPoints(
                supportingSampleCount: supportingSampleCount,
                sampleCount: sampleCount
            )
        )
    }

    static let exact = RuleEvidence(
        sampleCount: 1,
        supportingSampleCount: 1,
        confidenceBasisPoints: 10_000
    )!

    private static func confidenceBasisPoints(
        supportingSampleCount: Int,
        sampleCount: Int
    ) -> Int {
        let ratio = Decimal(supportingSampleCount) * Decimal(10_000) / Decimal(sampleCount)
        return NSDecimalNumber(decimal: ratio).intValue
    }
}

enum RuleEvidencePayload {
    static let sampleCountKey = "__ruleEvidenceSampleCount"
    static let supportingSampleCountKey = "__ruleEvidenceSupportingSampleCount"
    static let confidenceBasisPointsKey = "__ruleEvidenceConfidenceBasisPoints"

    static func persistedPayload(for draft: InsightDraft) -> [String: InsightValue] {
        guard let evidence = draft.evidence else { return draft.payload }
        var payload = draft.payload
        payload[sampleCountKey] = .integer(evidence.sampleCount)
        payload[supportingSampleCountKey] = .integer(evidence.supportingSampleCount)
        payload[confidenceBasisPointsKey] = .basisPoints(evidence.confidenceBasisPoints)
        return payload
    }

    static func decoded(
        from persistedPayload: [String: InsightValue]
    ) throws -> (payload: [String: InsightValue], evidence: RuleEvidence?) {
        var payload = persistedPayload
        let sample = payload.removeValue(forKey: sampleCountKey)
        let supporting = payload.removeValue(forKey: supportingSampleCountKey)
        let confidence = payload.removeValue(forKey: confidenceBasisPointsKey)
        guard sample != nil || supporting != nil || confidence != nil else {
            return (payload, nil)
        }
        guard case let .integer(sampleCount) = sample,
              case let .integer(supportingSampleCount) = supporting,
              case let .basisPoints(confidenceBasisPoints) = confidence,
              let evidence = RuleEvidence(
                sampleCount: sampleCount,
                supportingSampleCount: supportingSampleCount,
                confidenceBasisPoints: confidenceBasisPoints
              ) else {
            throw DataValidationError.invalidSpendingInsight
        }
        return (payload, evidence)
    }
}

struct CycleAggregate: Equatable, Sendable {
    let periodStart: Date
    let periodEnd: Date
    let currencyCode: String
    let totalMinorUnits: Int64
    let imageRelatedMinorUnits: Int64
}

struct CoolingOffOutcomeSummary: Equatable, Sendable {
    let outcome: CoolingOffOutcome
    let outcomeRecordedAt: Date
}

struct PurchaseCandidate: Equatable, Sendable {
    let name: String?
    let amount: Money
    let category: ExpenseCategory
    let bucket: BudgetBucket
    let reason: PurchaseReason?
    let emotionTag: EmotionTag?
}

struct ReminderThrottleMetadata: Equatable, Sendable {
    let scopeKey: String
    let categoryRiskBasisPoints: Int?
}

struct InsightDraft: Equatable, Sendable {
    let type: SpendingInsightType
    let severity: InsightSeverity
    let dedupeKey: String
    let payload: [String: InsightValue]
    let evidence: RuleEvidence?
    let throttleMetadata: ReminderThrottleMetadata
    let relatedCategory: ExpenseCategory?
    let relatedEmotionTag: EmotionTag?
    let periodStart: Date
    let periodEnd: Date

    init(
        type: SpendingInsightType,
        severity: InsightSeverity,
        dedupeKey: String,
        payload: [String: InsightValue],
        evidence: RuleEvidence? = nil,
        throttleMetadata: ReminderThrottleMetadata,
        relatedCategory: ExpenseCategory?,
        relatedEmotionTag: EmotionTag?,
        periodStart: Date,
        periodEnd: Date
    ) {
        self.type = type
        self.severity = severity
        self.dedupeKey = dedupeKey
        self.payload = payload
        self.evidence = evidence
        self.throttleMetadata = throttleMetadata
        self.relatedCategory = relatedCategory
        self.relatedEmotionTag = relatedEmotionTag
        self.periodStart = periodStart
        self.periodEnd = periodEnd
    }

    var titleKey: String { "insight.\(type.rawValue).title" }
    var bodyKey: String { "insight.\(type.rawValue).body" }
}

protocol SpendingPatternDetecting: Sendable {
    func detectPatterns(
        expenses: [ExpenseSummary],
        snapshot: BudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary],
        historicalCycles: [CycleAggregate],
        coolingOffOutcomes: [CoolingOffOutcomeSummary],
        config: RuleConfiguration,
        now: Date,
        calendar: Calendar
    ) -> [InsightDraft]

    func evaluatePotentialPurchase(
        candidate: PurchaseCandidate,
        expenses: [ExpenseSummary],
        snapshot: BudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary],
        historicalCycles: [CycleAggregate],
        config: RuleConfiguration,
        now: Date,
        calendar: Calendar
    ) -> [InsightDraft]
}

struct SpendingPatternDetector: SpendingPatternDetecting, Sendable {
    func detectPatterns(
        expenses: [ExpenseSummary],
        snapshot: BudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary],
        historicalCycles: [CycleAggregate],
        coolingOffOutcomes: [CoolingOffOutcomeSummary],
        config: RuleConfiguration,
        now: Date,
        calendar: Calendar
    ) -> [InsightDraft] {
        let cycleExpenses = expenses.filter {
            snapshot.cycle.start <= $0.spentAt && $0.spentAt < snapshot.cycle.end
        }
        var drafts = recurringPatternDrafts(
            expenses: expenses,
            snapshot: snapshot,
            historicalCycles: historicalCycles,
            config: config,
            now: now,
            calendar: calendar
        )

        if case let .configured(configured) = snapshot {
            if let latest = cycleExpenses
                .filter({ isLargePurchase($0.amount, snapshot: configured, config: config) })
                .max(by: { $0.spentAt < $1.spentAt }) {
                drafts.append(
                    draft(
                        type: .highSinglePurchase,
                        severity: .caution,
                        payload: ["amount": .money(latest.amount)],
                        snapshot: snapshot
                    )
                )
            }

            if configured.freeBudget.minorUnits > 0,
               let latest = cycleExpenses
                .filter({ expense in
                    isLateNight(expense, config: config, calendar: calendar)
                        && Decimal(expense.amount.minorUnits)
                            >= Decimal(configured.freeBudget.minorUnits)
                                * config.lateNightMinimumRatio
                })
                .max(by: { $0.spentAt < $1.spentAt }) {
                let windowStart = calendar.date(
                    byAdding: .day,
                    value: -config.lateNightWindowDays,
                    to: latest.spentAt
                ) ?? latest.spentAt
                let windowExpenses = expenses.filter {
                    windowStart <= $0.spentAt && $0.spentAt <= latest.spentAt
                }
                let count = windowExpenses.filter {
                    isLateNight($0, config: config, calendar: calendar)
                }.count
                if count >= config.lateNightMinimumCount {
                    drafts.append(
                        draft(
                            type: .lateNightSpending,
                            severity: .gentle,
                            payload: ["count": .integer(count)],
                            evidence: RuleEvidence.measured(
                                sampleCount: windowExpenses.count,
                                supportingSampleCount: count
                            ) ?? .exact,
                            snapshot: snapshot
                        )
                    )
                }
            }

            for budget in categoryBudgets {
                let spent = configured.spentByCategory[budget.category]?.minorUnits ?? 0
                guard categoryRiskTriggered(
                    projectedMinorUnits: spent,
                    budget: budget
                ), let risk = basisPoints(numerator: spent, denominator: budget.limitMinorUnits)
                else { continue }
                drafts.append(
                    categoryRiskDraft(
                        category: budget.category,
                        riskBasisPoints: risk,
                        snapshot: snapshot
                    )
                )
            }
        }

        let currentCycleOutcomes = coolingOffOutcomes.filter {
            snapshot.cycle.start <= $0.outcomeRecordedAt
                && $0.outcomeRecordedAt < snapshot.cycle.end
        }
        let skippedCount = currentCycleOutcomes.filter { $0.outcome == .skipped }.count
        if skippedCount > 0 {
            drafts.append(
                draft(
                    type: .coolingOffSuccess,
                    severity: .info,
                    payload: ["count": .integer(skippedCount)],
                    evidence: RuleEvidence.measured(
                        sampleCount: currentCycleOutcomes.count,
                        supportingSampleCount: skippedCount
                    ) ?? .exact,
                    snapshot: snapshot
                )
            )
        }

        return deduplicated(drafts)
    }

    func evaluatePotentialPurchase(
        candidate: PurchaseCandidate,
        expenses: [ExpenseSummary],
        snapshot: BudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary],
        historicalCycles: [CycleAggregate],
        config: RuleConfiguration,
        now: Date,
        calendar: Calendar
    ) -> [InsightDraft] {
        var drafts = recurringPatternDrafts(
            expenses: expenses,
            candidate: candidate,
            snapshot: snapshot,
            historicalCycles: historicalCycles,
            config: config,
            now: now,
            calendar: calendar
        )

        guard case let .configured(configured) = snapshot,
              candidate.amount.currencyCode == configured.currencyCode,
              let impact = try? BudgetEngine().impact(
                of: candidate.amount,
                category: candidate.category,
                bucket: candidate.bucket,
                snapshot: configured,
                categoryBudgets: categoryBudgets
              ) else {
            return deduplicated(drafts)
        }

        if isLargePurchase(candidate.amount, snapshot: configured, config: config) {
            drafts.append(
                draft(
                    type: .highSinglePurchase,
                    severity: .caution,
                    payload: [
                        "amount": .money(candidate.amount),
                        "remainingFreeAfter": .money(impact.remainingFreeAfter)
                    ],
                    snapshot: snapshot
                )
            )
        }

        let candidateHour = calendar.component(.hour, from: now)
        if isHour(candidateHour, in: config.lateNightStartHour, config.lateNightEndHour),
           configured.freeBudget.minorUnits > 0,
           Decimal(candidate.amount.minorUnits)
                >= Decimal(configured.freeBudget.minorUnits) * config.lateNightMinimumRatio {
            let windowStart = calendar.date(
                byAdding: .day,
                value: -config.lateNightWindowDays,
                to: now
            ) ?? now
            let windowExpenses = expenses.filter {
                windowStart <= $0.spentAt && $0.spentAt <= now
            }
            let existingCount = windowExpenses.filter {
                isLateNight($0, config: config, calendar: calendar)
            }.count
            let count = existingCount + 1
            if count >= config.lateNightMinimumCount {
                drafts.append(
                    draft(
                        type: .lateNightSpending,
                        severity: .gentle,
                        payload: ["count": .integer(count)],
                        evidence: RuleEvidence.measured(
                            sampleCount: windowExpenses.count + 1,
                            supportingSampleCount: count
                        ) ?? .exact,
                        snapshot: snapshot
                    )
                )
            }
        }

        if let risk = impact.categoryRisk,
           let budget = categoryBudgets.first(where: { $0.category == candidate.category }),
           categoryRiskTriggered(
                projectedMinorUnits: risk.projectedAfterPurchase.minorUnits,
                budget: budget
           ),
           let riskBasisPoints = basisPoints(
                numerator: risk.projectedAfterPurchase.minorUnits,
                denominator: risk.limit.minorUnits
           ) {
            drafts.append(
                categoryRiskDraft(
                    category: candidate.category,
                    riskBasisPoints: riskBasisPoints,
                    snapshot: snapshot
                )
            )
        }

        let warningTypes: Set<SpendingInsightType> = [
            .highSinglePurchase,
            .categoryBudgetRisk,
            .lateNightSpending,
            .repeatedStressSpending,
            .imageRelatedIncrease,
            .impulseCluster
        ]
        if drafts.allSatisfy({ !warningTypes.contains($0.type) }) {
            let requiredBuffer = Decimal(configured.safeDailySpend.minorUnits)
                * Decimal(configured.daysRemaining)
                * Decimal(config.safeProceedBufferBasisPoints)
                / Decimal(10_000)
            if Decimal(impact.remainingFreeAfter.minorUnits) >= requiredBuffer {
                drafts.append(
                    draft(
                        type: .safeToProceed,
                        severity: .info,
                        payload: ["remainingFreeAfter": .money(impact.remainingFreeAfter)],
                        snapshot: snapshot
                    )
                )
            }
        }

        return deduplicated(drafts)
    }

    private func recurringPatternDrafts(
        expenses: [ExpenseSummary],
        candidate: PurchaseCandidate? = nil,
        snapshot: BudgetSnapshot,
        historicalCycles: [CycleAggregate],
        config: RuleConfiguration,
        now: Date,
        calendar: Calendar
    ) -> [InsightDraft] {
        var drafts: [InsightDraft] = []
        let stressWindowStart = calendar.date(
            byAdding: .day,
            value: -config.stressWindowDays,
            to: now
        ) ?? now
        let stressWindowExpenses = expenses.filter {
            stressWindowStart <= $0.spentAt && $0.spentAt <= now
        }
        let stressCount = stressWindowExpenses.filter(isStressRelated).count
            + (candidate.map { isStressRelated($0) } == true ? 1 : 0)
        if stressCount >= config.stressMinimumCount {
            drafts.append(
                draft(
                    type: .repeatedStressSpending,
                    severity: .gentle,
                    payload: ["count": .integer(stressCount)],
                    evidence: RuleEvidence.measured(
                        sampleCount: stressWindowExpenses.count + (candidate == nil ? 0 : 1),
                        supportingSampleCount: stressCount
                    ) ?? .exact,
                    snapshot: snapshot,
                    relatedEmotionTag: .stressed
                )
            )
        }

        let impulseWindowStart = calendar.date(
            byAdding: .hour,
            value: -config.impulseWindowHours,
            to: now
        ) ?? now
        let impulseWindowExpenses = expenses.filter {
            impulseWindowStart <= $0.spentAt && $0.spentAt <= now
        }
        let impulseCount = impulseWindowExpenses.filter(isImpulseRelated).count
            + (candidate.map { isImpulseRelated($0) } == true ? 1 : 0)
        if impulseCount >= config.impulseMinimumCount {
            drafts.append(
                draft(
                    type: .impulseCluster,
                    severity: .caution,
                    payload: ["count": .integer(impulseCount)],
                    evidence: RuleEvidence.measured(
                        sampleCount: impulseWindowExpenses.count + (candidate == nil ? 0 : 1),
                        supportingSampleCount: impulseCount
                    ) ?? .exact,
                    snapshot: snapshot,
                    relatedEmotionTag: .impulse
                )
            )
        }

        let baseline = historicalCycles
            .filter {
                $0.currencyCode == snapshot.currencyCode && $0.periodEnd <= snapshot.cycle.start
            }
            .sorted { $0.periodEnd > $1.periodEnd }
            .prefix(config.imageBaselineMonths)
        if baseline.count >= config.minimumBaselineMonthsRequired,
           let historicalTotal = checkedSum(baseline.map(\.imageRelatedMinorUnits)),
           historicalTotal > 0,
           let currentStored = checkedSum(
                expenses
                    .filter {
                        snapshot.cycle.start <= $0.spentAt && $0.spentAt < snapshot.cycle.end
                            && isImageRelated($0)
                    }
                    .map(\.amount.minorUnits)
           ) {
            let candidateAmount = candidate.map { isImageRelated($0) } == true
                ? candidate?.amount.minorUnits ?? 0
                : 0
            let (currentTotal, overflow) = currentStored.addingReportingOverflow(candidateAmount)
            let baselineAverage = Decimal(historicalTotal) / Decimal(baseline.count)
            if !overflow,
               currentTotal >= config.imageRelatedMinimumAmount.minorUnits,
               Decimal(currentTotal) > baselineAverage * config.imageIncreaseMultiplier {
                let changeBasisPoints = baselineAverage > 0
                    ? decimalToBasisPoints(Decimal(currentTotal) / baselineAverage)
                    : nil
                drafts.append(
                    draft(
                        type: .imageRelatedIncrease,
                        severity: .gentle,
                        payload: [
                            "current": .money(
                                Money(minorUnits: currentTotal, currencyCode: snapshot.currencyCode)
                            ),
                            "change": .basisPoints(changeBasisPoints ?? 0)
                        ],
                        evidence: RuleEvidence.measured(
                            sampleCount: baseline.count,
                            supportingSampleCount: baseline.filter {
                                $0.imageRelatedMinorUnits > 0
                            }.count
                        ) ?? .exact,
                        snapshot: snapshot,
                        relatedEmotionTag: .imageBoost
                    )
                )
            }
        }
        return drafts
    }

    private func categoryRiskDraft(
        category: ExpenseCategory,
        riskBasisPoints: Int,
        snapshot: BudgetSnapshot
    ) -> InsightDraft {
        draft(
            type: .categoryBudgetRisk,
            severity: riskBasisPoints >= 10_000 ? .caution : .gentle,
            payload: [
                "category": .category(category),
                "risk": .basisPoints(riskBasisPoints)
            ],
            snapshot: snapshot,
            scopeKey: "categoryBudgetRisk:\(category.rawValue)",
            categoryRiskBasisPoints: riskBasisPoints,
            relatedCategory: category
        )
    }

    private func draft(
        type: SpendingInsightType,
        severity: InsightSeverity,
        payload: [String: InsightValue],
        evidence: RuleEvidence = .exact,
        snapshot: BudgetSnapshot,
        scopeKey: String? = nil,
        categoryRiskBasisPoints: Int? = nil,
        relatedCategory: ExpenseCategory? = nil,
        relatedEmotionTag: EmotionTag? = nil
    ) -> InsightDraft {
        let resolvedScope = scopeKey ?? "\(type.rawValue):global"
        return InsightDraft(
            type: type,
            severity: severity,
            dedupeKey: "\(type.rawValue):\(periodKey(snapshot.cycle)):" +
                "\(relatedCategory?.rawValue ?? "global")",
            payload: payload,
            evidence: evidence,
            throttleMetadata: ReminderThrottleMetadata(
                scopeKey: resolvedScope,
                categoryRiskBasisPoints: categoryRiskBasisPoints
            ),
            relatedCategory: relatedCategory,
            relatedEmotionTag: relatedEmotionTag,
            periodStart: snapshot.cycle.start,
            periodEnd: snapshot.cycle.end
        )
    }

    private func isLargePurchase(
        _ amount: Money,
        snapshot: ConfiguredBudgetSnapshot,
        config: RuleConfiguration
    ) -> Bool {
        amount.currencyCode == snapshot.currencyCode
            && amount.currencyCode == config.largePurchaseFloor.currencyCode
            && amount.minorUnits >= config.largePurchaseFloor.minorUnits
            && Decimal(amount.minorUnits)
                >= Decimal(snapshot.freeBudget.minorUnits)
                    * config.largePurchaseFreeBudgetRatio
    }

    private func categoryRiskTriggered(
        projectedMinorUnits: Int64,
        budget: CategoryBudgetSummary
    ) -> Bool {
        guard projectedMinorUnits >= 0, budget.limitMinorUnits >= 0,
              (1...10_000).contains(budget.warningThresholdBasisPoints) else {
            return false
        }
        return Decimal(projectedMinorUnits) >= Decimal(budget.limitMinorUnits)
            * Decimal(budget.warningThresholdBasisPoints) / Decimal(10_000)
    }

    private func isLateNight(
        _ expense: ExpenseSummary,
        config: RuleConfiguration,
        calendar: Calendar
    ) -> Bool {
        guard let hour = try? BudgetCycleCalculator().recordedLocalHour(
            at: expense.spentAt,
            timeZoneIdentifier: expense.spentTimeZoneIdentifier,
            calendar: calendar
        ) else { return false }
        return isHour(hour, in: config.lateNightStartHour, config.lateNightEndHour)
    }

    private func isHour(_ hour: Int, in start: Int, _ end: Int) -> Bool {
        start < end ? hour >= start && hour < end : hour >= start || hour < end
    }

    private func isStressRelated(_ expense: ExpenseSummary) -> Bool {
        expense.emotionTag == .stressed || expense.purchaseReason == .stressRelief
    }

    private func isStressRelated(_ candidate: PurchaseCandidate) -> Bool {
        candidate.emotionTag == .stressed || candidate.reason == .stressRelief
    }

    private func isImpulseRelated(_ expense: ExpenseSummary) -> Bool {
        expense.emotionTag == .impulse || expense.purchaseReason == .impulse
    }

    private func isImpulseRelated(_ candidate: PurchaseCandidate) -> Bool {
        candidate.emotionTag == .impulse || candidate.reason == .impulse
    }

    private func isImageRelated(_ expense: ExpenseSummary) -> Bool {
        expense.emotionTag == .imageBoost || expense.purchaseReason == .imageUpgrade
    }

    private func isImageRelated(_ candidate: PurchaseCandidate) -> Bool {
        candidate.emotionTag == .imageBoost || candidate.reason == .imageUpgrade
    }

    private func basisPoints(numerator: Int64, denominator: Int64) -> Int? {
        guard numerator >= 0 else { return nil }
        guard denominator > 0 else { return numerator > 0 ? 10_000 : 0 }
        let (scaled, overflow) = numerator.multipliedReportingOverflow(by: 10_000)
        guard !overflow else { return nil }
        let value = scaled / denominator
        guard value <= Int64(Int.max) else { return nil }
        return Int(value)
    }

    private func decimalToBasisPoints(_ value: Decimal) -> Int? {
        let scaled = value * Decimal(10_000)
        guard scaled >= 0, scaled <= Decimal(Int.max) else { return nil }
        return NSDecimalNumber(decimal: scaled).intValue
    }

    private func checkedSum<S: Sequence>(_ values: S) -> Int64? where S.Element == Int64 {
        var total: Int64 = 0
        for value in values {
            let (next, overflow) = total.addingReportingOverflow(value)
            guard !overflow else { return nil }
            total = next
        }
        return total
    }

    private func periodKey(_ interval: DateInterval) -> String {
        "\(Int(interval.start.timeIntervalSinceReferenceDate))"
    }

    private func deduplicated(_ drafts: [InsightDraft]) -> [InsightDraft] {
        var seen: Set<String> = []
        return drafts
            .sorted {
                if $0.severity == $1.severity { return $0.type.rawValue < $1.type.rawValue }
                return $0.severity > $1.severity
            }
            .filter { seen.insert($0.dedupeKey).inserted }
    }

}

enum CycleAggregateBuildError: Error, Equatable, Sendable {
    case amountOverflow(periodStart: Date)
}

struct CycleAggregateBuilder: Sendable {
    func build(
        plans: [BudgetPlanSummary],
        expenses: [ExpenseSummary],
        before date: Date
    ) throws -> [CycleAggregate] {
        try plans
            .filter { $0.cycleEnd <= date }
            .sorted { $0.cycleStart < $1.cycleStart }
            .map { plan in
                let cycleExpenses = expenses.filter {
                    plan.cycleStart <= $0.spentAt && $0.spentAt < plan.cycleEnd
                        && $0.amount.currencyCode == plan.currencyCode
                }
                guard let total = checkedSum(cycleExpenses.map(\.amount.minorUnits)),
                      let image = checkedSum(
                        cycleExpenses
                            .filter {
                                $0.emotionTag == .imageBoost
                                    || $0.purchaseReason == .imageUpgrade
                            }
                            .map(\.amount.minorUnits)
                      ) else {
                    throw CycleAggregateBuildError.amountOverflow(
                        periodStart: plan.cycleStart
                    )
                }
                return CycleAggregate(
                    periodStart: plan.cycleStart,
                    periodEnd: plan.cycleEnd,
                    currencyCode: plan.currencyCode,
                    totalMinorUnits: total,
                    imageRelatedMinorUnits: image
                )
            }
    }

    private func checkedSum(_ values: [Int64]) -> Int64? {
        var total: Int64 = 0
        for value in values {
            let (next, overflow) = total.addingReportingOverflow(value)
            guard !overflow else { return nil }
            total = next
        }
        return total
    }
}
