import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // 1. 请求用户授权发送通知
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已授予。")
            } else if let error = error {
                print("请求通知权限时出错: \(error.localizedDescription)")
            }
        }
    }

    // 2. 为单个习惯安排通知
    func scheduleNotification(for habit: Habit) {
        // 确保习惯开启了提醒
        guard habit.isReminderOn else { return }

        let center = UNUserNotificationCenter.current()

        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "习惯提醒⏰"
        content.body = "是时候完成你的习惯了：\(habit.name)"
        content.sound = .default

        // 创建触发器，根据用户设定的时间，每日重复
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: habit.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // 创建并添加请求
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("安排通知时出错: \(error.localizedDescription)")
            } else {
                print("已成功为'\(habit.name)'在每天 \(dateComponents.hour!):\(dateComponents.minute!) 安排通知。")
            }
        }
    }

    // 3. 取消单个习惯的通知
    func cancelNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        // 根据习惯的唯一 ID 移除待处理的通知
        center.removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
        print("已为'\(habit.name)'取消所有待处理的通知。")
    }
}
