import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    PetalCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Daily path reminder", isOn: reminderBinding)
                                .tint(AppTheme.primary)
                            if store.reminderEnabled {
                                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .onChange(of: reminderTime) { newValue in
                                        let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                        store.updateReminder(enabled: true, hour: parts.hour ?? 8, minute: parts.minute ?? 0, requestPermission: false)
                                    }
                                Text("Skipped automatically if you already finished a path today.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if !store.focusStopName.isEmpty {
                        PetalCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Next beginning")
                                    .font(.headline)
                                Text(store.focusStopName)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    row("Rate Us", "star.fill") { rateApp() }
                    row("Privacy", "hand.raised.fill") {
                        if let url = URL(string: AppLinks.privacy.rawValue) {
                            UIApplication.shared.open(url)
                        }
                    }
                    row("Terms", "doc.text.fill") {
                        if let url = URL(string: AppLinks.terms.rawValue) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Reset All Data", role: .destructive) { confirmReset = true }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding()
                        .background(AppTheme.stoneShape(2).fill(Color.white.opacity(0.8)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .clearScrollBackground()
            .screenBackdrop("BgTrail")
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .alert("Clear paths and check-ins?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { store.resetAllData() }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear { reminderTime = time(from: store.reminderHour, store.reminderMinute) }
        }
        .tint(AppTheme.primary)
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { store.reminderEnabled },
            set: { on in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                store.updateReminder(enabled: on, hour: parts.hour ?? 8, minute: parts.minute ?? 0, requestPermission: on)
            }
        )
    }

    private func time(from hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    private func row(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                AppTheme.stoneShape(0)
                    .fill(AppTheme.stone)
                    .overlay(AppTheme.stoneShape(0).stroke(AppTheme.primary.opacity(0.22), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.14), radius: 8, y: 4)
            )
        }
        .buttonStyle(SoftPressStyle())
        .frame(minHeight: 44)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
