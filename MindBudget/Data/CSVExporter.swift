import Foundation

struct CSVExportResult: Equatable, Sendable {
    let data: Data
    let rowCount: Int
}

struct CSVExporter: Sendable {
    static let header = [
        "id",
        "spent_at_utc",
        "spent_time_zone",
        "amount",
        "amount_minor_units",
        "currency_code",
        "category",
        "bucket",
        "merchant_name",
        "note",
        "payment_method",
        "emotion_tag",
        "purchase_reason",
        "is_planned",
        "is_recurring",
        "source",
        "allow_merchant_indexing",
        "created_at_utc",
        "updated_at_utc",
    ]

    func export(_ records: [ExpenseExportRecord]) -> CSVExportResult {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        var lines = [Self.header.joined(separator: ",")]
        lines.reserveCapacity(records.count + 1)
        for record in records {
            let fields = [
                record.id.uuidString.lowercased(),
                dateFormatter.string(from: record.spentAt),
                record.spentTimeZoneIdentifier,
                exactMajorUnits(record.amount),
                String(record.amount.minorUnits),
                record.amount.currencyCode,
                record.category.rawValue,
                record.bucket.rawValue,
                spreadsheetSafe(record.merchantName ?? ""),
                spreadsheetSafe(record.note ?? ""),
                record.paymentMethod?.rawValue ?? "",
                record.emotionTag?.rawValue ?? "",
                record.purchaseReason?.rawValue ?? "",
                record.isPlanned ? "true" : "false",
                record.isRecurring ? "true" : "false",
                record.source.rawValue,
                record.allowMerchantIndexing ? "true" : "false",
                dateFormatter.string(from: record.createdAt),
                dateFormatter.string(from: record.updatedAt),
            ]
            lines.append(fields.map(escapedCell).joined(separator: ","))
        }

        let body = lines.joined(separator: "\r\n") + "\r\n"
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(body.utf8))
        return CSVExportResult(data: data, rowCount: records.count)
    }

    private func exactMajorUnits(_ money: Money) -> String {
        let exponent = money.exponent
        let isNegative = money.minorUnits < 0
        var digits = String(money.minorUnits.magnitude)
        if exponent > 0 {
            if digits.count <= exponent {
                digits = String(repeating: "0", count: exponent - digits.count + 1) + digits
            }
            let separator = digits.index(digits.endIndex, offsetBy: -exponent)
            digits.insert(".", at: separator)
        }
        return isNegative ? "-" + digits : digits
    }

    private func spreadsheetSafe(_ value: String) -> String {
        guard let first = value.drop(while: { $0.isWhitespace }).first,
              "=+-@".contains(first) else {
            return value
        }
        return "'" + value
    }

    private func escapedCell(_ value: String) -> String {
        guard value.contains(",")
                || value.contains("\"")
                || value.contains("\n")
                || value.contains("\r") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
