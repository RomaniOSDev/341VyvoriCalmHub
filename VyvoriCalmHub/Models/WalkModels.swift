import Foundation

struct WalkSession: Codable, Identifiable, Hashable {
    var id: UUID
    var startedAt: Date
    var durationMinutes: Int
    var location: String
    var reflection: String
    var completed: Bool
}

struct Insight: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var text: String
    var walkId: UUID?
    var mood: String
}

struct FavoritePlace: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
}

struct ProgramProgress: Codable, Equatable {
    var programId: String
    var completedDays: [Int]
    var startedAt: Date
}

struct WeeklyKeepNote: Codable, Identifiable, Hashable {
    var id: UUID
    var year: Int
    var weekOfYear: Int
    var text: String
}

struct WalkProgram: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let durationMinutes: Int
    let dayPrompts: [String]
}

enum WalkPrompts {
    static let standard = [
        "Notice five colors around you.",
        "Match your breath to your steps.",
        "Name one sound that is far away.",
        "Feel the weight of each footfall."
    ]

    static let catalog: [WalkProgram] = [
        WalkProgram(
            id: "evening-ground",
            title: "Evening grounding",
            summary: "Seven short dusk walks to arrive back in your body.",
            durationMinutes: 15,
            dayPrompts: [
                "Let the day drop with each exhale.",
                "Feel the temperature on your cheeks.",
                "Name three still things along the path.",
                "Soften your shoulders for ten steps.",
                "Listen for the quietest sound nearby.",
                "Walk as if you have nowhere else to be.",
                "Thank the path before you turn home."
            ]
        ),
        WalkProgram(
            id: "morning-clear",
            title: "Morning clear",
            summary: "A week of light starts before the day fills in.",
            durationMinutes: 10,
            dayPrompts: [
                "Notice the first color of the morning.",
                "Count ten unhurried steps.",
                "Let your eyes rest on something far away.",
                "Breathe in the newest air you can find.",
                "Keep your hands easy at your sides.",
                "Hear one bird, or the hush if none.",
                "Carry one quiet thought into the day."
            ]
        ),
        WalkProgram(
            id: "soft-return",
            title: "Soft return",
            summary: "Twenty-minute walks for weeks that felt too loud.",
            durationMinutes: 20,
            dayPrompts: [
                "Begin slower than you think you need.",
                "If a thought pulls, return to your feet.",
                "Look for something living and small.",
                "Let your jaw unclench for a minute.",
                "Match your pace to a calm inner count.",
                "Leave one worry on a bench and walk on.",
                "End by standing still for three breaths."
            ]
        )
    ]

    static func program(id: String) -> WalkProgram? {
        catalog.first { $0.id == id }
    }
}

struct ActiveWalk: Codable, Equatable {
    var walkId: UUID
    var remainingSeconds: Int
    var startedAt: Date
    var location: String
    var plannedMinutes: Int
    var promptIndex: Int
    var running: Bool
    var isOpenEnded: Bool
    var elapsedSeconds: Int
    var programId: String?
    var programDay: Int?
    var prompts: [String]

    init(
        walkId: UUID,
        remainingSeconds: Int,
        startedAt: Date,
        location: String,
        plannedMinutes: Int,
        promptIndex: Int,
        running: Bool,
        isOpenEnded: Bool = false,
        elapsedSeconds: Int = 0,
        programId: String? = nil,
        programDay: Int? = nil,
        prompts: [String] = WalkPrompts.standard
    ) {
        self.walkId = walkId
        self.remainingSeconds = remainingSeconds
        self.startedAt = startedAt
        self.location = location
        self.plannedMinutes = plannedMinutes
        self.promptIndex = promptIndex
        self.running = running
        self.isOpenEnded = isOpenEnded
        self.elapsedSeconds = elapsedSeconds
        self.programId = programId
        self.programDay = programDay
        self.prompts = prompts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        walkId = try c.decode(UUID.self, forKey: .walkId)
        remainingSeconds = try c.decode(Int.self, forKey: .remainingSeconds)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        location = try c.decode(String.self, forKey: .location)
        plannedMinutes = try c.decode(Int.self, forKey: .plannedMinutes)
        promptIndex = try c.decode(Int.self, forKey: .promptIndex)
        running = try c.decode(Bool.self, forKey: .running)
        isOpenEnded = try c.decodeIfPresent(Bool.self, forKey: .isOpenEnded) ?? false
        elapsedSeconds = try c.decodeIfPresent(Int.self, forKey: .elapsedSeconds) ?? 0
        programId = try c.decodeIfPresent(String.self, forKey: .programId)
        programDay = try c.decodeIfPresent(Int.self, forKey: .programDay)
        prompts = try c.decodeIfPresent([String].self, forKey: .prompts) ?? WalkPrompts.standard
    }
}
