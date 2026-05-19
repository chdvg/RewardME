import Foundation

/// An immutable snapshot of a reward being redeemed — stored as history.
struct RedemptionRecord: Identifiable, Codable {
    var id: UUID
    var rewardID: UUID
    var rewardTitle: String
    var rewardEmoji: String
    var pointCost: Int
    var redeemedAt: Date

    init(reward: RewardDefinition) {
        self.id          = UUID()
        self.rewardID    = reward.id
        self.rewardTitle = reward.title
        self.rewardEmoji = reward.emoji
        self.pointCost   = reward.pointCost
        self.redeemedAt  = Date()
    }

    // MARK: - Migration-safe Codable

    enum CodingKeys: String, CodingKey {
        case id, rewardID, rewardTitle, rewardEmoji, pointCost, redeemedAt
    }

    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,   forKey: .id)
        rewardID     = try c.decodeIfPresent(UUID.self,   forKey: .rewardID)    ?? UUID()
        rewardTitle  = try c.decode(String.self, forKey: .rewardTitle)
        rewardEmoji  = try c.decodeIfPresent(String.self, forKey: .rewardEmoji) ?? "🎁"
        pointCost    = try c.decode(Int.self,    forKey: .pointCost)
        redeemedAt   = try c.decode(Date.self,   forKey: .redeemedAt)
    }
}
