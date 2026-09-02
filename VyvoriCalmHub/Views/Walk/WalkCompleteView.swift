import SwiftUI

struct WalkCompleteView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let walkId: UUID
    let minutes: Int
    let location: String
    @Binding var sessionPresented: Bool
    @State private var text = ""
    @State private var mood = "Calm"
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image("BannerJournal")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 130)
                    .clipShape(AppTheme.stoneShape(1))
                    .overlay(AppTheme.stoneShape(1).stroke(AppTheme.primary.opacity(0.3), lineWidth: 1.2))

                PetalCard(cut: 2) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What stayed with you?")
                            .font(AppTheme.display(26))
                        Text("\(minutes) minutes · \(location.isEmpty ? "No place noted" : location)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Mood", selection: $mood) {
                            Text("Calm").tag("Calm")
                            Text("Clear").tag("Clear")
                            Text("Heavy").tag("Heavy")
                            Text("Curious").tag("Curious")
                        }
                        .pickerStyle(.segmented)
                        TextEditor(text: $text)
                            .frame(minHeight: 120)
                            .padding(8)
                        .background(Color.white.opacity(0.55), in: AppTheme.stoneShape(0))
                        if let error {
                            Text(error).font(.caption).foregroundColor(.red)
                        }
                        PetalButton(title: "Save reflection", systemImage: "leaf.fill") {
                            save()
                        }
                        .accessibilityIdentifier("save_insight")
                    }
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgTrail")
        .navigationTitle("Insight")
        .navigationBarBackButtonHidden(true)
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Write at least one character."
            return
        }
        let insight = Insight(id: UUID(), date: Date(), text: trimmed, walkId: walkId, mood: mood)
        store.upsertInsight(insight)
        if var walk = store.walks.first(where: { $0.id == walkId }) {
            walk.reflection = trimmed
            walk.location = location
            walk.completed = true
            store.upsertWalk(walk)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        sessionPresented = false
        dismiss()
    }
}
