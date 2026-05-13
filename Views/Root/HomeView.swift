import SwiftUI
import SwiftData

@MainActor
struct HomeView: View {
    @Query(filter: #Predicate<GameRecord> { $0.isComplete })
    private var completedPuzzles: [GameRecord]

    var streak: Int {
        // Count consecutive completed puzzle days (simplified: just count total for Phase 1)
        completedPuzzles.count
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("HEXEX")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .tracking(4)

            if streak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak) puzzle\(streak == 1 ? "" : "s") solved")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
