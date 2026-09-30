import SwiftUI
import Combine

struct ArriveMarkerView: View {
    @State private var inhaling = true

    var body: some View {
        ZStack {
            RippleRings(count: 4, base: inhaling ? 118 : 98)
                .animation(.easeInOut(duration: 3.2), value: inhaling)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.trail)
                .frame(width: inhaling ? 86 : 74, height: inhaling ? 86 : 74)
                .rotationEffect(.degrees(45))
                .shadow(color: AppTheme.primary.opacity(0.4), radius: 12, y: 6)
                .animation(.easeInOut(duration: 3.2), value: inhaling)
            VStack(spacing: 2) {
                TrailBlaze(size: 12)
                Text("Here")
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(height: 180)
        .onAppear { inhaling = true }
        .onReceive(Timer.publish(every: 3.2, on: .main, in: .common).autoconnect()) { _ in
            inhaling.toggle()
        }
        .allowsHitTesting(false)
    }
}
