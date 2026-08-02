import Foundation
import SwiftData

@Model
final class ReminderEvent {
    @Attribute(.unique) var id: UUID
    var insightTypeRaw: String
    var scopeKey: String
    var channelRaw: String
    var shownAt: Date
    var categoryRiskBasisPoints: Int?
    var isInterrupting: Bool
    var userResponseRaw: String?
    var respondedAt: Date?

    init(
        id: UUID,
        insightTypeRaw: String,
        scopeKey: String,
        channelRaw: String,
        shownAt: Date,
        categoryRiskBasisPoints: Int?,
        isInterrupting: Bool,
        userResponseRaw: String?,
        respondedAt: Date?
    ) {
        self.id = id
        self.insightTypeRaw = insightTypeRaw
        self.scopeKey = scopeKey
        self.channelRaw = channelRaw
        self.shownAt = shownAt
        self.categoryRiskBasisPoints = categoryRiskBasisPoints
        self.isInterrupting = isInterrupting
        self.userResponseRaw = userResponseRaw
        self.respondedAt = respondedAt
    }
}
