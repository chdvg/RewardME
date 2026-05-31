import SwiftUI

struct RedemptionHistoryView: View {
    @EnvironmentObject private var viewModel: RewardViewModel

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    /// Redemptions grouped by month string, sorted newest-first.
    private var grouped: [(month: String, sortDate: Date, records: [RedemptionRecord])] {
        let fmt = Self.monthFormatter
        var dict: [String: (Date, [RedemptionRecord])] = [:]
        for r in viewModel.redemptions {
            let key  = fmt.string(from: r.redeemedAt)
            let date = fmt.date(from: key) ?? Date.distantPast
            var (_, existing) = dict[key] ?? (date, [])
            existing.append(r)
            dict[key] = (date, existing)
        }
        return dict
            .map { key, value in
                (
                    month:    key,
                    sortDate: value.0,
                    records:  value.1.sorted { $0.redeemedAt > $1.redeemedAt }
                )
            }
            .sorted { $0.sortDate > $1.sortDate }
    }

    var body: some View {
        List {
            if viewModel.redemptions.isEmpty {
                emptyState
            } else {
                ForEach(grouped, id: \.month) { group in
                    Section(group.month) {
                        ForEach(group.records) { record in
                            HStack(spacing: 14) {
                                Text(record.rewardEmoji)
                                    .font(.system(size: 28))
                                    .frame(width: 40)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.rewardTitle)
                                        .font(.body)
                                    Text(Self.dateFormatter.string(from: record.redeemedAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Label("\(record.pointCost)", systemImage: "star.fill")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section {
                    Text("History window: \(AppSettings.shared.historyRetention.rawValue). Change in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Redemption History")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No redemptions yet")
                .font(.headline)
            Text("When you spend points on a reward it will appear here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    NavigationStack {
        RedemptionHistoryView()
            .environmentObject(RewardViewModel())
    }
}
