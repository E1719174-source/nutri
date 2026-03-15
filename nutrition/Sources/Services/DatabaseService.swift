import Foundation

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    @Published var currentUser: UserProfile?
    @Published var dailyRecords: [DailyRecord] = []
    @Published var foods: [FoodItem] = []
    
    private let userKey = "user_profile"
    private let recordsKey = "daily_records"
    private let foodsKey = "saved_foods"
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Load User
        if let encryptedData = UserDefaults.standard.data(forKey: userKey),
           let userData = SecurityHelper.shared.decrypt(encryptedData),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            self.currentUser = user
        }
        
        // Load Records (Assuming records don't contain sensitive PII directly, but better to encrypt)
        if let recordsData = UserDefaults.standard.data(forKey: recordsKey),
           let records = try? JSONDecoder().decode([DailyRecord].self, from: recordsData) {
            self.dailyRecords = records
        }
        
        // Load Foods
        if let foodsData = UserDefaults.standard.data(forKey: foodsKey),
           let foodList = try? JSONDecoder().decode([FoodItem].self, from: foodsData) {
            self.foods = foodList
        }
    }
    
    func saveUser(_ user: UserProfile) {
        if let data = try? JSONEncoder().encode(user),
           let encrypted = SecurityHelper.shared.encrypt(data) {
            UserDefaults.standard.set(encrypted, forKey: userKey)
            self.currentUser = user
        }
    }
    
    func saveRecord(_ record: DailyRecord) {
        if let index = dailyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: record.date) }) {
            dailyRecords[index] = record
        } else {
            dailyRecords.append(record)
        }
        
        if let data = try? JSONEncoder().encode(dailyRecords) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }
    
    func saveFood(_ food: FoodItem) {
        foods.append(food)
        if let data = try? JSONEncoder().encode(foods) {
            UserDefaults.standard.set(data, forKey: foodsKey)
        }
    }
    
    func getRecord(for date: Date) -> DailyRecord {
        if let record = dailyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return record
        }
        return DailyRecord(date: date, meals: [], waterIntake: 0)
    }
}
