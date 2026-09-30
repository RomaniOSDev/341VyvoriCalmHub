import SwiftUI

struct WeeklyReviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedStop = ""
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    tile("Paths", "\(weekWalks.count)", "map")
                    tile("Stops", "\(weekStops.count)", "mappin")
                }
                PetalCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Most visited landing")
                            .font(.system(.headline, design: .serif))
                        Text(favoriteStop ?? "Finish a path this week to see this.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                PetalCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This week’s trails")
                            .font(.system(.headline, design: .serif))
                        if weekWalks.isEmpty {
                            Text("Walk a route of stops, then return here on Sunday.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(weekWalks) { walk in
                                PathMapTrail(
                                    titles: walk.checkIns.map(\.stopName),
                                    doneCount: walk.checkIns.count
                                )
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                PetalCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Which stop will you begin with next?")
                            .font(.system(.headline, design: .serif))
                        if weekStops.isEmpty {
                            Text("Check in at stops this week to choose one.")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Next stop", selection: $selectedStop) {
                                ForEach(weekStops, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                        if saved {
                            Text("Saved as next beginning.")
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                        }
                        PetalButton(title: "Begin here next week", systemImage: "bookmark.fill") {
                            store.saveFocusStop(selectedStop)
                            saved = true
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }
                        .disabled(selectedStop.isEmpty)
                        Button("Close for this week") {
                            store.markReviewSeen()
                        }
                        .foregroundColor(AppTheme.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .navigationTitle("Sunday stops")
        .onAppear {
            selectedStop = store.focusStopName.isEmpty ? (weekStops.first ?? "") : store.focusStopName
            if !weekStops.contains(selectedStop) {
                selectedStop = weekStops.first ?? ""
            }
        }
    }

    private var weekWalks: [RouteWalk] {
        store.completedWalks(since: store.weekStart)
    }

    private var weekStops: [String] {
        let names = weekWalks.flatMap { $0.checkIns.map(\.stopName) }
        return Array(Set(names)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var favoriteStop: String? {
        let grouped = Dictionary(grouping: weekWalks.flatMap(\.checkIns), by: \.stopName)
        return grouped.max { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return lhs.key > rhs.key
            }
            return lhs.value.count < rhs.value.count
        }?.key
    }

    private func tile(_ title: String, _ value: String, _ icon: String) -> some View {
        PetalCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                Text(value)
                    .font(AppTheme.display(22))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
