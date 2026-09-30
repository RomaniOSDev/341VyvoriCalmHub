import SwiftUI

struct RouteEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let routeID: UUID
    @State private var title = ""
    @State private var summary = ""
    @State private var stops: [RouteStop] = []
    @State private var error: String?
    @State private var confirmDelete = false
    @State private var loaded = false

    private var route: WalkingRoute? {
        store.routes.first { $0.id == routeID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PetalCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Path name")
                            .font(.system(.headline, design: .serif))
                        TextField("Evening loop, lamp to lamp…", text: $title)
                            .textFieldStyle(.roundedBorder)
                        Text("Why this path")
                            .font(.system(.headline, design: .serif))
                        TextField("Four landings after dusk", text: $summary, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }
                }

                ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                    stopCard(index: index, stop: stop)
                }

                HStack(spacing: 12) {
                    Button("Add stop") { addStop() }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundColor(AppTheme.primary)
                        .disabled(stops.count >= 6)
                    Button("Remove last") { removeLast() }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundColor(AppTheme.primary)
                        .disabled(stops.count <= 4)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                PetalButton(title: "Save path", systemImage: "checkmark") {
                    save()
                }
                Button("Duplicate this path") {
                    save(dismissAfter: false)
                    if let route {
                        store.duplicateRoute(route)
                        dismiss()
                    }
                }
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                Button("Delete path", role: .destructive) { confirmDelete = true }
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .navigationTitle("Edit path")
        .onAppear { hydrate() }
        .alert("Delete this path?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                store.deleteRoute(routeID)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func stopCard(index: Int, stop: RouteStop) -> some View {
        PetalCard(cut: index) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Stop \(index + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.primary)
                TextField("Bench, oak, corner, stoop…", text: binding(index, \.name))
                    .textFieldStyle(.roundedBorder)
                Picker("Ritual", selection: binding(index, \.ritual)) {
                    ForEach(StopRitual.allCases) { ritual in
                        Text(ritual.title).tag(ritual)
                    }
                }
                .pickerStyle(.menu)
                if stops[index].ritual == .standStill {
                    Stepper(value: binding(index, \.dwellSeconds), in: 20...60, step: 5) {
                        Text("Stand for \(stops[index].dwellSeconds)s")
                    }
                }
                TextField("Cue for when you arrive", text: binding(index, \.cue), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func binding<T>(_ index: Int, _ keyPath: WritableKeyPath<RouteStop, T>) -> Binding<T> {
        Binding(
            get: { stops[index][keyPath: keyPath] },
            set: { stops[index][keyPath: keyPath] = $0 }
        )
    }

    private func hydrate() {
        guard !loaded, let route else { return }
        loaded = true
        title = route.title
        summary = route.summary
        stops = route.stops
    }

    private func addStop() {
        guard stops.count < 6 else { return }
        stops.append(RouteStop(name: "", ritual: .shortNote))
    }

    private func removeLast() {
        guard stops.count > 4 else { return }
        stops.removeLast()
    }

    private func save(dismissAfter: Bool = true) {
        let named = stops.filter { !$0.trimmedName.isEmpty }
        guard (4...6).contains(stops.count) else {
            error = "A path needs 4 to 6 stops."
            return
        }
        guard named.count == stops.count else {
            error = "Give every stop a place name."
            return
        }
        guard let existing = route else { return }
        var updated = existing
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if updated.title.isEmpty { updated.title = "Untitled path" }
        updated.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.stops = stops
        store.upsertRoute(updated)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if dismissAfter { dismiss() }
    }
}
