import Foundation

// MARK: - Nutrition Calculator Service
class NutritionCalculator {
    
    // Constants
    static let MIN_SAFE_CALORIES: Double = 1200.0
    static let CALORIES_PER_KG_FAT: Double = 7700.0 // Approx calories to burn 1kg fat
    
    // MARK: - BMR Calculation (Mifflin-St Jeor)
    static func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double {
        // Formula: (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + s
        // s is +5 for males and -161 for females
        let s = (gender == .male) ? 5.0 : -161.0
        let bmr = (10.0 * weight) + (6.25 * height) - (5.0 * Double(age)) + s
        return max(bmr, 0) // Ensure non-negative
    }
    
    // MARK: - TDEE Calculation
    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        let multipliers: [ActivityLevel: Double] = [
            .sedentary: 1.2,
            .light: 1.375,
            .moderate: 1.55,
            .active: 1.725,
            .athlete: 1.9
        ]
        return bmr * (multipliers[activityLevel] ?? 1.2)
    }
    
    // MARK: - Goal Adjustment
    // Returns: (Daily Calorie Budget, Weekly Weight Change in kg, Warning Message?)
    static func calculateDailyBudget(
        user: User,
        goalType: GoalType,
        targetWeight: Double?,
        targetDate: Date?
    ) -> (calories: Double, weeklyChange: Double, warning: String?) {
        
        let age = Calendar.current.dateComponents([.year], from: user.birthDate, to: Date()).year ?? 25
        let bmr = calculateBMR(weight: user.weight, height: user.height, age: age, gender: user.gender)
        let tdee = calculateTDEE(bmr: bmr, activityLevel: user.activityLevel)
        
        var dailyCalories = tdee
        var weeklyChange = 0.0
        var warning: String? = nil
        
        switch goalType {
        case .maintain:
            dailyCalories = tdee
            weeklyChange = 0.0
            
        case .gainMuscle:
            // Surplus for muscle gain (conservative)
            dailyCalories = tdee + 300
            weeklyChange = 300 * 7 / CALORIES_PER_KG_FAT // Approx gain
            
        case .loseWeight:
            if let targetW = targetWeight, let targetD = targetDate {
                // Advanced Calculation based on Target Date
                let totalLossNeeded = user.weight - targetW
                guard totalLossNeeded > 0 else {
                    // Already at or below target
                    return (tdee, 0, "您当前的体重已低于或等于目标体重。")
                }
                
                let days = Calendar.current.dateComponents([.day], from: Date(), to: targetD).day ?? 1
                let weeks = Double(max(days, 1)) / 7.0
                
                // Required weekly loss
                let requiredWeeklyLoss = totalLossNeeded / weeks
                weeklyChange = -requiredWeeklyLoss
                
                // Calculate deficit
                let dailyDeficit = (requiredWeeklyLoss * CALORIES_PER_KG_FAT) / 7.0
                dailyCalories = tdee - dailyDeficit
                
                // Safety Checks
                if requiredWeeklyLoss > 1.0 {
                    warning = "目标设定过于激进（每周减重超过1kg），建议延长达成时间。"
                }
            } else {
                // Default Moderate Deficit (0.5kg / week)
                let deficit = 500.0
                dailyCalories = tdee - deficit
                weeklyChange = -0.5
            }
        }
        
        // Safety Threshold Check
        if dailyCalories < MIN_SAFE_CALORIES {
            warning = warning ?? "计算出的热量低于最低安全阈值 (\(Int(MIN_SAFE_CALORIES)) kcal)，已自动调整为安全值。"
            dailyCalories = MIN_SAFE_CALORIES
        }
        
        return (dailyCalories, weeklyChange, warning)
    }
}
