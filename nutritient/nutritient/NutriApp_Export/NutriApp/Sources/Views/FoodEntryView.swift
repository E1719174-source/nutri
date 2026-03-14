import SwiftUI

struct FoodEntryView: View {
    @StateObject private var viewModel = FoodEntryViewModel()
    @ObservedObject private var historyManager = HistoryManager.shared // Add HistoryManager
    @Environment(\.presentationMode) var presentationMode
    
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
                    TextField("搜索食物 (支持 AI 自动补全)", text: $viewModel.searchQuery)
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
                
                // Meal Type Picker
                Picker("餐次", selection: $viewModel.selectedMeal) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // AI Suggestion Card (Step 2)
                if let suggestion = viewModel.aiSuggestion {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("🤖 AI 发现新食物")
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
                                Text("确认添加")
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
                            Text("尝试输入完整食物名称，\nAI 将自动为您估算营养数据")
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
                                    Text("\(Int(food.calories)) kcal/100g · \(food.category)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("添加饮食")
            .navigationBarItems(
                leading: HStack {
                    Button(action: {
                        historyManager.undo()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(historyManager.canUndo ? .blue : .gray)
                    }
                    .disabled(!historyManager.canUndo)
                    
                    Button(action: {
                        historyManager.redo()
                    }) {
                        Image(systemName: "arrow.uturn.forward")
                            .foregroundColor(historyManager.canRedo ? .blue : .gray)
                    }
                    .disabled(!historyManager.canRedo)
                }
            )
            .sheet(item: $viewModel.selectedFood) { food in
                FoodDetailSheet(food: food, viewModel: viewModel)
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

struct FoodDetailSheet: View {
    let food: Food
    @ObservedObject var viewModel: FoodEntryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("食物信息")) {
                    HStack {
                        Text("名称")
                        Spacer()
                        Text(food.name)
                    }
                    HStack {
                        Text("分类")
                        Spacer()
                        Text(food.category)
                    }
                    HStack {
                        Text("单位热量")
                        Spacer()
                        Text("\(Int(food.calories)) kcal/100g")
                    }
                }
                
                Section(header: Text("营养成分 (每100g)")) {
                    HStack {
                        Text("蛋白质")
                        Spacer()
                        Text(String(format: "%.1fg", food.protein))
                    }
                    HStack {
                        Text("脂肪")
                        Spacer()
                        Text(String(format: "%.1fg", food.fat))
                    }
                    HStack {
                        Text("碳水")
                        Spacer()
                        Text(String(format: "%.1fg", food.carbs))
                    }
                }
                
                Section(header: Text("摄入量")) {
                    if let unitW = food.unitWeight, let unitName = food.unitName {
                        Toggle("按数量记录", isOn: $viewModel.useUnit)
                            .onChange(of: viewModel.useUnit) { shouldUseUnit, _ in
                                if shouldUseUnit {
                                    viewModel.updateQuantityFromWeight()
                                } else {
                                    viewModel.updateWeightFromQuantity()
                                }
                            }
                        
                        if viewModel.useUnit {
                            HStack {
                                TextField("数量", text: $viewModel.quantity)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: viewModel.quantity) { _, _ in
                                        viewModel.updateWeightFromQuantity()
                                    }
                                Text(unitName)
                                Spacer()
                                Text("≈ \(viewModel.weight)g")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            HStack {
                                TextField("重量", text: $viewModel.weight)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: viewModel.weight) { _, _ in
                                        viewModel.updateQuantityFromWeight()
                                    }
                                Text("克")
                            }
                        }
                    } else {
                        HStack {
                            TextField("重量", text: $viewModel.weight)
                                .keyboardType(.decimalPad)
                            Text("克")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        viewModel.addRecord()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("确认添加")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.green)
                }
            }
            .navigationTitle("记录详情")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
