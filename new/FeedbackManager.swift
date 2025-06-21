import Foundation
import AVFoundation
import UIKit

import Foundation
import AVFoundation
import UIKit

// A dedicated singleton class to manage sound playback robustly.
// This class acts as the delegate to ensure the audio player is released correctly.
class SoundPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    
    func playSound(named soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: nil) else {
            print("Could not find sound file named \(soundName).")
            return
        }
        
        do {
            // Configure the audio session for playback.
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Initialize the player and set this class as its delegate.
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Couldn't play sound file named \(soundName): \(error.localizedDescription)")
        }
    }
    
    // This delegate method is called when the sound has finished playing.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Release the player to prevent memory leaks.
        audioPlayer = nil
    }
}

struct FeedbackManager {
    static func taskCompleted() {
        // Use the robust SoundPlayer singleton to play the sound.
        SoundPlayer.shared.playSound(named: "fireworks.mp3")
        
        // Trigger a success haptic feedback.
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func taskUncompleted() {
        // Play a subtle system sound for deselection.
        AudioServicesPlaySystemSound(1104)
        
        // Trigger a light impact haptic.
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
