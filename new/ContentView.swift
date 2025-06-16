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
    var isReminderOn: Bool
    var reminderTime: Date

    init(name: String, icon: String, isCompleted: Bool = false, streak: Int = 0, isReminderOn: Bool = false, reminderTime: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isCompleted = isCompleted
        self.streak = streak
        self.creationDate = .now
        self.isReminderOn = isReminderOn
        self.reminderTime = reminderTime
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


// MARK: - Main View with TabBar
struct ContentView: View {
    @State private var showingVoiceInputSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                HomeView()
                    .tabItem {
                        Label("任务", systemImage: "house")
                    }

                StatisticsView()
                    .tabItem {
                        Label("统计", systemImage: "chart.bar.xaxis")
                    }
            }

            // Floating voice button overlay
            Button(action: {
                showingVoiceInputSheet = true
            }) {
                Image(systemName: "mic.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 65, height: 65)
                    .foregroundColor(.accentColor)
                    .background(.white.opacity(0.95))
                    .clipShape(Circle())
                    .shadow(radius: 5, y: 2)
            }
            .offset(y: -25) // Adjust vertical position
            .sheet(isPresented: $showingVoiceInputSheet) {
                VoiceInputView()
            }
        }
        .ignoresSafeArea(.keyboard) // Prevent keyboard from pushing the button up
    }
}

// MARK: - Home Screen View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles.square.filled.on.square")
                .font(.system(size: 80))
                .foregroundColor(.accentColor.opacity(0.7))
            
            Text("开启你的高效生活")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("点击下方的麦克风或右上角的加号，\n创建你的第一个任务吧！")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
            Group {
                if habits.isEmpty && todoItems.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        Section(header: headerView) {
                            EmptyView()
                        }
                        .listRowInsets(EdgeInsets())

                        Section(header: Text("习惯")) {
                            ForEach(habits) { habit in
                                HabitRowView(habit: habit)
                                    .swipeActions(edge: .trailing) {
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
                                        .tint(.accentColor)
                                    }
                            }
                        }
                        
                        Section(header: Text("待办事项")) {
                            ForEach(todoItems) { item in
                                TodoItemRowView(todoItem: item)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            delete(todoItem: item)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
            }
            .navigationTitle("任务")
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
        VStack {
            Text("\(completedHabitsCount)/\(totalHabitsCount) 习惯已完成")
                .font(.headline)
                .padding()
            
            ProgressView(value: Double(completedHabitsCount), total: Double(totalHabitsCount))
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .padding([.leading, .trailing, .bottom])
        }
        .background(Color(.systemGroupedBackground))
    }

    private func delete(habit: Habit) {
        // 在删除数据前，先取消它的通知
        NotificationManager.shared.cancelNotification(for: habit)
        modelContext.delete(habit)
    }

    private func delete(todoItem: TodoItem) {
        modelContext.delete(todoItem)
    }
    
    private func addSampleDataIfNeeded() {
        let key = "didAddSampleData"
        if !UserDefaults.standard.bool(forKey: key) {
            let sampleHabit = Habit(name: "每天运动 30 分钟", icon: "flame.fill", isReminderOn: true, reminderTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!)
            let sampleTodo = TodoItem(title: "完成项目报告")
            modelContext.insert(sampleHabit)
            modelContext.insert(sampleTodo)
            UserDefaults.standard.set(true, forKey: key)
        }
    }
}

// MARK: - Row Views
struct HabitRowView: View {
    @Bindable var habit: Habit
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .foregroundColor(.accentColor)
            Text(habit.name)
            Spacer()
            Text("连胜: \(habit.streak)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                habit.isCompleted.toggle()
                if habit.isCompleted {
                    habit.streak += 1
                    FeedbackManager.taskCompleted()
                } else {
                    habit.streak = max(0, habit.streak - 1)
                    FeedbackManager.taskUncompleted()
                }
            }) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct TodoItemRowView: View {
    @Bindable var todoItem: TodoItem

    var body: some View {
        HStack {
            Text(todoItem.title)
            Spacer()
            Button(action: {
                todoItem.isCompleted.toggle()
                if todoItem.isCompleted {
                    FeedbackManager.taskCompleted()
                } else {
                    FeedbackManager.taskUncompleted()
                }
            }) {
                Image(systemName: todoItem.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Add/Edit Views

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var isReminderOn: Bool = false
    @State private var reminderTime: Date = .now
    
    let icons = ["star.fill", "heart.fill", "flame.fill", "flag.fill", "bell.fill", "book.fill", "figure.walk", "trophy.fill"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基础信息")) {
                    TextField("习惯名称", text: $name)
                    
                    Picker("选择图标", selection: $selectedIcon) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("提醒设置")) {
                    Toggle("开启提醒", isOn: $isReminderOn)
                    
                    if isReminderOn {
                        DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("添加新习惯")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        let newHabit = Habit(name: name, icon: selectedIcon, isReminderOn: isReminderOn, reminderTime: reminderTime)
                        modelContext.insert(newHabit)
                        NotificationManager.shared.scheduleNotification(for: newHabit)
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
    
    @State private var title: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("待办事项")) {
                    TextField("要做什么？", text: $title)
                }
            }
            .navigationTitle("添加新待办")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
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

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit

    let icons = ["star.fill", "heart.fill", "flame.fill", "flag.fill", "bell.fill", "book.fill", "figure.walk", "trophy.fill"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基础信息")) {
                    TextField("习惯名称", text: $habit.name)
                    
                    Picker("选择图标", selection: $habit.icon) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("提醒设置")) {
                    Toggle("开启提醒", isOn: $habit.isReminderOn)
                    
                    if habit.isReminderOn {
                        DatePicker("提醒时间", selection: $habit.reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("编辑习惯")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        // 先取消旧的通知，再根据新的设置安排通知
                        NotificationManager.shared.cancelNotification(for: habit)
                        NotificationManager.shared.scheduleNotification(for: habit)
                        dismiss()
                    }
                }
            }
        }
    }
}
struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var todoItem: TodoItem

    var body: some View {
        NavigationView {
            Form {
                TextField("待办事项标题", text: $todoItem.title)
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
