import SwiftUI

struct GoalSettingView: View {
    @ObservedObject var dataService = DataService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedGoal: GoalType = .maintain
    @State private var targetWeight: String = ""
    @State private var targetDate = Date().addingTimeInterval(86400 * 30) // Default 30 days later
    @State private var useAdvancedSettings = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择目标")) {
                    Picker("目标类型", selection: $selectedGoal) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedGoal == .loseWeight {
                    Section(header: Text("减重目标")) {
                        HStack {
                            TextField("目标体重", text: $targetWeight)
                                .keyboardType(.decimalPad)
                            Text("kg")
                        }
                        
                        Toggle("设定达成日期", isOn: $useAdvancedSettings)
                        
                        if useAdvancedSettings {
                            DatePicker("达成日期", selection: $targetDate, in: Date()..., displayedComponents: .date)
                        }
                    }
                }
                
                Section {
                    Button(action: saveGoal) {
                        Text("保存目标")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.green)
                }
            }
            .navigationTitle("设定健康目标")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let current = dataService.currentGoal {
                    selectedGoal = current.type
                    if let w = current.targetWeight {
                        targetWeight = String(format: "%.1f", w)
                    }
                }
            }
        }
    }
    
    private func saveGoal() {
        let tWeight = Double(targetWeight)
        let tDate = useAdvancedSettings ? targetDate : nil
        
        dataService.updateGoalType(selectedGoal, targetWeight: tWeight, targetDate: tDate)
        presentationMode.wrappedValue.dismiss()
    }
}
