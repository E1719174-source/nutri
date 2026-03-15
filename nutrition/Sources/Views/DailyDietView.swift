import SwiftUI

struct DailyDietView: View {
    @EnvironmentObject var dietViewModel: DietViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("你好，\(userViewModel.userProfile?.nickname ?? "Yutong")")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("今天也要吃得健康哦！")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "person.crop.circle.fill") // Placeholder for avatar
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Nutrition Card
                    if let user = userViewModel.userProfile {
                        NutritionCard(current: dietViewModel.currentRecord, target: user)
                    } else {
                        Text("请先完善个人信息")
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Create Recipe Button
                    Button(action: {
                        // Action for creating recipe
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("创建食谱")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.orange)
                        .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    
                    // Water Tracker
                    WaterTrackerCard(
                        current: dietViewModel.currentRecord.waterIntake,
                        target: dietViewModel.currentRecord.waterTarget,
                        onAdd: { amount in
                            dietViewModel.updateWaterIntake(amount: amount)
                        }
                    )
                    
                    // Daily Diet List
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("今日饮食")
                                .font(.headline)
                            Spacer()
                            Button("清空") {
                                dietViewModel.clearAllRecords()
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        ForEach(MealType.allCases) { mealType in
                            if let meal = dietViewModel.currentRecord.meals.first(where: { $0.type == mealType }), !meal.foods.isEmpty {
                                MealSectionView(mealType: mealType, meal: meal)
                            } else {
                                // Show empty meal section if desired, or hide it.
                                // Screenshot shows "Breakfast" with items.
                                // Let's show header for all meal types to encourage adding? 
                                // Or only show if there are items. The screenshot implies a list where added items appear.
                                // If I want to exactly match the screenshot where "Breakfast" is shown with items:
                                MealSectionView(mealType: mealType, meal: dietViewModel.currentRecord.meals.first(where: { $0.type == mealType }))
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

struct NutritionCard: View {
    let current: DailyRecord
    let target: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("今日热量")
                    .font(.headline)
                Spacer()
                Text("\(Int(current.totalCalories)) / \(Int(target.dailyCalorieTarget)) kcal")
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: current.totalCalories, total: target.dailyCalorieTarget)
                .accentColor(current.totalCalories > target.dailyCalorieTarget ? .red : .gray) // Gray or Green? Screenshot bar looks gray/filled
            
            HStack {
                MacroStatView(name: "蛋白质", current: current.totalProtein, target: target.proteinTarget, color: .blue)
                Spacer()
                MacroStatView(name: "碳水", current: current.totalCarbs, target: target.carbTarget, color: .orange)
                Spacer()
                MacroStatView(name: "脂肪", current: current.totalFat, target: target.fatTarget, color: .yellow)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct MacroStatView: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
            HStack(spacing: 2) {
                Text("\(Int(current))")
                    .font(.headline)
                    .foregroundColor(color)
                Text("/\(Int(target))g")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            ProgressView(value: current, total: target)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .frame(width: 100) // Fixed width for alignment
    }
}

struct WaterTrackerCard: View {
    let current: Double
    let target: Double
    let onAdd: (Double) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text("饮水记录")
                    .font(.headline)
                Text("已喝 \(Int(current))ml / 目标 \(Int(target))ml")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { onAdd(200) }) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(15)
        .padding(.horizontal)
        
        // "View Details" link could be added below or part of the card
        HStack {
            Button("查看详情") {
                // Action
            }
            .font(.caption)
            .foregroundColor(.blue)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, -10) // Pull up closer to card
    }
}

struct MealSectionView: View {
    let mealType: MealType
    let meal: MealRecord?
    
    var totalCalories: Double {
        meal?.totalCalories ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let meal = meal, !meal.foods.isEmpty {
                HStack {
                    Text(mealType.rawValue)
                        .font(.headline)
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(Int(totalCalories)) kcal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                ForEach(meal.foods) { food in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(food.name)
                                .font(.body)
                            Text("\(Int(food.amount))\(food.unit.rawValue)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(Int(food.totalCalories)) kcal")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            } 
            // If empty, we might skip showing it or show "No records"
            // Screenshot only shows Breakfast which has items.
            // Let's only show if it has items for now, based on logic in parent.
        }
    }
}
