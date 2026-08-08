import Foundation
import SwiftData

@Model
final class Income {
    @Attribute(.unique) var id: UUID
    var amountMinorUnits: Int64
    var currencyCode: String
    var categoryRaw: String
    var sourceName: String?
    var note: String?
    var receivedAt: Date
    var receivedTimeZoneIdentifier: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        amountMinorUnits: Int64,
        currencyCode: String,
        categoryRaw: String,
        sourceName: String?,
        note: String?,
        receivedAt: Date,
        receivedTimeZoneIdentifier: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.categoryRaw = categoryRaw
        self.sourceName = sourceName
        self.note = note
        self.receivedAt = receivedAt
        self.receivedTimeZoneIdentifier = receivedTimeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
