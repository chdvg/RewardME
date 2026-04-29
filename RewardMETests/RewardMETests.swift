import XCTest
@testable import RewardME

// MARK: - Helpers

private extension RewardViewModel {
    /// Convenience: add a task, immediately complete it, and return the completed task.
    @discardableResult
    func addAndComplete(title: String, difficulty: TaskDifficulty) -> TaskItem {
        addTask(title: title, difficulty: difficulty)
        let task = tasks.first { $0.title == title }!
        toggleCompletion(of: task)
        return tasks.first { $0.id == task.id }!
    }
}

// MARK: - TaskItem Tests

final class TaskItemTests: XCTestCase {

    func test_defaultTask_isIncomplete() {
        let task = TaskItem(title: "Test", difficulty: .easy)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedDate)
        XCTAssertEqual(task.pointsAwarded, 0)
    }

    func test_completionDay_isNil_whenNotCompleted() {
        let task = TaskItem(title: "Test")
        XCTAssertNil(task.completionDay)
    }
}

// MARK: - TaskDifficulty Tests

final class TaskDifficultyTests: XCTestCase {

    func test_basePoints_areOrdered() {
        XCTAssertLessThan(TaskDifficulty.easy.basePoints,   TaskDifficulty.medium.basePoints)
        XCTAssertLessThan(TaskDifficulty.medium.basePoints, TaskDifficulty.hard.basePoints)
        XCTAssertLessThan(TaskDifficulty.hard.basePoints,   TaskDifficulty.epic.basePoints)
    }

    func test_allCases_haveNonZeroPoints() {
        for diff in TaskDifficulty.allCases {
            XCTAssertGreaterThan(diff.basePoints, 0, "\(diff.rawValue) should award points")
        }
    }
}

// MARK: - RewardViewModel Tests

@MainActor
final class RewardViewModelTests: XCTestCase {

    // Use in-memory store by resetting before each test
    var vm: RewardViewModel!

    override func setUp() {
        super.setUp()
        DataStore.shared.reset()
        vm = RewardViewModel()
    }

    override func tearDown() {
        DataStore.shared.reset()
        super.tearDown()
    }

    // MARK: Adding tasks

    func test_addTask_increasesCount() {
        vm.addTask(title: "Task 1")
        XCTAssertEqual(vm.tasks.count, 1)
    }

    func test_addTask_createsWithCorrectDifficulty() {
        vm.addTask(title: "Hard task", difficulty: .hard)
        XCTAssertEqual(vm.tasks.first?.difficulty, .hard)
    }

    // MARK: Completing tasks

    func test_completeTask_marksAsCompleted() {
        vm.addTask(title: "T1")
        let task = vm.tasks.first!
        vm.toggleCompletion(of: task)
        XCTAssertTrue(vm.tasks.first!.isCompleted)
    }

    func test_completeTask_awardsPoints() {
        vm.addTask(title: "T1", difficulty: .easy)
        let task = vm.tasks.first!
        vm.toggleCompletion(of: task)
        XCTAssertEqual(vm.tasks.first!.pointsAwarded, TaskDifficulty.easy.basePoints)
        XCTAssertEqual(vm.profile.totalPoints, TaskDifficulty.easy.basePoints)
    }

    func test_completeHardTask_awardsCorrectPoints() {
        vm.addTask(title: "Hard", difficulty: .hard)
        let task = vm.tasks.first!
        vm.toggleCompletion(of: task)
        XCTAssertEqual(vm.profile.totalPoints, TaskDifficulty.hard.basePoints)
    }

    func test_uncompleteTask_subtractsPoints() {
        vm.addTask(title: "T1", difficulty: .medium)
        let task = vm.tasks.first!
        vm.toggleCompletion(of: task)

        let ptsAfterComplete = vm.profile.totalPoints
        vm.toggleCompletion(of: vm.tasks.first!)   // un-complete
        XCTAssertEqual(vm.profile.totalPoints, 0)
        XCTAssertGreaterThan(ptsAfterComplete, 0)
    }

    func test_uncompleteTask_decrementsTotalTasksCompleted() {
        vm.addAndComplete(title: "T1", difficulty: .easy)
        XCTAssertEqual(vm.profile.totalTasksCompleted, 1)
        vm.toggleCompletion(of: vm.tasks.first!)
        XCTAssertEqual(vm.profile.totalTasksCompleted, 0)
    }

    // MARK: Deletion

    func test_deleteTask_removesIt() {
        vm.addTask(title: "Delete me")
        let task = vm.tasks.first!
        vm.deleteTask(task)
        XCTAssertTrue(vm.tasks.isEmpty)
    }

    // MARK: Streak

    func test_firstCompletion_setsStreakToOne() {
        vm.addAndComplete(title: "T1", difficulty: .easy)
        XCTAssertEqual(vm.profile.currentStreak, 1)
    }

    func test_pendingAndCompleted_filters() {
        vm.addTask(title: "Pending")
        vm.addTask(title: "Done")
        vm.toggleCompletion(of: vm.tasks.last!)
        XCTAssertEqual(vm.pendingTasks.count, 1)
        XCTAssertEqual(vm.completedTasks.count, 1)
    }

    // MARK: Badges

    func test_firstTaskBadge_isAwarded() {
        vm.addAndComplete(title: "First!", difficulty: .easy)
        XCTAssertTrue(vm.profile.earnedBadgeIDs.contains(.firstTask))
    }

    func test_fiveTasksBadge_isAwardedAfterFive() {
        for i in 1...5 {
            vm.addAndComplete(title: "Task \(i)", difficulty: .easy)
        }
        XCTAssertTrue(vm.profile.earnedBadgeIDs.contains(.tasks5))
    }

    func test_firstHardBadge_isAwardedForHardTask() {
        vm.addAndComplete(title: "Hard", difficulty: .hard)
        XCTAssertTrue(vm.profile.earnedBadgeIDs.contains(.firstHard))
    }

    func test_firstEpicBadge_isAwardedForEpicTask() {
        vm.addAndComplete(title: "Epic", difficulty: .epic)
        XCTAssertTrue(vm.profile.earnedBadgeIDs.contains(.firstEpic))
    }

    func test_easyTaskDoesNotAwardFirstHardBadge() {
        vm.addAndComplete(title: "Easy", difficulty: .easy)
        XCTAssertFalse(vm.profile.earnedBadgeIDs.contains(.firstHard))
    }

    // MARK: Points preview

    func test_previewPoints_returnsBasePointsWithNoStreak() {
        XCTAssertEqual(vm.previewPoints(difficulty: .easy), TaskDifficulty.easy.basePoints)
    }

    // MARK: Stats

    func test_dailyStat_isIncrementedOnCompletion() {
        vm.addAndComplete(title: "T", difficulty: .easy)
        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(vm.profile.tasksCompleted(on: today), 1)
    }

    func test_dailyStat_isDecrementedOnUncompletion() {
        vm.addAndComplete(title: "T", difficulty: .easy)
        vm.toggleCompletion(of: vm.tasks.first!)  // un-complete
        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(vm.profile.tasksCompleted(on: today), 0)
    }

    // MARK: UserProfile key helpers

    func test_dailyKey_format() {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = 2024; comps.month = 3; comps.day = 5
        let date = cal.date(from: comps)!
        XCTAssertEqual(UserProfile.dailyKey(for: date), "2024-03-05")
    }

    func test_monthlyKey_format() {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = 2024; comps.month = 11; comps.day = 1
        let date = cal.date(from: comps)!
        XCTAssertEqual(UserProfile.monthlyKey(for: date), "2024-11")
    }

    func test_yearlyKey_format() {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = 2025; comps.month = 6; comps.day = 15
        let date = cal.date(from: comps)!
        XCTAssertEqual(UserProfile.yearlyKey(for: date), "2025")
    }
}

// MARK: - Badge Catalog Tests

final class BadgeCatalogTests: XCTestCase {

    func test_allBadgeIDsHaveCatalogEntry() {
        for id in BadgeID.allCases {
            XCTAssertNotNil(BadgeDefinition.catalog[id], "Missing catalog entry for \(id.rawValue)")
        }
    }

    func test_allCatalogEntriesHaveNonEmptyName() {
        for (id, def) in BadgeDefinition.catalog {
            XCTAssertFalse(def.name.isEmpty, "Badge \(id.rawValue) has empty name")
        }
    }

    func test_allCatalogEntriesHaveIcon() {
        for (id, def) in BadgeDefinition.catalog {
            XCTAssertFalse(def.icon.isEmpty, "Badge \(id.rawValue) has empty icon")
        }
    }
}
