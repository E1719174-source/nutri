import Foundation

// MARK: - Command Pattern for Undo/Redo
protocol Command {
    func execute()
    func undo()
}

class AddFoodRecordCommand: Command {
    private let record: FoodRecord
    private let dataService: DataService
    
    init(record: FoodRecord, dataService: DataService = .shared) {
        self.record = record
        self.dataService = dataService
    }
    
    func execute() {
        dataService.addRecord(record)
    }
    
    func undo() {
        dataService.removeRecord(withId: record.id)
    }
}

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    private var undoStack: [Command] = []
    private var redoStack: [Command] = []
    
    private init() {}
    
    func execute(_ command: Command) {
        command.execute()
        undoStack.append(command)
        redoStack.removeAll() // Clear redo stack on new action
        updateState()
    }
    
    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        updateState()
    }
    
    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        updateState()
    }
    
    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
