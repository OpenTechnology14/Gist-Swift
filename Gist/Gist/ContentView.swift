import SwiftUI

struct ContentView: View {
    @EnvironmentObject var storageService: StorageService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ListsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
                .tag(0)

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
                .tag(1)
        }
        .tint(Color(hex: "#7ac94b"))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "#2a2118"))
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#7ac94b"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#7ac94b"))]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
