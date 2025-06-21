import Foundation
import Speech
import AVFoundation

// 这个类将管理整个语音转文字的过程。
class SpeechManager: ObservableObject {
    
    // Published 属性会实时更新 UI。
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var error: String?
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    // 我们将使用中文作为识别语言。
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

    init() {
        // 在管理器创建时就请求权限。
        requestPermissions()
    }

    deinit {
        stopListening()
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
                }
            }
            
            if let error = error {
                // 将 error 转换为 NSError 以检查 domain 和 code
                let nsError = error as NSError
                
                // 如果错误是用户主动取消（code 301），则不视为真正的错误，静默处理即可。
                // 否则，打印错误并停止监听。
                if !(nsError.domain == "kLSRErrorDomain" && nsError.code == 301) {
                    DispatchQueue.main.async {
                        self.error = "识别错误: \(error.localizedDescription)"
                        // We should not call stopListening() from here as it can cause race conditions
                        // with deinit or other UI-driven calls. Instead, we just update the state.
                        // The view's lifecycle (e.g., onDisappear) is responsible for cleanup.
                        self.isListening = false
                    }
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            self.error = "无法启动音频引擎: \(error.localizedDescription)"
            stopListening()
        }
    }

    func stopListening() {
        // The order of operations is critical for a clean shutdown.
        
        // 1. Stop the audio engine and remove the tap to prevent further audio processing.
        if audioEngine?.isRunning == true {
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine?.stop()
        }
        
        // 2. Finalize the recognition request.
        request?.endAudio()
        
        // 3. Cancel the recognition task.
        task?.cancel()
        
        // 4. Nil out all optional properties to break potential retain cycles and release memory.
        audioEngine = nil
        request = nil
        task = nil
        
        // 5. Deactivate the audio session to release the hardware.
        // This should be done after all other components are stopped.
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        
        // 6. Update the UI on the main thread.
        DispatchQueue.main.async { [weak self] in
            self?.isListening = false
        }
    }
}
