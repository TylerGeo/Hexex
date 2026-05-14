import Foundation

final class RegexEvaluator: @unchecked Sendable {

    private let cacheLock = NSLock()
    private var cache: [String: NSRegularExpression] = [:]

    /// Evaluate one line against a regex pattern.
    /// `.incomplete` if any cell is `.empty`; `.correct` on a full match; `.incorrect` otherwise.
    func evaluateLine(pattern: String, cells: [CellState]) -> ClueState {
        let hasEmpty = cells.contains {
            if case .empty = $0 { return true }
            return false
        }
        if hasEmpty { return .incomplete }
        let str = lineString(from: cells)
        return fullMatch(pattern: pattern, input: str) ? .correct : .incorrect
    }

    func lineString(from cells: [CellState]) -> String {
        let chars: [Character] = cells.map { state in
            switch state {
            case .empty:                 return " "
            case .filled(let c):         return c
            case .revealed(let c):       return c
            }
        }
        return String(chars).trimmingCharacters(in: .whitespaces)
    }

    private func compiled(_ pattern: String) -> NSRegularExpression? {
        cacheLock.lock()
        if let r = cache[pattern] {
            cacheLock.unlock()
            return r
        }
        cacheLock.unlock()
        let wrapped = "^(?:\(pattern))$"
        guard let r = try? NSRegularExpression(pattern: wrapped) else { return nil }
        cacheLock.lock()
        cache[pattern] = r
        cacheLock.unlock()
        return r
    }

    private func fullMatch(pattern: String, input: String) -> Bool {
        guard !input.isEmpty else { return false }
        guard let regex = compiled(pattern) else { return false }
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, range: range) != nil
    }
}
