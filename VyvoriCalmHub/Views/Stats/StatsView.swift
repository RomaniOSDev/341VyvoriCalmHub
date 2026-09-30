import SwiftUI
import Charts

struct PlacesView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    statTile("Paths", "\(completed.count)", "map")
                    statTile("Stops", "\(store.distinctStopNames.count)", "mappin")
                    statTile("Check-ins", "\(checkIns.count)", "flag")
                }

                NavigationLink {
                    WeeklyReviewView()
                } label: {
                    TrailRow(title: "Sunday stops", subtitle: "Pick the landing to start with next week", systemImage: "sun.haze.fill", cut: 2)
                }
                .buttonStyle(.plain)

                PetalCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Landings this week")
                            .font(.system(.headline, design: .serif))
                        if checkIns.isEmpty {
                            emptyHint
                        } else {
                            Chart(weekDays) { item in
                                BarMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Stops", item.count)
                                )
                                .foregroundStyle(AppTheme.primary)
                            }
                            .frame(height: 180)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PetalCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ritual mix")
                            .font(.system(.headline, design: .serif))
                        if ritualCounts.isEmpty {
                            Text("Rituals appear after you check in at a stop.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Chart(ritualCounts) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Ritual", item.title)
                                )
                                .foregroundStyle(AppTheme.accent)
                            }
                            .frame(height: CGFloat(max(120, ritualCounts.count * 44)))
                            .chartXAxis {
                                AxisMarks(position: .bottom)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PetalCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Places you have landed")
                            .font(.system(.headline, design: .serif))
                        if store.distinctStopNames.isEmpty {
                            Text("Walk a path to collect stop names.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(store.distinctStopNames, id: \.self) { name in
                                HStack {
                                    TrailBlaze(size: 9)
                                    Text(name)
                                    Spacer()
                                    Text("\(visitCount(name))")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.primary)
                                }
                                .frame(minHeight: 36)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .navigationTitle("Places")
    }

    private var emptyHint: some View {
        Text("Finish a path to see landings by day.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
    }

    private var completed: [RouteWalk] {
        store.walks.filter(\.completed)
    }

    private var checkIns: [StopCheckIn] {
        store.walks.flatMap(\.checkIns)
    }

    private var weekDays: [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) else { return nil }
            let count = checkIns.filter { calendar.isDate($0.completedAt, inSameDayAs: date) }.count
            return DayCount(date: date, count: count)
        }
    }

    private var ritualCounts: [RitualCount] {
        let grouped = Dictionary(grouping: checkIns, by: \.ritual)
        return grouped
            .map { RitualCount(title: $0.key.title, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private func visitCount(_ name: String) -> Int {
        checkIns.filter { $0.stopName.caseInsensitiveCompare(name) == .orderedSame }.count
    }

    private func statTile(_ title: String, _ value: String, _ icon: String) -> some View {
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

private struct DayCount: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}

private struct RitualCount: Identifiable {
    var id: String { title }
    let title: String
    let count: Int
}
