import Foundation

struct ChatCompletionResponse: Codable {
    let id: String
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    private let apiKey = "sk-yccjdjimfzutdguqhsltcmqvzxshdnkptuwkfhjvmsopbquq"
    // Using a common model available on Silicon Flow. Adjust if needed (e.g., deepseek-ai/deepseek-llm-7b-chat)
    private let modelName = "deepseek-ai/DeepSeek-V3" 
    
    func searchFood(query: String, completion: @escaping ([FoodItem]) -> Void) {
        print("Searching for \(query) via Silicon Flow API...")
        
        let systemPrompt = """
        You are a nutrition database assistant. When the user inputs a food name, you must output a valid JSON array of food items.
        Each item should have: name (string), calories (number, kcal/100g), protein (number, g/100g), fat (number, g/100g), carbs (number, g/100g), fiber (number, g/100g), unit (string, one of: "克", "个", "盒", "瓶"), amount (number, default 100 or 1).
        
        Example output:
        [
            {"name": "Apple (100g)", "calories": 52, "protein": 0.3, "fat": 0.2, "carbs": 14, "fiber": 2.4, "unit": "克", "amount": 100},
            {"name": "Apple (1 medium)", "calories": 95, "protein": 0.5, "fat": 0.3, "carbs": 25, "fiber": 4.4, "unit": "个", "amount": 1}
        ]
        
        Only output the JSON. Do not output any markdown code blocks or other text.
        """
        
        let messages = [
            ChatCompletionRequest.Message(role: "system", content: systemPrompt),
            ChatCompletionRequest.Message(role: "user", content: "Search for: \(query)")
        ]
        
        let requestBody = ChatCompletionRequest(
            model: modelName,
            messages: messages,
            temperature: 0.1, // Low temperature for deterministic JSON
            max_tokens: 1024
        )
        
        performRequest(requestBody: requestBody) { result in
            switch result {
            case .success(let content):
                // Clean content if it contains markdown code blocks
                var jsonString = content
                if jsonString.contains("```json") {
                    jsonString = jsonString.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
                }
                
                guard let data = jsonString.data(using: .utf8) else {
                    print("Failed to convert string to data")
                    completion([])
                    return
                }
                
                do {
                    // Define a temporary struct to decode the JSON from LLM
                    struct TempFood: Codable {
                        let name: String
                        let calories: Double
                        let protein: Double
                        let fat: Double
                        let carbs: Double
                        let fiber: Double
                        let unit: String
                        let amount: Double
                    }
                    
                    let tempFoods = try JSONDecoder().decode([TempFood].self, from: data)
                    
                    let foods = tempFoods.map { temp in
                        FoodItem(
                            name: temp.name,
                            calories: temp.calories,
                            protein: temp.protein,
                            fat: temp.fat,
                            carbs: temp.carbs,
                            fiber: temp.fiber,
                            unit: FoodUnit(rawValue: temp.unit) ?? .gram,
                            amount: temp.amount
                        )
                    }
                    completion(foods)
                } catch {
                    print("JSON Decoding Error: \(error)")
                    completion([])
                }
                
            case .failure(let error):
                print("Network Error: \(error)")
                completion([])
            }
        }
    }
    
    func getAIConsultation(history: String, question: String, completion: @escaping (String) -> Void) {
        print("Sending to DeepSeek LLM via Silicon Flow...")
        
        let systemPrompt = """
        You are a professional nutrition consultant. You are helpful, knowledgeable, and polite.
        Respond in a conversational tone.
        
        Important:
        1. Always include a disclaimer: "Please consult a professional nutritionist for medical advice."
        2. Use the provided user history to give personalized advice.
        """
        
        let userContent = "History: \(history)\n\nUser Question: \(question)"
        
        let messages = [
            ChatCompletionRequest.Message(role: "system", content: systemPrompt),
            ChatCompletionRequest.Message(role: "user", content: userContent)
        ]
        
        let requestBody = ChatCompletionRequest(
            model: modelName,
            messages: messages,
            temperature: 0.7,
            max_tokens: 4096
        )
        
        performRequest(requestBody: requestBody) { result in
            switch result {
            case .success(let content):
                completion(content)
            case .failure(let error):
                print("Consultation Error: \(error)")
                completion("Sorry, I couldn't reach the server. Please try again later.")
            }
        }
    }
    
    private func performRequest(requestBody: ChatCompletionRequest, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            // Debug: Print raw response
            if let str = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(str)")
            }
            
            do {
                let responseObj = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                if let content = responseObj.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
