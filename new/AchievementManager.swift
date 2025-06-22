import Foundation
import SwiftUI

class AchievementManager: ObservableObject {
    
    // 使用 @Published 属性包装器，以便在解锁新成就时能够自动更新UI
    @Published private(set) var unlockedAchievements: Set<String> = []
    
    // 定义所有可能的成就
    let allAchievements: [Achievement] = [
        Achievement(id: "streak_7", name: "初露锋芒", description: "连续7天完成任意一个习惯", iconName: "flame", colors: [.orange, .red]),
        Achievement(id: "streak_30", name: "月度冠军", description: "连续30天完成任意一个习惯", iconName: "crown", colors: [.yellow, .orange]),
        Achievement(id: "perfect_week", name: "完美一周", description: "在一周内完成所有设定的习惯", iconName: "star.circle.fill", colors: [.green, .mint]),
        Achievement(id: "first_habit", name: "新的开始", description: "创建你的第一个习惯", iconName: "plus.circle", colors: [.blue, .cyan]),
        Achievement(id: "habit_master", name: "习惯大师", description: "创建超过5个习惯", iconName: "list.bullet.rectangle", colors: [.purple, .pink])
    ]
    
    // 用于存储解锁成就的键
    private let unlockedAchievementsKey = "unlockedAchievementsKey"
    
    init() {
        loadUnlockedAchievements()
    }
    
    // 从 UserDefaults 加载已解锁的成就
    private func loadUnlockedAchievements() {
        let saved = UserDefaults.standard.stringArray(forKey: unlockedAchievementsKey) ?? []
        unlockedAchievements = Set(saved)
    }
    
    // 检查并解锁成就
    func checkAchievements(for habits: [Habit]) {
        // 检查是否解锁“新的开始”
        if !habits.isEmpty {
            unlock(achievementId: "first_habit")
        }
        
        // 检查是否解锁“习惯大师”
        if habits.count > 5 {
            unlock(achievementId: "habit_master")
        }
        
        // 遍历所有习惯，检查连胜成就
        for habit in habits {
            // 使用我们重构后的计算属性来获取最新的连胜天数
            if habit.currentStreak >= 7 {
                unlock(achievementId: "streak_7")
            }
            if habit.currentStreak >= 30 {
                unlock(achievementId: "streak_30")
            }
        }
        
        // (未来可以添加检查“完美一周”的逻辑)
    }
    
    // 解锁一个成就
    private func unlock(achievementId: String) {
        // 检查是否已经解锁，避免重复操作
        guard !unlockedAchievements.contains(achievementId) else { return }
        
        // 更新本地集合
        unlockedAchievements.insert(achievementId)
        
        // 保存到 UserDefaults
        UserDefaults.standard.set(Array(unlockedAchievements), forKey: unlockedAchievementsKey)
        
        // 找到对应的成就对象
        if let achievement = allAchievements.first(where: { $0.id == achievementId }) {
            // 发送通知，以便UI可以响应（例如弹出祝贺窗口）
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didUnlockAchievement, object: achievement)
                print("🎉 Achievement Unlocked: \(achievement.name)!")
            }
        }
    }
}
