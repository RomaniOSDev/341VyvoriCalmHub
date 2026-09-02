import SwiftUI

struct WalkHistoryView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PetalCard {
                    Text(store.weeklySummary)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if store.walks.isEmpty {
                    PetalCard {
                        VStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(AppTheme.primary)
                                .font(.system(size: 32))
                            Text("No walks yet! Start your journey towards mindfulness by logging your first session.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    ForEach(store.walks) { walk in
                        NavigationLink {
                            WalkDetailView(walkId: walk.id)
                        } label: {
                            PetalCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(walk.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(walk.durationMinutes) min · \(walk.location.isEmpty ? "Unnamed path" : walk.location)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(statusLabel(for: walk))
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgTrail")
        .navigationTitle("Journal")
    }

    private func statusLabel(for walk: WalkSession) -> String {
        if walk.completed { return "Completed" }
        if store.activeWalk?.walkId == walk.id { return "In progress" }
        return "Interrupted"
    }
}

struct WalkDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let walkId: UUID
    @State private var location = ""
    @State private var reflection = ""
    @State private var confirmDelete = false

    private var walk: WalkSession? { store.walks.first { $0.id == walkId } }

    var body: some View {
        Group {
            if let walk {
                ScrollView {
                    VStack(spacing: 14) {
                        PetalCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(walk.durationMinutes) minutes")
                                    .font(.title2)
                                TextField("Location", text: $location)
                                    .textFieldStyle(.roundedBorder)
                                TextEditor(text: $reflection)
                                    .frame(minHeight: 120)
                                PetalButton(title: "Save changes", systemImage: "checkmark") {
                                    var copy = walk
                                    copy.location = location
                                    copy.reflection = reflection
                                    store.upsertWalk(copy)
                                    if !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        if let existing = store.insights.first(where: { $0.walkId == walk.id }) {
                                            var i = existing
                                            i.text = reflection
                                            store.upsertInsight(i)
                                        } else {
                                            store.upsertInsight(Insight(id: UUID(), date: Date(), text: reflection, walkId: walk.id, mood: "Calm"))
                                        }
                                    }
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                }
                                Button("Delete walk", role: .destructive) { confirmDelete = true }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                        }
                    }
                    .padding(18)
                }
                .screenBackdrop("BgTrail")
                .onAppear {
                    location = walk.location
                    reflection = walk.reflection
                }
                .alert("Delete this walk?", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive) { store.deleteWalk(walk.id) }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                Text("Walk unavailable.")
                    .screenBackdrop("BgTrail")
            }
        }
        .navigationTitle("Walk")
    }
}
