import Foundation

enum StopRitual: String, Codable, CaseIterable, Identifiable {
    case standStill
    case nameSound
    case groundTexture
    case shortNote

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standStill: return "Stand still"
        case .nameSound: return "Name a sound"
        case .groundTexture: return "Read the ground"
        case .shortNote: return "Leave a line"
        }
    }

    var instruction: String {
        switch self {
        case .standStill: return "Arrive, then stay with your feet until the count ends."
        case .nameSound: return "Name the farthest sound you can still hear."
        case .groundTexture: return "Look at the ground. Write one texture, color, or crack."
        case .shortNote: return "One sentence you can leave at this stop."
        }
    }

    var systemImage: String {
        switch self {
        case .standStill: return "pause.circle"
        case .nameSound: return "ear"
        case .groundTexture: return "leaf"
        case .shortNote: return "square.and.pencil"
        }
    }
}

struct RouteStop: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var ritual: StopRitual
    var dwellSeconds: Int
    var cue: String

    init(
        id: UUID = UUID(),
        name: String,
        ritual: StopRitual,
        dwellSeconds: Int = 30,
        cue: String = ""
    ) {
        self.id = id
        self.name = name
        self.ritual = ritual
        self.dwellSeconds = dwellSeconds
        self.cue = cue
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct WalkingRoute: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var summary: String
    var stops: [RouteStop]
    var createdAt: Date
    var isStarter: Bool

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        stops: [RouteStop],
        createdAt: Date = Date(),
        isStarter: Bool = false
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.stops = stops
        self.createdAt = createdAt
        self.isStarter = isStarter
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isWalkable: Bool {
        let named = stops.filter { !$0.trimmedName.isEmpty }
        return named.count == stops.count && (4...6).contains(stops.count)
    }
}

struct StopCheckIn: Codable, Identifiable, Hashable {
    var id: UUID
    var stopId: UUID
    var stopName: String
    var ritual: StopRitual
    var body: String
    var dwellSeconds: Int
    var completedAt: Date
}

struct RouteWalk: Codable, Identifiable, Hashable {
    var id: UUID
    var routeId: UUID
    var routeTitle: String
    var startedAt: Date
    var finishedAt: Date?
    var stops: [RouteStop]
    var checkIns: [StopCheckIn]
    var currentStopIndex: Int
    var completed: Bool
    var closingLine: String
    var standRemaining: Int
    var draftNote: String

    var nextStop: RouteStop? {
        guard stops.indices.contains(currentStopIndex) else { return nil }
        return stops[currentStopIndex]
    }
}

enum StarterRoutes {
    static let all: [WalkingRoute] = [thresholdLoop, lampToLamp, softCircuit]

    static let thresholdLoop = WalkingRoute(
        id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567001")!,
        title: "Threshold loop",
        summary: "Four outdoor landings from the door and back.",
        stops: [
            RouteStop(
                name: "The doorstep",
                ritual: .standStill,
                dwellSeconds: 30,
                cue: "Feel the first outdoor air before you take a step."
            ),
            RouteStop(
                name: "First tree or lamp",
                ritual: .nameSound,
                cue: "Stand beside it. Name a sound that is farther than your breath."
            ),
            RouteStop(
                name: "A bench, wall, or low curb",
                ritual: .groundTexture,
                cue: "Look down. Write one thing the ground is doing."
            ),
            RouteStop(
                name: "The turn toward home",
                ritual: .shortNote,
                cue: "Leave one sentence you do not need to carry inside."
            )
        ],
        isStarter: true
    )

    static let lampToLamp = WalkingRoute(
        id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567002")!,
        title: "Lamp to lamp",
        summary: "Five short landings along whatever lights you already pass.",
        stops: [
            RouteStop(
                name: "Gate or building corner",
                ritual: .standStill,
                dwellSeconds: 20,
                cue: "Let your shoulders drop before the first lamp."
            ),
            RouteStop(
                name: "Second lamp or sign",
                ritual: .nameSound,
                cue: "Is the sound mechanical, human, or weather?"
            ),
            RouteStop(
                name: "A patch of open ground",
                ritual: .groundTexture,
                cue: "Pebble, leaf, crack, or wet shine — pick one."
            ),
            RouteStop(
                name: "The farthest lamp you meant to reach",
                ritual: .shortNote,
                cue: "Write what this stretch of street felt like."
            ),
            RouteStop(
                name: "The last corner before your door",
                ritual: .standStill,
                dwellSeconds: 30,
                cue: "Arrive home slower than you left."
            )
        ],
        isStarter: true
    )

    static let softCircuit = WalkingRoute(
        id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567003")!,
        title: "Soft circuit",
        summary: "Six stops for a week that already felt too loud.",
        stops: [
            RouteStop(
                name: "Threshold",
                ritual: .standStill,
                dwellSeconds: 45,
                cue: "Begin slower than you think you need."
            ),
            RouteStop(
                name: "Something living and small",
                ritual: .groundTexture,
                cue: "Moss, insect, weed in a crack — stay with it."
            ),
            RouteStop(
                name: "A place you can rest a hand",
                ritual: .nameSound,
                cue: "Name the quietest sound near your hand."
            ),
            RouteStop(
                name: "A bench you could leave a worry on",
                ritual: .shortNote,
                cue: "Write the worry in one line, then walk on."
            ),
            RouteStop(
                name: "A long view or an empty lot",
                ritual: .standStill,
                dwellSeconds: 30,
                cue: "Let your eyes rest farther than your thoughts."
            ),
            RouteStop(
                name: "Home stoop",
                ritual: .shortNote,
                cue: "Thank the path in one sentence before you go in."
            )
        ],
        isStarter: true
    )
}
