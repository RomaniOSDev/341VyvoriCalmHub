import SwiftUI

struct BreathPrepView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var sessionPresented: Bool
    @State private var remaining = 45
    @State private var inhaling = true
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let breath = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                RippleRings(count: 5, base: inhaling ? 150 : 118)
                    .animation(.easeInOut(duration: 4), value: inhaling)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.trail)
                    .frame(width: inhaling ? 132 : 108, height: inhaling ? 132 : 108)
                    .rotationEffect(.degrees(45))
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 16, y: 8)
                    .animation(.easeInOut(duration: 4), value: inhaling)
                VStack(spacing: 4) {
                    Text(inhaling ? "Breathe in" : "Breathe out")
                        .font(.system(.headline, design: .serif))
                    Text("with a step")
                        .font(.caption)
                        .opacity(0.85)
                }
                .foregroundColor(.white)
            }
            .frame(height: 280)
            Text("\(remaining)s")
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
            Text("A short landing before you walk.")
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(.white.opacity(0.86))
            Spacer()
            PetalButton(title: remaining == 0 ? "Begin walk" : "Skip", systemImage: remaining == 0 ? "figure.walk" : "forward.fill") {
                store.isWalkTimerShown = true
            }
        }
        .padding(18)
        .screenBackdrop("BgTrail")
        .keepScreenAwake()
        .navigationTitle("Settle")
        .onAppear { inhaling = true }
        .onReceive(ticker) { _ in
            guard !store.isWalkTimerShown, remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 {
                store.isWalkTimerShown = true
            }
        }
        .onReceive(breath) { _ in
            guard !store.isWalkTimerShown else { return }
            inhaling.toggle()
        }
        .navigationDestination(isPresented: $store.isWalkTimerShown) {
            WalkTimerView(sessionPresented: $sessionPresented)
        }
    }
}
