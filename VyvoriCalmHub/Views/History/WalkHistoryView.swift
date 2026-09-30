import SwiftUI

struct RitualMapView: View {
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
                            Image(systemName: "map")
                                .foregroundColor(AppTheme.primary)
                                .font(.system(size: 32))
                            Text("Finished paths appear here as a trail of stops — not a list of timed sessions.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    ForEach(store.walks) { walk in
                        NavigationLink {
                            RouteWalkDetailView(walkId: walk.id)
                        } label: {
                            PetalCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(walk.routeTitle)
                                        .font(.system(.headline, design: .serif))
                                        .foregroundColor(.primary)
                                    Text(walk.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    PathMapTrail(
                                        titles: walk.stops.map(\.trimmedName),
                                        doneCount: walk.checkIns.count,
                                        highlightIndex: walk.completed ? nil : walk.currentStopIndex
                                    )
                                    Text(walk.completed ? "Completed" : "In progress · stop \(walk.currentStopIndex + 1)")
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .navigationTitle("Ritual map")
    }
}

struct RouteWalkDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let walkId: UUID
    @State private var confirmDelete = false

    private var walk: RouteWalk? { store.walks.first { $0.id == walkId } }

    var body: some View {
        Group {
            if let walk {
                ScrollView {
                    VStack(spacing: 14) {
                        PetalCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(walk.routeTitle)
                                    .font(AppTheme.display(26))
                                Text(walk.startedAt.formatted(date: .long, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                PathMapTrail(
                                    titles: walk.stops.map(\.trimmedName),
                                    doneCount: walk.checkIns.count
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        ForEach(walk.checkIns) { item in
                            PetalCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.stopName)
                                        .font(.system(.headline, design: .serif))
                                    Text(item.ritual.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.primary)
                                    Text(item.body)
                                    Text(item.completedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        if !walk.closingLine.isEmpty {
                            PetalCard(cut: 2) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Closing line")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.primary)
                                    Text(walk.closingLine)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Button("Delete this path", role: .destructive) { confirmDelete = true }
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .clearScrollBackground()
                .screenBackdrop("BgTrail")
                .alert("Delete this path from the map?", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive) { store.deleteWalk(walk.id) }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                Text("Path unavailable.")
                    .screenBackdrop("BgTrail")
            }
        }
        .navigationTitle("One path")
    }
}
