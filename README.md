# RewardME 🏆

A SwiftUI iOS app that gamifies your productivity. Complete tasks, earn points, maintain streaks, and unlock badges!

---

## Features

### ✅ Task Management
- Add tasks with a **title**, optional **notes**, and a **difficulty level**
- Swipe to **complete**, **edit**, or **delete** tasks
- Separate views for pending and completed tasks

### 🎯 Difficulty Levels & Points
| Difficulty | Base Points |
|------------|-------------|
| Easy 🌿    | 10 pts      |
| Medium ⚡️  | 25 pts      |
| Hard 🔥    | 50 pts      |
| Epic ⭐️   | 100 pts     |

### 🔥 Streak System
- Earn a **daily streak** by completing at least one task each day
- **Streak bonus**: +10% extra points per 5-day streak tier (up to +100%)
- Streaks reset if you miss a day

### 🏅 Badges (21 total)
Unlock badges by hitting milestones:
- **Task count**: 1, 5, 10, 25, 50, 100 completed tasks
- **Streaks**: 3, 7, 14, 30 consecutive days
- **Difficulty**: First Hard task, First Epic task, 10 Epic tasks
- **Time windows**: Daily Champion (5/day), Weekly Warrior (20/week), Monthly Marathon (50/month)
- **Points milestones**: 500, 1 000, 5 000 total points

### 📊 Statistics
- Daily, weekly, and monthly bar charts of completed tasks
- Year-at-a-glance monthly breakdown
- Per-difficulty breakdown (count + points earned)

### 👤 Profile
- Total points with badge-bonus breakdown
- Current & longest streak
- All-time task counts by difficulty
- Points guide

---

## Getting Started

### Requirements
- Xcode 15.4 or later
- iOS 17.0+ deployment target

### Setup
1. Clone the repository
2. Open `RewardME.xcodeproj` in Xcode
3. Select an iOS 17 simulator or device
4. Press **⌘R** to build and run

### Running Tests
In Xcode, press **⌘U** to run the unit test suite (`RewardMETests`).

---

## Architecture

```
RewardME/
├── Models/
│   ├── TaskDifficulty.swift   – Difficulty enum with points & colors
│   ├── TaskItem.swift         – Task data model
│   ├── Badge.swift            – Badge definitions & earned-badge records
│   └── UserProfile.swift      – Points, streak, and stats model
├── ViewModels/
│   └── RewardViewModel.swift  – All business logic (points, streaks, badges)
├── Views/
│   ├── TaskListView.swift     – Main task list with pending/done toggle
│   ├── TaskRowView.swift      – Individual task row
│   ├── AddTaskView.swift      – Add / edit task form
│   ├── BadgesView.swift       – Badge gallery
│   ├── StatsView.swift        – Progress charts
│   └── ProfileView.swift      – User profile & points breakdown
├── Persistence/
│   └── DataStore.swift        – UserDefaults JSON persistence
├── ContentView.swift          – Tab navigation
└── RewardMEApp.swift          – App entry point
```
