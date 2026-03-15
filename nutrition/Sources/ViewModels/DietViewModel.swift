import Foundation
import Combine

class DietViewModel: ObservableObject {
    @Published var currentRecord: DailyRecord
    @Published var selectedDate: Date = Date()
    @Published var searchResults: [FoodItem] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    
    private let database = DatabaseService.shared
    private let apiService = APIService.shared
    
    init() {
        self.currentRecord = database.getRecord(for: Date())
    }
    
    func loadRecord(for date: Date) {
        self.selectedDate = date
        self.currentRecord = database.getRecord(for: date)
    }
    
    func addFood(_ food: FoodItem, to mealType: MealType) {
        // Check if meal exists, if not create one
        if let index = currentRecord.meals.firstIndex(where: { $0.type == mealType }) {
            var meal = currentRecord.meals[index]
            meal.foods.append(food)
            currentRecord.meals[index] = meal
        } else {
            let newMeal = MealRecord(type: mealType, foods: [food])
            currentRecord.meals.append(newMeal)
        }
        saveCurrentRecord()
    }
    
    func updateWaterIntake(amount: Double) {
        currentRecord.waterIntake += amount
        saveCurrentRecord()
    }
    
    func setWaterTarget(_ target: Double) {
        currentRecord.waterTarget = target
        saveCurrentRecord()
    }
    
    private func saveCurrentRecord() {
        database.saveRecord(currentRecord)
    }
    
    func searchFood(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        // Local search first
        let localResults = database.foods.filter { $0.name.localizedCaseInsensitiveContains(query) }
        
        if !localResults.isEmpty {
            self.searchResults = localResults
            self.isSearching = false
        } else {
            // API Search
            apiService.searchFood(query: query) { [weak self] results in
                DispatchQueue.main.async {
                    self?.searchResults = results
                    self?.isSearching = false
                    // Save to local for future use
                    for food in results {
                        self?.database.saveFood(food)
                    }
                }
            }
        }
    }
    
    func clearAllRecords() {
        currentRecord.meals = []
        currentRecord.waterIntake = 0
        saveCurrentRecord()
    }
}
