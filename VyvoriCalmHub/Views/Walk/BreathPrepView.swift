import SwiftUI

struct ArriveMarkerView: View {
    var body: some View {
        Image("HereMarker")
            .resizable()
            .scaledToFit()
            .frame(height: 148)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
            .accessibilityLabel("Here")
    }
}
