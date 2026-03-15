import Foundation

class UserViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isSetupRequired: Bool = false
    
    private let database = DatabaseService.shared
    
    init() {
        self.userProfile = database.currentUser
        if self.userProfile == nil {
            isSetupRequired = true
        }
    }
    
    func saveProfile(height: Double, weight: Double, gender: Gender, activityLevel: ActivityLevel, goal: DietGoal, age: Int, nickname: String = "Yutong") {
        let profile = UserProfile(
            id: "18190830317", // Mock phone number from screenshot
            nickname: nickname,
            height: height,
            weight: weight,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal,
            age: age
        )
        self.userProfile = profile
        database.saveUser(profile)
        isSetupRequired = false
    }
    
    func updateWeight(_ newWeight: Double) {
        guard var profile = userProfile else { return }
        let oldWeight = profile.weight
        profile.weight = newWeight
        
        // Add history
        let history = ProfileHistory(
            date: Date(),
            key: "weight",
            oldValue: String(oldWeight),
            newValue: String(newWeight)
        )
        profile.history.append(history)
        
        self.userProfile = profile
        database.saveUser(profile)
    }
}
