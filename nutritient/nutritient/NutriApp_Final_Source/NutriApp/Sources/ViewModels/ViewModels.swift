import SwiftUI
import Combine

// MARK: - App ViewModel
class AppViewModel: ObservableObject {
    @Published var currentTab: Tab = .home
    @Published var isLoggedIn: Bool = false
    
    private var dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum Tab {
        case home, record, ai, report, profile
    }
    
    init() {
        checkLoginStatus()
        
        // Listen to DataService changes (in case logout happens elsewhere)
        dataService.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.isLoggedIn = user != nil
            }
            .store(in: &cancellables)
    }
    
    func checkLoginStatus() {
        // Simple check
        isLoggedIn = dataService.currentUser != nil
    }
}

// Updated ViewModel
@MainActor
class FoodEntryViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Food] = []
    @Published var selectedMeal: MealType = .breakfast
    @Published var selectedFood: Food?
    @Published var weight: String = "100"
    @Published var quantity: String = "1" // For unit-based entry
    @Published var useUnit: Bool = false  // Toggle between weight/unit
    @Published var isSearching: Bool = false
    @Published var aiSuggestion: Food? // For editing before add
    @Published var errorMessage: String?
    
    private var registryService = FoodRegistryService.shared
    private var dataService = DataService.shared
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Bind Registry Service Updates
        registryService.$searchResults
            .receive(on: RunLoop.main)
            .assign(to: \.searchResults, on: self)
            .store(in: &cancellables)
            
        registryService.$isSearching
            .receive(on: RunLoop.main)
            .assign(to: \.isSearching, on: self)
            .store(in: &cancellables)
            
        registryService.$aiSuggestion
            .receive(on: RunLoop.main)
            .assign(to: \.aiSuggestion, on: self)
            .store(in: &cancellables)
            
        registryService.$error
            .receive(on: RunLoop.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    func search() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            if !Task.isCancelled {
                await registryService.search(query: searchQuery)
            }
        }
    }
    
    func confirmAISuggestion(editedFood: Food) {
        registryService.confirmAddFood(editedFood)
        // Automatically select the newly added food
        self.selectedFood = editedFood
        self.aiSuggestion = nil // Clear suggestion
    }
    
    func cancelAISuggestion() {
        self.aiSuggestion = nil
    }
    
    // Update weight based on quantity if unit is available
    func updateWeightFromQuantity() {
        guard let food = selectedFood, let unitW = food.unitWeight, let qty = Double(quantity) else { return }
        self.weight = String(format: "%.0f", unitW * qty)
    }
    
    // Update quantity based on weight (approximate)
    func updateQuantityFromWeight() {
        guard let food = selectedFood, let unitW = food.unitWeight, let w = Double(weight) else { return }
        self.quantity = String(format: "%.1f", w / unitW)
    }
    
    func addRecord() {
        guard let food = selectedFood, let weightVal = Double(weight) else { return }
        
        let ratio = weightVal / 100.0
        let record = FoodRecord(
            id: UUID(),
            foodId: food.id,
            foodName: food.name,
            weight: weightVal,
            calories: food.calories * ratio,
            protein: food.protein * ratio,
            fat: food.fat * ratio,
            carbs: food.carbs * ratio,
            recordDate: Date(),
            mealType: selectedMeal
        )
        
        // Use HistoryManager to execute command
        let command = AddFoodRecordCommand(record: record)
        HistoryManager.shared.execute(command)
    }
}
