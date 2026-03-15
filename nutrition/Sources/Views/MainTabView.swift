import SwiftUI

struct MainTabView: View {
    @StateObject private var dietViewModel = DietViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var aiViewModel = AIViewModel()
    
    var body: some View {
        TabView {
            DailyDietView()
                .environmentObject(dietViewModel)
                .environmentObject(userViewModel)
                .tabItem {
                    Label("首页", systemImage: "house")
                }
            
            RecordView()
                .environmentObject(dietViewModel)
                .tabItem {
                    Label("记录", systemImage: "plus.circle")
                }
            
            AIConsultantView()
                .environmentObject(aiViewModel)
                .tabItem {
                    Label("AI 顾问", systemImage: "bubble.left.and.bubble.right")
                }
            
            ProfileView()
                .environmentObject(userViewModel)
                .environmentObject(dietViewModel) // Inject DietViewModel for clear records
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
        .accentColor(.green) // Primary color from screenshots
    }
}
