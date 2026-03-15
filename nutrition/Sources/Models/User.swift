import Foundation

enum Gender: String, Codable {
    case male = "男"
    case female = "女"
}

enum ActivityLevel: String, Codable, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"
    
    var multiplier: Double {
        switch self {
        case .low: return 1.2
        case .medium: return 1.375
        case .high: return 1.55
        }
    }
}

enum DietGoal: String, Codable, CaseIterable {
    case weightLoss = "减重"
    case maintain = "维持"
    case muscleGain = "增肌"
    
    var calorieAdjustment: Double {
        switch self {
        case .weightLoss: return -500
        case .maintain: return 0
        case .muscleGain: return 300
        }
    }
}

struct UserProfile: Codable {
    var id: String // Phone number
    var nickname: String = "Yutong" // Default or from input
    var height: Double // cm
    var weight: Double // kg
    var gender: Gender
    var activityLevel: ActivityLevel
    var goal: DietGoal
    var age: Int
    
    // History tracking
    var history: [ProfileHistory] = []
    
    // BMI
    var bmi: Double {
        let heightInMeters = height / 100.0
        guard heightInMeters > 0 else { return 0 }
        return weight / (heightInMeters * heightInMeters)
    }
    
    // Calculated BMR (Mifflin-St Jeor Equation)
    var bmr: Double {
        let s = (gender == .male ? 5.0 : -161.0)
        return (10 * weight) + (6.25 * height) - (5 * Double(age)) + s
    }
    
    // TDEE (Total Daily Energy Expenditure)
    var tdee: Double {
        return bmr * activityLevel.multiplier
    }
    
    // Daily Calorie Target
    var dailyCalorieTarget: Double {
        let target = tdee + goal.calorieAdjustment
        // Minimum calorie check (e.g., 1200 for women, 1500 for men)
        let minCalories = (gender == .male ? 1500.0 : 1200.0)
        return max(target, minCalories)
    }
    
    // Macro Targets
    var proteinTarget: Double {
        let factor = (goal == .muscleGain ? 1.6 : 1.2)
        return weight * factor
    }
    
    var fatTarget: Double {
        // 25-30% of total calories. Let's use 27.5% average or simple 25%
        return (dailyCalorieTarget * 0.25) / 9.0
    }
    
    var carbTarget: Double {
        // Remaining calories
        let proteinCals = proteinTarget * 4
        let fatCals = fatTarget * 9
        let remaining = dailyCalorieTarget - proteinCals - fatCals
        return max(0, remaining / 4.0)
    }
}

struct ProfileHistory: Codable {
    var date: Date
    var key: String
    var oldValue: String
    var newValue: String
}
