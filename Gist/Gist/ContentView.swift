import SwiftUI

struct ContentView: View {
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var auth: AuthService
    @State private var selectedTab  = 0
    @State private var showAccount  = false
    @State private var showAdmin    = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ListsView()
                .tabItem { Label("Lists",    systemImage: "list.bullet") }
                .tag(0)

            DiscoverView()
                .tabItem { Label("Discover", systemImage: "sparkles") }
                .tag(1)

            AccountTab(showAdmin: $showAdmin)
                .tabItem { Label("Account",  systemImage: "person.circle") }
                .tag(2)
        }
        .tint(Color(hex: "#34c759"))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance    = appearance
            UITabBar.appearance().scrollEdgeAppearance  = appearance
        }
        .sheet(isPresented: $showAdmin) {
            AdminView()
        }
    }
}

// MARK: - Account Tab

struct AccountTab: View {
    @EnvironmentObject var auth: AuthService
    @Binding var showAdmin: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    LabeledContent("Email", value: auth.profile?.email ?? "—")
                    LabeledContent("Role",  value: auth.profile?.role  ?? "—")
                }
                Section("Limits") {
                    LabeledContent("Max Lists", value: "\(auth.profile?.maxLists ?? 4)")
                    LabeledContent("Max Items", value: "\(auth.profile?.maxItems ?? 50)")
                }
                if auth.profile?.isAdmin == true {
                    Section {
                        Button("Open Admin Panel") { showAdmin = true }
                            .foregroundColor(Color(hex: "#34c759"))
                    }
                }
                Section {
                    Button("Sign Out", role: .destructive) { auth.signOut() }
                }
            }
            .navigationTitle("Account")
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
