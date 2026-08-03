import Foundation
import SwiftData

@Model
final class CoolingOffPlan {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var reviewAt: Date
    var durationHours: Int
    var statusRaw: String
    var notificationIdentifier: String?
    var completedAt: Date?
    var outcomeRaw: String?
    var outcomeRecordedAt: Date?
    var wishItem: WishItem?

    init(
        id: UUID,
        startedAt: Date,
        reviewAt: Date,
        durationHours: Int,
        statusRaw: String,
        notificationIdentifier: String?,
        completedAt: Date?,
        outcomeRaw: String?,
        outcomeRecordedAt: Date?,
        wishItem: WishItem?
    ) {
        self.id = id
        self.startedAt = startedAt
        self.reviewAt = reviewAt
        self.durationHours = durationHours
        self.statusRaw = statusRaw
        self.notificationIdentifier = notificationIdentifier
        self.completedAt = completedAt
        self.outcomeRaw = outcomeRaw
        self.outcomeRecordedAt = outcomeRecordedAt
        self.wishItem = wishItem
    }

}
