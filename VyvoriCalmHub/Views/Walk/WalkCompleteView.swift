import SwiftUI

struct RouteCompleteView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let walkId: UUID
    @Binding var sessionPresented: Bool
    @State private var closing = ""

    private var walk: RouteWalk? {
        store.walks.first { $0.id == walkId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image("BannerJournal")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 130)
                    .clipShape(AppTheme.stoneShape(1))
                    .overlay(AppTheme.stoneShape(1).stroke(AppTheme.primary.opacity(0.3), lineWidth: 1.2))

                PetalCard(cut: 2) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Path complete")
                            .font(AppTheme.display(26))
                        if let walk {
                            Text("\(walk.routeTitle) · \(walk.checkIns.count) landings")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            PathMapTrail(
                                titles: walk.checkIns.map { "\($0.stopName) · \($0.ritual.title)" },
                                doneCount: walk.checkIns.count
                            )
                        }
                    }
                }

                PetalCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("A closing line (optional)")
                            .font(.system(.headline, design: .serif))
                        TextEditor(text: $closing)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.white.opacity(0.55), in: AppTheme.stoneShape(0))
                        ForEach(walk?.checkIns.filter { !$0.body.isEmpty } ?? []) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.stopName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppTheme.primary)
                                Text(item.body)
                                    .font(.subheadline)
                            }
                        }
                        PetalButton(title: "Save this path", systemImage: "leaf.fill") {
                            save()
                        }
                        .accessibilityIdentifier("save_insight")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .navigationTitle("Landed")
        .navigationBarBackButtonHidden(true)
        .onAppear { closing = walk?.closingLine ?? "" }
    }

    private func save() {
        store.finishWalk(walkId: walkId, closingLine: closing)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        sessionPresented = false
        dismiss()
    }
}
