import SwiftUI

/// A view that intelligently and safely displays an icon.
/// It is designed to be crash-proof, even with malformed icon names.
struct IconView: View {
    let iconName: String
    
    var body: some View {
        // 1. CRITICAL: Defend against empty strings, a known cause of SIGABRT crashes.
        if iconName.isEmpty {
            // Provide a sensible default icon instead of crashing.
            Image(systemName: "questionmark.circle")
        // 2. Check if it's a valid SF Symbol name.
        } else if UIImage(systemName: iconName) != nil {
            Image(systemName: iconName)
        // 3. If all else fails, render it as text (suitable for emojis).
        } else {
            Text(iconName)
        }
    }
}
