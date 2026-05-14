import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}
