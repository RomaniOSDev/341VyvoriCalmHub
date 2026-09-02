import SwiftUI

struct WeeklyReviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var keepText = ""
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    tile("Streak", "\(store.currentStreak)", "flame.fill")
                    tile("This week", "\(weekWalks.count)", "leaf.fill")
                }
                PetalCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorite mood")
                            .font(.system(.headline, design: .serif))
                        Text(favoriteMood ?? "No reflections this week yet.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                PetalCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calmest walk")
                            .font(.system(.headline, design: .serif))
                        if let walk = calmestWalk {
                            Text(walk.startedAt.formatted(date: .abbreviated, time: .shortened))
                            Text("\(walk.durationMinutes) min · \(walk.location.isEmpty ? "Unnamed path" : walk.location)")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Complete a walk this week to see this.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                PetalCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What will you keep next week?")
                            .font(.system(.headline, design: .serif))
                        TextEditor(text: $keepText)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color.white.opacity(0.55), in: AppTheme.stoneShape(1))
                        if saved {
                            Text("Saved for this week.")
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                        }
                        PetalButton(title: "Save this intention", systemImage: "bookmark.fill") {
                            store.saveWeeklyKeep(keepText)
                            saved = true
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }
                        Button("Close for this week") {
                            store.markReviewSeen()
                        }
                        .foregroundColor(AppTheme.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgTrail")
        .navigationTitle("Weekly review")
        .onAppear {
            keepText = store.keepNoteThisWeek()
        }
    }

    private var weekStart: Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromSunday = weekday - 1
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysFromSunday, to: now) ?? now)
    }

    private var weekWalks: [WalkSession] {
        store.walks.filter { $0.completed && $0.startedAt >= weekStart }
    }

    private var weekInsights: [Insight] {
        store.insights.filter { $0.date >= weekStart }
    }

    private var favoriteMood: String? {
        let grouped = Dictionary(grouping: weekInsights, by: \.mood)
        return grouped.max { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return lhs.key > rhs.key
            }
            return lhs.value.count < rhs.value.count
        }?.key
    }

    private var calmestWalk: WalkSession? {
        let calmIds = Set(weekInsights.filter { $0.mood == "Calm" }.compactMap(\.walkId))
        let calmWalks = weekWalks.filter { calmIds.contains($0.id) }
        if let longestCalm = calmWalks.max(by: { $0.durationMinutes < $1.durationMinutes }) {
            return longestCalm
        }
        return weekWalks.min(by: { $0.durationMinutes < $1.durationMinutes })
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
