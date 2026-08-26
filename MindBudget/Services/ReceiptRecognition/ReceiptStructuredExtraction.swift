import Foundation

enum ReceiptDateOrder: Equatable, Sendable {
    case monthDayYear
    case dayMonthYear
}

struct ReceiptCalendarDate: Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int
}

enum ReceiptFieldSource: String, Equatable, Sendable {
    case deterministic
    case onDeviceModel
}

enum ReceiptFieldIssue: String, CaseIterable, Equatable, Sendable {
    case invalidMerchant
    case ambiguousDate
    case invalidDate
    case ambiguousTotal
    case invalidAmount
    case unsupportedCurrency
    case currencyMismatch
    case unsupportedScale
    case amountOutOfRange
}

enum ReceiptFieldResolution<Value: Equatable & Sendable>: Equatable, Sendable {
    case missing
    case accepted(Value, source: ReceiptFieldSource)
    case rejected(ReceiptFieldIssue)

    var acceptedValue: Value? {
        guard case let .accepted(value, _) = self else { return nil }
        return value
    }
}

struct ReceiptCoreFields: Equatable, Sendable {
    let merchantName: ReceiptFieldResolution<String>
    let purchaseDate: ReceiptFieldResolution<ReceiptCalendarDate>
    let total: ReceiptFieldResolution<Money>

    var isComplete: Bool {
        merchantName.acceptedValue != nil
            && purchaseDate.acceptedValue != nil
            && total.acceptedValue != nil
    }
}

struct ReceiptLineItem: Equatable, Sendable {
    let name: String
    let amount: Money
}

struct ReceiptLineItemExperiment: Equatable, Sendable {
    let isEnabled: Bool

    /// Line-item extraction is not a production capability until a later owner decision accepts it.
    static let production = ReceiptLineItemExperiment(isEnabled: false)
}

struct ReceiptDuplicateReference: Equatable, Sendable {
    let id: UUID
    let merchantName: String?
    let purchaseDate: ReceiptCalendarDate
    let total: Money
}

enum ReceiptDuplicateResolution: Equatable, Sendable {
    case notEvaluable
    case noMatch
    case exactMatches([UUID])
}

enum ReceiptModelFallbackReason: String, Equatable, Sendable {
    case unavailable
    case timedOut
    case invalidEvidence
    case invalidOutput
    case modelError
}

enum ReceiptExtractionExecution: Equatable, Sendable {
    case deterministic
    case deterministicWithOnDeviceModel
    case deterministicFallback(ReceiptModelFallbackReason)
}

struct ReceiptStructuredExtractionResult: Equatable, Sendable {
    let fields: ReceiptCoreFields
    let lineItems: [ReceiptLineItem]
    let duplicateResolution: ReceiptDuplicateResolution
    let execution: ReceiptExtractionExecution
}

struct ReceiptExtractionContext: Sendable {
    let expectedCurrencyCode: String
    let dateOrder: ReceiptDateOrder
    let calendar: Calendar
    let localeIdentifier: String
    let duplicateReferences: [ReceiptDuplicateReference]

    init(
        expectedCurrencyCode: String,
        dateOrder: ReceiptDateOrder,
        calendar: Calendar,
        localeIdentifier: String,
        duplicateReferences: [ReceiptDuplicateReference] = []
    ) {
        self.expectedCurrencyCode = expectedCurrencyCode
        self.dateOrder = dateOrder
        self.calendar = calendar
        self.localeIdentifier = localeIdentifier
        self.duplicateReferences = duplicateReferences
    }
}

struct ReceiptRawLineItemCandidate: Equatable, Sendable {
    let nameEvidence: String
    let amountEvidence: String
}

struct ReceiptRawCandidates: Equatable, Sendable {
    let merchantEvidence: [String]
    let dateEvidence: [String]
    let totalEvidence: [String]
    let lineItemEvidence: [ReceiptRawLineItemCandidate]

    static let empty = ReceiptRawCandidates(
        merchantEvidence: [],
        dateEvidence: [],
        totalEvidence: [],
        lineItemEvidence: []
    )
}

protocol ReceiptLocalModelExtracting: Sendable {
    /// Every returned string must be copied from `document`; deterministic code verifies that
    /// provenance before interpreting any field.
    func extract(
        from document: ReceiptOCRDocument,
        context: ReceiptExtractionContext,
        lineItemsEnabled: Bool
    ) async throws -> ReceiptRawCandidates
}

struct UnavailableReceiptLocalModelExtractor: ReceiptLocalModelExtracting, Sendable {
    func extract(
        from document: ReceiptOCRDocument,
        context: ReceiptExtractionContext,
        lineItemsEnabled: Bool
    ) async throws -> ReceiptRawCandidates {
        throw ReceiptStructuredExtractionError.modelUnavailable
    }
}

enum ReceiptStructuredExtractionError: Error, Equatable, Sendable {
    case unavailable
    case invalidContext
    case modelUnavailable
    case timedOut
}

struct ReceiptStructuredExtractionService: Sendable {
    private let baseline: LocalReceiptRecognitionBaseline
    private let deterministicExtractor: ReceiptDeterministicExtractor
    private let validator: ReceiptCandidateValidator
    private let localModel: any ReceiptLocalModelExtracting
    private let lineItemExperiment: ReceiptLineItemExperiment
    private let modelTimeoutNanoseconds: UInt64

    init(
        baseline: LocalReceiptRecognitionBaseline,
        deterministicExtractor: ReceiptDeterministicExtractor = ReceiptDeterministicExtractor(),
        validator: ReceiptCandidateValidator = ReceiptCandidateValidator(),
        localModel: any ReceiptLocalModelExtracting = FoundationModelsReceiptExtractor(),
        lineItemExperiment: ReceiptLineItemExperiment = .production,
        modelTimeoutNanoseconds: UInt64 = 4_000_000_000
    ) {
        self.baseline = baseline
        self.deterministicExtractor = deterministicExtractor
        self.validator = validator
        self.localModel = localModel
        self.lineItemExperiment = lineItemExperiment
        self.modelTimeoutNanoseconds = modelTimeoutNanoseconds
    }

    func extract(
        from document: ReceiptOCRDocument,
        context: ReceiptExtractionContext
    ) async throws -> ReceiptStructuredExtractionResult {
        guard baseline != .unavailable else {
            throw ReceiptStructuredExtractionError.unavailable
        }
        guard Money.isSupported(context.expectedCurrencyCode),
              !context.localeIdentifier.isEmpty,
              modelTimeoutNanoseconds > 0 else {
            throw ReceiptStructuredExtractionError.invalidContext
        }
        try Task.checkCancellation()

        let deterministicCandidates = deterministicExtractor.extract(from: document)
        let deterministic = validator.validate(
            deterministicCandidates,
            source: .deterministic,
            context: context,
            lineItemExperiment: lineItemExperiment
        )

        guard baseline == .deterministicWithOnDeviceModel else {
            return finalized(deterministic, execution: .deterministic, context: context)
        }
        guard !deterministic.fields.isComplete || lineItemExperiment.isEnabled else {
            return finalized(deterministic, execution: .deterministic, context: context)
        }

        do {
            let modelCandidates = try await timedModelExtraction(
                document: document,
                context: context
            )
            guard ReceiptModelEvidenceVerifier().isBackedByDocument(
                modelCandidates,
                document: document
            ) else {
                return finalized(
                    deterministic,
                    execution: .deterministicFallback(.invalidEvidence),
                    context: context
                )
            }
            let model = validator.validate(
                modelCandidates,
                source: .onDeviceModel,
                context: context,
                lineItemExperiment: lineItemExperiment
            )
            let merged = validator.merge(deterministic: deterministic, supplement: model)
            let execution: ReceiptExtractionExecution = merged.usedSupplement
                ? .deterministicWithOnDeviceModel
                : .deterministicFallback(.invalidOutput)
            return finalized(merged.result, execution: execution, context: context)
        } catch is CancellationError {
            throw CancellationError()
        } catch ReceiptStructuredExtractionError.timedOut {
            return finalized(
                deterministic,
                execution: .deterministicFallback(.timedOut),
                context: context
            )
        } catch ReceiptStructuredExtractionError.modelUnavailable {
            return finalized(
                deterministic,
                execution: .deterministicFallback(.unavailable),
                context: context
            )
        } catch {
            return finalized(
                deterministic,
                execution: .deterministicFallback(.modelError),
                context: context
            )
        }
    }

    private func finalized(
        _ validated: ReceiptValidatedCandidates,
        execution: ReceiptExtractionExecution,
        context: ReceiptExtractionContext
    ) -> ReceiptStructuredExtractionResult {
        let duplicateResolution = ReceiptDuplicateDetector().resolve(
            fields: validated.fields,
            references: context.duplicateReferences
        )
        return ReceiptStructuredExtractionResult(
            fields: validated.fields,
            lineItems: validated.lineItems,
            duplicateResolution: duplicateResolution,
            execution: execution
        )
    }

    private func timedModelExtraction(
        document: ReceiptOCRDocument,
        context: ReceiptExtractionContext
    ) async throws -> ReceiptRawCandidates {
        let localModel = localModel
        let lineItemsEnabled = lineItemExperiment.isEnabled
        let timeout = modelTimeoutNanoseconds
        return try await withThrowingTaskGroup(of: ReceiptRawCandidates.self) { group in
            group.addTask {
                try await localModel.extract(
                    from: document,
                    context: context,
                    lineItemsEnabled: lineItemsEnabled
                )
            }
            group.addTask {
                try await Task.sleep(nanoseconds: timeout)
                throw ReceiptStructuredExtractionError.timedOut
            }
            guard let first = try await group.next() else {
                throw ReceiptStructuredExtractionError.modelUnavailable
            }
            group.cancelAll()
            return first
        }
    }
}

struct ReceiptDeterministicExtractor: Sendable {
    private let totalLabels = [
        "grand total", "amount due", "balance due", "total", "应付", "應付", "实付", "實付",
        "合计", "合計", "总计", "總計",
    ]
    private let nonTotalLabels = [
        "subtotal", "sub total", "tax", "tip", "change", "cash", "tendered", "小计", "小計",
        "税", "稅", "找零",
    ]

    func extract(from document: ReceiptOCRDocument) -> ReceiptRawCandidates {
        let values = document.lines.map(\.text.value)
        let totalLines = values.filter(isExplicitTotalLine)
        let currencyLines = values.filter(containsCurrencyMarker)
        let fallbackTotals = totalLines.isEmpty && currencyLines.count == 1 ? currencyLines : []

        return ReceiptRawCandidates(
            merchantEvidence: Array(values.prefix(8).filter(isMerchantCandidate).prefix(1)),
            dateEvidence: values.filter(containsDateShape),
            totalEvidence: totalLines.isEmpty ? fallbackTotals : totalLines,
            lineItemEvidence: []
        )
    }

    private func isExplicitTotalLine(_ value: String) -> Bool {
        let folded = folded(value)
        guard nonTotalLabels.allSatisfy({ !containsLabel($0, in: folded) }) else { return false }
        return totalLabels.contains { containsLabel($0, in: folded) }
    }

    private func isMerchantCandidate(_ value: String) -> Bool {
        let folded = folded(value)
        guard !folded.isEmpty,
              folded != ReceiptSensitiveTextFilter.replacementToken,
              !isExplicitTotalLine(value),
              !containsDateShape(value),
              !containsCurrencyMarker(value),
              !folded.allSatisfy({ $0.isNumber || $0.isWhitespace || $0.isPunctuation }) else {
            return false
        }
        return true
    }

    private func containsDateShape(_ value: String) -> Bool {
        let patterns = [
            #"\b\p{N}{4}[\-\./]\p{N}{1,2}[\-\./]\p{N}{1,2}\b"#,
            #"\b\p{N}{1,2}[\-\./]\p{N}{1,2}[\-\./]\p{N}{4}\b"#,
            #"\p{N}{4}\s*年\s*\p{N}{1,2}\s*月\s*\p{N}{1,2}\s*日"#,
        ]
        return patterns.contains { pattern in
            value.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func containsCurrencyMarker(_ value: String) -> Bool {
        if let expression = try? NSRegularExpression(pattern: #"\b[A-Z]{3}\b"#) {
            let range = NSRange(value.startIndex..<value.endIndex, in: value)
            if expression.matches(in: value, range: range).contains(where: { match in
                guard let range = Range(match.range, in: value) else { return false }
                return Money.isSupported(String(value[range]))
            }) {
                return true
            }
        }
        return value.unicodeScalars.contains { scalar in
            "$€£¥￥₹₩₫฿₱₪₺".unicodeScalars.contains(scalar)
        }
    }

    private func containsLabel(_ label: String, in value: String) -> Bool {
        guard label.unicodeScalars.allSatisfy({ CharacterSet.lowercaseLetters.contains($0) || $0 == " " }) else {
            return value.contains(label)
        }
        let escaped = NSRegularExpression.escapedPattern(for: label)
        return value.range(
            of: #"(?<![a-z])\#(escaped)(?![a-z])"#,
            options: .regularExpression
        ) != nil
    }

    private func folded(_ value: String) -> String {
        value.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }
}

struct ReceiptValidatedCandidates: Equatable, Sendable {
    let fields: ReceiptCoreFields
    let lineItems: [ReceiptLineItem]
}

struct ReceiptCandidateValidator: Sendable {
    struct MergeResult: Sendable {
        let result: ReceiptValidatedCandidates
        let usedSupplement: Bool
    }

    func validate(
        _ candidates: ReceiptRawCandidates,
        source: ReceiptFieldSource,
        context: ReceiptExtractionContext,
        lineItemExperiment: ReceiptLineItemExperiment
    ) -> ReceiptValidatedCandidates {
        let fields = ReceiptCoreFields(
            merchantName: resolveMerchant(candidates.merchantEvidence, source: source),
            purchaseDate: ReceiptDateParser().resolve(
                candidates.dateEvidence,
                source: source,
                order: context.dateOrder,
                calendar: context.calendar
            ),
            total: ReceiptAmountParser().resolve(
                candidates.totalEvidence,
                source: source,
                expectedCurrencyCode: context.expectedCurrencyCode,
                localeIdentifier: context.localeIdentifier
            )
        )
        return ReceiptValidatedCandidates(
            fields: fields,
            lineItems: validateLineItems(
                candidates.lineItemEvidence,
                source: source,
                expectedCurrencyCode: context.expectedCurrencyCode,
                localeIdentifier: context.localeIdentifier,
                experiment: lineItemExperiment
            )
        )
    }

    func merge(
        deterministic: ReceiptValidatedCandidates,
        supplement: ReceiptValidatedCandidates
    ) -> MergeResult {
        var usedSupplement = false
        let merchant = merged(
            deterministic.fields.merchantName,
            supplement.fields.merchantName,
            usedSupplement: &usedSupplement
        )
        let date = merged(
            deterministic.fields.purchaseDate,
            supplement.fields.purchaseDate,
            usedSupplement: &usedSupplement
        )
        let total = merged(
            deterministic.fields.total,
            supplement.fields.total,
            usedSupplement: &usedSupplement
        )
        let lineItems: [ReceiptLineItem]
        if deterministic.lineItems.isEmpty, !supplement.lineItems.isEmpty {
            lineItems = supplement.lineItems
            usedSupplement = true
        } else {
            lineItems = deterministic.lineItems
        }
        return MergeResult(
            result: ReceiptValidatedCandidates(
                fields: ReceiptCoreFields(
                    merchantName: merchant,
                    purchaseDate: date,
                    total: total
                ),
                lineItems: lineItems
            ),
            usedSupplement: usedSupplement
        )
    }

    private func resolveMerchant(
        _ evidence: [String],
        source: ReceiptFieldSource
    ) -> ReceiptFieldResolution<String> {
        guard !evidence.isEmpty else { return .missing }
        let candidates = evidence.compactMap { value -> String? in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  trimmed.utf8.count <= 160,
                  trimmed != ReceiptSensitiveTextFilter.replacementToken,
                  trimmed.contains(where: { $0.isLetter }) else {
                return nil
            }
            return trimmed
        }
        guard let first = candidates.first else { return .rejected(.invalidMerchant) }
        let unique = Set(candidates.compactMap(ReceiptMerchantNormalizer.normalizedKey))
        guard unique.count == 1 else { return .rejected(.invalidMerchant) }
        return .accepted(first, source: source)
    }

    private func validateLineItems(
        _ candidates: [ReceiptRawLineItemCandidate],
        source: ReceiptFieldSource,
        expectedCurrencyCode: String,
        localeIdentifier: String,
        experiment: ReceiptLineItemExperiment
    ) -> [ReceiptLineItem] {
        guard experiment.isEnabled, candidates.count <= 64 else { return [] }
        var output: [ReceiptLineItem] = []
        output.reserveCapacity(candidates.count)
        for candidate in candidates {
            let name = candidate.nameEvidence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty,
                  name.utf8.count <= 160,
                  name.contains(where: { $0.isLetter }) else {
                return []
            }
            let resolution = ReceiptAmountParser().resolve(
                [candidate.amountEvidence],
                source: source,
                expectedCurrencyCode: expectedCurrencyCode,
                localeIdentifier: localeIdentifier
            )
            guard case let .accepted(amount, _) = resolution else { return [] }
            output.append(ReceiptLineItem(name: name, amount: amount))
        }
        return output
    }

    private func merged<Value: Equatable & Sendable>(
        _ deterministic: ReceiptFieldResolution<Value>,
        _ supplement: ReceiptFieldResolution<Value>,
        usedSupplement: inout Bool
    ) -> ReceiptFieldResolution<Value> {
        switch deterministic {
        case .accepted, .rejected:
            return deterministic
        case .missing:
            if case .accepted = supplement {
                usedSupplement = true
                return supplement
            }
            return deterministic
        }
    }
}

struct ReceiptDateParser: Sendable {
    func resolve(
        _ evidence: [String],
        source: ReceiptFieldSource,
        order: ReceiptDateOrder,
        calendar: Calendar
    ) -> ReceiptFieldResolution<ReceiptCalendarDate> {
        guard !evidence.isEmpty else { return .missing }
        var dates: Set<ReceiptCalendarDate> = []
        var sawInvalidCandidate = false
        for value in evidence {
            let parsed = parsedDates(in: value, order: order, calendar: calendar)
            dates.formUnion(parsed.dates)
            sawInvalidCandidate = sawInvalidCandidate || parsed.sawInvalidCandidate
        }
        guard !sawInvalidCandidate else { return .rejected(.invalidDate) }
        guard !dates.isEmpty else { return .rejected(.invalidDate) }
        guard dates.count == 1, let date = dates.first else {
            return .rejected(.ambiguousDate)
        }
        return .accepted(date, source: source)
    }

    private func parsedDates(
        in value: String,
        order: ReceiptDateOrder,
        calendar: Calendar
    ) -> (dates: Set<ReceiptCalendarDate>, sawInvalidCandidate: Bool) {
        let normalized = ReceiptTextNormalization.asciiDigits(value)
        let yearFirst = matches(
            pattern: #"\b(\d{4})[\-\./](\d{1,2})[\-\./](\d{1,2})\b"#,
            in: normalized
        ).map { ($0[1], $0[2], $0[3]) }
        let chinese = matches(
            pattern: #"(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日"#,
            in: normalized
        ).map { ($0[1], $0[2], $0[3]) }
        let localOrder = matches(
            pattern: #"\b(\d{1,2})[\-\./](\d{1,2})[\-\./](\d{4})\b"#,
            in: normalized
        ).map { values -> (String, String, String) in
            switch order {
            case .monthDayYear: (values[3], values[1], values[2])
            case .dayMonthYear: (values[3], values[2], values[1])
            }
        }
        let shapes = yearFirst + chinese + localOrder
        var dates: Set<ReceiptCalendarDate> = []
        var sawInvalidCandidate = shapes.isEmpty
        for shape in shapes {
            guard let year = Int(shape.0), let month = Int(shape.1), let day = Int(shape.2) else {
                sawInvalidCandidate = true
                continue
            }
            let candidate = ReceiptCalendarDate(year: year, month: month, day: day)
            if isValid(candidate, calendar: calendar) {
                dates.insert(candidate)
            } else {
                sawInvalidCandidate = true
            }
        }
        return (dates, sawInvalidCandidate)
    }

    private func isValid(_ value: ReceiptCalendarDate, calendar: Calendar) -> Bool {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = value.year
        components.month = value.month
        components.day = value.day
        components.hour = 12
        guard let date = calendar.date(from: components) else { return false }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        return roundTrip.year == value.year
            && roundTrip.month == value.month
            && roundTrip.day == value.day
    }

    private func matches(pattern: String, in value: String) -> [[String]] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return expression.matches(in: value, range: range).compactMap { match in
            guard match.numberOfRanges == 4 else { return nil }
            return (0..<4).compactMap { index -> String? in
                guard let range = Range(match.range(at: index), in: value) else { return nil }
                return String(value[range])
            }
        }
    }
}

struct ReceiptAmountParser: Sendable {
    private enum ParseFailure: Error {
        case invalidAmount
        case unsupportedCurrency
        case currencyMismatch
        case unsupportedScale
        case amountOutOfRange
        case ambiguous
    }

    func resolve(
        _ evidence: [String],
        source: ReceiptFieldSource,
        expectedCurrencyCode: String,
        localeIdentifier: String
    ) -> ReceiptFieldResolution<Money> {
        guard !evidence.isEmpty else { return .missing }
        var amounts: Set<Money> = []
        var failures: [ParseFailure] = []
        for value in evidence {
            do {
                amounts.formUnion(
                    try parsedAmounts(
                        in: value,
                        expectedCurrencyCode: expectedCurrencyCode,
                        localeIdentifier: localeIdentifier
                    )
                )
            } catch let failure as ParseFailure {
                failures.append(failure)
            } catch {
                failures.append(.invalidAmount)
            }
        }
        guard failures.isEmpty else {
            return .rejected(issue(for: failures[0]))
        }
        guard amounts.count <= 1 else { return .rejected(.ambiguousTotal) }
        if let amount = amounts.first {
            return .accepted(amount, source: source)
        }
        return .rejected(issue(for: failures.first ?? .invalidAmount))
    }

    private func parsedAmounts(
        in value: String,
        expectedCurrencyCode: String,
        localeIdentifier: String
    ) throws -> Set<Money> {
        guard Money.isSupported(expectedCurrencyCode) else { throw ParseFailure.unsupportedCurrency }
        try validateCurrencyMarker(in: value, expectedCurrencyCode: expectedCurrencyCode)

        let normalized = ReceiptTextNormalization.asciiDigits(value)
        guard let expression = try? NSRegularExpression(
            pattern: #"(?<![\p{N}])[-+]?\p{N}[\p{N}\s'’,\.]*\p{N}|(?<![\p{N}])[-+]?\p{N}(?![\p{N}])"#
        ) else {
            throw ParseFailure.invalidAmount
        }
        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        let tokens = expression.matches(in: normalized, range: range).compactMap { match -> String? in
            guard let range = Range(match.range, in: normalized) else { return nil }
            return String(normalized[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var values: Set<Money> = []
        var failures: [ParseFailure] = []
        for token in tokens {
            do {
                values.formUnion(
                    try parseNumericToken(
                        token,
                        currencyCode: expectedCurrencyCode,
                        localeIdentifier: localeIdentifier
                    )
                )
            } catch let failure as ParseFailure {
                failures.append(failure)
            }
        }
        if let failure = failures.first {
            throw failure
        }
        guard !values.isEmpty else { throw failures.first ?? ParseFailure.invalidAmount }
        return values
    }

    private func validateCurrencyMarker(
        in value: String,
        expectedCurrencyCode: String
    ) throws {
        let uppercase = value.uppercased()
        let ignoredAdjacentLabels: Set<String> = ["DUE", "TAX", "TIP", "PAY"]
        if let expression = try? NSRegularExpression(pattern: #"\b[A-Z]{3}\b"#) {
            let range = NSRange(uppercase.startIndex..<uppercase.endIndex, in: uppercase)
            let codes = expression.matches(in: uppercase, range: range).compactMap { match -> String? in
                guard let range = Range(match.range, in: uppercase) else { return nil }
                return String(uppercase[range])
            }
            let currencyCodes = codes.filter(Money.isSupported)
            if let explicit = currencyCodes.first, explicit != expectedCurrencyCode {
                throw ParseFailure.currencyMismatch
            }
            if Set(currencyCodes).count > 1 { throw ParseFailure.currencyMismatch }
        }

        if let expression = try? NSRegularExpression(
            pattern: #"\b([A-Z]{3})\b(?=\s*(?:[$€£¥￥₹₩₫฿₱₪₺]\s*)?[-+]?\p{N})"#
        ) {
            let range = NSRange(uppercase.startIndex..<uppercase.endIndex, in: uppercase)
            let adjacentCodes = expression.matches(in: uppercase, range: range).compactMap {
                match -> String? in
                guard let range = Range(match.range(at: 1), in: uppercase) else { return nil }
                return String(uppercase[range])
            }
            if adjacentCodes.contains(where: {
                !Money.isSupported($0) && !ignoredAdjacentLabels.contains($0)
            }) {
                throw ParseFailure.unsupportedCurrency
            }
        }

        let exactSymbols: [Character: String] = [
            "€": "EUR", "£": "GBP", "₹": "INR", "₩": "KRW", "₫": "VND", "฿": "THB",
            "₱": "PHP", "₪": "ILS", "₺": "TRY",
        ]
        for (symbol, currency) in exactSymbols where value.contains(symbol) {
            guard currency == expectedCurrencyCode else { throw ParseFailure.currencyMismatch }
        }
        if value.contains("$") {
            let dollarCurrencies: Set<String> = ["AUD", "CAD", "HKD", "MXN", "NZD", "SGD", "TWD", "USD"]
            guard dollarCurrencies.contains(expectedCurrencyCode) else {
                throw ParseFailure.currencyMismatch
            }
        }
        if value.contains("¥") || value.contains("￥") {
            guard expectedCurrencyCode == "CNY" || expectedCurrencyCode == "JPY" else {
                throw ParseFailure.currencyMismatch
            }
        }
    }

    private func parseNumericToken(
        _ raw: String,
        currencyCode: String,
        localeIdentifier: String
    ) throws -> Set<Money> {
        var token = raw.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
        guard !token.hasPrefix("-"), !token.hasPrefix("+"), !token.isEmpty else {
            throw ParseFailure.invalidAmount
        }
        token = ReceiptTextNormalization.asciiDigits(token)
        let exponent = Money.exponent(for: currencyCode)
        var interpretations: Set<Int64> = []

        let dotCount = token.filter { $0 == "." }.count
        let commaCount = token.filter { $0 == "," }.count
        let locale = Locale(identifier: localeIdentifier)
        let localeDecimal = locale.decimalSeparator?.first
        let localeGrouping = locale.groupingSeparator?.first
        let hasLocalePunctuation = [localeDecimal, localeGrouping]
            .compactMap { $0 }
            .contains { token.contains($0) }

        if hasLocalePunctuation {
            if let localeValue = interpreted(
                token,
                decimalSeparator: localeDecimal,
                groupingSeparator: localeGrouping,
                exponent: exponent
            ) {
                interpretations.insert(localeValue)
            }
        } else if dotCount > 0, commaCount > 0 {
            let decimalSeparator: Character = token.lastIndex(of: ".")! > token.lastIndex(of: ",")!
                ? "." : ","
            let groupingSeparator: Character = decimalSeparator == "." ? "," : "."
            if let value = interpreted(
                token,
                decimalSeparator: decimalSeparator,
                groupingSeparator: groupingSeparator,
                exponent: exponent
            ) {
                interpretations.insert(value)
            }
        } else if dotCount > 0 || commaCount > 0 {
            let separator: Character = dotCount > 0 ? "." : ","
            if let decimal = interpreted(
                token,
                decimalSeparator: separator,
                groupingSeparator: nil,
                exponent: exponent
            ) {
                interpretations.insert(decimal)
            }
            if let grouped = interpreted(
                token,
                decimalSeparator: nil,
                groupingSeparator: separator,
                exponent: exponent
            ) {
                interpretations.insert(grouped)
            }
            if token.filter({ $0 == separator }).count > 1,
               let mixed = interpreted(
                   token,
                   decimalSeparator: separator,
                   groupingSeparator: separator,
                   exponent: exponent
               ) {
                interpretations.insert(mixed)
            }
        } else if let value = scaledMinorUnits(major: token, fraction: "", exponent: exponent) {
            interpretations.insert(value)
        }

        guard !interpretations.isEmpty else {
            throw token.contains(".") || token.contains(",")
                ? ParseFailure.unsupportedScale
                : ParseFailure.invalidAmount
        }
        guard interpretations.count == 1, let minorUnits = interpretations.first else {
            throw ParseFailure.ambiguous
        }
        guard minorUnits > 0,
              minorUnits <= Money.maximumMinorUnits(for: currencyCode) else {
            throw ParseFailure.amountOutOfRange
        }
        return [Money(minorUnits: minorUnits, currencyCode: currencyCode)]
    }

    private func interpreted(
        _ token: String,
        decimalSeparator: Character?,
        groupingSeparator: Character?,
        exponent: Int
    ) -> Int64? {
        let parts: [Substring]
        var majorPart: String
        let fractionPart: String

        if let decimalSeparator, token.contains(decimalSeparator) {
            parts = token.split(separator: decimalSeparator, omittingEmptySubsequences: false)
            if decimalSeparator == groupingSeparator {
                guard parts.count >= 2 else { return nil }
                fractionPart = String(parts.last!)
                let majorGroups = parts.dropLast().map { String($0) }
                guard validGrouping(majorGroups) else { return nil }
                majorPart = majorGroups.joined()
            } else {
                guard parts.count == 2 else { return nil }
                majorPart = String(parts[0])
                fractionPart = String(parts[1])
                if let groupingSeparator, majorPart.contains(groupingSeparator) {
                    let groups = majorPart.split(
                        separator: groupingSeparator,
                        omittingEmptySubsequences: false
                    ).map { String($0) }
                    guard validGrouping(groups) else { return nil }
                    majorPart = groups.joined()
                }
            }
        } else {
            fractionPart = ""
            if let groupingSeparator, token.contains(groupingSeparator) {
                let groups = token.split(
                    separator: groupingSeparator,
                    omittingEmptySubsequences: false
                ).map { String($0) }
                guard validGrouping(groups) else { return nil }
                majorPart = groups.joined()
            } else {
                majorPart = token
            }
        }

        guard !majorPart.isEmpty,
              majorPart.allSatisfy(\.isNumber),
              fractionPart.allSatisfy(\.isNumber),
              fractionPart.count <= exponent else {
            return nil
        }
        return scaledMinorUnits(major: majorPart, fraction: fractionPart, exponent: exponent)
    }

    private func validGrouping(_ groups: [String]) -> Bool {
        guard let first = groups.first,
              (1...3).contains(first.count),
              first.allSatisfy(\.isNumber) else {
            return false
        }
        return groups.dropFirst().allSatisfy { group in
            group.count == 3 && group.allSatisfy(\.isNumber)
        }
    }

    private func scaledMinorUnits(major: String, fraction: String, exponent: Int) -> Int64? {
        guard let majorUnits = Int64(major) else { return nil }
        let scale: Int64? = switch exponent {
        case 0: 1
        case 1: 10
        case 2: 100
        case 3: 1_000
        default: nil
        }
        guard let scale else { return nil }
        let paddedFraction = fraction + String(repeating: "0", count: exponent - fraction.count)
        guard let fractionUnits = Int64(paddedFraction.isEmpty ? "0" : paddedFraction) else {
            return nil
        }
        let product = majorUnits.multipliedReportingOverflow(by: scale)
        guard !product.overflow else { return nil }
        let sum = product.partialValue.addingReportingOverflow(fractionUnits)
        guard !sum.overflow else { return nil }
        return sum.partialValue
    }

    private func issue(for failure: ParseFailure) -> ReceiptFieldIssue {
        switch failure {
        case .invalidAmount: .invalidAmount
        case .unsupportedCurrency: .unsupportedCurrency
        case .currencyMismatch: .currencyMismatch
        case .unsupportedScale: .unsupportedScale
        case .amountOutOfRange: .amountOutOfRange
        case .ambiguous: .ambiguousTotal
        }
    }
}

struct ReceiptDuplicateDetector: Sendable {
    func resolve(
        fields: ReceiptCoreFields,
        references: [ReceiptDuplicateReference]
    ) -> ReceiptDuplicateResolution {
        guard let merchant = fields.merchantName.acceptedValue,
              let date = fields.purchaseDate.acceptedValue,
              let total = fields.total.acceptedValue,
              let merchantKey = ReceiptMerchantNormalizer.normalizedKey(merchant) else {
            return .notEvaluable
        }
        let matches = references.compactMap { reference -> UUID? in
            guard reference.purchaseDate == date,
                  reference.total == total,
                  reference.merchantName.flatMap(ReceiptMerchantNormalizer.normalizedKey) == merchantKey else {
                return nil
            }
            return reference.id
        }.sorted { $0.uuidString < $1.uuidString }
        return matches.isEmpty ? .noMatch : .exactMatches(matches)
    }
}

enum ReceiptMerchantNormalizer {
    static func normalizedKey(_ name: String) -> String? {
        let folded = name.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        let scalars = folded.unicodeScalars.filter(CharacterSet.alphanumerics.contains)
        let value = String(String.UnicodeScalarView(scalars))
        return value.isEmpty ? nil : value
    }
}

struct ReceiptModelEvidenceVerifier: Sendable {
    func isBackedByDocument(
        _ candidates: ReceiptRawCandidates,
        document: ReceiptOCRDocument
    ) -> Bool {
        let source = document.modelSafeText
        let evidence = candidates.merchantEvidence
            + candidates.dateEvidence
            + candidates.totalEvidence
            + candidates.lineItemEvidence.flatMap { [$0.nameEvidence, $0.amountEvidence] }
        return evidence.allSatisfy { value in
            !value.isEmpty
                && source.range(of: value) != nil
        }
    }
}

enum ReceiptTextNormalization {
    static func asciiDigits(_ value: String) -> String {
        String(value.map { character -> Character in
            guard let number = character.wholeNumberValue, (0...9).contains(number) else {
                return character
            }
            return Character(String(number))
        })
    }
}
