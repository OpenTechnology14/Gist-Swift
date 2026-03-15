import SwiftUI

@main
struct GistApp: App {
    @StateObject private var storageService = StorageService()
    @StateObject private var auth = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storageService)
                .environmentObject(auth)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var storageService: StorageService

    var body: some View {
        Group {
            if auth.isSignedIn {
                ContentView()
                    .task { await storageService.pullFromCloud() }
            } else {
                AuthView()
            }
        }
        .task {
            // Warm discover cache on launch so Discover tab loads instantly
            OpenFoodFactsService.shared.warmDiscoverCache()
        }
    }
}
