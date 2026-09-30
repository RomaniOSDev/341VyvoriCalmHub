import SwiftUI

private struct RouteEditNav: Identifiable, Hashable {
    let id: UUID
}

struct RoutesListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var editNav: RouteEditNav?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("A path is a sequence of outdoor landings you already know — a doorstep, a lamp, a bench. You walk it by arriving at each stop and doing its ritual.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(store.routes) { route in
                    NavigationLink {
                        RouteEditorView(routeID: route.id)
                    } label: {
                        PetalCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(route.trimmedTitle.isEmpty ? "Untitled path" : route.trimmedTitle)
                                    .font(.system(.title3, design: .serif))
                                    .foregroundColor(.primary)
                                Text(route.summary)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(route.stops.count) stops · \(route.isWalkable ? "Ready to walk" : "Needs named stops")")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppTheme.primary)
                                PathMapTrail(
                                    titles: route.stops.map { $0.trimmedName.isEmpty ? "Unnamed" : $0.trimmedName }
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }

                PetalButton(title: "New path", systemImage: "plus") {
                    let draft = WalkingRoute(
                        title: "",
                        summary: "A route of outdoor stops you choose yourself.",
                        stops: (0..<4).map { index in
                            RouteStop(name: "", ritual: StopRitual.allCases[index % StopRitual.allCases.count])
                        }
                    )
                    store.upsertRoute(draft)
                    editNav = RouteEditNav(id: draft.id)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .navigationTitle("Paths")
        .navigationDestination(isPresented: Binding(
            get: { editNav != nil },
            set: { if !$0 { editNav = nil } }
        )) {
            if let id = editNav?.id {
                RouteEditorView(routeID: id)
            }
        }
    }
}
