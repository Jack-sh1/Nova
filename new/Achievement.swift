import SwiftUI
import Foundation

/**
 Represents a single achievement or badge that a user can unlock.
 */
struct Achievement: Identifiable, Hashable {
    /**
     A unique identifier for the achievement, e.g., "monthly_champion".
     */
    let id: String
    
    /**
     The display name of the achievement, e.g., "月度冠军".
     */
    let name: String
    
    /**
     A description of how to unlock the achievement.
     */
    let description: String
    
    /**
     The name of the SF Symbol to be used as an icon.
     */
    let iconName: String
    
    /**
     An array of colors to be used in the badge's gradient. 
     This allows each achievement to have a unique color scheme.
     */
    let colors: [Color]
}

extension Notification.Name {
    /**
     Notification posted when a new achievement is unlocked.
     The `object` of the notification will be the unlocked `Achievement`.
     */
    static let didUnlockAchievement = Notification.Name("didUnlockAchievement")
}
