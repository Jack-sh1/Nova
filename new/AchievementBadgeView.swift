import SwiftUI

// Custom hexagonal shape, the foundation of the Apple Watch-style badge.
struct BadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Create a hexagon by rotating points around the center
        let corners = (0..<6).map { i -> CGPoint in
            let angle = .pi / 3 * Double(i) - .pi / 6 // Start from -30 degrees for a flat top
            return CGPoint(
                x: center.x + radius * cos(CGFloat(angle)),
                y: center.y + radius * sin(CGFloat(angle))
            )
        }
        
        path.addLines(corners)
        path.closeSubpath()
        return path
    }
}

/// A view that displays an achievement badge with a 3D, metallic, Apple Watch-like appearance.
struct AchievementBadgeView: View {
    let achievement: Achievement
    let isUnlocked: Bool

    // Dynamic gradient created from the achievement's specific colors.
    private var unlockedGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: achievement.colors), startPoint: .top, endPoint: .bottom)
    }

    private var metalBorderGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [.white.opacity(0.6), .gray.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // --- Badge Base and Border ---
                BadgeShape()
                    .fill(isUnlocked ? metalBorderGradient : LinearGradient(gradient: Gradient(colors: [Color(.systemGray3), Color(.systemGray4)]), startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)

                // --- Inner "Enamel" Part ---
                BadgeShape()
                    .scale(0.9)
                    .fill(isUnlocked ? unlockedGradient : LinearGradient(colors: [Color(.systemGray5)], startPoint: .top, endPoint: .bottom))

                // --- Embossed Icon ---
                Image(systemName: achievement.iconName)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(isUnlocked ? .white : Color(.systemGray2))
                    .shadow(color: .black.opacity(isUnlocked ? 0.25 : 0), radius: 1, y: 1) // Inner shadow effect

                // --- Lock Overlay for Locked Badges ---
                if !isUnlocked {
                    BadgeShape()
                        .fill(.black.opacity(0.4))
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 110, height: 120)

            // --- Text Content ---
            Text(achievement.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isUnlocked ? .primary : .secondary)

            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 35)
        }
    }
}
