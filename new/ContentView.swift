//
//  ContentView.swift
//  new
//
//  Created by zhetaoWang on 2025/6/16.
//

import SwiftUI
import SwiftData

// MARK: - Habit Extension for Achievements
extension Habit {
    /**
     Calculates the current continuous completion streak ending today or yesterday.
     */
    func calculateCurrentStreak() -> Int {
        guard !completionDates.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create a set of start-of-day dates for efficient lookup
        let completedDays = Set(completionDates.map { calendar.startOfDay(for: $0) })

        var streak = 0
        var currentDate = today

        // If today isn't completed, the streak might have ended yesterday.
        // So, we start checking from yesterday.
        if !completedDays.contains(today) {
            currentDate = calendar.date(byAdding: .day, value: -1, to: today)!
        }
        
        // Iterate backwards from the starting date
        while completedDays.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
}

// MARK: - Models
@Model
class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String? // The color of the habit icon, now optional for migration
    var creationDate: Date
    var isReminderOn: Bool
    var reminderTime: Date
    // Stored property is now Data to be compatible with SwiftData
    private var completionDatesData: Data = Data()

    init(name: String, icon: String, colorHex: String = "52D7BF", isReminderOn: Bool = false, reminderTime: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.creationDate = .now
        self.isReminderOn = isReminderOn
        self.reminderTime = reminderTime
        // Initialize with an empty array, which gets encoded to data
        self.completionDates = []
    }
    
    // Computed property to get a SwiftUI Color from the hex string
    var color: Color {
        // Provide a default color if hex is nil (for migrated data)
        Color(hex: colorHex ?? "888888") // A neutral gray
    }
    
    // Computed property for easy access and to maintain compatibility with existing code
    var completionDates: [Date] {
        get {
            // Decode data into [Date], providing an empty array as a fallback.
            (try? JSONDecoder().decode([Date].self, from: completionDatesData)) ?? []
        }
        set {
            // Encode [Date] into data
            completionDatesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return completionDates.contains { date in
            Calendar.current.isDate(date, inSameDayAs: today)
        }
    }
    
    var currentStreak: Int {
        calculateCurrentStreak()
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
    @State private var unlockedAchievement: Achievement?
    
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
            if let achievement = unlockedAchievement {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture {
                    withAnimation { unlockedAchievement = nil }
                }
                AchievementUnlockedView(achievement: achievement)
                    .onTapGesture {
                        withAnimation { unlockedAchievement = nil }
                    }
            }
        }
        .ignoresSafeArea(.keyboard) // Prevent keyboard from pushing the button up
        .onReceive(NotificationCenter.default.publisher(for: .didUnlockAchievement)) { notification in
            // Ensure we don't show a new alert if one is already showing
            guard unlockedAchievement == nil else { return }
            
            if let achievement = notification.object as? Achievement {
                // Present the achievement
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    self.unlockedAchievement = achievement
                }
                
                // Haptic feedback for celebration
                // Assuming FeedbackManager has this method. If not, we can add it.
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                // Automatically hide after a few seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        // Only hide if it's still the same achievement being shown
                        if self.unlockedAchievement?.id == achievement.id {
                            self.unlockedAchievement = nil
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Unlocked View
struct AchievementUnlockedView: View {
    let achievement: Achievement
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -15

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 成就解锁 🎉")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Image(systemName: achievement.iconName)
                .font(.system(size: 70))
                .foregroundColor(.white)
                .padding(24)
                .background(
                    Circle().fill(Color.yellow.gradient)
                )
                .shadow(color: .yellow.opacity(0.7), radius: 10)


            Text(achievement.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(achievement.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 32)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .scaleEffect(scale)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 1.0, y: 0.0, z: 0.0)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.5)))
        .zIndex(10) // Make sure it's on top of everything
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
    @EnvironmentObject var achievementManager: AchievementManager
    
    @Query(sort: \Habit.creationDate) private var habits: [Habit]
    @Query(sort: \TodoItem.creationDate) private var todoItems: [TodoItem]
    
    @State private var showingAddHabitSheet = false
    @State private var showingAddTodoSheet = false
    @State private var habitToEdit: Habit?
    @State private var todoToEdit: TodoItem?

    var completedHabitsCount: Int {
        habits.filter { $0.isCompletedToday }.count
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
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            delete(todoItem: item)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            todoToEdit = item
                                        } label: {
                                            Label("编辑", systemImage: "pencil")
                                        }
                                        .tint(.accentColor)
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
                        Button {
                            showingAddHabitSheet = true
                        } label: {
                            Label("添加新习惯", systemImage: "flame.fill")
                        }
                        
                        Button {
                            showingAddTodoSheet = true
                        } label: {
                            Label("添加新待办", systemImage: "checklist")
                        }
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
            .onAppear {
                addSampleDataIfNeeded()
                achievementManager.checkAchievements(for: habits)
            }
            .onChange(of: habits.count) { // Check when habits are added or deleted
                achievementManager.checkAchievements(for: habits)
            }
            .onChange(of: habits.map { $0.completionDates.count }) { // Check when a habit is completed/uncompleted
                achievementManager.checkAchievements(for: habits)
            }
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
            IconView(iconName: habit.icon)
                .font(.title)
                .frame(width: 40)
            Text(habit.name)
            Spacer()
            Text("连胜: \(habit.currentStreak)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                toggleCompletion()
            }) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func toggleCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        if let index = habit.completionDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            // It was completed today, so un-complete it
            habit.completionDates.remove(at: index)
            FeedbackManager.taskUncompleted()
        } else {
            // It was not completed today, so complete it
            habit.completionDates.append(Date())
            FeedbackManager.taskCompleted()
        }
    }
}

struct TodoItemRowView: View {
    @Bindable var todoItem: TodoItem

    var body: some View {
        HStack {
            Text(todoItem.title)
                .strikethrough(todoItem.isCompleted)
                .foregroundColor(todoItem.isCompleted ? .secondary : .primary)

            Spacer()

            Button(action: {
                // This action is now one-way.
                withAnimation {
                    todoItem.isCompleted = true
                }
                FeedbackManager.taskCompleted()
            }) {
                Image(systemName: todoItem.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todoItem.isCompleted ? .green : .accentColor)
            }
            .buttonStyle(PlainButtonStyle())
            // Disable the button once the task is completed.
            .disabled(todoItem.isCompleted)
        }
    }
}

// MARK: - Add/Edit Views

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "⭐️"
    @State private var isReminderOn: Bool = false
    @State private var reminderTime: Date = Date()
    
    let icons = ["⭐️", "❤️", "🔥", "🚩", "🔔", "📖", "🏃", "🏆"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基础信息")) {
                    TextField("习惯名称", text: $name)
                    
                    Picker("选择图标", selection: $selectedIcon) {
                        ForEach(icons, id: \.self) { icon in
                            Text(icon)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Text("习惯是需要长期坚持的目标，持续打卡来见证你的成长。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("提醒设置")) {
                    Toggle("开启提醒", isOn: $isReminderOn.animation())
                    
                    if isReminderOn {
                        DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("添加新习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        let newHabit = Habit(name: name, icon: selectedIcon, isReminderOn: isReminderOn, reminderTime: reminderTime)
                        modelContext.insert(newHabit)
                        if newHabit.isReminderOn {
                            NotificationManager.shared.scheduleNotification(for: newHabit)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
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
                
                Section {
                    Text("待办是一次性的任务，完成后即可勾选。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加新待办")
            .navigationBarTitleDisplayMode(.inline)
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
                    .fontWeight(.bold)
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
                    
                    // Custom Icon Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .padding(12)
                                    .background(habit.icon == icon ? habit.color : Color(UIColor.systemGray5))
                                    .foregroundColor(habit.icon == icon ? .white : .primary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        withAnimation {
                                            habit.icon = icon
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                    }
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

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
