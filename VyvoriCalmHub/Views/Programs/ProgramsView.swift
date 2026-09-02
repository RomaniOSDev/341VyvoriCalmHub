import SwiftUI

struct ProgramsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var startSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(WalkPrompts.catalog) { program in
                    ProgramCard(program: program) { day in
                        store.prepareProgramWalk(program: program, day: day)
                        store.isWalkTimerShown = false
                        startSession = true
                    }
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgTrail")
        .navigationTitle("Programs")
        .navigationDestination(isPresented: $startSession) {
            BreathPrepView(sessionPresented: $startSession)
        }
    }
}

private struct ProgramCard: View {
    @EnvironmentObject private var store: AppDataStore
    let program: WalkProgram
    let onStartDay: (Int) -> Void

    private var progress: ProgramProgress? { store.progress(for: program.id) }

    var body: some View {
        PetalCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(program.title)
                    .font(.system(.title3, design: .serif))
                Text(program.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(program.durationMinutes) min · \(progress?.completedDays.count ?? 0)/7 days")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.primary)
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { day in
                        let done = progress?.completedDays.contains(day) == true
                        Button {
                            onStartDay(day)
                        } label: {
                            Text("\(day + 1)")
                                .font(.caption.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(done ? AppTheme.primary : Color.white.opacity(0.72))
                                        .rotationEffect(.degrees(45))
                                        .padding(6)
                                )
                                .foregroundColor(done ? .white : AppTheme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if progress != nil {
                    Button("Reset this course", role: .destructive) {
                        store.resetProgram(program.id)
                    }
                    .frame(minHeight: 44)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
