import SwiftUI

struct ProfileView: View {
    @ObservedObject var dataService = DataService.shared
    @State private var showEditProfile = false
    @State private var showGoalSetting = false
    @State private var showClearHistoryAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info
                if let user = dataService.currentUser {
                    HStack {
                        if let avatarURL = UserManager.shared.getAvatarURL(for: user),
                           let imageData = try? Data(contentsOf: avatarURL),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(user.nickname)
                                .font(.headline)
                            Text("ID: \(user.phone)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    Section(header: Text("基本信息")) {
                        HStack {
                            Text("身高")
                            Spacer()
                            Text("\(Int(user.height)) cm")
                        }
                        HStack {
                            Text("体重")
                            Spacer()
                            Text("\(user.weight, specifier: "%.1f") kg")
                        }
                        HStack {
                            Text("BMI")
                            Spacer()
                            Text("\(user.bmi, specifier: "%.1f")")
                        }
                        HStack {
                            Text("活动强度")
                            Spacer()
                            Text(user.activityLevel.rawValue)
                        }
                        
                        Button("编辑") {
                            showEditProfile = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("健康目标")) {
                    if let goal = dataService.currentGoal {
                        HStack {
                            Text("目标类型")
                            Spacer()
                            Text(goal.type.rawValue)
                        }
                        HStack {
                            Text("每日热量预算")
                            Spacer()
                            Text("\(Int(goal.dailyCalories)) kcal")
                        }
                        HStack {
                            Text("每日饮水目标")
                            Spacer()
                            Text("\(goal.dailyWater) ml")
                        }
                        
                        Button("调整目标") {
                            showGoalSetting = true
                        }
                        .foregroundColor(.blue)
                    } else {
                        Button("设定目标") {
                            showGoalSetting = true
                        }
                    }
                }
                
                Section(header: Text("数据管理")) {
                    Button(action: { showClearHistoryAlert = true }) {
                        Text("清空所有饮食记录")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("退出登录") {
                        dataService.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("我的")
            .sheet(isPresented: $showEditProfile) {
                if let user = dataService.currentUser {
                    ProfileEditView(user: Binding(
                        get: { user },
                        set: { dataService.currentUser = $0 }
                    ))
                }
            }
            .sheet(isPresented: $showGoalSetting) {
                GoalSettingView()
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
        }
    }
}
