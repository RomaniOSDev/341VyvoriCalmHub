import SwiftUI

struct WalkTimerView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @Binding var sessionPresented: Bool
    @State private var walkId = UUID()
    @State private var startedAt = Date()
    @State private var location = ""
    @State private var showComplete = false
    @State private var plannedMinutes = 20
    @State private var sessionEnded = false
    @State private var didLoadSession = false
    @State private var prompts = WalkPrompts.standard
    @State private var programId: String?
    @State private var programDay: Int?

    private var clock: WalkClock { store.clock }

    var body: some View {
        VStack(spacing: 22) {
            Image("BannerSteps")
                .resizable()
                .scaledToFill()
                .frame(height: 96)
                .clipShape(AppTheme.stoneShape(2))
                .overlay(AppTheme.stoneShape(2).stroke(AppTheme.primary.opacity(0.3), lineWidth: 1.2))

            ZStack {
                RippleRings(count: 3, base: 150)
                Text(timeLabel)
                    .font(.system(size: 56, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)
            }
            .frame(height: 220)

            PetalCard(cut: 1) {
                VStack(spacing: 8) {
                    Text(prompts.isEmpty ? WalkPrompts.standard[0] : prompts[clock.promptIndex % max(prompts.count, 1)])
                        .font(.system(.title3, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    TextField("Where are you walking?", text: $location)
                        .textFieldStyle(.roundedBorder)
                    if !store.favoritePlaces.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.favoritePlaces) { place in
                                    Button(place.name) {
                                        location = place.name
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.stoneShape(0).fill(AppTheme.primary.opacity(0.16)))
                                    .foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    }
                    if canSavePlace {
                        Button("Save as favorite") {
                            store.addFavoritePlace(location)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                        .frame(minHeight: 44)
                    }
                }
            }

            HStack(spacing: 12) {
                PetalButton(title: clock.running ? "Pause" : "Resume", systemImage: clock.running ? "pause.fill" : "play.fill") {
                    if sessionEnded || (!clock.running && !clock.isOpenEnded && clock.remaining == 0) {
                        startFresh()
                    } else if clock.running {
                        clock.pause()
                        persistProgress(updateWalk: true)
                    } else {
                        clock.resume()
                    }
                }
                Button("Stop") {
                    if clock.isOpenEnded {
                        finish(completed: true)
                    } else {
                        let done = clock.remaining == 0
                        finish(completed: done)
                        if !done {
                            sessionPresented = false
                        }
                    }
                }
                .frame(minHeight: 44)
                .foregroundColor(AppTheme.primary)
            }

            Spacer()
        }
        .padding(18)
        .screenBackdrop("BgTrail")
        .keepScreenAwake()
        .navigationTitle("Session")
        .onAppear {
            restoreOrStart()
        }
        .onDisappear {
            persistProgress(updateWalk: true)
        }
        .onChange(of: clock.remaining) { value in
            if value == 0, !clock.isOpenEnded, clock.elapsed > 0, !sessionEnded {
                finish(completed: true)
            }
        }
        .onChange(of: clock.elapsed) { value in
            if clock.running, value > 0, value % 15 == 0 {
                persistProgress(updateWalk: false)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                clock.pause()
                persistProgress(updateWalk: true)
            }
        }
        .navigationDestination(isPresented: $showComplete) {
            WalkCompleteView(
                walkId: walkId,
                minutes: displayMinutes,
                location: location,
                sessionPresented: $sessionPresented
            )
        }
    }

    private var canSavePlace: Bool {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, store.favoritePlaces.count < 5 else { return false }
        return !store.favoritePlaces.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    private var timeLabel: String {
        let total = clock.isOpenEnded ? clock.elapsed : clock.remaining
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private var displayMinutes: Int {
        if clock.isOpenEnded {
            return max(1, Int((Double(clock.elapsed) / 60.0).rounded(.up)))
        }
        return max(plannedMinutes, 1)
    }

    private func restoreOrStart() {
        if sessionEnded { return }
        if clock.isLive {
            didLoadSession = true
            return
        }
        if didLoadSession { return }
        didLoadSession = true
        if let active = store.activeWalk, active.isOpenEnded || active.remainingSeconds > 0 {
            walkId = active.walkId
            startedAt = active.startedAt
            location = active.location
            plannedMinutes = active.plannedMinutes
            prompts = active.prompts.isEmpty ? WalkPrompts.standard : active.prompts
            programId = active.programId
            programDay = active.programDay
            if active.isOpenEnded {
                clock.loadOpenEnded(elapsed: active.elapsedSeconds, promptIndex: active.promptIndex)
            } else {
                clock.loadCountdown(seconds: active.remainingSeconds, elapsed: active.elapsedSeconds, promptIndex: active.promptIndex)
            }
            if active.running {
                clock.resume()
            }
            return
        }
        startFresh()
    }

    private func startFresh() {
        sessionEnded = false
        walkId = UUID()
        startedAt = Date()
        let duration = store.launchDurationMin ?? store.walkDurationMin
        plannedMinutes = duration
        prompts = store.launchPrompts ?? WalkPrompts.standard
        programId = store.launchProgramId
        programDay = store.launchProgramDay
        if duration == 0 {
            clock.loadOpenEnded(elapsed: 0, promptIndex: 0)
        } else {
            clock.loadCountdown(seconds: duration * 60, elapsed: 0, promptIndex: 0)
        }
        clock.resume()
        let walk = WalkSession(id: walkId, startedAt: startedAt, durationMinutes: max(plannedMinutes, 1), location: location, reflection: "", completed: false)
        store.upsertWalk(walk)
        persistProgress(updateWalk: false)
    }

    private func persistProgress(updateWalk: Bool) {
        guard !sessionEnded else { return }
        if !clock.isOpenEnded, clock.remaining <= 0, clock.elapsed == 0 { return }
        let elapsedSec = clock.elapsed
        let elapsedMin = max(1, Int((Double(max(elapsedSec, 1)) / 60.0).rounded(.up)))
        if updateWalk {
            var walk = store.walks.first(where: { $0.id == walkId }) ?? WalkSession(id: walkId, startedAt: startedAt, durationMinutes: elapsedMin, location: location, reflection: "", completed: false)
            walk.location = location
            walk.durationMinutes = elapsedMin
            walk.completed = false
            store.upsertWalk(walk)
        }
        store.activeWalk = ActiveWalk(
            walkId: walkId,
            remainingSeconds: clock.remaining,
            startedAt: startedAt,
            location: location,
            plannedMinutes: plannedMinutes,
            promptIndex: clock.promptIndex,
            running: clock.running,
            isOpenEnded: clock.isOpenEnded,
            elapsedSeconds: clock.elapsed,
            programId: programId,
            programDay: programDay,
            prompts: prompts
        )
        store.save()
    }

    private func finish(completed: Bool) {
        guard !sessionEnded else { return }
        clock.pause()
        sessionEnded = true
        store.isWalkTimerShown = false
        let elapsedSec = clock.elapsed
        let elapsedMin = max(1, completed && !clock.isOpenEnded ? max(plannedMinutes, 1) : Int((Double(elapsedSec) / 60.0).rounded(.up)))
        var walk = store.walks.first(where: { $0.id == walkId }) ?? WalkSession(id: walkId, startedAt: startedAt, durationMinutes: elapsedMin, location: location, reflection: "", completed: completed)
        walk.location = location
        walk.durationMinutes = elapsedMin
        walk.completed = completed
        store.upsertWalk(walk)
        if completed, let programId, let programDay {
            store.markProgramDay(programId: programId, day: programDay)
        }
        store.activeWalk = nil
        store.clearLaunchOverrides()
        clock.reset()
        store.save()
        if completed {
            showComplete = true
        }
    }
}
