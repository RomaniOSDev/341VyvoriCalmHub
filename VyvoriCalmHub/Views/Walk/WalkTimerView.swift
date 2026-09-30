import SwiftUI
import Combine

struct RouteWalkView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @Binding var sessionPresented: Bool
    @State private var walkId: UUID?
    @State private var note = ""
    @State private var remaining = 0
    @State private var standFinished = false
    @State private var error: String?
    @State private var showComplete = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var walk: RouteWalk? {
        guard let walkId else { return store.activeWalk }
        return store.walks.first { $0.id == walkId } ?? store.activeWalk
    }

    private var stop: RouteStop? { walk?.nextStop }

    var body: some View {
        Group {
            if showComplete {
                Color.clear
                    .screenBackdrop("BgTrail")
            } else if let walk, let stop {
                walkBody(walk: walk, stop: stop)
            } else {
                Text("This path is no longer available.")
                    .foregroundColor(.white)
                    .screenBackdrop("BgTrail")
            }
        }
        .navigationTitle("On the path")
        .onAppear { prepare() }
        .navigationDestination(isPresented: $showComplete) {
            if let walkId {
                RouteCompleteView(walkId: walkId, sessionPresented: $sessionPresented)
            }
        }
    }

    private func walkBody(walk: RouteWalk, stop: RouteStop) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("BannerSteps")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 96)
                    .clipShape(AppTheme.stoneShape(2))
                    .overlay(AppTheme.stoneShape(2).stroke(AppTheme.primary.opacity(0.3), lineWidth: 1.2))

                Text("Stop \(walk.currentStopIndex + 1) of \(walk.stops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))

                ArriveMarkerView()

                PetalCard(cut: 1) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(stop.trimmedName)
                            .font(AppTheme.display(26))
                        Text(stop.ritual.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.primary)
                        Text(stop.cue.isEmpty ? stop.ritual.instruction : stop.cue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        PathMapTrail(
                            titles: walk.stops.map(\.trimmedName),
                            doneCount: walk.checkIns.count,
                            highlightIndex: walk.currentStopIndex
                        )
                    }
                }

                ritualCard(for: stop)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                PetalButton(
                    title: walk.currentStopIndex + 1 >= walk.stops.count ? "Check in & finish" : "Check in & walk on",
                    systemImage: "checkmark"
                ) {
                    submit()
                }
                Button("Leave path") {
                    store.persistWalkProgress(walkId: walk.id, note: note, standRemaining: remaining)
                    sessionPresented = false
                }
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .keepScreenAwake()
        .onReceive(ticker) { _ in tickStandStill() }
        .onDisappear {
            if !showComplete {
                store.persistWalkProgress(walkId: walk.id, note: note, standRemaining: remaining)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active, !showComplete {
                store.persistWalkProgress(walkId: walk.id, note: note, standRemaining: remaining)
            }
        }
    }

    @ViewBuilder
    private func ritualCard(for stop: RouteStop) -> some View {
        PetalCard(cut: 2) {
            VStack(alignment: .leading, spacing: 12) {
                switch stop.ritual {
                case .standStill:
                    Text(standFinished ? "You can check in." : "Stand with this stop.")
                        .font(.system(.headline, design: .serif))
                    ZStack {
                        RippleRings(count: 3, base: 110)
                        Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                            .font(.system(size: 44, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(AppTheme.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                case .nameSound:
                    Text("The farthest sound")
                        .font(.system(.headline, design: .serif))
                    TextField("A bus, a bird, a door…", text: $note, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                case .groundTexture:
                    Text("What the ground is doing")
                        .font(.system(.headline, design: .serif))
                    TextField("Wet leaf, hairline crack, pale dust…", text: $note, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                case .shortNote:
                    Text("A line to leave here")
                        .font(.system(.headline, design: .serif))
                    TextEditor(text: $note)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.55), in: AppTheme.stoneShape(0))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func prepare() {
        if let active = store.activeWalk {
            walkId = active.id
            restoreRitual(from: active)
            if active.completed {
                showComplete = true
            }
        }
    }

    private func restoreRitual(from walk: RouteWalk) {
        error = nil
        note = walk.draftNote
        guard let stop = walk.nextStop else {
            standFinished = true
            remaining = 0
            return
        }
        if stop.ritual == .standStill {
            let start = max(20, stop.dwellSeconds)
            remaining = walk.standRemaining > 0 ? min(walk.standRemaining, start) : start
            standFinished = remaining == 0
        } else {
            remaining = 0
            standFinished = true
        }
    }

    private func resetRitual(for stop: RouteStop?) {
        note = ""
        error = nil
        standFinished = stop?.ritual != .standStill
        remaining = stop?.ritual == .standStill ? max(20, stop?.dwellSeconds ?? 30) : 0
    }

    private func tickStandStill() {
        guard let stop, stop.ritual == .standStill, !standFinished, remaining > 0 else { return }
        remaining -= 1
        if remaining == 0 {
            standFinished = true
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func submit() {
        guard let walk, let stop else { return }
        error = nil
        if stop.ritual == .standStill, !standFinished {
            error = "Stay at this stop until the count ends."
            return
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if stop.ritual != .standStill, trimmed.isEmpty {
            error = "Write what you found at this stop."
            return
        }
        let body: String
        switch stop.ritual {
        case .standStill:
            body = "Stood still for \(stop.dwellSeconds)s"
        case .nameSound, .groundTexture, .shortNote:
            body = trimmed
        }
        let checkIn = StopCheckIn(
            id: UUID(),
            stopId: stop.id,
            stopName: stop.trimmedName,
            ritual: stop.ritual,
            body: body,
            dwellSeconds: stop.ritual == .standStill ? stop.dwellSeconds : 0,
            completedAt: Date()
        )
        let wasLast = walk.currentStopIndex + 1 >= walk.stops.count
        store.recordCheckIn(walkId: walk.id, checkIn: checkIn)
        if wasLast {
            showComplete = true
        } else {
            resetRitual(for: store.walks.first { $0.id == walk.id }?.nextStop)
        }
    }
}
