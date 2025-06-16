import Foundation

struct APIKeyManager {
    
    static var deepSeekAPIKey: String? {
        // 我们将从一个名为 "APIKeys.plist" 的文件中读取密钥。
        // 这个文件不会被包含在版本控制中，以确保安全。
        guard let url = Bundle.main.url(forResource: "APIKeys", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let key = plist["DeepSeekAPIKey"] as? String else {
            
            print("错误：无法找到或读取 APIKeys.plist 文件，或文件中缺少 'DeepSeekAPIKey'。")
            print("请确保您已在项目中创建了 APIKeys.plist 文件，并添加了您的 DeepSeek API 密钥。")
            return nil
        }
        return key
    }
}
