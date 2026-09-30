import SwiftUI
import UIKit

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func screenBackdrop(_ imageName: String) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                AppTheme.background
                    .overlay {
                        TrailGround(imageName: imageName)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }

    func keepScreenAwake() -> some View {
        self
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

final class KeyboardDismissInstaller: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissInstaller()

    func install(on window: UIWindow) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView {
                return false
            }
            view = current.superview
        }
        return true
    }
}

private struct TrailGround: View {
    let imageName: String

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height * 0.42)
                    .clipped()
                    .opacity(0.22)
                    .mask(
                        LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                    )
                Canvas { ctx, size in
                    let origin = CGPoint(x: size.width * 0.78, y: size.height * 0.12)
                    for i in 1...7 {
                        let r = CGFloat(i) * 42
                        var ring = Path()
                        ring.addEllipse(in: CGRect(x: origin.x - r, y: origin.y - r, width: r * 2, height: r * 2))
                        ctx.stroke(ring, with: .color(AppTheme.primary.opacity(0.11)), lineWidth: 1.3)
                    }
                    var y: CGFloat = 28
                    var left = true
                    while y < size.height {
                        var pebble = Path()
                        let x: CGFloat = left ? 18 : 28
                        pebble.addEllipse(in: CGRect(x: x, y: y, width: left ? 6 : 4.5, height: left ? 6 : 4.5))
                        ctx.fill(pebble, with: .color(AppTheme.primary.opacity(left ? 0.34 : 0.18)))
                        y += 16
                        left.toggle()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
