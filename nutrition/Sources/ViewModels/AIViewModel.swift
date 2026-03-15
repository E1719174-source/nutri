import Foundation
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

class AIViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isThinking: Bool = false
    
    private let apiService = APIService.shared
    private let database = DatabaseService.shared
    
    init() {
        // Initial greeting
        messages.append(ChatMessage(text: "你好！我是你的专属 AI 营养顾问。我会根据你的身体数据和饮食记录为你提供建议。有什么我可以帮你的吗？", isUser: false))
    }
    
    func sendMessage(_ text: String) {
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        
        isThinking = true
        
        // Prepare context
        let history = getRecentHistory()
        
        apiService.getAIConsultation(history: history, question: text) { [weak self] response in
            DispatchQueue.main.async {
                let aiMessage = ChatMessage(text: response, isUser: false)
                self?.messages.append(aiMessage)
                self?.isThinking = false
            }
        }
    }
    
    private func getRecentHistory() -> String {
        // Get last 30 days summary
        // Simplified for now
        let records = database.dailyRecords.prefix(30)
        let summary = records.map { "Date: \($0.date), Cals: \($0.totalCalories)" }.joined(separator: "; ")
        return summary
    }
}
