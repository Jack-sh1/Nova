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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    HealthKitManager.shared.requestAuthorization { success, error in
                        if success {
                            print("健康数据授权成功")
                        } else if let error = error {
                            print("健康数据授权失败: \(error.localizedDescription)")
                        }
                    }
                }
        }
        .modelContainer(for: [Habit.self, TodoItem.self])
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // 3. 当应用变为活跃状态时，执行重置检查
            if newPhase == .active {
                // 请求通知权限
                NotificationManager.shared.requestAuthorization()
                // 执行每日重置检查
                DailyResetManager.resetHabitsIfNeeded(context: modelContext)
            }
        }
    }
}
