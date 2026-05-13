import SwiftUI
import SwiftData

@main
struct HexexApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: GameRecord.self)
    }
}
