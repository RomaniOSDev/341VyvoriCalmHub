import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @State private var showSettings = false
    @State private var goTimer = false
    @State private var goBreath = false
    @State private var showDuration = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image("BannerLake")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 168)
                        .clipShape(AppTheme.stoneShape(0))
                        .overlay(AppTheme.stoneShape(0).stroke(AppTheme.primary.opacity(0.35), lineWidth: 1.4))
                        .overlay(alignment: .topLeading) {
                            TrailBlaze(size: 13)
                                .padding(16)
                        }
                        .shadow(color: Color.black.opacity(0.22), radius: 14, y: 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A quiet walk")
                            .font(AppTheme.display(36))
                            .foregroundColor(.white)
                        Text(store.weeklySummary)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.86))
                    }

                    HStack {
                        Spacer()
                        startControl
                        Spacer()
                    }

                    Button(store.durationLabel) {
                        showDuration = true
                    }
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)

                    trailLinks
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .screenBackdrop("BgTrail")
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        ZStack {
                            TrailBlaze(size: 22)
                            Image(systemName: "gearshape")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                    }
                }
            }
            .navigationDestination(isPresented: $goTimer) {
                WalkTimerView(sessionPresented: $goTimer)
            }
            .navigationDestination(isPresented: $goBreath) {
                BreathPrepView(sessionPresented: $goBreath)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showDuration) {
                DurationPickerView()
                    .environmentObject(store)
            }
        }
        .tint(AppTheme.primary)
        .environmentObject(store)
    }

    private var continueSeconds: Int {
        if store.clock.isLive {
            return store.clock.isOpenEnded ? store.clock.elapsed : store.clock.remaining
        }
        guard let active = store.activeWalk else { return 0 }
        return active.isOpenEnded ? active.elapsedSeconds : active.remainingSeconds
    }

    private var startControl: some View {
        Button {
            if store.hasResumableWalk {
                goTimer = true
            } else {
                store.clearLaunchOverrides()
                store.isWalkTimerShown = false
                goBreath = true
            }
        } label: {
            ZStack {
                RippleRings(count: 4, base: 126)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.trail)
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(45))
                    .shadow(color: AppTheme.primary.opacity(0.5), radius: 16, y: 8)
                VStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 30, weight: .medium))
                    Text(store.hasResumableWalk ? "Continue" : "Begin")
                        .font(.system(.headline, design: .serif))
                    if store.hasResumableWalk {
                        Text(Self.clock(continueSeconds))
                            .font(.caption.monospacedDigit())
                    }
                }
                .foregroundColor(.white)
            }
            .frame(width: 230, height: 230)
        }
        .buttonStyle(FootfallPressStyle())
        .accessibilityIdentifier("start_walk")
    }

    private var trailLinks: some View {
        VStack(spacing: 14) {
            if store.shouldShowSundayReview {
                NavigationLink {
                    WeeklyReviewView()
                } label: {
                    TrailRow(title: "Sunday review", subtitle: "Streak, mood, and what to keep", systemImage: "sun.haze.fill", cut: 0, inset: 0)
                }
                .buttonStyle(.plain)
            }
            NavigationLink {
                ProgramsView()
            } label: {
                TrailRow(title: "7-day programs", subtitle: "Evening, morning, or a soft return", systemImage: "calendar", cut: 1, inset: 18)
            }
            .buttonStyle(.plain)
            NavigationLink {
                StatsView()
            } label: {
                TrailRow(title: "Statistics", subtitle: store.walks.isEmpty ? "Charts of your walks" : "Minutes, streaks, moods", systemImage: "chart.bar.fill", cut: 2, inset: 0)
            }
            .buttonStyle(.plain)
            NavigationLink {
                InsightsListView()
            } label: {
                TrailRow(title: "Reflections", subtitle: store.insights.isEmpty ? "Start noting your reflections" : "\(store.insights.count) saved", systemImage: "text.quote", cut: 0, inset: 18)
            }
            .buttonStyle(.plain)
            NavigationLink {
                WalkHistoryView()
            } label: {
                TrailRow(title: "Walk journal", subtitle: store.walks.isEmpty ? "No walks yet" : "\(store.walks.filter(\.completed).count) completed", systemImage: "leaf.fill", cut: 1, inset: 0)
            }
            .buttonStyle(.plain)
        }
    }

    private static func clock(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
