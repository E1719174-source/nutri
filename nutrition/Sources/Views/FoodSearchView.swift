import SwiftUI

struct RecordView: View {
    @EnvironmentObject var viewModel: DietViewModel
    @State private var searchText = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedFood: FoodItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("搜索食物 (支持 AI 自动补全)", text: $searchText, onCommit: {
                        viewModel.searchFood(query: searchText)
                    })
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Meal Type Selector
                HStack {
                    ForEach(MealType.allCases) { type in
                        Button(action: {
                            selectedMealType = type
                        }) {
                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedMealType == type ? .bold : .regular)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedMealType == type ? Color.white : Color.clear)
                                .foregroundColor(selectedMealType == type ? .black : .gray)
                                .cornerRadius(8)
                                .shadow(color: selectedMealType == type ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .padding(4)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom)
                
                if viewModel.isSearching {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if viewModel.searchResults.isEmpty {
                    Spacer()
                } else {
                    List(viewModel.searchResults) { food in
                        Button(action: {
                            selectedFood = food
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(food.name)
                                        .font(.headline)
                                    Text("\(Int(food.calories)) kcal / \(food.amount)\(food.unit.rawValue)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("添加饮食")
            .sheet(item: $selectedFood) { food in
                FoodDetailView(food: food, mealType: selectedMealType, onAdd: { addedFood in
                    viewModel.addFood(addedFood, to: selectedMealType)
                    // Optional: Show success message or clear search
                    searchText = ""
                    viewModel.searchResults = []
                })
            }
        }
    }
}

// Keep FoodDetailView as is, or move to a separate file if needed. 
// For now, I'll include it here to ensure it compiles, reusing the existing logic.
struct FoodDetailView: View {
    @State private var food: FoodItem
    let mealType: MealType
    let onAdd: (FoodItem) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    init(food: FoodItem, mealType: MealType, onAdd: @escaping (FoodItem) -> Void) {
        _food = State(initialValue: food)
        self.mealType = mealType
        self.onAdd = onAdd
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    HStack {
                        Text("名称")
                        Spacer()
                        Text(food.name)
                    }
                    HStack {
                        Text("份量")
                        Spacer()
                        TextField("数量", value: $food.amount, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(food.unit.rawValue)
                    }
                }
                
                Section(header: Text("营养成分 (基于当前份量)")) {
                    HStack {
                        Text("热量")
                        Spacer()
                        Text("\(Int(food.totalCalories)) kcal")
                    }
                    HStack {
                        Text("蛋白质")
                        Spacer()
                        Text("\(String(format: "%.1f", food.totalProtein)) g")
                    }
                    HStack {
                        Text("脂肪")
                        Spacer()
                        Text("\(String(format: "%.1f", food.totalFat)) g")
                    }
                    HStack {
                        Text("碳水")
                        Spacer()
                        Text("\(String(format: "%.1f", food.totalCarbs)) g")
                    }
                }
                
                Button(action: {
                    onAdd(food)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("确认添加")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("食物详情")
            .navigationBarItems(leading: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
