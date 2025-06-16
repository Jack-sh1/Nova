//
//  ContentView.swift
//  new
//
//  Created by zhetaoWang on 2025/6/16.
//

import SwiftUI
import SwiftData

// MARK: - Models
@Model
class Habit {
    @Attribute(.unique) let id: UUID
    var name: String
    var icon: String
    var isCompleted: Bool
    var streak: Int
    var creationDate: Date

    init(name: String, icon: String, isCompleted: Bool = false, streak: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isCompleted = isCompleted
        self.streak = streak
        self.creationDate = .now
    }
}

@Model
class TodoItem {
    @Attribute(.unique) let id: UUID
    var title: String
    var isCompleted: Bool
    var creationDate: Date

    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.creationDate = .now
    }
}


// MARK: - Main Content View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Habit.creationDate) private var habits: [Habit]
    @Query(sort: \TodoItem.creationDate) private var todoItems: [TodoItem]

    var completedHabitsCount: Int {
        habits.filter { $0.isCompleted }.count
    }
    
    var totalHabitsCount: Int {
        habits.count
    }

    var body: some View {
        NavigationView {
            List {
                // Header Section
                Section(header: headerView) {
                    EmptyView()
                }
                
                // Habits Section
                Section(header: Text("今日习惯").font(.title2).fontWeight(.bold).foregroundColor(.primary)) {
                    ForEach(habits) { habit in
                        HabitRowView(habit: habit)
                    }
                }
                
                // To-Do List Section
                Section(header: Text("待办事项").font(.title2).fontWeight(.bold).foregroundColor(.primary)) {
                    ForEach(todoItems) { todo in
                        TodoRowView(todo: todo)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("主页")
            .onAppear(perform: addSampleDataIfNeeded)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("你好，开始新的一天！")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("今天你已完成 \(completedHabitsCount) / \(totalHabitsCount) 个习惯。继续加油！")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private func addSampleDataIfNeeded() {
        if habits.isEmpty && todoItems.isEmpty {
            let sampleHabits = [
                Habit(name: "喝 8 杯水", icon: "cup.and.saucer.fill", isCompleted: true, streak: 3),
                Habit(name: "锻炼 30 分钟", icon: "figure.walk.circle.fill", streak: 5),
                Habit(name: "阅读 15 分钟", icon: "book.fill", streak: 12),
                Habit(name: "冥想 5 分钟", icon: "leaf.fill", isCompleted: true, streak: 1)
            ]
            
            let sampleTodos = [
                TodoItem(title: "完成项目报告"),
                TodoItem(title: "回复邮件", isCompleted: true),
                TodoItem(title: "购买生活用品")
            ]
            
            for habit in sampleHabits {
                modelContext.insert(habit)
            }
            
            for todo in sampleTodos {
                modelContext.insert(todo)
            }
        }
    }
}

// MARK: - Row Views

struct HabitRowView: View {
    @Bindable var habit: Habit
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: habit.icon)
                .font(.title)
                .foregroundColor(habit.isCompleted ? .green : .orange)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(habit.name)
                    .font(.headline)
                Text("连续坚持 \(habit.streak) 天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    habit.isCompleted.toggle()
                    if habit.isCompleted {
                        habit.streak += 1
                    } else {
                        habit.streak -= 1
                    }
                }
            }) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(habit.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TodoRowView: View {
    @Bindable var todo: TodoItem
    
    var body: some View {
        HStack {
            Text(todo.title)
                .strikethrough(todo.isCompleted, color: .secondary)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    todo.isCompleted.toggle()
                }
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(todo.isCompleted ? .blue : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [Habit.self, TodoItem.self], inMemory: true)
    }
}
