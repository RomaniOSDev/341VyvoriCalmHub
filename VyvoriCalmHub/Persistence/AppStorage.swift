import Foundation
import Combine

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var routes: [WalkingRoute] = []
    @Published var walks: [RouteWalk] = []
    @Published var reminderEnabled = false
    @Published var reminderHour = 8
    @Published var reminderMinute = 0
    @Published var focusStopName = ""
    @Published var lastReviewYear = 0
    @Published var lastReviewWeek = 0
    @Published var selectedRouteId: UUID?

    private let defaults = UserDefaults.standard
    private let routesKey = "walkingRoutes.v2"
    private let walksKey = "routeWalks.v2"
    private let seededKey = "didSeedStarterRoutes.v2"
    private let reminderOnKey = "reminderEnabled"
    private let reminderHourKey = "reminderHour"
    private let reminderMinuteKey = "reminderMinute"
    private let focusStopKey = "focusStopName"
    private let lastReviewYearKey = "lastReviewYear"
    private let lastReviewWeekKey = "lastReviewWeek"
    private let selectedRouteKey = "selectedRouteId"
    private let legacyKeys = [
        "walks", "insights", "walkDurationMin", "lastVisitedInsightDate", "weeklySummary",
        "activeWalk", "favoritePlaces", "programProgress", "weeklyKeeps"
    ]

    private init() {
        load()
    }

    func load() {
        routes = decode([WalkingRoute].self, key: routesKey) ?? []
        walks = decode([RouteWalk].self, key: walksKey) ?? []
        if !defaults.bool(forKey: seededKey), routes.isEmpty {
            routes = StarterRoutes.all
            defaults.set(true, forKey: seededKey)
            encode(routes, key: routesKey)
        }
        reminderEnabled = defaults.bool(forKey: reminderOnKey)
        reminderHour = (defaults.object(forKey: reminderHourKey) as? Int) ?? 8
        reminderMinute = (defaults.object(forKey: reminderMinuteKey) as? Int) ?? 0
        focusStopName = defaults.string(forKey: focusStopKey) ?? ""
        lastReviewYear = defaults.integer(forKey: lastReviewYearKey)
        lastReviewWeek = defaults.integer(forKey: lastReviewWeekKey)
        if let raw = defaults.string(forKey: selectedRouteKey), let id = UUID(uuidString: raw) {
            selectedRouteId = id
        }
        if selectedRouteId == nil || !(routes.contains { $0.id == selectedRouteId }) {
            selectedRouteId = preferredRoute?.id
        }
        rescheduleReminder()
    }

    func save() {
        encode(routes, key: routesKey)
        encode(walks, key: walksKey)
        defaults.set(reminderEnabled, forKey: reminderOnKey)
        defaults.set(reminderHour, forKey: reminderHourKey)
        defaults.set(reminderMinute, forKey: reminderMinuteKey)
        defaults.set(focusStopName, forKey: focusStopKey)
        defaults.set(lastReviewYear, forKey: lastReviewYearKey)
        defaults.set(lastReviewWeek, forKey: lastReviewWeekKey)
        defaults.set(selectedRouteId?.uuidString, forKey: selectedRouteKey)
    }

    var preferredRoute: WalkingRoute? {
        if let id = selectedRouteId, let match = routes.first(where: { $0.id == id }) {
            return match
        }
        return routes.first(where: \.isWalkable) ?? routes.first
    }

    var activeWalk: RouteWalk? {
        walks.first { !$0.completed && $0.nextStop != nil }
    }

    var hasResumableWalk: Bool {
        activeWalk != nil
    }

    var weeklySummary: String {
        let week = completedWalks(since: weekStart)
        if week.isEmpty { return "No path finished this week yet." }
        let stops = week.reduce(0) { $0 + $1.checkIns.count }
        let places = Set(week.flatMap { $0.checkIns.map(\.stopName) }).count
        return "\(week.count) paths · \(stops) stops · \(places) distinct places"
    }

    var hasCompletedWalkToday: Bool {
        walks.contains { $0.completed && Calendar.current.isDateInToday($0.startedAt) }
    }

    var distinctStopNames: [String] {
        let names = walks.filter(\.completed).flatMap { $0.checkIns.map(\.stopName) }
        return Array(Set(names)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var shouldShowSundayReview: Bool {
        let calendar = Calendar.current
        guard calendar.component(.weekday, from: Date()) == 1 else { return false }
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        let week = calendar.component(.weekOfYear, from: Date())
        return lastReviewYear != year || lastReviewWeek != week
    }

    func selectRoute(_ id: UUID) {
        selectedRouteId = id
        save()
    }

    func upsertRoute(_ route: WalkingRoute) {
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index] = route
        } else {
            routes.insert(route, at: 0)
        }
        selectedRouteId = route.id
        save()
    }

    func deleteRoute(_ id: UUID) {
        routes.removeAll { $0.id == id }
        if selectedRouteId == id {
            selectedRouteId = preferredRoute?.id
        }
        save()
    }

    func duplicateRoute(_ route: WalkingRoute) {
        var copy = route
        copy.id = UUID()
        copy.title = route.trimmedTitle.isEmpty ? "Copied path" : "\(route.trimmedTitle) copy"
        copy.isStarter = false
        copy.createdAt = Date()
        copy.stops = route.stops.map { stop in
            var next = stop
            next.id = UUID()
            return next
        }
        upsertRoute(copy)
    }

    func startWalk(from route: WalkingRoute) -> RouteWalk? {
        guard route.isWalkable else { return nil }
        if let existing = activeWalk {
            return existing
        }
        let walk = RouteWalk(
            id: UUID(),
            routeId: route.id,
            routeTitle: route.trimmedTitle,
            startedAt: Date(),
            finishedAt: nil,
            stops: route.stops,
            checkIns: [],
            currentStopIndex: 0,
            completed: false,
            closingLine: "",
            standRemaining: 0,
            draftNote: ""
        )
        walks.insert(walk, at: 0)
        selectedRouteId = route.id
        save()
        return walk
    }

    func recordCheckIn(walkId: UUID, checkIn: StopCheckIn) {
        guard let index = walks.firstIndex(where: { $0.id == walkId }) else { return }
        walks[index].checkIns.append(checkIn)
        walks[index].currentStopIndex += 1
        walks[index].draftNote = ""
        walks[index].standRemaining = 0
        if walks[index].currentStopIndex >= walks[index].stops.count {
            walks[index].completed = true
            walks[index].finishedAt = Date()
        }
        save()
        if walks[index].completed {
            rescheduleReminder()
        }
    }

    func finishWalk(walkId: UUID, closingLine: String) {
        guard let index = walks.firstIndex(where: { $0.id == walkId }) else { return }
        walks[index].closingLine = closingLine.trimmingCharacters(in: .whitespacesAndNewlines)
        walks[index].completed = true
        walks[index].finishedAt = walks[index].finishedAt ?? Date()
        walks[index].currentStopIndex = walks[index].stops.count
        save()
        rescheduleReminder()
    }

    func persistWalkProgress(walkId: UUID, note: String, standRemaining: Int) {
        guard let index = walks.firstIndex(where: { $0.id == walkId }) else { return }
        walks[index].draftNote = note
        walks[index].standRemaining = standRemaining
        save()
    }

    func deleteWalk(_ id: UUID) {
        walks.removeAll { $0.id == id }
        save()
        rescheduleReminder()
    }

    func completedWalks(since date: Date) -> [RouteWalk] {
        walks.filter { $0.completed && $0.startedAt >= date }
    }

    func saveFocusStop(_ name: String) {
        focusStopName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        markReviewSeen()
        save()
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
        WalkReminder.reschedule(
            enabled: reminderEnabled,
            hour: reminderHour,
            minute: reminderMinute,
            walkedToday: hasCompletedWalkToday
        )
    }

    var weekStart: Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromSunday = weekday - 1
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysFromSunday, to: now) ?? now)
    }

    func resetAllData() {
        ([routesKey, walksKey, seededKey, reminderOnKey, reminderHourKey, reminderMinuteKey,
          focusStopKey, lastReviewYearKey, lastReviewWeekKey, selectedRouteKey] + legacyKeys)
            .forEach { defaults.removeObject(forKey: $0) }
        routes = StarterRoutes.all
        walks = []
        reminderEnabled = false
        reminderHour = 8
        reminderMinute = 0
        focusStopName = ""
        lastReviewYear = 0
        lastReviewWeek = 0
        selectedRouteId = routes.first?.id
        defaults.set(true, forKey: seededKey)
        save()
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
