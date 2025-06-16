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
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.error = "麦克风使用权限未被授予。"
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
        
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let audioEngine = audioEngine, let request = request else {
            self.error = "无法创建音频引擎或识别请求。"
            return
        }
        
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        task = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            } else if let error = error {
                print("识别错误: \(error)")
                self.stopListening()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
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
        task?.cancel()
        task = nil
        
        request?.endAudio()
        request = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
}
