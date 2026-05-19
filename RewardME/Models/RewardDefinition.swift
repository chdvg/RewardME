import Foundation

/// A user-defined reward that can be unlocked by spending points.
struct RewardDefinition: Identifiable, Codable {
    var id: UUID
    var title: String
    var notes: String       // optional description / how to use it
    var pointCost: Int
    var emoji: String       // single emoji for the reward icon
    var createdDate: Date

    init(title: String, notes: String = "", pointCost: Int, emoji: String = "🎁") {
        self.id          = UUID()
        self.title       = title
        self.notes       = notes
        self.pointCost   = max(1, pointCost)
        self.emoji       = emoji.isEmpty ? "🎁" : emoji
        self.createdDate = Date()
    }

    // MARK: - Migration-safe Codable

    enum CodingKeys: String, CodingKey {
        case id, title, notes, pointCost, emoji, createdDate
    }

    init(from decoder: Decoder) throws {
        let c       = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes)       ?? ""
        pointCost   = try c.decode(Int.self,    forKey: .pointCost)
        emoji       = try c.decodeIfPresent(String.self, forKey: .emoji)       ?? "🎁"
        createdDate = try c.decodeIfPresent(Date.self,   forKey: .createdDate) ?? Date()
    }
}
