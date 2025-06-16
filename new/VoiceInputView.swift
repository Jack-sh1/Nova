import SwiftUI

struct VoiceInputView: View {
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isProcessing = false
    @State private var aiError: String?
    
    private let deepSeekManager = DeepSeekManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                if isProcessing {
                    ProgressView("AI 正在分析您的指令...")
                } else {
                    Text(speechManager.isListening ? "请讲，我听着呢..." : "点击麦克风开始语音输入")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Text(speechManager.transcribedText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 100, maxHeight: .infinity, alignment: .topLeading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                
                Button(action: {
                    if speechManager.isListening {
                        speechManager.stopListening()
                    } else {
                        speechManager.startListening()
                    }
                }) {
                    Image(systemName: speechManager.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(speechManager.isListening ? .red : .accentColor)
                        .shadow(radius: 5)
                }
                
                if !speechManager.transcribedText.isEmpty && !speechManager.isListening {
                    Button("用这段文字创建任务") {
                        processText()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                if let error = speechManager.error ?? aiError {
                    Text("错误: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("语音创建任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    func processText() {
        guard !speechManager.transcribedText.isEmpty else { return }
        
        isProcessing = true
        aiError = nil
        
        deepSeekManager.analyzeText(speechManager.transcribedText) { result in
            isProcessing = false
            switch result {
            case .success(let content):
                // 解析 AI 返回的 "类型:任务名称"
                let parts = content.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard parts.count == 2 else {
                    aiError = "AI 返回格式不正确: \(content)"
                    return
                }
                
                let type = parts[0]
                let name = parts[1]
                
                if type == "习惯" {
                    let newHabit = Habit(name: name, icon: "star.fill")
                    modelContext.insert(newHabit)
                } else {
                    let newTodo = TodoItem(title: name)
                    modelContext.insert(newTodo)
                }
                dismiss()
                
            case .failure(let error):
                aiError = error.localizedDescription
            }
        }
    }
}
