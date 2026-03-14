import SwiftUI
import SwiftData

struct CreateRecipeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var foodRegistry = FoodRegistryService.shared
    
    @State private var recipeName = ""
    @State private var recipeDescription = "" // Optional
    @State private var servings = "1"
    
    // Ingredients List
    @State private var ingredients: [FoodRecord] = []
    
    // Search Sheet
    @State private var showFoodSearch = false
    
    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.protein }
    }
    
    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fat }
    }
    
    var totalCarbs: Double {
        ingredients.reduce(0) { $0 + $1.carbs }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("食谱信息")) {
                    TextField("食谱名称 (如: 番茄炒蛋)", text: $recipeName)
                    TextField("份数 (默认1份)", text: $servings)
                        .keyboardType(.numberPad)
                }
                
                Section(header: HStack {
                    Text("食材列表")
                    Spacer()
                    Button(action: { showFoodSearch = true }) {
                        Label("添加食材", systemImage: "plus")
                            .font(.caption)
                    }
                }) {
                    if ingredients.isEmpty {
                        Text("暂无食材，请添加")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(ingredients) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.foodName)
                                    Text("\(Int(item.weight))g")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("\(Int(item.calories)) kcal")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteIngredient)
                    }
                }
                
                Section(header: Text("营养总览 (整道菜)")) {
                    HStack {
                        Text("总热量")
                        Spacer()
                        Text("\(Int(totalCalories)) kcal")
                            .fontWeight(.bold)
                    }
                    HStack(spacing: 20) {
                        NutrientBadge(title: "蛋白质", value: totalProtein, color: .blue)
                        NutrientBadge(title: "脂肪", value: totalFat, color: .yellow)
                        NutrientBadge(title: "碳水", value: totalCarbs, color: .orange)
                    }
                    .padding(.vertical, 5)
                }
                
                Section {
                    Button(action: saveRecipe) {
                        Text("保存食谱")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.green)
                    .disabled(recipeName.isEmpty || ingredients.isEmpty)
                }
            }
            .navigationTitle("创建食谱")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showFoodSearch) {
                RecipeIngredientSearchView(onSelect: { record in
                    ingredients.append(record)
                    showFoodSearch = false
                })
            }
        }
    }
    
    private func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
    
    private func saveRecipe() {
        guard !recipeName.isEmpty, !ingredients.isEmpty else { return }
        
        let totalWeight = ingredients.reduce(0) { $0 + $1.weight }
        let servingCount = Double(servings) ?? 1.0
        
        // Calculate per 100g values for the Food model
        // If total weight is 500g, and total calories is 500kcal.
        // Then per 100g is 100kcal.
        let ratio = 100.0 / totalWeight
        
        let newRecipeFood = Food(
            id: UUID().uuidString,
            name: recipeName,
            calories: totalCalories * ratio,
            protein: totalProtein * ratio,
            fat: totalFat * ratio,
            carbs: totalCarbs * ratio,
            fiber: 0, // Simplified
            category: "自制食谱",
            unitWeight: totalWeight / servingCount, // Weight per serving
            unitName: "份",
            isRecipe: true,
            ingredients: ingredients
        )
        
        foodRegistry.confirmAddFood(newRecipeFood)
        presentationMode.wrappedValue.dismiss()
    }
}

struct NutrientBadge: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(String(format: "%.1f", value))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// Simplified Search View for Ingredients
struct RecipeIngredientSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = FoodEntryViewModel()
    var onSelect: (FoodRecord) -> Void
    
    // For editing AI suggestion
    @State private var editName: String = ""
    @State private var editCategory: String = ""
    @State private var editCalories: String = ""
    @State private var editProtein: String = ""
    @State private var editFat: String = ""
    @State private var editCarbs: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("搜索食材 (支持 AI 自动补全)", text: $viewModel.searchQuery)
                        .onChange(of: viewModel.searchQuery) { _, _ in
                            viewModel.search()
                        }
                    
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // AI Suggestion Card
                if let suggestion = viewModel.aiSuggestion {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("🤖 AI 发现新食材")
                                .font(.headline)
                                .foregroundColor(.purple)
                            Spacer()
                        }
                        
                        // Editable Fields
                        TextField("名称", text: $editName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("分类", text: $editCategory)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("热量 (kcal)")
                                    .font(.caption)
                                TextField("0", text: $editCalories)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            VStack(alignment: .leading) {
                                Text("蛋白质 (g)")
                                    .font(.caption)
                                TextField("0", text: $editProtein)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                viewModel.cancelAISuggestion()
                            }) {
                                Text("取消")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                confirmSuggestion(originalId: suggestion.id)
                            }) {
                                Text("确认并使用")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(12)
                    .padding()
                    .onAppear {
                        // Pre-fill fields
                        editName = suggestion.name
                        editCategory = suggestion.category
                        editCalories = String(format: "%.0f", suggestion.calories)
                        editProtein = String(format: "%.1f", suggestion.protein)
                        editFat = String(format: "%.1f", suggestion.fat)
                        editCarbs = String(format: "%.1f", suggestion.carbs)
                    }
                }
                // Results List
                else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                    VStack {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            Text("未找到匹配项")
                                .foregroundColor(.gray)
                                .padding()
                            Text("尝试输入完整食材名称，\nAI 将自动为您估算营养数据")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(viewModel.searchResults) { food in
                        Button(action: {
                            viewModel.selectedFood = food
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(food.name)
                                        .font(.headline)
                                    Text("\(Int(food.calories)) kcal/100g")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加食材")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(item: $viewModel.selectedFood) { food in
                RecipeIngredientDetailSheet(food: food, onAdd: { weight in
                    let ratio = weight / 100.0
                    let record = FoodRecord(
                        id: UUID(),
                        foodId: food.id,
                        foodName: food.name,
                        weight: weight,
                        calories: food.calories * ratio,
                        protein: food.protein * ratio,
                        fat: food.fat * ratio,
                        carbs: food.carbs * ratio,
                        recordDate: Date(),
                        mealType: .snack // Dummy
                    )
                    onSelect(record)
                })
            }
        }
    }
    
    func confirmSuggestion(originalId: String) {
        let newFood = Food(
            id: originalId, // Keep generated ID
            name: editName,
            calories: Double(editCalories) ?? 0,
            protein: Double(editProtein) ?? 0,
            fat: Double(editFat) ?? 0,
            carbs: Double(editCarbs) ?? 0,
            fiber: 0, // Simplified
            category: editCategory
        )
        viewModel.confirmAISuggestion(editedFood: newFood)
    }
}

struct RecipeIngredientDetailSheet: View {
    let food: Food
    var onAdd: (Double) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var weightString = "100"
    @State private var quantityString = "1"
    @State private var useUnit = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("食材: \(food.name)")) {
                    if let unitW = food.unitWeight, let unitName = food.unitName {
                        Toggle("按数量记录", isOn: $useUnit)
                            .onChange(of: useUnit) { shouldUseUnit, _ in
                                if shouldUseUnit {
                                    if let w = Double(weightString) {
                                        quantityString = String(format: "%.1f", w / unitW)
                                    }
                                } else {
                                    if let q = Double(quantityString) {
                                        weightString = String(format: "%.0f", q * unitW)
                                    }
                                }
                            }
                        
                        if useUnit {
                            HStack {
                                TextField("数量", text: $quantityString)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: quantityString) { _, _ in
                                        if let q = Double(quantityString) {
                                            weightString = String(format: "%.0f", q * unitW)
                                        }
                                    }
                                Text(unitName)
                                Spacer()
                                Text("≈ \(weightString)g")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            HStack {
                                TextField("重量", text: $weightString)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: weightString) { _, _ in
                                        if let w = Double(weightString) {
                                            quantityString = String(format: "%.1f", w / unitW)
                                        }
                                    }
                                Text("克")
                            }
                        }
                    } else {
                        HStack {
                            TextField("重量", text: $weightString)
                                .keyboardType(.decimalPad)
                            Text("克")
                        }
                    }
                }
                
                Button("确认添加") {
                    if let w = Double(weightString) {
                        onAdd(w)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("输入用量")
        }
    }
}
