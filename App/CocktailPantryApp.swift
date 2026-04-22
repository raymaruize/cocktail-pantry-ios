import SwiftUI

@main
struct CocktailPantryApp: App {
    @StateObject private var pantryVM = PantryViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                TabView {
                    PantryView(viewModel: pantryVM)
                        .tabItem {
                            Label("Pantry", systemImage: "archivebox.fill")
                        }

                    DiscoverView(viewModel: pantryVM)
                        .tabItem {
                            Label("Discover", systemImage: "sparkles")
                        }

                    ShoppingView(viewModel: pantryVM)
                        .tabItem {
                            Label("Shopping", systemImage: "cart.fill")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .tint(.blue)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color(.systemBackground), for: .tabBar)
            }
        }
    }
}
