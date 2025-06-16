import Foundation
import AVFoundation
import UIKit

struct FeedbackManager {
    
    // 创建一个静态的 AVAudioPlayer 实例，以防止每次播放时都重新创建
    static var audioPlayer: AVAudioPlayer?

    static func taskCompleted() {
        // 播放自定义的烟花音效
        playSound(named: "fireworks.mp3")
        
        // 触发一个表示成功的触感反馈。
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func taskUncompleted() {
        // 播放一个更细微的音效用于取消选中。ID 1104 是一个“叮”声。
        AudioServicesPlaySystemSound(1104)
        
        // 触发一个轻微的冲击触感。
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // 新增一个私有方法来播放指定名称的声音文件
    private static func playSound(named soundName: String) {
        // 从项目的主 Bundle 中查找声音文件
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: nil) else {
            print("无法找到名为 \(soundName) 的声音文件。请确保您已将 'fireworks.mp3' 添加到 Xcode 项目中。")
            return
        }
        
        do {
            // 初始化 AVAudioPlayer 并播放声音
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("无法播放声音文件 \(soundName): \(error.localizedDescription)")
        }
    }
}
