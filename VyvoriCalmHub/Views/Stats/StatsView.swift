import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    statTile("Walks", "\(completed.count)", "leaf.fill")
                    statTile("Minutes", "\(totalMinutes)", "clock.fill")
                    statTile("Streak", "\(store.currentStreak)", "flame.fill")
                }

                NavigationLink {
                    WeeklyReviewView()
                } label: {
                    TrailRow(title: "Weekly review", subtitle: "Look back, then choose what to keep", systemImage: "sun.haze.fill", cut: 2)
                }
                .buttonStyle(.plain)

                PetalCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Minutes this week")
                            .font(.system(.headline, design: .serif))
                        if completed.isEmpty {
                            emptyChartHint
                        } else {
                            Chart(weekDays) { item in
                                BarMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Minutes", item.minutes)
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
                        Text("Walks, last 14 days")
                            .font(.system(.headline, design: .serif))
                        if completed.isEmpty {
                            emptyChartHint
                        } else {
                            Chart(fortnightDays) { item in
                                LineMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Walks", item.walks)
                                )
                                .foregroundStyle(AppTheme.primary)
                                .interpolationMethod(.catmullRom)
                                AreaMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Walks", item.walks)
                                )
                                .foregroundStyle(AppTheme.primary.opacity(0.18))
                                .interpolationMethod(.catmullRom)
                            }
                            .frame(height: 180)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
                        Text("Moods")
                            .font(.system(.headline, design: .serif))
                        if moodCounts.isEmpty {
                            Text("Moods appear after you save a reflection.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Chart(moodCounts) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Mood", item.mood)
                                )
                                .foregroundStyle(AppTheme.accent)
                            }
                            .frame(height: CGFloat(max(120, moodCounts.count * 44)))
                            .chartXAxis {
                                AxisMarks(position: .bottom)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PetalCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Averages")
                            .font(.system(.headline, design: .serif))
                        Text("Typical walk: \(averageMinutes) min")
                            .foregroundColor(.secondary)
                        Text("Reflections saved: \(store.insights.count)")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgTrail")
        .navigationTitle("Statistics")
    }

    private var emptyChartHint: some View {
        Text("Complete a walk to see this chart.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
    }

    private var completed: [WalkSession] {
        store.walks.filter(\.completed)
    }

    private var totalMinutes: Int {
        completed.reduce(0) { $0 + $1.durationMinutes }
    }

    private var averageMinutes: Int {
        completed.isEmpty ? 0 : totalMinutes / completed.count
    }

    private var weekDays: [DayMinutes] {
        buckets(days: 7).map { DayMinutes(date: $0.date, minutes: $0.minutes) }
    }

    private var fortnightDays: [DayWalks] {
        buckets(days: 14).map { DayWalks(date: $0.date, walks: $0.walks) }
    }

    private var moodCounts: [MoodCount] {
        let grouped = Dictionary(grouping: store.insights, by: \.mood)
        return grouped
            .map { MoodCount(mood: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private func buckets(days: Int) -> [(date: Date, minutes: Int, walks: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(days - 1 - offset), to: today) else { return nil }
            let dayWalks = completed.filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
            return (date, dayWalks.reduce(0) { $0 + $1.durationMinutes }, dayWalks.count)
        }
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

private struct DayMinutes: Identifiable {
    var id: Date { date }
    let date: Date
    let minutes: Int
}

private struct DayWalks: Identifiable {
    var id: Date { date }
    let date: Date
    let walks: Int
}

private struct MoodCount: Identifiable {
    var id: String { mood }
    let mood: String
    let count: Int
}
