import Foundation

// 定义 AI 返回结果的结构，方便解析 JSON
struct AIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// 定义我们将发送给 AI 的数据结构
struct APIRequest: Codable {
    struct Message: Codable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
}

class DeepSeekManager {
    
    // DeepSeek API 的端点 URL
    private let apiURL = URL(string: "https://api.deepseek.com/chat/completions")!
    
    // 这是核心的分析函数
    func analyzeText(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        // 1. 从安全的地方获取 API 密钥
        guard let apiKey = APIKeyManager.deepSeekAPIKey else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "未找到 DeepSeek API 密钥"])))
            return
        }
        
        // 2. 构建发送给 AI 的请求体
        let systemPrompt = "你是一个任务分类助手。请分析用户的输入，判断它是一个需要长期坚持的'习惯'，还是一个一次性的'待办'。然后提取核心任务名称。你的回答必须严格遵循'类型:任务名称'的格式，例如：'习惯:每天冥想10分钟' 或 '待办:下午三点去银行'。不要添加任何额外的解释或文字。"
        
        let messages = [
            APIRequest.Message(role: "system", content: systemPrompt),
            APIRequest.Message(role: "user", content: text)
        ]
        
        let requestBody = APIRequest(model: "deepseek-chat", messages: messages)
        
        // 3. 配置网络请求
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // 4. 发送请求并处理响应
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "未收到任何数据"])))
                return
            }
            
            do {
                let aiResponse = try JSONDecoder().decode(AIResponse.self, from: data)
                if let content = aiResponse.choices.first?.message.content {
                    // 将 AI 的回答传回主线程
                    DispatchQueue.main.async {
                        completion(.success(content))
                    }
                } else {
                    completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "AI 返回的数据格式不正确"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
