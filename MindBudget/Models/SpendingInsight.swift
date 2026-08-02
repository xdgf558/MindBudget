import Foundation
import SwiftData

@Model
final class SpendingInsight {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var dedupeKey: String
    var typeRaw: String
    var severityRaw: String
    var titleKey: String
    var bodyKey: String
    var payloadJSON: String
    var relatedCategoryRaw: String?
    var relatedEmotionTagRaw: String?
    var createdAt: Date
    var periodStart: Date
    var periodEnd: Date
    var isDismissed: Bool
    var dismissedAt: Date?

    init(
        id: UUID,
        dedupeKey: String,
        typeRaw: String,
        severityRaw: String,
        titleKey: String,
        bodyKey: String,
        payloadJSON: String,
        relatedCategoryRaw: String?,
        relatedEmotionTagRaw: String?,
        createdAt: Date,
        periodStart: Date,
        periodEnd: Date,
        isDismissed: Bool,
        dismissedAt: Date?
    ) {
        self.id = id
        self.dedupeKey = dedupeKey
        self.typeRaw = typeRaw
        self.severityRaw = severityRaw
        self.titleKey = titleKey
        self.bodyKey = bodyKey
        self.payloadJSON = payloadJSON
        self.relatedCategoryRaw = relatedCategoryRaw
        self.relatedEmotionTagRaw = relatedEmotionTagRaw
        self.createdAt = createdAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.isDismissed = isDismissed
        self.dismissedAt = dismissedAt
    }
}
