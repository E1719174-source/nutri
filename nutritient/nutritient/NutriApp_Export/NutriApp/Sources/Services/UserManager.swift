import Foundation
import UIKit

// MARK: - User Manager
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var authError: String?
    
    private let usersKey = "NutriUsers"
    private let currentUserIdKey = "CurrentUserId"
    
    init() {
        loadCurrentUser()
    }
    
    // MARK: - Avatar
    func updateAvatar(url: URL) {
        guard var user = currentUser else { return }
        
        do {
            // Save image to documents directory
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "avatar_\(user.id).jpg"
            let destinationURL = documents.appendingPathComponent(fileName)
            
            // If copying from a picker URL, we need to access security scoped resource or just copy data
            if url.startAccessingSecurityScopedResource() {
                let data = try Data(contentsOf: url)
                try data.write(to: destinationURL)
                url.stopAccessingSecurityScopedResource()
            } else {
                let data = try Data(contentsOf: url)
                try data.write(to: destinationURL)
            }
            
            // Update user model with local path filename (not full path, to be safe across launches)
            user.avatarUrl = fileName
            updateUser(user)
            
        } catch {
            print("Failed to save avatar: \(error)")
        }
    }
    
    func getAvatarURL(for user: User) -> URL? {
        guard let fileName = user.avatarUrl else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }
    
    // MARK: - Internal Helpers
    
    private func loginUser(_ user: User) {
        currentUser = user
        UserDefaults.standard.set(user.id, forKey: currentUserIdKey)
    }
    
    func login(phone: String) -> Bool {
        let users = loadAllUsers()
        if let user = users.first(where: { $0.phone == phone }) {
            loginUser(user)
            return true
        }
        authError = "用户不存在"
        return false
    }
    
    func register(phone: String, nickname: String, gender: Gender, height: Double, weight: Double, activityLevel: ActivityLevel, goalType: GoalType) -> Bool {
        // Validate Phone (Simple)
        guard phone.count >= 11 else {
            authError = "手机号格式不正确"
            return false
        }
        
        var users = loadAllUsers()
        if users.contains(where: { $0.phone == phone }) {
            authError = "该手机号已注册"
            return false
        }
        
        let newUser = User(
            id: UUID().uuidString,
            phone: phone,
            nickname: nickname,
            gender: gender,
            birthDate: Date(), // Default
            height: height,
            weight: weight,
            activityLevel: activityLevel
        )
        
        users.append(newUser)
        saveAllUsers(users)
        
        // Auto Login
        loginUser(newUser)
        
        // Setup Initial Goal in DataService (Delegate)
        DataService.shared.setupInitialGoal(for: newUser, type: goalType)
        
        return true
    }
    
    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
    }
    
    private func updateUser(_ user: User) {
        var users = loadAllUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveAllUsers(users)
            currentUser = user // Update memory
        }
    }
    
    // MARK: - Persistence
    
    private func loadCurrentUser() {
        guard let userId = UserDefaults.standard.string(forKey: currentUserIdKey) else { return }
        let users = loadAllUsers()
        currentUser = users.first(where: { $0.id == userId })
    }
    
    private func loadAllUsers() -> [User] {
        guard let data = try? Data(contentsOf: getUsersFileURL()) else { return [] }
        return (try? JSONDecoder().decode([User].self, from: data)) ?? []
    }
    
    private func saveAllUsers(_ users: [User]) {
        guard let data = try? JSONEncoder().encode(users) else { return }
        try? data.write(to: getUsersFileURL())
    }
    
    private func getUsersFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("users.json")
    }
}
