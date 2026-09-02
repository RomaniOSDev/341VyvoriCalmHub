import Foundation
import Combine

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

final class WalkClock: ObservableObject {
    @Published var remaining = 0
    @Published var elapsed = 0
    @Published var running = false
    @Published var isOpenEnded = false
    @Published var promptIndex = 0

    private var timer: Timer?

    var isLive: Bool {
        isOpenEnded || remaining > 0
    }

    func loadCountdown(seconds: Int, elapsed: Int, promptIndex: Int) {
        isOpenEnded = false
        remaining = max(0, seconds)
        self.elapsed = elapsed
        self.promptIndex = promptIndex
    }

    func loadOpenEnded(elapsed: Int, promptIndex: Int) {
        isOpenEnded = true
        remaining = 0
        self.elapsed = elapsed
        self.promptIndex = promptIndex
    }

    func resume() {
        running = true
        arm()
    }

    func pause() {
        running = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        remaining = 0
        elapsed = 0
        isOpenEnded = false
        promptIndex = 0
    }

    private func arm() {
        timer?.invalidate()
        let next = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }

    private func tick() {
        guard running else { return }
        if isOpenEnded {
            elapsed += 1
            if elapsed % 60 == 0 {
                promptIndex += 1
            }
            return
        }
        guard remaining > 0 else { return }
        remaining -= 1
        elapsed += 1
        if remaining % 60 == 0 {
            promptIndex += 1
        }
        if remaining == 0 {
            pause()
        }
    }
}

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var walks: [WalkSession] = []
    @Published var insights: [Insight] = []
    @Published var walkDurationMin: Int = 20
    @Published var lastVisitedInsightDate: Date?
    @Published var weeklySummary: String = ""
    @Published var activeWalk: ActiveWalk?
    @Published var favoritePlaces: [FavoritePlace] = []
    @Published var programProgress: [ProgramProgress] = []
    @Published var reminderEnabled = false
    @Published var reminderHour = 8
    @Published var reminderMinute = 0
    @Published var weeklyKeeps: [WeeklyKeepNote] = []
    @Published var lastReviewYear = 0
    @Published var lastReviewWeek = 0
    @Published var isWalkTimerShown = false
    let clock = WalkClock()
    var launchPrompts: [String]?
    var launchProgramId: String?
    var launchProgramDay: Int?
    var launchDurationMin: Int?

    private let defaults = UserDefaults.standard
    private let walksKey = "walks"
    private let insightsKey = "insights"
    private let durationKey = "walkDurationMin"
    private let lastInsightKey = "lastVisitedInsightDate"
    private let weeklyKey = "weeklySummary"
    private let activeWalkKey = "activeWalk"
    private let favoritesKey = "favoritePlaces"
    private let programsKey = "programProgress"
    private let reminderOnKey = "reminderEnabled"
    private let reminderHourKey = "reminderHour"
    private let reminderMinuteKey = "reminderMinute"
    private let weeklyKeepsKey = "weeklyKeeps"
    private let lastReviewYearKey = "lastReviewYear"
    private let lastReviewWeekKey = "lastReviewWeek"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        clock.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        load()
    }

    func load() {
        walks = decode([WalkSession].self, key: walksKey) ?? []
        insights = decode([Insight].self, key: insightsKey) ?? []
        if defaults.object(forKey: durationKey) == nil {
            walkDurationMin = 20
        } else {
            walkDurationMin = defaults.integer(forKey: durationKey)
        }
        lastVisitedInsightDate = defaults.object(forKey: lastInsightKey) as? Date
        weeklySummary = defaults.string(forKey: weeklyKey) ?? ""
        activeWalk = decode(ActiveWalk.self, key: activeWalkKey)
        if let active = activeWalk, !active.isOpenEnded, active.remainingSeconds <= 0 {
            activeWalk = nil
        }
        favoritePlaces = decode([FavoritePlace].self, key: favoritesKey) ?? []
        programProgress = decode([ProgramProgress].self, key: programsKey) ?? []
        reminderEnabled = defaults.bool(forKey: reminderOnKey)
        let hour = defaults.object(forKey: reminderHourKey) as? Int
        reminderHour = hour ?? 8
        reminderMinute = defaults.object(forKey: reminderMinuteKey) as? Int ?? 0
        weeklyKeeps = decode([WeeklyKeepNote].self, key: weeklyKeepsKey) ?? []
        lastReviewYear = defaults.integer(forKey: lastReviewYearKey)
        lastReviewWeek = defaults.integer(forKey: lastReviewWeekKey)
        refreshWeekly()
        rescheduleReminder()
    }

    func save() {
        encode(walks, key: walksKey)
        encode(insights, key: insightsKey)
        defaults.set(walkDurationMin, forKey: durationKey)
        defaults.set(lastVisitedInsightDate, forKey: lastInsightKey)
        defaults.set(weeklySummary, forKey: weeklyKey)
        if let activeWalk {
            encode(activeWalk, key: activeWalkKey)
        } else {
            defaults.removeObject(forKey: activeWalkKey)
        }
        encode(favoritePlaces, key: favoritesKey)
        encode(programProgress, key: programsKey)
        defaults.set(reminderEnabled, forKey: reminderOnKey)
        defaults.set(reminderHour, forKey: reminderHourKey)
        defaults.set(reminderMinute, forKey: reminderMinuteKey)
        encode(weeklyKeeps, key: weeklyKeepsKey)
        defaults.set(lastReviewYear, forKey: lastReviewYearKey)
        defaults.set(lastReviewWeek, forKey: lastReviewWeekKey)
    }

    var hasResumableWalk: Bool {
        if clock.isLive { return true }
        guard let active = activeWalk else { return false }
        return active.isOpenEnded || active.remainingSeconds > 0
    }

    var durationLabel: String {
        walkDurationMin == 0 ? "Until I stop" : "Duration: \(walkDurationMin) min"
    }

    var hasCompletedWalkToday: Bool {
        walks.contains { $0.completed && Calendar.current.isDateInToday($0.startedAt) }
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let days = Set(walks.filter(\.completed).map { calendar.startOfDay(for: $0.startedAt) })
        var cursor = calendar.startOfDay(for: Date())
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    var shouldShowSundayReview: Bool {
        let calendar = Calendar.current
        guard calendar.component(.weekday, from: Date()) == 1 else { return false }
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        let week = calendar.component(.weekOfYear, from: Date())
        return lastReviewYear != year || lastReviewWeek != week
    }

    func upsertWalk(_ walk: WalkSession) {
        if let index = walks.firstIndex(where: { $0.id == walk.id }) {
            walks[index] = walk
        } else {
            walks.insert(walk, at: 0)
        }
        refreshWeekly()
        save()
        if walk.completed {
            rescheduleReminder()
        }
    }

    func deleteWalk(_ id: UUID) {
        walks.removeAll { $0.id == id }
        insights.removeAll { $0.walkId == id }
        if activeWalk?.walkId == id {
            activeWalk = nil
        }
        refreshWeekly()
        save()
        rescheduleReminder()
    }

    func upsertInsight(_ insight: Insight) {
        if let index = insights.firstIndex(where: { $0.id == insight.id }) {
            insights[index] = insight
        } else {
            insights.insert(insight, at: 0)
        }
        lastVisitedInsightDate = insight.date
        refreshWeekly()
        save()
    }

    func deleteInsight(_ id: UUID) {
        insights.removeAll { $0.id == id }
        save()
    }

    func addFavoritePlace(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, favoritePlaces.count < 5 else { return }
        guard !favoritePlaces.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        favoritePlaces.append(FavoritePlace(id: UUID(), name: trimmed))
        save()
    }

    func removeFavoritePlace(_ id: UUID) {
        favoritePlaces.removeAll { $0.id == id }
        save()
    }

    func markProgramDay(programId: String, day: Int) {
        if let index = programProgress.firstIndex(where: { $0.programId == programId }) {
            if !programProgress[index].completedDays.contains(day) {
                programProgress[index].completedDays.append(day)
            }
        } else {
            programProgress.append(ProgramProgress(programId: programId, completedDays: [day], startedAt: Date()))
        }
        save()
    }

    func resetProgram(_ programId: String) {
        programProgress.removeAll { $0.programId == programId }
        save()
    }

    func progress(for programId: String) -> ProgramProgress? {
        programProgress.first { $0.programId == programId }
    }

    func prepareProgramWalk(program: WalkProgram, day: Int) {
        launchDurationMin = program.durationMinutes
        launchProgramId = program.id
        launchProgramDay = day
        var prompts = WalkPrompts.standard
        if program.dayPrompts.indices.contains(day) {
            prompts.insert(program.dayPrompts[day], at: 0)
        }
        launchPrompts = prompts
    }

    func clearLaunchOverrides() {
        launchPrompts = nil
        launchProgramId = nil
        launchProgramDay = nil
        launchDurationMin = nil
    }

    func saveWeeklyKeep(_ text: String) {
        let calendar = Calendar.current
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        let week = calendar.component(.weekOfYear, from: Date())
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = weeklyKeeps.firstIndex(where: { $0.year == year && $0.weekOfYear == week }) {
            weeklyKeeps[index].text = trimmed
        } else {
            weeklyKeeps.insert(WeeklyKeepNote(id: UUID(), year: year, weekOfYear: week, text: trimmed), at: 0)
        }
        markReviewSeen()
        save()
    }

    func keepNoteThisWeek() -> String {
        let calendar = Calendar.current
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        let week = calendar.component(.weekOfYear, from: Date())
        return weeklyKeeps.first { $0.year == year && $0.weekOfYear == week }?.text ?? ""
    }

    func markReviewSeen() {
        let calendar = Calendar.current
        lastReviewYear = calendar.component(.yearForWeekOfYear, from: Date())
        lastReviewWeek = calendar.component(.weekOfYear, from: Date())
        save()
    }

    func updateReminder(enabled: Bool, hour: Int, minute: Int, requestPermission: Bool) {
        reminderEnabled = enabled
        reminderHour = hour
        reminderMinute = minute
        save()
        if requestPermission, enabled {
            WalkReminder.enable(hour: hour, minute: minute, walkedToday: hasCompletedWalkToday)
        } else {
            rescheduleReminder()
        }
    }

    func rescheduleReminder() {
        WalkReminder.reschedule(enabled: reminderEnabled, hour: reminderHour, minute: reminderMinute, walkedToday: hasCompletedWalkToday)
    }

    func refreshWeekly() {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekWalks = walks.filter { $0.startedAt >= weekAgo && $0.completed }
        let minutes = weekWalks.reduce(0) { $0 + $1.durationMinutes }
        weeklySummary = weekWalks.isEmpty ? "No completed walks this week yet." : "\(weekWalks.count) walks · \(minutes) mindful minutes"
    }

    func resetAllData() {
        [
            walksKey, insightsKey, durationKey, lastInsightKey, weeklyKey, activeWalkKey,
            favoritesKey, programsKey, reminderOnKey, reminderHourKey, reminderMinuteKey,
            weeklyKeepsKey, lastReviewYearKey, lastReviewWeekKey
        ].forEach { defaults.removeObject(forKey: $0) }
        walks = []
        insights = []
        walkDurationMin = 20
        lastVisitedInsightDate = nil
        weeklySummary = ""
        activeWalk = nil
        favoritePlaces = []
        programProgress = []
        reminderEnabled = false
        reminderHour = 8
        reminderMinute = 0
        weeklyKeeps = []
        lastReviewYear = 0
        lastReviewWeek = 0
        isWalkTimerShown = false
        clock.reset()
        clearLaunchOverrides()
        WalkReminder.cancel()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
