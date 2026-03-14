import SwiftUI
import SwiftData

@main
struct NutriApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Food.self)
    }
}
