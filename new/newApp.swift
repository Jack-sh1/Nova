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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Habit.self, TodoItem.self])
    }
}
