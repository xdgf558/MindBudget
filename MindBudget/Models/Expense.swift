import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amountMinorUnits: Int64
    var currencyCode: String
    var categoryRaw: String
    var bucketRaw: String
    var merchantName: String?
    /// Stable derived key used for local aggregation and privacy-eligible lookups.
    var normalizedMerchantName: String?
    var note: String?
    var spentAt: Date
    var spentTimeZoneIdentifier: String
    var createdAt: Date
    var updatedAt: Date
    var paymentMethodRaw: String?
    var emotionTagRaw: String?
    var purchaseReasonRaw: String?
    var isPlanned: Bool
    var isRecurring: Bool
    var sourceRaw: String
    var allowMerchantIndexing: Bool

    init(
        id: UUID,
        amountMinorUnits: Int64,
        currencyCode: String,
        categoryRaw: String,
        bucketRaw: String,
        merchantName: String?,
        normalizedMerchantName: String?,
        note: String?,
        spentAt: Date,
        spentTimeZoneIdentifier: String,
        createdAt: Date,
        updatedAt: Date,
        paymentMethodRaw: String?,
        emotionTagRaw: String?,
        purchaseReasonRaw: String?,
        isPlanned: Bool,
        isRecurring: Bool,
        sourceRaw: String,
        allowMerchantIndexing: Bool
    ) {
        self.id = id
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.categoryRaw = categoryRaw
        self.bucketRaw = bucketRaw
        self.merchantName = merchantName
        self.normalizedMerchantName = normalizedMerchantName
        self.note = note
        self.spentAt = spentAt
        self.spentTimeZoneIdentifier = spentTimeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.paymentMethodRaw = paymentMethodRaw
        self.emotionTagRaw = emotionTagRaw
        self.purchaseReasonRaw = purchaseReasonRaw
        self.isPlanned = isPlanned
        self.isRecurring = isRecurring
        self.sourceRaw = sourceRaw
        self.allowMerchantIndexing = allowMerchantIndexing
    }

}
