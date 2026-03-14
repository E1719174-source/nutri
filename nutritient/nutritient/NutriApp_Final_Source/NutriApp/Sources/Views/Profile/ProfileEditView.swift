import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Binding var user: User
    @Environment(\.presentationMode) var presentationMode
    
    // Local state for editing
    @State private var nickname: String
    @State private var gender: Gender
    @State private var height: String
    @State private var weight: String
    @State private var activityLevel: ActivityLevel
    
    @State private var showQuiz = false // State for quiz sheet
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    
    init(user: Binding<User>) {
        self._user = user
        _nickname = State(initialValue: user.wrappedValue.nickname)
        _gender = State(initialValue: user.wrappedValue.gender)
        _height = State(initialValue: String(format: "%.0f", user.wrappedValue.height))
        _weight = State(initialValue: String(format: "%.1f", user.wrappedValue.weight))
        _activityLevel = State(initialValue: user.wrappedValue.activityLevel)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("头像")) {
                    HStack {
                        Spacer()
                        Button(action: { showImagePicker = true }) {
                            if let image = inputImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let avatarURL = UserManager.shared.getAvatarURL(for: user),
                                      let imageData = try? Data(contentsOf: avatarURL),
                                      let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("基本信息")) {
                    TextField("昵称", text: $nickname)
                    
                    Picker("性别", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("身体数据")) {
                    HStack {
                        TextField("身高", text: $height)
                            .keyboardType(.decimalPad)
                        Text("cm")
                    }
                    
                    HStack {
                        TextField("体重", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                    }
                    
                    HStack {
                        Text("活动强度")
                        Spacer()
                        Button(action: { showQuiz = true }) {
                            Text("不知道怎么选？做个测试")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Picker("活动强度", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.rawValue)
                                    .font(.body)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .tag(level)
                        }
                    }
                }
                
                Section {
                    Button(action: saveProfile) {
                        Text("保存修改")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.green)
                }
            }
            .navigationTitle("编辑个人资料")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showQuiz) {
                ActivityQuizView(selectedActivityLevel: $activityLevel)
            }
            .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        // Save image immediately when selected
        if let url = saveImageToTemporaryFile(image: inputImage) {
            UserManager.shared.updateAvatar(url: url)
            // Trigger UI update by updating user binding (optional, as we display inputImage directly)
        }
    }
    
    private func saveImageToTemporaryFile(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_avatar.jpg")
        try? data.write(to: tempURL)
        return tempURL
    }
    
    private func saveProfile() {
        guard let h = Double(height), let w = Double(weight) else { return }
        
        var updatedUser = user
        updatedUser.nickname = nickname
        updatedUser.gender = gender
        updatedUser.height = h
        updatedUser.weight = w
        updatedUser.activityLevel = activityLevel
        
        // Save via DataService/UserManager
        // Here we update the binding which updates the model, but we need to persist it
        // The binding setter in ProfileView does: dataService.currentUser = $0
        // And DataService calls UserManager to save.
        
        user = updatedUser
        
        // Also trigger recalculation of goals if needed (handled in DataService.updateProfile if we had it, or here)
        DataService.shared.updateGoalType(DataService.shared.currentGoal?.type ?? .maintain)
        
        presentationMode.wrappedValue.dismiss()
    }
}
