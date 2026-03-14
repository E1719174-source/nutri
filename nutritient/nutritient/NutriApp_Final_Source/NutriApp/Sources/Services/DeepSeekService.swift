import Foundation

class DeepSeekService {
    static let shared = DeepSeekService()
    
    private init() {}
    
    func generateContentStream(prompt: String, history: [String], max_tokens: Int) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                // Mock implementation for demo purposes
                // In real app, this would call DeepSeek API
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate delay
                
                // Mock response based on prompt keywords (very simple mock)
                if prompt.contains("营养数据") {
                    let mockJSON = """
                    {
                        "name": "未知食物",
                        "calories": 150,
                        "protein": 5.0,
                        "fat": 2.0,
                        "carbs": 25.0,
                        "fiber": 3.0,
                        "category": "其他"
                    }
                    """
                    continuation.yield(mockJSON)
                } else {
                    continuation.yield("AI 服务正在连接中...")
                }
                
                continuation.finish()
            }
        }
    }
}
