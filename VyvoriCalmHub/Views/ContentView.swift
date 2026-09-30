import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @State private var showSettings = false
    @State private var goWalk = false
    @State private var walkError: String?

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
                        Text("Walk by stops")
                            .font(AppTheme.display(36))
                            .foregroundColor(.white)
                        Text(store.weeklySummary)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.86))
                        if !store.focusStopName.isEmpty {
                            Text("Begin next with: \(store.focusStopName)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white.opacity(0.92))
                        }
                    }

                    HStack {
                        Spacer()
                        startControl
                        Spacer()
                    }

                    if let route = store.preferredRoute {
                        PetalCard(cut: 1) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(route.trimmedTitle.isEmpty ? "Untitled path" : route.trimmedTitle)
                                    .font(.system(.headline, design: .serif))
                                PathMapTrail(
                                    titles: route.stops.map { $0.trimmedName.isEmpty ? "Unnamed stop" : $0.trimmedName },
                                    doneCount: 0,
                                    highlightIndex: 0
                                )
                            }
                        }
                    }

                    routePicker
                    trailLinks
                    if let walkError {
                        Text(walkError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .clearScrollBackground()
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
            .navigationDestination(isPresented: $goWalk) {
                RouteWalkView(sessionPresented: $goWalk)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
            }
        }
        .tint(AppTheme.primary)
        .environmentObject(store)
    }

    private var startControl: some View {
        Button {
            beginOrResume()
        } label: {
            ZStack {
                RippleRings(count: 4, base: 126)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.trail)
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(45))
                    .shadow(color: AppTheme.primary.opacity(0.5), radius: 16, y: 8)
                VStack(spacing: 4) {
                    Image(systemName: store.hasResumableWalk ? "arrow.uturn.left" : "figure.walk")
                        .font(.system(size: 30, weight: .medium))
                    Text(store.hasResumableWalk ? "Continue" : "Walk path")
                        .font(.system(.headline, design: .serif))
                    if let active = store.activeWalk, let stop = active.nextStop {
                        Text("Stop \(active.currentStopIndex + 1) · \(stop.trimmedName)")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .foregroundColor(.white)
            }
            .frame(width: 230, height: 230)
        }
        .buttonStyle(FootfallPressStyle())
        .accessibilityIdentifier("start_walk")
    }

    private var routePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.routes) { route in
                    Button {
                        store.selectRoute(route.id)
                    } label: {
                        Text(route.trimmedTitle.isEmpty ? "Untitled" : route.trimmedTitle)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                AppTheme.stoneShape(0)
                                    .fill(store.selectedRouteId == route.id ? AppTheme.primary.opacity(0.28) : AppTheme.surface.opacity(0.85))
                            )
                            .foregroundColor(AppTheme.primary)
                    }
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var trailLinks: some View {
        VStack(spacing: 14) {
            if store.shouldShowSundayReview {
                NavigationLink {
                    WeeklyReviewView()
                } label: {
                    TrailRow(title: "Sunday stops", subtitle: "Choose the landing to begin with next week", systemImage: "sun.haze.fill", cut: 0, inset: 0)
                }
                .buttonStyle(.plain)
            }
            NavigationLink {
                RoutesListView()
            } label: {
                TrailRow(title: "Compose a path", subtitle: store.routes.isEmpty ? "Build 4 to 6 outdoor stops" : "\(store.routes.count) routes", systemImage: "square.and.pencil", cut: 1, inset: 18)
            }
            .buttonStyle(.plain)
            NavigationLink {
                PlacesView()
            } label: {
                TrailRow(title: "Places", subtitle: store.distinctStopNames.isEmpty ? "Stops you have landed on" : "\(store.distinctStopNames.count) distinct stops", systemImage: "mappin.and.ellipse", cut: 2, inset: 0)
            }
            .buttonStyle(.plain)
            NavigationLink {
                CheckInNotesView()
            } label: {
                TrailRow(title: "Stop notes", subtitle: allNotes.isEmpty ? "Lines left at landings" : "\(allNotes.count) saved", systemImage: "text.quote", cut: 0, inset: 18)
            }
            .buttonStyle(.plain)
            NavigationLink {
                RitualMapView()
            } label: {
                    TrailRow(title: "Ritual map", subtitle: store.walks.isEmpty ? "Finished paths appear here" : "\(store.walks.filter(\.completed).count) completed", systemImage: "map", cut: 1, inset: 0)
            }
            .buttonStyle(.plain)
        }
    }

    private var allNotes: [StopCheckIn] {
        store.walks.flatMap(\.checkIns).filter { !$0.body.isEmpty }
    }

    private func beginOrResume() {
        walkError = nil
        if store.hasResumableWalk {
            goWalk = true
            return
        }
        guard let route = store.preferredRoute else {
            walkError = "Compose a path with 4 to 6 named stops first."
            return
        }
        guard route.isWalkable else {
            walkError = "Name every stop (4 to 6) before walking this path."
            return
        }
        _ = store.startWalk(from: route)
        goWalk = true
    }
}
