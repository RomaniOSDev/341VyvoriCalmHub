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
                            .foregroundColor(AppTheme.ink)
                        Text(store.weeklySummary)
                            .font(.body)
                            .foregroundColor(AppTheme.inkMuted)
                        if !store.focusStopName.isEmpty {
                            Text("Begin next with: \(store.focusStopName)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.accentInk)
                        }
                    }

                    startControl

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
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(red: 0.55, green: 0.08, blue: 0.08))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .clearScrollBackground()
            .screenBackdrop("BgTrail")
            .readableChrome()
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
        .tint(AppTheme.accentInk)
        .preferredColorScheme(.light)
        .environmentObject(store)
    }

    @ViewBuilder
    private var startControl: some View {
        if store.hasResumableWalk {
            VStack(spacing: 8) {
                PetalButton(title: "Continue", systemImage: "arrow.uturn.left") {
                    beginOrResume()
                }
                .accessibilityIdentifier("start_walk")
                if let active = store.activeWalk, let stop = active.nextStop {
                    Text("Stop \(active.currentStopIndex + 1) · \(stop.trimmedName)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        } else {
            HStack {
                Spacer()
                Button {
                    beginOrResume()
                } label: {
                    ZStack {
                        RippleRings(count: 3, base: 96)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.trail)
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(45))
                            .shadow(color: AppTheme.primary.opacity(0.5), radius: 12, y: 6)
                        VStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 26, weight: .medium))
                            Text("Walk path")
                                .font(.system(.headline, design: .serif))
                        }
                        .foregroundColor(.white)
                    }
                    .frame(width: 168, height: 168)
                }
                .buttonStyle(FootfallPressStyle())
                .accessibilityIdentifier("start_walk")
                Spacer()
            }
        }
    }

    private var routePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.routes) { route in
                    Button {
                        store.selectRoute(route.id)
                    } label: {
                        Text(route.trimmedTitle.isEmpty ? "Untitled" : route.trimmedTitle)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                AppTheme.stoneShape(0)
                                    .fill(store.selectedRouteId == route.id ? AppTheme.card : AppTheme.card.opacity(0.92))
                                    .overlay(AppTheme.stoneShape(0).stroke(store.selectedRouteId == route.id ? AppTheme.accentInk : AppTheme.ink.opacity(0.18), lineWidth: 1.2))
                            )
                            .foregroundColor(AppTheme.ink)
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
