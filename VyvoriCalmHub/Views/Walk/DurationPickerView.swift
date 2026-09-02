import SwiftUI

struct DurationPickerView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var customMinutes = 20

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    PetalCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Presets")
                                .font(.system(.headline, design: .serif))
                            HStack(spacing: 8) {
                                ForEach(Array([10, 20, 30, 45].enumerated()), id: \.element) { index, minutes in
                                    Button("\(minutes)") { apply(minutes) }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(
                                            AppTheme.stoneShape(index)
                                                .fill(store.walkDurationMin == minutes ? AppTheme.primary.opacity(0.28) : AppTheme.surface.opacity(0.85))
                                        )
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    }
                    PetalCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom")
                                .font(.headline)
                            Stepper(value: $customMinutes, in: 1...180) {
                                Text("\(customMinutes) minutes")
                            }
                            PetalButton(title: "Use \(customMinutes) min", systemImage: "checkmark") {
                                apply(customMinutes)
                            }
                        }
                    }
                    PetalCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Open walk")
                                .font(.headline)
                            Text("Counts up until you stop.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            PetalButton(title: "Until I stop", systemImage: "infinity") {
                                apply(0)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .screenBackdrop("BgTrail")
            .navigationTitle("Walk length")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onAppear {
                customMinutes = store.walkDurationMin == 0 ? 20 : store.walkDurationMin
            }
        }
        .tint(AppTheme.primary)
    }

    private func apply(_ minutes: Int) {
        store.walkDurationMin = minutes
        store.save()
        dismiss()
    }
}
