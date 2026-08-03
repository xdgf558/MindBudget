import Foundation
import SwiftData

@Model
final class ReflectionLog {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var contextRaw: String
    var selectedEmotionTagRaw: String?
    var selectedReasonRaw: String?
    var note: String?
    var relatedExpenseId: UUID?
    var relatedWishItemId: UUID?

    init(
        id: UUID,
        createdAt: Date,
        contextRaw: String,
        selectedEmotionTagRaw: String?,
        selectedReasonRaw: String?,
        note: String?,
        relatedExpenseId: UUID?,
        relatedWishItemId: UUID?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.contextRaw = contextRaw
        self.selectedEmotionTagRaw = selectedEmotionTagRaw
        self.selectedReasonRaw = selectedReasonRaw
        self.note = note
        self.relatedExpenseId = relatedExpenseId
        self.relatedWishItemId = relatedWishItemId
    }
}
