import SwiftUI

struct AddRewardView: View {
    @EnvironmentObject private var vm: RewardViewModel
    @Environment(\.dismiss) private var dismiss

    var rewardToEdit: RewardDefinition?

    @State private var title: String  = ""
    @State private var notes: String  = ""
    @State private var pointCost: Int = 200
    @State private var emoji: String  = "🎁"
    @State private var showGuide      = false

    private var isEditing: Bool { rewardToEdit != nil }

    init(editing reward: RewardDefinition? = nil) {
        self.rewardToEdit = reward
    }

    // MARK: - Preset emojis

    private let emojiPresets = [
        "🎁", "☕", "🍕", "🎮", "🎬", "📚",
        "🛍️", "✈️", "🍰", "🎵", "💆", "🏖️",
        "🍷", "🎯", "💤", "🌴", "👟", "💎",
        "🎪", "🛁", "🏆", "🍦", "🎭", "🚀"
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // ── Reward details ──────────────────────────────────────
                Section("Reward") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("e.g. Coffee break", text: $title)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Notes")
                        Spacer()
                        TextField("Optional description", text: $notes)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // ── Emoji icon ──────────────────────────────────────────
                Section("Icon") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: 10
                    ) {
                        ForEach(emojiPresets, id: \.self) { e in
                            Text(e)
                                .font(.system(size: 26))
                                .padding(6)
                                .background(
                                    emoji == e
                                        ? Color.accentColor.opacity(0.2)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            emoji == e ? Color.accentColor : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .onTapGesture { emoji = e }
                        }
                    }
                    .padding(.vertical, 4)
                    HStack {
                        Text("Custom emoji")
                        Spacer()
                        TextField("Paste any emoji", text: $emoji)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                // ── Point cost ──────────────────────────────────────────
                Section {
                    HStack {
                        Text("Point Cost")
                        Spacer()
                        Stepper(
                            "\(pointCost) pts",
                            value: $pointCost,
                            in: 1...99_999,
                            step: stepSize
                        )
                    }
                    Slider(
                        value: Binding(
                            get: { Double(pointCost) },
                            set: { pointCost = max(1, Int($0)) }
                        ),
                        in: 10...5000,
                        step: 10
                    )
                } header: {
                    Text("Point Cost")
                } footer: {
                    Text(affordabilityHint)
                        .foregroundColor(affordabilityColor)
                }

                // ── Point guide ─────────────────────────────────────────
                Section {
                    DisclosureGroup("💡 How to price your rewards", isExpanded: $showGuide) {
                        guideContent
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Reward" : "New Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.bold)
                }
            }
            .onAppear { loadFromReward() }
        }
    }

    // MARK: - Computed helpers

    private var stepSize: Int {
        switch pointCost {
        case 0..<100:   return 10
        case 100..<500: return 25
        default:        return 50
        }
    }

    private var affordabilityHint: String {
        let avail = vm.profile.availablePoints
        if pointCost <= avail {
            return "You can redeem this right now with your \(avail) available pts."
        } else {
            return "You need \(pointCost - avail) more pts to redeem this."
        }
    }

    private var affordabilityColor: Color {
        pointCost <= vm.profile.availablePoints ? .green : .secondary
    }

    // MARK: - Guide content

    private var guideContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How many points can you earn?")
                .font(.subheadline.bold())
                .padding(.bottom, 2)

            earningRow(icon: "leaf.fill",  color: .green,  label: "Easy tasks",   value: "10 pts each")
            earningRow(icon: "bolt.fill",  color: .blue,   label: "Medium tasks", value: "25 pts each")
            earningRow(icon: "flame.fill", color: .orange, label: "Hard tasks",   value: "50 pts each")
            earningRow(icon: "star.fill",  color: .purple, label: "Epic tasks",   value: "100 pts each")
            earningRow(
                icon: "bolt.badge.clock.fill", color: .yellow,
                label: "Streak bonus", value: "+10% per 5-day tier (up to ×2)"
            )

            Divider().padding(.vertical, 4)

            Text("Suggested reward tiers")
                .font(.subheadline.bold())
                .padding(.bottom, 2)

            tierRow(emoji: "🍬", label: "Quick treat (snack, short break)",   range: "50–150")
            tierRow(emoji: "☕", label: "Small splurge (coffee, movie night)", range: "300–600")
            tierRow(emoji: "🎁", label: "Nice reward (dinner, new item)",      range: "750–2,000")
            tierRow(emoji: "✨", label: "Epic reward (experience, big buy)",   range: "3,000–5,000+")

            Text("A casual user doing 3 easy tasks/day earns ~200 pts/week. An active user tackling hard & epic tasks with a streak can reach 1,500+ pts/week.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 6)
    }

    private func earningRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 20)
            Text(label).font(.caption)
            Spacer()
            Text(value).font(.caption).foregroundColor(.secondary)
        }
    }

    private func tierRow(emoji e: String, label: String, range: String) -> some View {
        HStack(alignment: .top) {
            Text(e).frame(width: 24)
            Text(label).font(.caption)
            Spacer()
            Text(range + " pts").font(.caption.bold()).foregroundColor(.orange)
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let finalEmoji   = emoji.trimmingCharacters(in: .whitespaces).isEmpty ? "🎁" : emoji

        if var updated = rewardToEdit {
            updated.title     = trimmedTitle
            updated.notes     = trimmedNotes
            updated.pointCost = pointCost
            updated.emoji     = finalEmoji
            vm.updateReward(updated)
        } else {
            vm.addReward(title: trimmedTitle, notes: trimmedNotes, pointCost: pointCost, emoji: finalEmoji)
        }
        dismiss()
    }

    private func loadFromReward() {
        guard let r = rewardToEdit else { return }
        title     = r.title
        notes     = r.notes
        pointCost = r.pointCost
        emoji     = r.emoji
    }
}

#Preview {
    AddRewardView()
        .environmentObject(RewardViewModel())
}
