import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        if appViewModel.isLoggedIn {
            MainTabView(appViewModel: appViewModel)
        } else {
            LoginView(appViewModel: appViewModel)
        }
    }
}

struct MainTabView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        TabView(selection: $appViewModel.currentTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(AppViewModel.Tab.home)
            
            FoodEntryView()
                .tabItem {
                    Label("记录", systemImage: "plus.circle.fill")
                }
                .tag(AppViewModel.Tab.record)
            
            AIConsultantView()
                .tabItem {
                    Label("AI顾问", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(AppViewModel.Tab.ai)
            
            Text("报告页 (开发中)")
                .tabItem {
                    Label("报告", systemImage: "chart.bar.fill")
                }
                .tag(AppViewModel.Tab.report)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(AppViewModel.Tab.profile)
        }
        .accentColor(.green)
    }
}
