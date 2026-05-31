import SwiftUI

// MARK: - Stats View

struct StatsView: View {
    @EnvironmentObject private var viewModel: RewardViewModel
    @State private var selectedPeriod: StatPeriod = .week

    enum StatPeriod: String, CaseIterable {
        case week  = "Week"
        case month = "Month"
        case year  = "Year"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(StatPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Summary cards
                    summaryCards

                    // Bar chart
                    chartSection

                    // Difficulty breakdown
                    difficultySection

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Summary cards

    private var summaryCards: some View {
        let stats = currentStats
        let total  = stats.reduce(0) { $0 + $1.count }
        let points = stats.reduce(0) { $0 + $1.points }

        return HStack(spacing: 12) {
            statCard(value: "\(total)",    label: "Tasks",  icon: "checkmark.circle.fill", color: .green)
            statCard(value: "\(points)",   label: "Points", icon: "star.fill",             color: .yellow)
            statCard(value: "\(viewModel.profile.currentStreak)🔥", label: "Streak", icon: "bolt.fill", color: .orange)
        }
        .padding(.horizontal)
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.title2).bold()
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks Completed")
                .font(.headline)
                .padding(.horizontal)

            let stats   = currentStats
            let maxCount = max(stats.map(\.count).max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        if stat.count > 0 {
                            Text("\(stat.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        RoundedRectangle(cornerRadius: 6)
                            .fill(barColor(for: stat.count, max: maxCount))
                            .frame(height: barHeight(for: stat.count, max: maxCount))
                        Text(stat.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func barHeight(for count: Int, max maxCount: Int) -> CGFloat {
        guard maxCount > 0 else { return 4 }
        return max(4, CGFloat(count) / CGFloat(maxCount) * 120)
    }

    private func barColor(for count: Int, max maxCount: Int) -> Color {
        if maxCount == 0 || count == 0 { return Color.gray.opacity(0.2) }
        let ratio = Double(count) / Double(maxCount)
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .blue }
        return .accentColor.opacity(0.6)
    }

    // MARK: - Difficulty breakdown

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("All-Time Difficulty")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(TaskDifficulty.allCases) { diff in
                    let count = viewModel.completedTasks.filter { $0.difficulty == diff }.count
                    let pts   = viewModel.completedTasks.filter { $0.difficulty == diff }.reduce(0) { $0 + $1.pointsAwarded }
                    difficultyRow(diff: diff, count: count, points: pts)
                }
            }
            .padding(.horizontal)
        }
    }

    private func difficultyRow(diff: TaskDifficulty, count: Int, points: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: diff.icon)
                .foregroundColor(diff.color)
                .frame(width: 24)
            Text(diff.rawValue)
                .frame(width: 64, alignment: .leading)
            Spacer()
            Text("\(count) tasks")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(points) pts")
                .font(.caption).bold()
                .foregroundColor(diff.color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(diff.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private var currentStats: [RewardViewModel.PeriodStat] {
        switch selectedPeriod {
        case .week:  return viewModel.last7DayStats
        case .month: return viewModel.last6MonthStats
        case .year:  return viewModel.currentYearMonthlyStats
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(RewardViewModel())
}
