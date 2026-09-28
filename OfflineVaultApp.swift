import SwiftUI

@main
struct OfflineVaultApp: App {
    @StateObject private var library = MediaLibrary()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}
