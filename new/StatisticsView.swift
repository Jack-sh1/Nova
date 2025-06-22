import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \Habit.creationDate) private var habits: [Habit]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if habits.isEmpty {
                        ContentUnavailableView("暂无统计数据", systemImage: "chart.pie", description: Text("开始添加并完成一些习惯后，这里将显示您的进度统计。"))
                    } else {
                        CompletionRateView(habits: habits)
                        WeeklyChartView(habits: habits)
                        StreakView(habits: habits)
                        AchievementsView()
                    }
                }
                .padding()
            }
            .navigationTitle("统计数据")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct CompletionRateView: View {
    let habits: [Habit]
    
    private var completionPercentage: Double {
        guard !habits.isEmpty else { return 0 }
        let completedCount = habits.filter { $0.isCompletedToday }.count
        return Double(completedCount) / Double(habits.count)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("今日完成率")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 5)
            
            HStack {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20.0)
                        .opacity(0.1)
                        .foregroundColor(.blue)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.completionPercentage, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.blue)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.easeOut, value: completionPercentage)
                    
                    Text(String(format: "%.0f %%", min(self.completionPercentage, 1.0) * 100.0))
                        .font(.title)
                        .bold()
                }
                .frame(width: 120, height: 120)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("太棒了！")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("继续保持这个势头，养成好习惯指日可待。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct WeeklyChartView: View {
    let habits: [Habit]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("习惯坚持天数")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 5)

            Chart(habits) { habit in
                BarMark(
                    x: .value("天数", habit.currentStreak),
                    y: .value("习惯", habit.name)
                )
                .foregroundStyle(by: .value("习惯", habit.name))
                .annotation(position: .trailing) {
                    Text("\(habit.currentStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .chartLegend(.hidden)
            .chartYAxis(.hidden)
            .frame(height: CGFloat(habits.count * 40))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StreakView: View {
    let habits: [Habit]
    
    private var sortedHabits: [Habit] {
        habits.sorted { $0.currentStreak > $1.currentStreak }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("连胜排行榜")
                .font(.title2)
                .fontWeight(.semibold)
            
            ForEach(Array(sortedHabits.prefix(3).enumerated()), id: \.element.id) { index, habit in
                HStack {
                    Image(systemName: "\(index + 1).circle.fill")
                        .font(.title)
                        .foregroundColor(index == 0 ? .yellow : (index == 1 ? .gray : .brown))
                    
                    IconView(iconName: habit.icon)
                        .font(.largeTitle)
                        .frame(width: 30)

                    Text(habit.name)
                        .font(.headline)
                    Spacer()
                    Text("\(habit.currentStreak) 天")
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}


struct AchievementsView: View {
    @EnvironmentObject var achievementManager: AchievementManager
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("我的徽章")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 5)
            
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(achievementManager.allAchievements) { achievement in
                    AchievementBadgeView(
                        achievement: achievement,
                        isUnlocked: achievementManager.unlockedAchievements.contains(achievement.id)
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(AchievementManager())
    }
}
