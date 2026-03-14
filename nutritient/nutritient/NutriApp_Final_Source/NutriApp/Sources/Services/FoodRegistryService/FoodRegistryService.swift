import Foundation
import Combine
import SwiftData

// MARK: - Audit Log Model
struct FoodAuditLog: Codable, Identifiable {
    let id: UUID
    let foodName: String
    let userId: String
    let timestamp: Date
    let aiResponse: String
    let status: String // "success", "failed", "duplicate"
}

// MARK: - Food Registry Service (Enhanced)
@MainActor
class FoodRegistryService: ObservableObject {
    static let shared = FoodRegistryService()
    
    @Published var searchResults: [Food] = []
    @Published var isSearching: Bool = false
    @Published var aiSuggestion: Food? // For step 2: Pre-fill UI
    @Published var error: String?
    
    private var localDatabase: [Food] = []
    private var auditLogs: [FoodAuditLog] = []
    
    private let userFoodsKey = "UserCustomFoods"
    private let auditLogsKey = "FoodAuditLogs"
    
    // SwiftData Container
    var modelContainer: ModelContainer?
    
    private init() {
        // Initialize SwiftData Container
        do {
            modelContainer = try ModelContainer(for: Food.self)
        } catch {
            print("❌ Failed to initialize ModelContainer: \(error)")
        }
        
        // Load Base Mock Data
        self.localDatabase = DataService.shared.foodDatabase
        
        // Migration: Check for old UserDefaults data
        migrateFromUserDefaults()
        
        // Load User's Custom/AI-Discovered Foods from SwiftData
        loadUserFoodsFromSwiftData()
        
        loadAuditLogs()
    }
    
    /// Unified search function: Local DB -> AI Fallback
    func search(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run { self.searchResults = [] }
            return
        }
        
        await MainActor.run {
            self.isSearching = true
            self.error = nil
            self.aiSuggestion = nil
        }
        
        // 1. Local Search (Case-insensitive)
        let normalizedQuery = query.lowercased()
        let localMatches = localDatabase.filter { item in
            item.name.lowercased().contains(normalizedQuery)
        }
        
        if !localMatches.isEmpty {
            await MainActor.run {
                self.searchResults = localMatches
                self.isSearching = false
            }
        } else {
            // 2. AI Fallback
            print("Local DB miss for '\(query)'. Asking AI to estimate...")
            await fetchFromAI(query: query)
        }
    }
    
    private func fetchFromAI(query: String) async {
        let prompt = """
        请作为一个专业的营养师，为食物“\(query)”提供估算的营养数据。
        请仅返回 JSON 格式数据，不要包含任何 markdown 标记或其他文字。
        数据应基于 100g 可食部。
        
        JSON 格式要求：
        {
            "name": "\(query)",
            "calories": 0.0, // kcal
            "protein": 0.0,  // g
            "fat": 0.0,      // g
            "carbs": 0.0,    // g
            "fiber": 0.0,    // g
            "category": "其他" // 例如：主食、肉类、蔬菜、水果、快餐等
        }
        """
        
        var jsonString = ""
        do {
            // Timeout handling handled in DeepSeekService (60s)
            let stream = DeepSeekService.shared.generateContentStream(prompt: prompt, history: [], max_tokens: 1000)
            for try await chunk in stream {
                jsonString += chunk
            }
            
            // Clean up JSON string (Robust)
            // 1. Remove markdown code blocks
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
            
            // 2. Extract only the JSON part (from first '{' to last '}')
            if let startIndex = jsonString.firstIndex(of: "{"),
               let endIndex = jsonString.lastIndex(of: "}") {
                jsonString = String(jsonString[startIndex...endIndex])
            }
            
            // 3. Remove Comments (// ...) which are invalid in standard JSON
            let lines = jsonString.components(separatedBy: .newlines)
            let cleanLines = lines.map { line -> String in
                if let commentRange = line.range(of: "//") {
                    return String(line[..<commentRange.lowerBound])
                }
                return line
            }
            jsonString = cleanLines.joined(separator: "\n")
            
            print("🔍 Trying to parse cleaned JSON: \(jsonString)") // Debug log
            
            // Use a temporary DTO to avoid strict matching issues with the main Food model
            struct AIFoodDTO: Codable {
                let name: String
                let calories: Double
                let protein: Double
                let fat: Double
                let carbs: Double
                let fiber: Double? // Make optional
                let category: String
            }
            
            if let data = jsonString.data(using: .utf8) {
                do {
                    let aiItem = try JSONDecoder().decode(AIFoodDTO.self, from: data)
                    
                    // Step 2: Pre-fill suggestion (Don't save yet)
                    let suggestion = Food(
                        id: UUID().uuidString,
                        name: aiItem.name,
                        calories: aiItem.calories,
                        protein: aiItem.protein,
                        fat: aiItem.fat,
                        carbs: aiItem.carbs,
                        fiber: aiItem.fiber ?? 0.0,
                        category: aiItem.category
                    )
                    
                    await MainActor.run {
                        self.aiSuggestion = suggestion
                        self.isSearching = false
                        // Log the attempt
                        self.logAudit(foodName: query, response: jsonString, status: "suggested")
                    }
                } catch {
                    print("❌ JSON Decode Error: \(error)")
                    throw error // Rethrow to trigger the catch block below
                }
            } else {
                print("Failed to parse AI JSON: \(jsonString)")
                await MainActor.run {
                    self.error = "AI 数据解析失败，请重试"
                    self.isSearching = false
                    self.logAudit(foodName: query, response: jsonString, status: "failed_parse")
                }
            }
            
        } catch {
            print("AI Search Error: \(error)")
            await MainActor.run {
                self.error = "网络请求超时或失败"
                self.isSearching = false
                self.logAudit(foodName: query, response: error.localizedDescription, status: "failed_network")
            }
        }
    }
    
    // Step 3: Confirm Add
    func confirmAddFood(_ food: Food) {
        // Duplicate check
        if localDatabase.contains(where: { $0.name.lowercased() == food.name.lowercased() }) {
            self.error = "该食物已存在"
            return
        }
        
        // Save to memory
        self.localDatabase.append(food)
        
        // Save to SwiftData
        saveUserFoodToSwiftData(food)
        
        // Update Search Results immediately
        self.searchResults = [food]
        self.aiSuggestion = nil
        self.error = nil
        
        // Log success
        logAudit(foodName: food.name, response: "User Confirmed", status: "success")
    }
    
    // MARK: - SwiftData Logic
    
    @MainActor
    private func saveUserFoodToSwiftData(_ food: Food) {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        
        context.insert(food)
        
        do {
            try context.save()
            print("✅ Saved food '\(food.name)' to SwiftData")
        } catch {
            print("❌ Failed to save food to SwiftData: \(error)")
        }
    }
    
    @MainActor
    private func loadUserFoodsFromSwiftData() {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        
        do {
            let descriptor = FetchDescriptor<Food>()
            let savedFoods = try context.fetch(descriptor)
            
            // Filter out duplicates if any (though logic should prevent it)
            // Or just append them to localDatabase (which starts with mock data)
            // Ensure we don't duplicate mock data if mock data was somehow saved to DB?
            // Assuming DB only contains user added foods.
            
            self.localDatabase.append(contentsOf: savedFoods)
            print("📥 Loaded \(savedFoods.count) foods from SwiftData")
        } catch {
            print("❌ Failed to fetch foods from SwiftData: \(error)")
        }
    }
    
    // MARK: - Migration
    
    @MainActor
    private func migrateFromUserDefaults() {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        
        if let data = UserDefaults.standard.data(forKey: userFoodsKey),
           let savedFoods = try? JSONDecoder().decode([Food].self, from: data) {
            
            print("📦 Found \(savedFoods.count) foods in UserDefaults. Migrating...")
            
            var count = 0
            for food in savedFoods {
                // Check if already exists in DB to avoid duplication during repeated migrations (if key wasn't cleared)
                let id = food.id
                let descriptor = FetchDescriptor<Food>(predicate: #Predicate { $0.id == id })
                
                if let existingCount = try? context.fetchCount(descriptor), existingCount == 0 {
                    context.insert(food)
                    count += 1
                }
            }
            
            if count > 0 {
                do {
                    try context.save()
                    print("✅ Migrated \(count) foods to SwiftData.")
                    
                    // Clear old data
                    UserDefaults.standard.removeObject(forKey: userFoodsKey)
                    print("🗑️ Cleared old UserDefaults data.")
                } catch {
                    print("❌ Migration failed to save: \(error)")
                }
            } else {
                 // Even if count is 0 (all duplicates), clear key
                 UserDefaults.standard.removeObject(forKey: userFoodsKey)
            }
        }
    }
    
    // MARK: - Audit Logging (Keep in UserDefaults or move to SwiftData too? Requirement didn't specify)
    // Keeping in UserDefaults for now as per "Upgrade the food persistence layer" usually implies the main data.
    // But logically, audit logs could also be in SwiftData. I'll leave them as is to minimize scope creep unless requested.
    
    private func loadAuditLogs() {
        if let data = UserDefaults.standard.data(forKey: auditLogsKey),
           let savedLogs = try? JSONDecoder().decode([FoodAuditLog].self, from: data) {
            self.auditLogs.append(contentsOf: savedLogs)
        }
    }
    
    private func logAudit(foodName: String, response: String, status: String) {
        let log = FoodAuditLog(
            id: UUID(),
            foodName: foodName,
            userId: DataService.shared.currentUser?.id ?? "guest",
            timestamp: Date(),
            aiResponse: response,
            status: status
        )
        self.auditLogs.append(log)
        
        // Save to disk
        if let encoded = try? JSONEncoder().encode(self.auditLogs) {
            UserDefaults.standard.set(encoded, forKey: auditLogsKey)
        }
    }
}
