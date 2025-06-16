import Foundation
import SwiftData

class DailyResetManager {
    
    // 使用 UserDefaults 存储用户上次打开应用的日期
    static let lastVisitDateKey = "lastVisitDate"
    
    static func resetHabitsIfNeeded(context: ModelContext) {
        let userDefaults = UserDefaults.standard
        let calendar = Calendar.current
        
        // 从 UserDefaults 中获取上次访问日期
        let lastVisitDate = userDefaults.object(forKey: lastVisitDateKey) as? Date
        
        // 如果是第一次启动应用，则只需记录当前日期并返回
        guard let lastVisit = lastVisitDate else {
            userDefaults.set(Date(), forKey: lastVisitDateKey)
            return
        }
        
        // 检查上次访问是否在今天之前
        if !calendar.isDateInToday(lastVisit) {
            // 如果是新的一天，开始重置流程
            print("新的一天开始了，正在重置习惯状态...")
            
            // 获取所有的习惯
            let descriptor = FetchDescriptor<Habit>()
            guard let habits = try? context.fetch(descriptor) else {
                print("无法获取习惯列表，重置失败。")
                return
            }
            
            for habit in habits {
                // 如果昨天的习惯没有完成，则将连续坚持天数清零
                if !habit.isCompleted {
                    habit.streak = 0
                }
                
                // 将所有习惯的完成状态重置为 false
                habit.isCompleted = false
            }
            
            // 将今天的日期存入 UserDefaults，用于下一次检查
            userDefaults.set(Date(), forKey: lastVisitDateKey)
            
            print("习惯重置完成！")
        }
    }
}
