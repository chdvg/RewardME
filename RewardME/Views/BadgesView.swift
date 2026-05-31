import SwiftUI

struct BadgesView: View {
    @EnvironmentObject private var viewModel: RewardViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary header
                    summaryHeader

                    // Badge grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.allBadges, id: \.definition.id) { item in
                            BadgeCard(definition: item.definition, earned: item.earned)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Badges")
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 0) {
            summaryTile(
                value: "\(viewModel.profile.earnedBadges.count)",
                label: "Earned",
                icon: "rosette",
                color: .yellow
            )
            Divider().frame(height: 60)
            summaryTile(
                value: "\(BadgeID.allCases.count - viewModel.profile.earnedBadges.count)",
                label: "Locked",
                icon: "lock.fill",
                color: .gray
            )
            Divider().frame(height: 60)
            summaryTile(
                value: "\(viewModel.profile.badgeBonusPoints)",
                label: "Bonus pts",
                icon: "star.fill",
                color: .orange
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func summaryTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.title2).bold()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Badge Card

struct BadgeCard: View {
    let definition: BadgeDefinition
    let earned: EarnedBadge?

    private var isEarned: Bool { earned != nil }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isEarned ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: definition.icon)
                    .font(.system(size: 26))
                    .foregroundColor(isEarned ? .yellow : .gray.opacity(0.4))

                if !isEarned {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .offset(x: 18, y: 18)
                }
            }

            Text(definition.name)
                .font(.caption).bold()
                .multilineTextAlignment(.center)
                .foregroundColor(isEarned ? .primary : .secondary)
                .lineLimit(2)

            Text(definition.description)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if definition.bonusPoints > 0 {
                Text("+\(definition.bonusPoints) pts")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isEarned ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .foregroundColor(isEarned ? .orange : .secondary)
                    .clipShape(Capsule())
            }

            if let earnedDate = earned?.earnedDate {
                Text(earnedDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEarned ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .opacity(isEarned ? 1 : 0.65)
    }
}

#Preview {
    BadgesView()
        .environmentObject(RewardViewModel())
}
