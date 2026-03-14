import SwiftUI

struct LoginView: View {
    @StateObject var appViewModel: AppViewModel
    @ObservedObject var userManager = UserManager.shared
    
    @State private var phone = ""
    @State private var code = ""
    @State private var isRegistering = false
    
    // Registration Fields
    @State private var nickname = ""
    @State private var gender: Gender = .male
    @State private var height = ""
    @State private var weight = ""
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var goalType: GoalType = .maintain
    
    @State private var showAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer().frame(height: 50)
                
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                
                Text(isRegistering ? "新用户注册" : "Nutri 登录")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                VStack(spacing: 20) {
                    TextField("手机号", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    SecureField("验证码 (任意输入)", text: $code)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if isRegistering {
                        Group {
                            TextField("昵称", text: $nickname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Picker("性别", selection: $gender) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Text(gender.rawValue).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            HStack {
                                TextField("身高 (cm)", text: $height)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                
                                TextField("体重 (kg)", text: $weight)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            Picker("活动强度", selection: $activityLevel) {
                                ForEach(ActivityLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            
                            Picker("初始目标", selection: $goalType) {
                                ForEach(GoalType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                if let error = userManager.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: handleAuth) {
                    Text(isRegistering ? "注册并登录" : "登录")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                Button(action: {
                    withAnimation {
                        isRegistering.toggle()
                        userManager.authError = nil
                    }
                }) {
                    Text(isRegistering ? "已有账号？去登录" : "没有账号？新用户注册")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
        }
        .onReceive(userManager.$currentUser) { user in
            if user != nil {
                appViewModel.isLoggedIn = true
            }
        }
    }
    
    func handleAuth() {
        if isRegistering {
            guard let h = Double(height), let w = Double(weight), !nickname.isEmpty else {
                userManager.authError = "请填写完整信息"
                return
            }
            
            let success = DataService.shared.register(
                phone: phone,
                nickname: nickname,
                gender: gender,
                height: h,
                weight: w,
                activityLevel: activityLevel,
                goalType: goalType
            )
            
            if success {
                // Login state handled by onReceive
            }
        } else {
            let success = DataService.shared.login(phone: phone)
            if success {
                // Login state handled by onReceive
            }
        }
    }
}
