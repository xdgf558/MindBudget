import Foundation

struct CSVExportResult: Equatable, Sendable {
    let data: Data
    let rowCount: Int
}

struct CSVExporter: Sendable {
    static let header = [
        "record_type",
        "id",
        "occurred_at_utc",
        "time_zone",
        "amount",
        "amount_minor_units",
        "currency_code",
        "category",
        "bucket",
        "source_name_or_merchant",
        "note",
        "payment_method",
        "emotion_tag",
        "purchase_reason",
        "is_planned",
        "is_recurring",
        "entry_source",
        "allow_merchant_indexing",
        "created_at_utc",
        "updated_at_utc",
    ]

    func export(_ records: [ExpenseExportRecord]) -> CSVExportResult {
        export(expenses: records, incomes: [])
    }

    func export(
        expenses: [ExpenseExportRecord],
        incomes: [IncomeExportRecord]
    ) -> CSVExportResult {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        var lines = [Self.header.joined(separator: ",")]
        lines.reserveCapacity(expenses.count + incomes.count + 1)
        let rows = expenses.map(ExportRow.expense) + incomes.map(ExportRow.income)
        for row in rows.sorted(by: { $0.occurredAt < $1.occurredAt }) {
            let fields: [String]
            switch row {
            case let .expense(record):
                fields = expenseFields(record, dateFormatter: dateFormatter)
            case let .income(record):
                fields = incomeFields(record, dateFormatter: dateFormatter)
            }
            lines.append(fields.map(escapedCell).joined(separator: ","))
        }

        let body = lines.joined(separator: "\r\n") + "\r\n"
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(body.utf8))
        return CSVExportResult(data: data, rowCount: rows.count)
    }

    private func expenseFields(
        _ record: ExpenseExportRecord,
        dateFormatter: ISO8601DateFormatter
    ) -> [String] {
        [
            "expense",
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
    }

    private func incomeFields(
        _ record: IncomeExportRecord,
        dateFormatter: ISO8601DateFormatter
    ) -> [String] {
        [
            "income",
            record.id.uuidString.lowercased(),
            dateFormatter.string(from: record.receivedAt),
            record.receivedTimeZoneIdentifier,
            exactMajorUnits(record.amount),
            String(record.amount.minorUnits),
            record.amount.currencyCode,
            record.category.rawValue,
            "",
            spreadsheetSafe(record.sourceName ?? ""),
            spreadsheetSafe(record.note ?? ""),
            "",
            "",
            "",
            "false",
            "false",
            "manual",
            "false",
            dateFormatter.string(from: record.createdAt),
            dateFormatter.string(from: record.updatedAt),
        ]
    }

    private enum ExportRow {
        case expense(ExpenseExportRecord)
        case income(IncomeExportRecord)

        var occurredAt: Date {
            switch self {
            case let .expense(value): value.spentAt
            case let .income(value): value.receivedAt
            }
        }
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
