//
//  newApp.swift
//  new
//
//  Created by zhetaoWang on 2025/6/16.
//

import SwiftUI
import SwiftData

@main
struct newApp: App {
    // 1. 监听应用场景的变化
    @Environment(\.scenePhase) private var scenePhase
    // 2. 获取 modelContext，以便传递给重置管理器
    @Environment(\.modelContext) private var modelContext
    
    // 3. 创建成就系统的“大脑”实例
    @StateObject private var achievementManager = AchievementManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(achievementManager) // 4. 将“大脑”注入到视图环境中
        }
        .modelContainer(for: [Habit.self, TodoItem.self])
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // 3. 当应用变为活跃状态时，执行重置检查
            if newPhase == .active {
                // 请求通知权限
                NotificationManager.shared.requestAuthorization()

            }
        }
    }
}
