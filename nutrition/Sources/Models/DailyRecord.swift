import Foundation

struct DailyRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var meals: [MealRecord]
    var waterIntake: Double // ml
    var waterTarget: Double = 2000.0
    
    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.totalCalories }
    }
    
    var totalProtein: Double {
        meals.reduce(0) { $0 + $1.totalProtein }
    }
    
    var totalFat: Double {
        meals.reduce(0) { $0 + $1.totalFat }
    }
    
    var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.totalCarbs }
    }
    
    var totalFiber: Double {
        meals.reduce(0) { $0 + $1.totalFiber }
    }
}

struct MealRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var type: MealType
    var foods: [FoodItem]
    
    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.totalCalories }
    }
    
    var totalProtein: Double {
        foods.reduce(0) { $0 + $1.totalProtein }
    }
    
    var totalFat: Double {
        foods.reduce(0) { $0 + $1.totalFat }
    }
    
    var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.totalCarbs }
    }
    
    var totalFiber: Double {
        foods.reduce(0) { $0 + $1.totalFiber }
    }
}
