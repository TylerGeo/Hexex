import Foundation

struct PuzzleLoader {

    // MARK: - Loading

    /// Load all puzzles from `puzzles.json` in the main bundle.
    /// Returns an empty array if the file is missing or malformed.
    static func loadAll() -> [Puzzle] {
        guard
            let url = Bundle.main.url(forResource: "puzzles", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let puzzles = try? JSONDecoder().decode([Puzzle].self, from: data),
            !puzzles.isEmpty
        else {
            return []
        }
        return puzzles
    }

    // MARK: - Daily selection

    /// Select today's puzzle by computing the number of days elapsed since the
    /// anchor date (2026-01-01) and taking the result modulo the puzzle count.
    static func todaysPuzzle(from puzzles: [Puzzle]) -> Puzzle? {
        guard !puzzles.isEmpty else { return nil }
        let anchor = anchorDate()
        let days = Calendar.current.dateComponents([.day], from: anchor, to: Date()).day ?? 0
        let index = abs(days) % puzzles.count
        return puzzles[index]
    }

    /// Returns the 1-based display number for a puzzle within the provided array.
    static func puzzleNumber(for puzzle: Puzzle, from puzzles: [Puzzle]) -> Int {
        (puzzles.firstIndex { $0.id == puzzle.id } ?? 0) + 1
    }

    // MARK: - Private helpers

    private static func anchorDate() -> Date {
        var components = DateComponents()
        components.year  = 2026
        components.month = 1
        components.day   = 1
        return Calendar.current.date(from: components) ?? Date()
    }
}
