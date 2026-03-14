import Foundation
import SwiftData

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    var phone: String
    var nickname: String
    var avatarUrl: String?
    var gender: Gender
    var birthDate: Date
    var height: Double // cm
    var weight: Double // kg
    var activityLevel: ActivityLevel
    
    var bmi: Double {
        guard height > 0 else { return 0 }
        let heightM = height / 100.0
        return weight / (heightM * heightM)
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "男"
    case female = "女"
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "久坐不动"
    case light = "轻度活动"
    case moderate = "中度活动"
    case active = "重度活动"
    case athlete = "专业运动"
    
    var description: String {
        switch self {
        case .sedentary: return "几乎不运动，办公室工作"
        case .light: return "每周运动 1-3 次"
        case .moderate: return "每周运动 3-5 次"
        case .active: return "每周运动 6-7 次"
        case .athlete: return "每天进行高强度训练"
        }
    }
}

// MARK: - Food Model
@Model
class Food: Codable, Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var calories: Double // per 100g
    var protein: Double
    var fat: Double
    var carbs: Double
    var fiber: Double
    var category: String
    var unitWeight: Double? // Weight per unit (e.g., 1 apple ≈ 150g)
    var unitName: String?   // Unit name (e.g., "个", "杯")
    var isRecipe: Bool?     // New field to identify if it is a recipe
    var ingredients: [FoodRecord]? // Store ingredients if it is a recipe
    
    init(id: String, name: String, calories: Double, protein: Double, fat: Double, carbs: Double, fiber: Double, category: String, unitWeight: Double? = nil, unitName: String? = nil, isRecipe: Bool = false, ingredients: [FoodRecord]? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.fiber = fiber
        self.category = category
        self.unitWeight = unitWeight
        self.unitName = unitName
        self.isRecipe = isRecipe
        self.ingredients = ingredients
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, fat, carbs, fiber, category, unitWeight, unitName, isRecipe, ingredients
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Double.self, forKey: .calories)
        protein = try container.decode(Double.self, forKey: .protein)
        fat = try container.decode(Double.self, forKey: .fat)
        carbs = try container.decode(Double.self, forKey: .carbs)
        fiber = try container.decode(Double.self, forKey: .fiber)
        category = try container.decode(String.self, forKey: .category)
        unitWeight = try container.decodeIfPresent(Double.self, forKey: .unitWeight)
        unitName = try container.decodeIfPresent(String.self, forKey: .unitName)
        isRecipe = try container.decodeIfPresent(Bool.self, forKey: .isRecipe)
        ingredients = try container.decodeIfPresent([FoodRecord].self, forKey: .ingredients)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(fat, forKey: .fat)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fiber, forKey: .fiber)
        try container.encode(category, forKey: .category)
        try container.encode(unitWeight, forKey: .unitWeight)
        try container.encode(unitName, forKey: .unitName)
        try container.encode(isRecipe, forKey: .isRecipe)
        try container.encode(ingredients, forKey: .ingredients)
    }
}

// MARK: - Record Model
struct FoodRecord: Codable, Identifiable {
    let id: UUID
    let foodId: String
    let foodName: String
    let weight: Double
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let recordDate: Date
    let mealType: MealType
}

// MARK: - Water Record Model
struct WaterRecord: Codable, Identifiable {
    let id: UUID
    let amount: Int
    let date: Date
}

enum MealType: String, Codable, CaseIterable, Comparable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"
    
    // Define order for sorting
    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }
    
    static func < (lhs: MealType, rhs: MealType) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Goal Model
struct HealthGoal: Codable, Identifiable {
    let id: UUID
    var type: GoalType
    var targetWeight: Double?
    var dailyCalories: Double
    var dailyWater: Int // ml
    var fastingWindow: FastingWindow?
    
    // Nutrient targets (simplified logic for demo)
    var proteinTarget: Double { dailyCalories * 0.2 / 4 } // 20% protein
    var fatTarget: Double { dailyCalories * 0.3 / 9 }     // 30% fat
    var carbsTarget: Double { dailyCalories * 0.5 / 4 }   // 50% carbs
}

enum GoalType: String, Codable, CaseIterable {
    case loseWeight = "减重"
    case gainMuscle = "增肌"
    case maintain = "维持"
}

enum FastingWindow: String, Codable, CaseIterable {
    case f16_8 = "16:8"
    case f14_10 = "14:10"
    case f12_12 = "12:12"
}

// MARK: - Report Data
struct DailySummary {
    var date: Date
    var totalCalories: Double
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var waterIntake: Int
}
