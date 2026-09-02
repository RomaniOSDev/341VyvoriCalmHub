import SwiftUI

struct InsightsListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAdd = false
    @State private var editing: Insight?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if store.insights.isEmpty {
                    PetalCard {
                        VStack(spacing: 10) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 34))
                                .foregroundColor(AppTheme.primary)
                            Text("Start noting your reflections")
                                .font(.system(.headline, design: .serif))
                            Text("After a walk, or any time a thought lands.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(store.insights) { item in
                        NavigationLink {
                            InsightDetailView(insightId: item.id)
                        } label: {
                            PetalCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.mood)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.primary)
                                    Text(item.text)
                                        .foregroundColor(.primary)
                                        .lineLimit(3)
                                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                PetalButton(title: "Add insight", systemImage: "plus") {
                    showAdd = true
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgTrail")
        .navigationTitle("Reflections")
        .sheet(isPresented: $showAdd) {
            InsightFormView()
                .environmentObject(store)
        }
    }
}

struct InsightDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let insightId: UUID
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var insight: Insight? { store.insights.first { $0.id == insightId } }

    var body: some View {
        Group {
            if let insight {
                ScrollView {
                    PetalCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(insight.mood)
                                .font(.headline)
                                .foregroundColor(AppTheme.primary)
                            Text(insight.text)
                            Text(insight.date.formatted(date: .long, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            PetalButton(title: "Edit", systemImage: "pencil") { showEdit = true }
                            Button("Delete", role: .destructive) { confirmDelete = true }
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                    .padding(18)
                }
                .screenBackdrop("BgTrail")
                .sheet(isPresented: $showEdit) {
                    InsightFormView(existing: insight)
                        .environmentObject(store)
                }
                .alert("Delete this reflection?", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive) { store.deleteInsight(insight.id) }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                Text("Reflection unavailable.")
                    .screenBackdrop("BgTrail")
            }
        }
        .navigationTitle("Note")
    }
}

struct InsightFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    var existing: Insight?
    @State private var text = ""
    @State private var mood = "Calm"
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Reflection") {
                    Picker("Mood", selection: $mood) {
                        Text("Calm").tag("Calm")
                        Text("Clear").tag("Clear")
                        Text("Heavy").tag("Heavy")
                        Text("Curious").tag("Curious")
                    }
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                    if let error {
                        Text(error).font(.caption).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(existing == nil ? "New insight" : "Edit insight")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing {
                    text = existing.text
                    mood = existing.mood
                }
            }
        }
        .tint(AppTheme.primary)
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Write at least one character."
            return
        }
        let item = Insight(id: existing?.id ?? UUID(), date: existing?.date ?? Date(), text: trimmed, walkId: existing?.walkId, mood: mood)
        store.upsertInsight(item)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        dismiss()
    }
}
