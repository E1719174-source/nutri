import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    // We might need DietViewModel to clear records
    @EnvironmentObject var dietViewModel: DietViewModel 
    @State private var isEditingProfile = false
    @State private var isAdjustingGoal = false
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("个人中心")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if let user = userViewModel.userProfile {
                        // Basic Info Section
                        VStack(spacing: 0) {
                            SectionHeader(title: "基本信息", actionTitle: "编辑") {
                                isEditingProfile = true
                            }
                            
                            InfoRow(label: "昵称", value: user.nickname)
                            Divider().padding(.leading)
                            InfoRow(label: "手机号", value: user.id) // Using ID as phone
                        }
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Body Data Section
                        VStack(spacing: 0) {
                            SectionHeader(title: "身体数据", actionTitle: nil, action: nil)
                            
                            InfoRow(label: "性别", value: user.gender.rawValue)
                            Divider().padding(.leading)
                            InfoRow(label: "身高", value: "\(Int(user.height)) cm")
                            Divider().padding(.leading)
                            InfoRow(label: "体重", value: "\(Int(user.weight)) kg")
                            Divider().padding(.leading)
                            InfoRow(label: "BMI", value: String(format: "%.1f", user.bmi), valueColor: .blue)
                            Divider().padding(.leading)
                            InfoRow(label: "活动强度", value: user.activityLevel.rawValue + "活动") // e.g. "中度活动"
                        }
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Goal Section
                        VStack(spacing: 0) {
                            SectionHeader(title: "目标", actionTitle: "调整") {
                                isAdjustingGoal = true
                            }
                            
                            InfoRow(label: "目标类型", value: user.goal.rawValue, valueColor: .purple)
                            Divider().padding(.leading)
                            InfoRow(label: "每日热量预算", value: "\(Int(user.dailyCalorieTarget)) kcal")
                        }
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Data Management Section
                        VStack(spacing: 0) {
                            SectionHeader(title: "数据管理", actionTitle: nil, action: nil)
                            
                            Button(action: {
                                showingClearConfirmation = true
                            }) {
                                HStack {
                                    Text("清空所有饮食记录")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                    } else {
                        Text("请先完善个人信息")
                            .padding()
                        Button("完善信息") {
                            isEditingProfile = true
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(viewModel: userViewModel)
            }
            .sheet(isPresented: $isAdjustingGoal) {
                EditProfileView(viewModel: userViewModel) // Reuse same view for now
            }
            .alert(isPresented: $showingClearConfirmation) {
                Alert(
                    title: Text("确认清空"),
                    message: Text("确定要清空所有饮食记录吗？此操作不可撤销。"),
                    primaryButton: .destructive(Text("清空")) {
                        dietViewModel.clearAllRecords()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 15)
        .padding(.bottom, 5)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
        .padding()
    }
}

struct EditProfileView: View {
    @ObservedObject var viewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Form States
    @State private var nickname: String = "Yutong"
    @State private var height: Double = 170
    @State private var weight: Double = 65
    @State private var gender: Gender = .female
    @State private var activityLevel: ActivityLevel = .medium
    @State private var goal: DietGoal = .maintain
    @State private var age: Int = 25
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本资料")) {
                    TextField("昵称", text: $nickname)
                    HStack {
                        Text("身高 (cm)")
                        Spacer()
                        TextField("cm", value: $height, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("体重 (kg)")
                        Spacer()
                        TextField("kg", value: $weight, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("性别", selection: $gender) {
                        Text("男").tag(Gender.male)
                        Text("女").tag(Gender.female)
                    }
                    HStack {
                        Text("年龄")
                        Spacer()
                        TextField("岁", value: $age, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("活动与目标")) {
                    Picker("活动强度", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Picker("饮食目标", selection: $goal) {
                        ForEach(DietGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }
                
                Button(action: {
                    viewModel.saveProfile(
                        height: height,
                        weight: weight,
                        gender: gender,
                        activityLevel: activityLevel,
                        goal: goal,
                        age: age,
                        nickname: nickname
                    )
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("保存设置")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let user = viewModel.userProfile {
                    self.nickname = user.nickname
                    self.height = user.height
                    self.weight = user.weight
                    self.gender = user.gender
                    self.activityLevel = user.activityLevel
                    self.goal = user.goal
                    self.age = user.age
                }
            }
        }
    }
}
