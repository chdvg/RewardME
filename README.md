# RewardME 🏆

A SwiftUI iOS app that gamifies your productivity. Complete tasks, earn points, maintain streaks, unlock badges, and spend your hard-earned points on real rewards!

---

## Features

### ✅ Task Management
- Add tasks with a **title**, optional **notes**, **difficulty**, and optional **due date**
- Status tabs: **Active / Completed / Cancelled**
- Swipe to **complete**, **edit**, **cancel**, or **restore** tasks
- Sort & filter sheet (difficulty, due date, status)

### 🔁 Recurring Tasks
Full Google Calendar-style recurrence engine:
- **Frequencies**: Daily, Weekly, Monthly, Yearly
- **Intervals**: every N days/weeks/months/years
- **Weekly**: choose specific days of the week
- **Monthly**: on a fixed day-of-month *or* a weekday-of-month (e.g. 2nd Tuesday)
- **End conditions**: Never, After N occurrences, On a date
- Completing a recurring task automatically spawns the next occurrence

### 🎯 Difficulty Levels & Points
| Difficulty | Base Points |
|------------|-------------|
| Easy 🌿    | 10 pts      |
| Medium ⚡️  | 25 pts      |
| Hard 🔥    | 50 pts      |
| Epic ⭐️   | 100 pts     |

**Streak bonus**: +10% per 5-day streak tier, up to +100% (×2 multiplier)

### 🔥 Streak System
- Earn a **daily streak** by completing at least one task each day
- Streak bonus stacks on top of base difficulty points
- Streak resets if you miss a day; tracked against your all-time longest streak

### 🎁 Rewards Shop
- Create custom **rewards** with a name, description, emoji icon, and point cost
- Built-in **pricing guide** so you can scale costs appropriately:
  - Quick treat (snack, short break): 50–150 pts
  - Small splurge (coffee, movie): 300–600 pts
  - Nice reward (dinner, new item): 750–2,000 pts
  - Epic reward (experience, big buy): 3,000–5,000+ pts
- **Redeem** rewards by spending available points
- **Redemption history** grouped by month, with configurable retention window (30 days → Forever)

### 🏅 Badges (21 total)
Unlock badges by hitting milestones:
- **Task count**: 1, 5, 10, 25, 50, 100 completed tasks
- **Streaks**: 3, 7, 14, 30 consecutive days
- **Difficulty**: First Hard, First Epic, 10 Epic tasks
- **Time windows**: Daily Champion (5/day), Weekly Warrior (20/week), Monthly Marathon (50/month)
- **Points milestones**: 500, 1,000, 5,000 total points
- Each badge awards bonus points on first unlock

### 🎉 Celebrations
Animated confetti & fireworks overlay when you complete a task — five levels:
- Off / Mild / Medium / Wild / Absolutely Unhinged
- Animation intensity scales with task difficulty
- Personalized **"Great job, [Name]!"** banner if your name is set

### 📊 Statistics
- Daily, weekly, and monthly bar charts of tasks completed
- Year-at-a-glance monthly breakdown
- Per-difficulty count and points breakdown

### 👤 Profile & Personalization
- Set your **name** and a **profile photo** (including your saved Memoji sticker)
- Avatar shown in the profile hero with **crown decoration** based on streak (⭐ 3-day, 👑 7-day)
- Total points earned, spent on rewards, and available to spend
- Current & longest streak, all-time task counts
- **Brag About It** share sheet to post your stats anywhere

### 🔔 Notifications
- Daily reminders at a configurable time
- Per-task due-date notifications auto-scheduled and auto-cancelled on completion

### ⚙️ Settings
- Celebration level picker
- Notification toggle + reminder time picker
- Redemption history retention window

---

## Getting Started

### Requirements
- Xcode 15.4 or later
- iOS 17.0+ deployment target

### Setup
1. Clone the repository
2. Open `RewardME.xcodeproj` in Xcode
3. Set your Team in **Signing & Capabilities**
4. Select an iOS 17 simulator or your device
5. Press **⌘R** to build and run

### Running Tests
In Xcode, press **⌘U** to run the unit test suite (`RewardMETests`).

---

## Architecture

```
RewardME/
├── Models/
│   ├── AppSettings.swift        – ObservableObject: celebration, notifications, retention, name, avatar
│   ├── TaskDifficulty.swift     – Difficulty enum with points, colors & sort order
│   ├── TaskItem.swift           – Task model + RecurrenceRule (full recurrence engine)
│   ├── Badge.swift              – Badge definitions, IDs & earned-badge records
│   ├── UserProfile.swift        – Points (earned/spent/available), streak, stats, badges
│   ├── RewardDefinition.swift   – User-created reward (name, emoji, point cost)
│   └── RedemptionRecord.swift   – Immutable redemption snapshot for history
├── ViewModels/
│   └── RewardViewModel.swift    – All business logic: tasks, points, streaks, badges, rewards
├── Views/
│   ├── TaskListView.swift       – Status tabs, filter chips, sort/filter sheet
│   ├── TaskRowView.swift        – Task row with recurrence badge
│   ├── AddTaskView.swift        – Add/edit task form with full recurrence UI
│   ├── BadgesView.swift         – Badge gallery
│   ├── StatsView.swift          – Progress charts
│   ├── ProfileView.swift        – Hero with avatar, greeting, points & stats
│   ├── AvatarView.swift         – Reusable circular avatar with optional crown
│   ├── EditProfileView.swift    – Name + Memoji/photo picker sheet
│   ├── RewardsView.swift        – Rewards shop with point balance hero
│   ├── AddRewardView.swift      – Create/edit reward with pricing guide
│   ├── RedemptionHistoryView.swift – Monthly-grouped redemption log
│   ├── SettingsView.swift       – Celebration, notifications, history retention
│   └── CelebrationView.swift   – Canvas confetti + fireworks overlay
├── Persistence/
│   └── DataStore.swift          – UserDefaults JSON persistence (tasks, profile, rewards, history)
├── NotificationManager.swift    – UNUserNotificationCenter wrapper
├── ContentView.swift            – TabView: Tasks / Badges / Rewards / Stats / Profile / Settings
└── RewardMEApp.swift            – App entry point
```

---

## Using Your Memoji as Profile Photo

1. Open **Messages** on your iPhone
2. Tap the text field → tap the **Memoji icon** (smiley face) in the keyboard row
3. Press-hold any Memoji sticker → tap **"Save to Photos"**
4. In RewardME → **Profile** → tap the pencil icon → **Choose Photo** → select your saved Memoji
