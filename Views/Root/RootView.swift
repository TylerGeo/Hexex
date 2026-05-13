import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: GameViewModel?

    var body: some View {
        Group {
            if let vm {
                GameView(vm: vm)
            } else {
                ProgressView("Loading puzzle…")
                    .task { await loadPuzzle() }
            }
        }
    }

    private func loadPuzzle() async {
        let puzzles = PuzzleLoader.loadAll()
        guard let puzzle = PuzzleLoader.todaysPuzzle(from: puzzles) else { return }
        let num = PuzzleLoader.puzzleNumber(for: puzzle, from: puzzles)
        let newVM = GameViewModel(puzzle: puzzle, puzzleNumber: num)

        // Restore saved progress if it exists
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.puzzleID == puzzle.id }
        )
        if let record = try? modelContext.fetch(descriptor).first {
            newVM.loadProgress(from: record)
        }

        newVM.startTimer()
        vm = newVM
    }
}
