import SwiftUI
import SwiftData

@MainActor
struct HomeView: View {
    @Query private var allRecords: [GameRecord]

    private var completedCount: Int {
        allRecords.filter(\.isComplete).count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("HEXEX")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .tracking(6)
                    Text("regex hexagonal puzzles")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.secondary)
                        .textCase(.lowercase)
                }
                .padding(.top, 40)

                VStack(spacing: 14) {
                    ForEach(Difficulty.allCases) { diff in
                        NavigationLink {
                            GameView(vm: GameViewModel(difficulty: diff))
                        } label: {
                            DifficultyCard(
                                difficulty: diff,
                                inProgress: hasInProgress(for: diff)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                if completedCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.hexCorrect)
                        Text("\(completedCount) puzzle\(completedCount == 1 ? "" : "s") solved")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)
                }

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }

    private func hasInProgress(for diff: Difficulty) -> Bool {
        allRecords.contains { $0.slotKey == diff.rawValue && !$0.isComplete }
    }
}

private struct DifficultyCard: View {
    let difficulty: Difficulty
    let inProgress: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                HexShape(size: 22)
                    .fill(Color.hexFillFilled)
                HexShape(size: 22)
                    .strokeBorder(Color.hexActiveBorder, lineWidth: 2)
                Text("\(difficulty.sideLength)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(difficulty.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    if inProgress {
                        Text("RESUME")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1)
                            .foregroundColor(.hexActiveBorder)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.hexActiveBorder.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(difficulty.subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.hexFill)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.hexActiveBorder.opacity(0.18), lineWidth: 1)
        )
    }
}
