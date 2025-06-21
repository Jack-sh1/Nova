import Foundation
import HealthKit

class HealthKitManager {
    
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    private init() { }
    
    /// 请求用户授权访问健康数据
    /// - Parameter completion: 授权成功或失败后的回调
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // 1. 检查设备是否支持 HealthKit
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "此设备不支持健康数据"]))
            return
        }
        
        // 2. 定义我们想要读取的数据类型（这里是“体能训练”）
        let typesToRead: Set = [
            HKObjectType.workoutType()
        ]
        
        // 3. 发起授权请求
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    /// 获取最近的体能训练数据 (后续实现)
    func fetchWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        // 这里将是我们下一步编写代码的地方
        print("后续将在这里实现获取运动数据的功能。")
        completion([], nil)
    }
}
