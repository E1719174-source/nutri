import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var dataService = DataService.shared
    @State private var showWaterSheet = false
    @State private var showClearHistoryAlert = false
    @State private var showCreateRecipe = false // State for Recipe View
    
    // For single item deletion
    @State private var recordToDelete: FoodRecord?
    @State private var showDeleteConfirmation = false
    
    // MARK: - Avatar Helper
    func getAvatarImage() -> UIImage? {
        if let user = dataService.currentUser,
           let url = UserManager.shared.getAvatarURL(for: user),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("你好，\(dataService.currentUser?.nickname ?? "用户")")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("今天也要吃得健康哦！")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if let avatar = getAvatarImage() {
                            Image(uiImage: avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    // Dashboard Card
                    let summary = dataService.getTodaySummary()
                    let goal = dataService.currentGoal
                    
                    DashboardCard(summary: summary, goal: goal)
                    
                    // Quick Actions (Create Recipe)
                    HStack {
                        Spacer()
                        Button(action: { showCreateRecipe = true }) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("创建食谱")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        }
                        .padding(.trailing)
                    }
                    
                    // Water Tracker
                    WaterTrackerView(
                        current: dataService.waterIntake,
                        goal: goal?.dailyWater ?? 2000,
                        showSheet: $showWaterSheet
                    )
                    
                    // Recent Records (Grouped by Meal)
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("今日饮食")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            if !dataService.foodRecords.isEmpty {
                                Button(action: { showClearHistoryAlert = true }) {
                                    Text("清空")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(6)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        let groupedRecords = Dictionary(grouping: dataService.foodRecords) { $0.mealType }
                        let sortedKeys = groupedRecords.keys.sorted()
                        
                        if dataService.foodRecords.isEmpty {
                             Text("还没有记录，快去添加吧！")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(sortedKeys, id: \.self) { mealType in
                                let records = groupedRecords[mealType] ?? []
                                let mealCalories = records.reduce(0) { $0 + $1.calories }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(mealType.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        Spacer()
                                        Text("\(Int(mealCalories)) kcal")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal)
                                    
                                    ForEach(records) { record in
                                        RecordRow(record: record)
                                            .onTapGesture {
                                                recordToDelete = record
                                                showDeleteConfirmation = true
                                            }
                                    }
                                }
                                .padding(.bottom, 10)
                            }
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showWaterSheet) {
                WaterInputSheet()
            }
            .sheet(isPresented: $showCreateRecipe) {
                CreateRecipeView()
            }
            .alert(isPresented: $showClearHistoryAlert) {
                Alert(
                    title: Text("确认清空？"),
                    message: Text("此操作将删除所有的饮食和饮水记录，且无法恢复。"),
                    primaryButton: .destructive(Text("清空")) {
                        dataService.clearHistory()
                    },
                    secondaryButton: .cancel()
                )
            }
            // Separate alert for single item deletion
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("撤销记录"),
                    message: Text("确定要删除这条 \(recordToDelete?.foodName ?? "") 记录吗？"),
                    primaryButton: .destructive(Text("删除")) {
                        if let record = recordToDelete {
                            dataService.removeRecord(withId: record.id)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct DashboardCard: View {
    let summary: DailySummary
    let goal: HealthGoal?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("今日热量")
                    .font(.headline)
                Spacer()
                Text("\(Int(summary.totalCalories)) / \(Int(goal?.dailyCalories ?? 2000)) kcal")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: min(summary.totalCalories / (goal?.dailyCalories ?? 2000), 1.0))
                .accentColor(.green)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack(spacing: 15) {
                NutrientInfo(title: "蛋白质", value: summary.totalProtein, target: goal?.proteinTarget ?? 100, color: .blue)
                NutrientInfo(title: "碳水", value: summary.totalCarbs, target: goal?.carbsTarget ?? 250, color: .orange)
                NutrientInfo(title: "脂肪", value: summary.totalFat, target: goal?.fatTarget ?? 60, color: .yellow)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct NutrientInfo: View {
    let title: String
    let value: Double
    let target: Double
    let color: Color
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", value))
                    .font(.headline)
                    .foregroundColor(color)
                Text("/\(Int(target))g")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WaterTrackerView: View {
    let current: Int
    let goal: Int
    @Binding var showSheet: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("饮水记录")
                        .font(.headline)
                    Text("已喝 \(current)ml / 目标 \(goal)ml")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Button(action: {
                    showSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                }
            }
            
            Divider().padding(.vertical, 8)
            
            NavigationLink(destination: WaterHistoryView()) {
                HStack {
                    Text("查看详情")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct WaterInputSheet: View {
    @State private var amountString = "250"
    @State private var date = Date()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("饮水量 (ml)")) {
                    TextField("输入毫升数", text: $amountString)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("时间")) {
                    DatePicker("饮水时间", selection: $date, displayedComponents: [.hourAndMinute])
                }
                
                Button("确认添加") {
                    if let amount = Int(amountString) {
                        DataService.shared.addWater(amount: amount, date: date)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.blue)
            }
            .navigationTitle("记录饮水")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct WaterHistoryView: View {
    @ObservedObject var dataService = DataService.shared
    
    var body: some View {
        List {
            ForEach(dataService.getTodayWaterRecords()) { record in
                HStack {
                    Text("\(record.amount) ml")
                        .font(.headline)
                    Spacer()
                    Text(record.date, style: .time)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("今日饮水记录")
    }
}

struct RecordRow: View {
    let record: FoodRecord
    @ObservedObject var dataService = DataService.shared
    @State private var isExpanded = false
    @State private var isEditing = false
    @State private var editWeight = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Main Row
            HStack {
                VStack(alignment: .leading) {
                    Text(record.foodName)
                        .font(.body)
                    Text("\(Int(record.weight))g")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(record.calories)) kcal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if !isEditing {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
            
            // Expanded Detail View
            if isExpanded {
                Divider()
                
                if isEditing {
                    // Editing Mode
                    HStack {
                        TextField("重量", text: $editWeight)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("g")
                        
                        Spacer()
                        
                        Button("取消") {
                            withAnimation { isEditing = false }
                        }
                        .foregroundColor(.gray)
                        
                        Button("保存") {
                            saveEdit()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                } else {
                    // Detail Display Mode
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 20) {
                            NutrientDetailItem(title: "蛋白质", value: record.protein, color: .blue)
                            NutrientDetailItem(title: "脂肪", value: record.fat, color: .yellow)
                            NutrientDetailItem(title: "碳水", value: record.carbs, color: .orange)
                            // Fiber not in record yet, if added later:
                            // NutrientDetailItem(title: "纤维", value: record.fiber, color: .green)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                editWeight = String(format: "%.0f", record.weight)
                                withAnimation { isEditing = true }
                            }) {
                                Label("修改重量", systemImage: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            // Trash Icon moved here for consistency in expanded view
                            // But keeping it outside is also fine.
                            // Let's keep the outer trash interaction logic in parent for now
                            // Or handle delete request via callback if needed.
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
    
    private func saveEdit() {
        guard let newWeight = Double(editWeight), newWeight > 0 else { return }
        
        let ratio = newWeight / record.weight
        
        let updatedRecord = FoodRecord(
            id: record.id,
            foodId: record.foodId,
            foodName: record.foodName,
            weight: newWeight,
            calories: record.calories * ratio,
            protein: record.protein * ratio,
            fat: record.fat * ratio,
            carbs: record.carbs * ratio,
            recordDate: record.recordDate,
            mealType: record.mealType
        )
        
        dataService.updateRecord(updatedRecord)
        
        withAnimation {
            isEditing = false
            // isExpanded = false // Optional: auto close
        }
    }
}

struct NutrientDetailItem: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(String(format: "%.1fg", value))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}
