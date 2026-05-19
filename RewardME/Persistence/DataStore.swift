import Foundation

/// Persists tasks and the user profile to UserDefaults using JSON encoding.
final class DataStore {
    static let shared = DataStore()

    private let tasksKey        = "rewardme_tasks"
    private let profileKey      = "rewardme_profile"
    private let rewardsKey      = "rewardme_rewards"
    private let redemptionsKey  = "rewardme_redemptions"
    private let defaults        = UserDefaults.standard

    private init() {}

    // MARK: - Tasks

    func saveTasks(_ tasks: [TaskItem]) {
        if let data = try? JSONEncoder().encode(tasks) {
            defaults.set(data, forKey: tasksKey)
        }
    }

    func loadTasks() -> [TaskItem] {
        guard
            let data  = defaults.data(forKey: tasksKey),
            let tasks = try? JSONDecoder().decode([TaskItem].self, from: data)
        else { return [] }
        return tasks
    }

    // MARK: - Profile

    func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: profileKey)
        }
    }

    func loadProfile() -> UserProfile {
        guard
            let data    = defaults.data(forKey: profileKey),
            let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return UserProfile() }
        return profile
    }

    // MARK: - Rewards

    func saveRewards(_ rewards: [RewardDefinition]) {
        if let data = try? JSONEncoder().encode(rewards) {
            defaults.set(data, forKey: rewardsKey)
        }
    }

    func loadRewards() -> [RewardDefinition] {
        guard
            let data    = defaults.data(forKey: rewardsKey),
            let rewards = try? JSONDecoder().decode([RewardDefinition].self, from: data)
        else { return [] }
        return rewards
    }

    // MARK: - Redemptions

    func saveRedemptions(_ redemptions: [RedemptionRecord]) {
        if let data = try? JSONEncoder().encode(redemptions) {
            defaults.set(data, forKey: redemptionsKey)
        }
    }

    func loadRedemptions() -> [RedemptionRecord] {
        guard
            let data        = defaults.data(forKey: redemptionsKey),
            let redemptions = try? JSONDecoder().decode([RedemptionRecord].self, from: data)
        else { return [] }
        return redemptions
    }

    // MARK: - Reset (for testing / debug)

    func reset() {
        defaults.removeObject(forKey: tasksKey)
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: rewardsKey)
        defaults.removeObject(forKey: redemptionsKey)
    }
}
