import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"
    
    var id: String { self.rawValue }
}

enum FoodUnit: String, Codable, CaseIterable {
    case gram = "克"
    case piece = "个"
    case box = "盒"
    case bottle = "瓶"
}

struct FoodItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var calories: Double // kcal per 100g or per unit
    var protein: Double // g
    var fat: Double // g
    var carbs: Double // g
    var fiber: Double // g
    var unit: FoodUnit
    var amount: Double // amount consumed
    
    // Calculated values based on amount
    var totalCalories: Double {
        if unit == .gram {
            return (calories * amount) / 100.0
        } else {
            return calories * amount
        }
    }
    
    var totalProtein: Double {
        if unit == .gram {
            return (protein * amount) / 100.0
        } else {
            return protein * amount
        }
    }
    
    var totalFat: Double {
        if unit == .gram {
            return (fat * amount) / 100.0
        } else {
            return fat * amount
        }
    }
    
    var totalCarbs: Double {
        if unit == .gram {
            return (carbs * amount) / 100.0
        } else {
            return carbs * amount
        }
    }
    
    var totalFiber: Double {
        if unit == .gram {
            return (fiber * amount) / 100.0
        } else {
            return fiber * amount
        }
    }
}
