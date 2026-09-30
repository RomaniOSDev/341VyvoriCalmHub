import SwiftUI

struct PetalCard<Content: View>: View {
    var cut: Int = 0
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .background {
                AppTheme.stoneShape(cut)
                    .fill(AppTheme.stone)
                    .overlay(AppTheme.stoneShape(cut).stroke(AppTheme.primary.opacity(0.28), lineWidth: 1.2))
                    .shadow(color: Color.black.opacity(0.18), radius: 10, y: 7)
            }
            .overlay(alignment: .topLeading) {
                TrailBlaze()
                    .offset(x: 16, y: -5)
            }
    }
}

struct PetalButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(.headline, design: .serif))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 22, bottomTrailingRadius: 6, topTrailingRadius: 22, style: .continuous)
                    .fill(AppTheme.trail)
            }
            .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, y: 5)
        }
        .buttonStyle(FootfallPressStyle())
        .frame(minHeight: 44)
    }
}

struct TrailRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var cut: Int = 0
    var inset: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            TrailBlaze(size: 14)
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.forward")
                .font(.caption.weight(.bold))
                .foregroundColor(AppTheme.primary)
        }
        .padding(16)
        .background {
            AppTheme.stoneShape(cut)
                .fill(AppTheme.stone)
                .overlay(AppTheme.stoneShape(cut).stroke(AppTheme.primary.opacity(0.22), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.16), radius: 8, y: 5)
        }
        .padding(.leading, inset)
    }
}

struct TrailBlaze: View {
    var size: CGFloat = 11

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(AppTheme.primary)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
            .shadow(color: AppTheme.primary.opacity(0.45), radius: 3, y: 1)
    }
}

struct PathMapTrail: View {
    let titles: [String]
    var doneCount: Int = 0
    var highlightIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        TrailBlaze(size: index == highlightIndex ? 14 : 11)
                        if index < titles.count - 1 {
                            Rectangle()
                                .fill(AppTheme.primary.opacity(index < doneCount ? 0.55 : 0.22))
                                .frame(width: 2, height: 28)
                        }
                    }
                    .frame(width: 18)
                    Text(title)
                        .font(.system(index == highlightIndex ? .headline : .subheadline, design: .serif))
                        .foregroundColor(index < doneCount || index == highlightIndex ? .primary : .secondary)
                        .padding(.top, 2)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RippleRings: View {
    var count: Int = 4
    var base: CGFloat = 148

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .stroke(AppTheme.primary.opacity(0.22 - Double(i) * 0.04), lineWidth: 1.4)
                    .frame(width: base + CGFloat(i) * 34, height: base + CGFloat(i) * 34)
            }
        }
        .allowsHitTesting(false)
    }
}
