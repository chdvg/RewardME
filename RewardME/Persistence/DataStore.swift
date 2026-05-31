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
        do {
            defaults.set(try JSONEncoder().encode(tasks), forKey: tasksKey)
        } catch {
            print("❌ DataStore: failed to save tasks — \(error.localizedDescription)")
        }
    }

    func loadTasks() -> [TaskItem] {
        guard let data = defaults.data(forKey: tasksKey) else { return [] }
        do {
            return try JSONDecoder().decode([TaskItem].self, from: data)
        } catch {
            print("❌ DataStore: failed to load tasks — \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Profile

    func saveProfile(_ profile: UserProfile) {
        do {
            defaults.set(try JSONEncoder().encode(profile), forKey: profileKey)
        } catch {
            print("❌ DataStore: failed to save profile — \(error.localizedDescription)")
        }
    }

    func loadProfile() -> UserProfile {
        guard let data = defaults.data(forKey: profileKey) else { return UserProfile() }
        do {
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("❌ DataStore: failed to load profile — \(error.localizedDescription)")
            return UserProfile()
        }
    }

    // MARK: - Rewards

    func saveRewards(_ rewards: [RewardDefinition]) {
        do {
            defaults.set(try JSONEncoder().encode(rewards), forKey: rewardsKey)
        } catch {
            print("❌ DataStore: failed to save rewards — \(error.localizedDescription)")
        }
    }

    func loadRewards() -> [RewardDefinition] {
        guard let data = defaults.data(forKey: rewardsKey) else { return [] }
        do {
            return try JSONDecoder().decode([RewardDefinition].self, from: data)
        } catch {
            print("❌ DataStore: failed to load rewards — \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Redemptions

    func saveRedemptions(_ redemptions: [RedemptionRecord]) {
        do {
            defaults.set(try JSONEncoder().encode(redemptions), forKey: redemptionsKey)
        } catch {
            print("❌ DataStore: failed to save redemptions — \(error.localizedDescription)")
        }
    }

    func loadRedemptions() -> [RedemptionRecord] {
        guard let data = defaults.data(forKey: redemptionsKey) else { return [] }
        do {
            return try JSONDecoder().decode([RedemptionRecord].self, from: data)
        } catch {
            print("❌ DataStore: failed to load redemptions — \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Reset (for testing / debug)

    func reset() {
        defaults.removeObject(forKey: tasksKey)
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: rewardsKey)
        defaults.removeObject(forKey: redemptionsKey)
    }
}
