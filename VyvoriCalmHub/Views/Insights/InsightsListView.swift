import SwiftUI

struct CheckInNotesView: View {
    @EnvironmentObject private var store: AppDataStore

    private var notes: [StopCheckIn] {
        store.walks
            .flatMap(\.checkIns)
            .filter { !$0.body.isEmpty }
            .sorted { $0.completedAt > $1.completedAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if notes.isEmpty {
                    PetalCard {
                        VStack(spacing: 10) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 34))
                                .foregroundColor(AppTheme.primary)
                            Text("Notes live on the stops")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(AppTheme.ink)
                            Text("Sounds, ground textures, and lines you leave while walking a path.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(notes) { item in
                        PetalCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.stopName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppTheme.accentInk)
                                Text(item.body)
                                    .font(.body)
                                    .foregroundColor(AppTheme.ink)
                                Text("\(item.ritual.title) · \(item.completedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.inkMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .clearScrollBackground()
        .screenBackdrop("BgTrail")
        .readableChrome()
        .navigationTitle("Stop notes")
    }
}
