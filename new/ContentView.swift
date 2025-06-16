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
    @Attribute(.unique) var id: UUID
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
    @Attribute(.unique) var id: UUID
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
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("主页", systemImage: "house.fill")
                }
            
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Habit.creationDate) private var habits: [Habit]
    @Query(sort: \TodoItem.creationDate) private var todoItems: [TodoItem]
    
    @State private var showingAddHabitSheet = false
    @State private var showingAddTodoSheet = false
    @State private var habitToEdit: Habit?
    @State private var todoToEdit: TodoItem?

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(habit: habit)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                Button {
                                    habitToEdit = habit
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                
                // To-Do List Section
                Section(header: Text("待办事项").font(.title2).fontWeight(.bold).foregroundColor(.primary)) {
                    ForEach(todoItems) { todo in
                        TodoRowView(todo: todo)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(todo: todo)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                Button {
                                    todoToEdit = todo
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("主页")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("添加新习惯") { showingAddHabitSheet = true }
                        Button("添加新待办") { showingAddTodoSheet = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) { AddHabitView() }
            .sheet(isPresented: $showingAddTodoSheet) { AddTodoView() }
            .sheet(item: $habitToEdit, content: EditHabitView.init)
            .sheet(item: $todoToEdit, content: EditTodoView.init)
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

    private func delete(habit: Habit) {
        modelContext.delete(habit)
    }

    private func delete(todo: TodoItem) {
        modelContext.delete(todo)
    }
    
    private func addSampleDataIfNeeded() {
        // This logic remains the same
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
        HStack {
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
                        FeedbackManager.taskCompleted()
                    } else {
                        habit.streak = max(0, habit.streak - 1) // 确保天数不为负
                        FeedbackManager.taskUncompleted()
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
                    if todo.isCompleted {
                        FeedbackManager.taskCompleted()
                    } else {
                        FeedbackManager.taskUncompleted()
                    }
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

// MARK: - Add Item Views

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon = "star.fill"
    let icons = ["star.fill", "heart.fill", "flame.fill", "flag.fill", "bell.fill", "book.fill", "figure.walk.circle.fill"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("习惯名称", text: $name)
                
                Picker("选择图标", selection: $icon) {
                    ForEach(icons, id: \.self) { iconName in
                        Image(systemName: iconName)
                            .font(.title2)
                            .tag(iconName)
                    }
                }
                .pickerStyle(.palette)
            }
            .navigationTitle("添加新习惯")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newHabit = Habit(name: name, icon: icon)
                        modelContext.insert(newHabit)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("待办事项标题", text: $title)
            }
            .navigationTitle("添加新待办")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newTodo = TodoItem(title: title)
                        modelContext.insert(newTodo)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [Habit.self, TodoItem.self], inMemory: true)
    }
}

// MARK: - Edit Item Views

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit

    let icons = ["star.fill", "heart.fill", "flame.fill", "flag.fill", "bell.fill", "book.fill", "figure.walk.circle.fill"]

    var body: some View {
        NavigationView {
            Form {
                TextField("习惯名称", text: $habit.name)
                Picker("选择图标", selection: $habit.icon) {
                    ForEach(icons, id: \.self) { iconName in
                        Image(systemName: iconName)
                            .font(.title2)
                            .tag(iconName)
                    }
                }
                .pickerStyle(.palette)
            }
            .navigationTitle("编辑习惯")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var todo: TodoItem

    var body: some View {
        NavigationView {
            Form {
                TextField("待办事项标题", text: $todo.title)
            }
            .navigationTitle("编辑待办")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
