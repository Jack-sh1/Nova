import SwiftUI

struct VoiceInputView: View {
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isProcessing = false
    @State private var aiError: String?
    @State private var displayAmplitude: CGFloat = 0.0
    
    private let deepSeekManager = DeepSeekManager()
    
    // MARK: - Body

    var body: some View {
        ZStack {
            // Use a dark background for a more immersive, modern feel.
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                
                // Main status text, which updates based on the current state.
                Text(titleText)
                    .font(speechManager.isListening && !speechManager.transcribedText.isEmpty ? .title2 : .largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 100)
                    .animation(.easeInOut, value: titleText)
                
                // Subtitle provides context or instructions.
                Text(subtitleText)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .animation(.easeInOut, value: subtitleText)

                if let error = aiError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .transition(.opacity)
                }

                Spacer()
                
                // The dynamic Siri-like wave visualization.
                SiriWaveView(amplitude: $displayAmplitude)
                    .frame(height: 200)
                    .onTapGesture {
                        toggleListening()
                    }
                
                Spacer().frame(height: 40)
            }
            .padding()
        }
        .onChange(of: speechManager.isListening) { _, isListening in
            // When listening stops and there is text, process it automatically.
            if !isListening && !speechManager.transcribedText.isEmpty {
                processText()
            }
        }
        .onChange(of: speechManager.audioLevel) { _, newLevel in
            withAnimation(.linear(duration: 0.05)) {
                displayAmplitude = newLevel
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
        }
        .onDisappear {
            speechManager.stopListening()
        }
    }
    
    // MARK: - Computed Properties for UI

    private var titleText: String {
        if isProcessing {
            return "正在分析您的指令..."
        }
        if speechManager.isListening {
            // Show transcribed text if available, otherwise show a prompt.
            return speechManager.transcribedText.isEmpty ? "请讲，我听着呢..." : speechManager.transcribedText
        }
        return "语音创建任务"
    }

    private var subtitleText: String {
        // Only show the subtitle when idle.
        if isProcessing || speechManager.isListening || !speechManager.transcribedText.isEmpty {
            return ""
        }
        return "点击下方声波开始或结束"
    }
    
    // MARK: - User Actions

    private func toggleListening() {
        if speechManager.isListening {
            speechManager.stopListening()
        } else {
            speechManager.startListening()
        }
    
    }
    
    private func processText() {
        guard !speechManager.transcribedText.isEmpty else { return }
        
        isProcessing = true
        aiError = nil
        
        deepSeekManager.analyzeText(speechManager.transcribedText) { result in
            isProcessing = false
            withAnimation {
                switch result {
                case .success(let content):
                    // Parse the AI response "Type:TaskName"
                    let parts = content.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    guard parts.count == 2 else {
                        aiError = "AI 返回格式不正确: \(content)"
                        return
                    }
                    
                    let type = parts[0]
                    let name = parts[1]
                    
                    if type == "习惯" {
                        // Define a palette of attractive colors for new habits.
                        let colorPalette = ["52D7BF", "F7A541", "F45B69", "3D5A80", "98C1D9", "8E44AD"]
                        let randomColorHex = colorPalette.randomElement() ?? "52D7BF"
                        
                        let newHabit = Habit(name: name, icon: "star.fill", colorHex: randomColorHex)
                        modelContext.insert(newHabit)
                        dismiss()
                    } else if type == "待办" {
                        let newTodo = TodoItem(title: name)
                        modelContext.insert(newTodo)
                        dismiss()
                    } else {
                        aiError = "无法识别的任务类型: \(type)"
                    }
                    
                case .failure(let error):
                    aiError = error.localizedDescription
                }
            }
        }
    }
}
