import Foundation
import SwiftData

@Model
final class Merchant {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var normalizedName: String
    var displayName: String
    var primaryCategoryRaw: String?
    var visitCount: Int
    var lastVisitedAt: Date?
    var totalMinorUnitsAllTime: Int64

    init(
        id: UUID,
        normalizedName: String,
        displayName: String,
        primaryCategoryRaw: String?,
        visitCount: Int,
        lastVisitedAt: Date?,
        totalMinorUnitsAllTime: Int64
    ) {
        self.id = id
        self.normalizedName = normalizedName
        self.displayName = displayName
        self.primaryCategoryRaw = primaryCategoryRaw
        self.visitCount = visitCount
        self.lastVisitedAt = lastVisitedAt
        self.totalMinorUnitsAllTime = totalMinorUnitsAllTime
    }
}

/// Currency metadata for the rebuildable merchant aggregate deliberately lives outside
/// `Merchant`. Keeping this companion model preserves the historical V1–V4 `Merchant`
/// schema hashes while making the aggregate's accounting currency explicit in Schema V5.
@Model
final class MerchantAccountingContext {
    @Attribute(.unique) var merchantID: UUID
    var currencyCode: String

    init(merchantID: UUID, currencyCode: String) {
        self.merchantID = merchantID
        self.currencyCode = currencyCode
    }
}
