import Foundation

enum ReceiptSensitiveTextKind: String, CaseIterable, Hashable, Sendable {
    case paymentCardNumber
    case paymentCardLastFour
    case authorizationCode
}

enum ReceiptSensitiveTextFilterError: Error, Equatable, Sendable {
    case invalidRule
    case residualSensitiveText
}

/// Text that has crossed the mandatory receipt privacy boundary.
///
/// There is intentionally no public or internal memberwise initializer. Receipt OCR output can
/// obtain this value only through `ReceiptSensitiveTextFilter.filter(_:)` in this file.
struct ReceiptModelSafeText: Equatable, Sendable {
    private let storage: String
    let redactedKinds: Set<ReceiptSensitiveTextKind>

    var value: String { storage }

    fileprivate init(storage: String, redactedKinds: Set<ReceiptSensitiveTextKind>) {
        self.storage = storage
        self.redactedKinds = redactedKinds
    }
}

struct ReceiptSensitiveTextFilter {
    static let replacementToken = "[redacted]"

    private struct Rule {
        let kind: ReceiptSensitiveTextKind
        let pattern: String
    }

    /// Removes the exact sensitive value while retaining a stable non-content marker so line
    /// geometry, reading order, and confidence do not disappear when a whole line is private.
    func filter(_ input: String) throws -> ReceiptModelSafeText? {
        var output = normalizeWhitespaceAndControls(input)
        guard !output.isEmpty else { return nil }

        var redactedKinds: Set<ReceiptSensitiveTextKind> = []
        for rule in rules {
            guard let expression = try? NSRegularExpression(
                pattern: rule.pattern,
                options: [.caseInsensitive]
            ) else {
                throw ReceiptSensitiveTextFilterError.invalidRule
            }
            let mutable = NSMutableString(string: output)
            let matches = expression.matches(
                in: output,
                range: NSRange(location: 0, length: mutable.length)
            )
            guard !matches.isEmpty else { continue }

            for match in matches.reversed() {
                mutable.replaceCharacters(in: match.range, with: Self.replacementToken)
            }
            output = normalizeWhitespaceAndControls(mutable as String)
            redactedKinds.insert(rule.kind)
        }

        // The replacement token cannot match any rule. A residual match therefore means the
        // boundary failed to remove a sensitive value and the complete line must fail closed.
        for rule in rules {
            guard let expression = try? NSRegularExpression(
                pattern: rule.pattern,
                options: [.caseInsensitive]
            ) else {
                throw ReceiptSensitiveTextFilterError.invalidRule
            }
            let range = NSRange(output.startIndex..<output.endIndex, in: output)
            guard expression.firstMatch(in: output, range: range) == nil else {
                throw ReceiptSensitiveTextFilterError.residualSensitiveText
            }
        }

        guard !output.isEmpty else { return nil }
        return ReceiptModelSafeText(storage: output, redactedKinds: redactedKinds)
    }

    private var rules: [Rule] {
        // Ordering is part of the privacy contract. A complete PAN must be removed before a
        // labelled last-four rule can consume its first group and leave only twelve digits,
        // which would fall below the PAN rule's thirteen-digit lower bound.
        [
            Rule(
                kind: .paymentCardNumber,
                // Thirteen through nineteen Unicode digits, allowing common printed separators.
                // Luhn validity is deliberately not required: OCR errors must over-redact rather
                // than allow a plausible card value through the boundary.
                pattern: #"(?<![\p{N}])(?:[\p{N}][\x{0020}\t\-‐‑‒–—•·]*){12,18}[\p{N}](?![\p{N}])"#
            ),
            Rule(
                kind: .paymentCardLastFour,
                // English, Simplified/Traditional Chinese, and printed mask prefixes.
                pattern: #"(?:(?:last\s*(?:4|four)|ends?\s*(?:in)?|ending\s*(?:in)?|card(?:\s*(?:no\.?|number))?|末\s*四\s*(?:位|码|碼)?|[后後]\s*四\s*(?:位|码|碼)?|尾\s*(?:号|號)|卡\s*(?:号|號))\s*[:#：-]?\s*|(?:[x*•·]{2,})[\s\-]*)[\p{N}]{4}(?![\p{N}])"#
            ),
            Rule(
                kind: .authorizationCode,
                pattern: #"(?:auth(?:orization|orisation)?(?:\s*(?:code|no\.?))?|approval(?:\s*(?:code|no\.?))?|授权(?:码|号|號)|授權(?:码|碼|号|號)|批准(?:码|碼)|核准(?:码|碼))\s*[:#：-]?\s*[A-Z\p{N}][A-Z\p{N}-]{2,31}"#
            ),
        ]
    }

    private func normalizeWhitespaceAndControls(_ input: String) -> String {
        let controlSafe = input.unicodeScalars.map { scalar -> String in
            CharacterSet.controlCharacters.contains(scalar) ? " " : String(scalar)
        }.joined()
        return controlSafe
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
