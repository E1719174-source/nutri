import Foundation
import Combine

// MARK: - Data Service (Business Logic & Data Aggregation)
class DataService: ObservableObject {
    static let shared = DataService()
    
    // Auth State (Delegated from UserManager)
    @Published var currentUser: User?
    
    // User Data
    @Published var currentGoal: HealthGoal?
    @Published var foodRecords: [FoodRecord] = []
    @Published var waterRecords: [WaterRecord] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let userManager = UserManager.shared
    
    // File paths for user-specific data
    private func dataFileURL(for userId: String, type: String) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("data_\(userId)_\(type).json")
    }
    
    var waterIntake: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return waterRecords
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Mock Food Database (Global)
    let foodDatabase: [Food] = [
        Food(id: "1", name: "米饭", calories: 116, protein: 2.6, fat: 0.3, carbs: 25.9, fiber: 0.4, category: "主食", unitWeight: 150, unitName: "碗"),
        Food(id: "2", name: "鸡胸肉", calories: 165, protein: 31.0, fat: 3.6, carbs: 0.0, fiber: 0.0, category: "肉类"),
        Food(id: "3", name: "西兰花", calories: 34, protein: 2.8, fat: 0.4, carbs: 7.0, fiber: 2.6, category: "蔬菜"),
        Food(id: "4", name: "苹果", calories: 52, protein: 0.3, fat: 0.2, carbs: 13.8, fiber: 2.4, category: "水果", unitWeight: 180, unitName: "个"),
        Food(id: "5", name: "牛奶", calories: 54, protein: 3.0, fat: 3.2, carbs: 5.0, fiber: 0.0, category: "乳制品", unitWeight: 250, unitName: "杯"),
        Food(id: "6", name: "全麦面包", calories: 247, protein: 13.0, fat: 3.4, carbs: 41.0, fiber: 6.0, category: "主食", unitWeight: 35, unitName: "片"),
        Food(id: "7", name: "鸡蛋", calories: 155, protein: 13.0, fat: 11.0, carbs: 1.1, fiber: 0.0, category: "蛋类", unitWeight: 50, unitName: "个")
    ]
    
    private init() {
        // Sync with UserManager
        userManager.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
                if let user = user {
                    self?.loadUserData(userId: user.id)
                } else {
                    self?.clearLocalData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Auth (Proxy)
    func login(phone: String) -> Bool {
        return userManager.login(phone: phone)
    }
    
    func register(phone: String, nickname: String, gender: Gender, height: Double, weight: Double, activityLevel: ActivityLevel, goalType: GoalType) -> Bool {
        return userManager.register(phone: phone, nickname: nickname, gender: gender, height: height, weight: weight, activityLevel: activityLevel, goalType: goalType)
    }
    
    func logout() {
        userManager.logout()
    }
    
  
    func updateGoalType(_ newType: GoalType, targetWeight: Double? = nil, targetDate: Date? = nil) {
        guard let user = self.currentUser else { return }
        
        // Use NutritionCalculator logic
        let result = NutritionCalculator.calculateDailyBudget(
            user: user,
            goalType: newType,
            targetWeight: targetWeight,
            targetDate: targetDate
        )
        
        // Update Goal Model
        var newGoal = self.currentGoal ?? HealthGoal(
            id: UUID(),
            type: newType,
            targetWeight: targetWeight,
            dailyCalories: 0, // Placeholder
            dailyWater: 0,
            fastingWindow: .f16_8
        )
        
        newGoal.type = newType
        newGoal.targetWeight = targetWeight
        newGoal.dailyCalories = result.calories
        newGoal.dailyWater = Int(user.weight * 33) // Simple water rule
        
        self.currentGoal = newGoal
        saveUserData(userId: user.id)
        
        // Log warning if any
        if let warn = result.warning {
            print("Goal Warning: \(warn)")
            // Ideally, propagate this warning to UI via a Published property
        }
    }
    

    func setupInitialGoal(for user: User, type: GoalType) {
        // Use Calculator for initial setup too
        let result = NutritionCalculator.calculateDailyBudget(
            user: user,
            goalType: type,
            targetWeight: type == .loseWeight ? user.weight - 5 : nil,
            targetDate: nil // Default pace
        )
        
        let newGoal = HealthGoal(
            id: UUID(),
            type: type,
            targetWeight: type == .loseWeight ? user.weight - 5 : nil,
            dailyCalories: result.calories,
            dailyWater: Int(user.weight * 33),
            fastingWindow: .f16_8
        )
        
        self.currentGoal = newGoal
        saveUserData(userId: user.id)
    }
    
    // MARK: - Data Management
    
    private func loadUserData(userId: String) {
        // Load Goal
        if let data = try? Data(contentsOf: dataFileURL(for: userId, type: "goal")),
           let goal = try? JSONDecoder().decode(HealthGoal.self, from: data) {
            self.currentGoal = goal
        } else {
            self.currentGoal = nil // Should ideally have a default or prompt setup
        }
        
        // Load Food Records
        if let data = try? Data(contentsOf: dataFileURL(for: userId, type: "food")),
           let records = try? JSONDecoder().decode([FoodRecord].self, from: data) {
            self.foodRecords = records
        } else {
            self.foodRecords = []
        }
        
        // Load Water Records
        if let data = try? Data(contentsOf: dataFileURL(for: userId, type: "water")),
           let records = try? JSONDecoder().decode([WaterRecord].self, from: data) {
            self.waterRecords = records
        } else {
            self.waterRecords = []
        }
    }
    
    private func saveUserData(userId: String) {
        do {
            if let goal = currentGoal {
                let data = try JSONEncoder().encode(goal)
                try data.write(to: dataFileURL(for: userId, type: "goal"))
            }
            
            let foodData = try JSONEncoder().encode(foodRecords)
            try foodData.write(to: dataFileURL(for: userId, type: "food"))
            
            let waterData = try JSONEncoder().encode(waterRecords)
            try waterData.write(to: dataFileURL(for: userId, type: "water"))
            
        } catch {
            print("Error saving user data: \(error)")
        }
    }
    
    private func clearLocalData() {
        currentGoal = nil
        foodRecords = []
        waterRecords = []
    }
    
    // MARK: - Operations
    
    func clearHistory() {
        foodRecords.removeAll()
        waterRecords.removeAll()
        if let uid = currentUser?.id { saveUserData(userId: uid) }
    }
    
    func addRecord(_ record: FoodRecord) {
        foodRecords.append(record)
        if let uid = currentUser?.id { saveUserData(userId: uid) }
    }
    
    func updateRecord(_ updatedRecord: FoodRecord) {
        if let index = foodRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
            foodRecords[index] = updatedRecord
            if let uid = currentUser?.id { saveUserData(userId: uid) }
        }
    }
    
    func removeRecord(withId id: UUID) {
        foodRecords.removeAll { $0.id == id }
        if let uid = currentUser?.id { saveUserData(userId: uid) }
    }
    
    func addWater(amount: Int, date: Date = Date()) {
        let record = WaterRecord(id: UUID(), amount: amount, date: date)
        waterRecords.append(record)
        if let uid = currentUser?.id { saveUserData(userId: uid) }
    }
    
    func searchFood(query: String) -> [Food] {
        if query.isEmpty { return foodDatabase }
        return foodDatabase.filter { $0.name.contains(query) }
    }
    
    func getTodaySummary() -> DailySummary {
        let today = Calendar.current.startOfDay(for: Date())
        let todayRecords = foodRecords.filter { Calendar.current.isDate($0.recordDate, inSameDayAs: today) }
        
        return DailySummary(
            date: today,
            totalCalories: todayRecords.reduce(0) { $0 + $1.calories },
            totalProtein: todayRecords.reduce(0) { $0 + $1.protein },
            totalFat: todayRecords.reduce(0) { $0 + $1.fat },
            totalCarbs: todayRecords.reduce(0) { $0 + $1.carbs },
            waterIntake: waterIntake
        )
    }
    
    func getTodayWaterRecords() -> [WaterRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        return waterRecords.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.sorted(by: { $0.date > $1.date })
    }
}
