import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var vm: RewardViewModel
    @State private var showAddReward    = false
    @State private var editingReward: RewardDefinition? = nil
    @State private var pendingRedeem: RewardDefinition? = nil
    @State private var showRedeemDialog = false
    @State private var redeemFailed     = false

    private var sortedRewards: [RewardDefinition] {
        vm.rewards.sorted { $0.pointCost < $1.pointCost }
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Available points hero ──────────────────────────────────
                Section {
                    pointsHeader
                }
                .listRowBackground(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.75), Color.purple.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .listRowInsets(EdgeInsets())

                // ── Reward catalog ─────────────────────────────────────────
                if vm.rewards.isEmpty {
                    Section { emptyState }
                } else {
                    Section("Your Rewards") {
                        ForEach(sortedRewards) { reward in
                            rewardRow(reward)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        vm.deleteReward(reward)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        editingReward = reward
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                }

                // ── History link ───────────────────────────────────────────
                if !vm.redemptions.isEmpty {
                    Section {
                        NavigationLink(destination: RedemptionHistoryView()) {
                            Label("Redemption History", systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Rewards Shop")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddReward = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddReward) {
                AddRewardView()
            }
            .sheet(item: $editingReward) { reward in
                AddRewardView(editing: reward)
            }
            .confirmationDialog(
                pendingRedeem.map { "Redeem \"\($0.title)\"?" } ?? "",
                isPresented: $showRedeemDialog,
                titleVisibility: .visible
            ) {
                if let reward = pendingRedeem {
                    Button("Spend \(reward.pointCost) pts") {
                        if !vm.redeemReward(reward) { redeemFailed = true }
                        pendingRedeem = nil
                    }
                    Button("Cancel", role: .cancel) {
                        pendingRedeem = nil
                    }
                }
            } message: {
                if let reward = pendingRedeem {
                    Text("You have \(vm.profile.availablePoints) pts available. This will leave you with \(vm.profile.availablePoints - reward.pointCost) pts.")
                }
            }
            .alert("Not Enough Points", isPresented: $redeemFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Keep completing tasks to earn more points!")
            }
        }
    }

    // MARK: - Sub-views

    private var pointsHeader: some View {
        VStack(spacing: 10) {
            Text("Available Points")
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.85))
            Text("\(vm.profile.availablePoints)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            HStack(spacing: 32) {
                VStack(spacing: 2) {
                    Text("\(vm.profile.totalPoints)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text("Earned")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.75))
                }
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 1, height: 32)
                VStack(spacing: 2) {
                    Text("\(vm.profile.spentPoints)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text("Spent")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }

    private func rewardRow(_ reward: RewardDefinition) -> some View {
        HStack(spacing: 14) {
            Text(reward.emoji)
                .font(.system(size: 32))
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(reward.title)
                    .font(.body.weight(.medium))
                if !reward.notes.isEmpty {
                    Text(reward.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Label("\(reward.pointCost) pts", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            Spacer()
            let canAfford = vm.profile.availablePoints >= reward.pointCost
            Button {
                pendingRedeem  = reward
                showRedeemDialog = true
            } label: {
                Text("Redeem")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canAfford ? Color.accentColor : Color.secondary.opacity(0.25))
                    .foregroundColor(canAfford ? .white : .secondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "gift.fill")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No rewards yet")
                .font(.headline)
            Text("Tap + to create a reward and set how many points it takes to unlock it.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

#Preview {
    RewardsView()
        .environmentObject(RewardViewModel())
}
