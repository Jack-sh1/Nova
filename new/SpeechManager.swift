import Foundation
import Speech
import AVFoundation

// 这个类将管理整个语音转文字的过程。
class SpeechManager: ObservableObject {
    
    // Published 属性会实时更新 UI。
    @Published private(set) var isListening = false
    @Published private(set) var transcribedText = ""
    @Published private(set) var error: String?
    @Published var audioLevel: CGFloat = 0.0
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    // 我们将使用中文作为识别语言。
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

    init() {
        // 在管理器创建时就请求权限。
        requestPermissions()
    }

    deinit {
        // Deinitialization must be synchronous and on the main thread for UI-related objects.
        // We ensure our stop logic can be called safely from here.
        _stopListening()
    }
    
    func requestPermissions() {
        // 请求语音识别授权。
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    self.error = "语音识别权限未被授予。"
                }
            }
        }
        
        // 请求麦克风使用权限。
        if #available(iOS 17.0, macOS 14.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if !granted {
                        self.error = "麦克风使用权限未被授予。"
                    }
                }
            }
        } else {
            // 为旧版系统提供回退方案
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if !granted {
                        self.error = "麦克风使用权限未被授予。"
                    }
                }
            }
        }
    }

    func startListening() {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            self.error = "语音识别器当前不可用。"
            return
        }
        
        transcribedText = ""
        error = nil
        
        // 显式配置并激活音频会话，确保硬件准备就绪
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "无法设置音频会话: \(error.localizedDescription)"
            return
        }
        
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let audioEngine = audioEngine, let request = request else {
            self.error = "无法创建音频引擎或识别请求。"
            return
        }
        
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                    // Reset the timer every time new text is received.
                    self.resetSilenceTimer()
                }
            }
            
            if let error = error {
                // 将 error 转换为 NSError 以检查 domain 和 code
                let nsError = error as NSError
                
                // 如果错误是用户主动取消（code 301），则不视为真正的错误，静默处理即可。
                // 否则，打印错误并停止监听。
                // If a significant error occurs (not just user cancellation), stop everything.
                if !(nsError.domain == "kLSRErrorDomain" && nsError.code == 301) {
                    DispatchQueue.main.async {
                        self.error = "识别错误: \(error.localizedDescription)"
                        // Call the main stop function to ensure a clean shutdown.
                        self._stopListening()
                    }
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            
            // --- Audio Level Calculation ---
            guard let self = self else { return }
            
            let channelData = buffer.floatChannelData![0]
            let channelDataValue = UnsafeMutablePointer<Float>(channelData)
            let channelDataValueArray = stride(from: 0,
                                               to: Int(buffer.frameLength),
                                               by: buffer.stride).map{ channelDataValue[$0] }
            let rms = sqrt(channelDataValueArray.map{ $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
            
            // Avoid log10(0) which is -infinity.
            guard rms > 0 else {
                DispatchQueue.main.async { self.audioLevel = 0 }
                return
            }
            
            let avgPower = 20 * log10(rms)
            // Normalize power to a 0-1 range, where -50 dB is 0 and 0 dB is 1.
            let normalizedPower = CGFloat(max(0, (avgPower + 50) / 50))

            DispatchQueue.main.async {
                self.audioLevel = normalizedPower
            }
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                // Start the silence detection timer.
                self.resetSilenceTimer()
            }
        } catch {
            self.error = "无法启动音频引擎: \(error.localizedDescription)"
            stopListening()
        }
    }

    // Public function to be called from UI, timers, etc.
    // It safely dispatches the core logic to the main thread to prevent race conditions.
    func stopListening() {
        DispatchQueue.main.async {
            self._stopListening()
        }
    }

    // Private core function to stop listening. MUST be called on the main thread.
    // It's idempotent, meaning it's safe to call multiple times.
    private func _stopListening() {
        // If we're not listening, there's nothing to do.
        guard isListening else { return }

        // Update state immediately to prevent re-entry.
        isListening = false
        audioLevel = 0.0

        // Invalidate the timer to prevent it from firing unexpectedly.
        silenceTimer?.invalidate()
        silenceTimer = nil

        // The order of operations is critical for a clean shutdown.
        if audioEngine?.isRunning == true {
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine?.stop()
        }
        request?.endAudio()
        task?.cancel()
        
        // Nil out all optional properties to break potential retain cycles and release memory.
        audioEngine = nil
        request = nil
        task = nil
        
        // Deactivate the audio session to release the hardware.
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    private func resetSilenceTimer() {
        // Invalidate any existing timer.
        silenceTimer?.invalidate()
        // Start a new timer. If it fires after 1.5 seconds of silence, stop listening.
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self = self, self.isListening else { return }
            self.stopListening()
        }
    }
}
