import Foundation

struct RegexEvaluator: Sendable {

    // MARK: - Public API

    /// Evaluate a line of cells against a regex pattern.
    ///
    /// - Returns: `.incomplete` if any cell is `.empty`;
    ///            `.correct` if the full string fully matches `pattern`;
    ///            `.incorrect` otherwise.
    func evaluateLine(pattern: String, cells: [CellState]) -> ClueState {
        let hasEmpty = cells.contains { state in
            if case .empty = state { return true }
            return false
        }
        if hasEmpty { return .incomplete }
        let str = lineString(from: cells)
        return fullMatch(pattern: pattern, input: str) ? .correct : .incorrect
    }

    /// Build the string representation of a line of cells.
    ///
    /// Empty cells contribute a space (they are stripped by `trimmingCharacters`
    /// only when the whole line is empty, but in practice `evaluateLine` checks
    /// for empties first, so this is used for display/debug purposes too).
    func lineString(from cells: [CellState]) -> String {
        let chars = cells.map { state -> Character in
            switch state {
            case .empty:                return " "
            case .filled(let c):        return c
            case .revealed(let c):      return c
            }
        }
        return String(chars).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Private helpers

    /// Returns `true` iff `input` is a full match for `pattern`
    /// (anchored with `^(?:...)$` wrapping).
    private func fullMatch(pattern: String, input: String) -> Bool {
        guard !input.isEmpty else { return false }
        guard let regex = try? NSRegularExpression(pattern: "^(?:\(pattern))$") else { return false }
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, range: range) != nil
    }
}
