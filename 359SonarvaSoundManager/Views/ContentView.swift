import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = DataStore.shared
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                BoothHomeView(tab: $tab)
            }
            .tabItem { Label("Booth", systemImage: "hifispeaker.fill") }
            .tag(0)

            NavigationStack {
                MomentsListView()
            }
            .tabItem { Label("Moments", systemImage: "opticaldisc") }
            .tag(1)

            NavigationStack {
                MemosListView()
            }
            .tabItem { Label("Memos", systemImage: "mic.fill") }
            .tag(2)

            NavigationStack {
                VisualsView()
            }
            .tabItem { Label("Visuals", systemImage: "sparkles") }
            .tag(3)

            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Pulse", systemImage: "chart.bar.fill") }
            .tag(4)
        }
        .tint(Color("AppPrimary"))
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .dismissKeyboardOnTap()
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(named: "AppBackground")
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
