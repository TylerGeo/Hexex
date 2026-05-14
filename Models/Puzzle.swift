import Foundation

/// A procedurally generated puzzle: the hidden solution, the alphabet it was
/// drawn from, and the regex clues the player sees on the board.
struct Puzzle: Sendable, Identifiable {
    let id: UUID
    let difficulty: Difficulty
    let sideLength: Int
    let alphabet: [Character]
    let solution: [Hex: Character]
    let clues: [RegexClue]

    /// O(1) clue lookup by axis + line key.
    private let cluesByKey: [String: RegexClue]

    init(
        id: UUID = UUID(),
        difficulty: Difficulty,
        sideLength: Int,
        alphabet: [Character],
        solution: [Hex: Character],
        clues: [RegexClue]
    ) {
        self.id = id
        self.difficulty = difficulty
        self.sideLength = sideLength
        self.alphabet = alphabet
        self.solution = solution
        self.clues = clues
        var idx: [String: RegexClue] = [:]
        idx.reserveCapacity(clues.count)
        for c in clues { idx[c.id] = c }
        self.cluesByKey = idx
    }

    func clue(axis: TraversalAxis, lineKey: Int) -> RegexClue? {
        cluesByKey["\(axis.rawValue)_\(lineKey)"]
    }
}

// MARK: - Codable (for persistence)

extension Puzzle: Codable {
    private struct Wire: Codable {
        let id: UUID
        let difficulty: Difficulty
        let sideLength: Int
        let alphabet: String
        let solution: [HexPair<String>]
        let clues: [RegexClue]
    }

    init(from decoder: Decoder) throws {
        let wire = try Wire(from: decoder)
        var sol: [Hex: Character] = [:]
        sol.reserveCapacity(wire.solution.count)
        for p in wire.solution {
            guard let c = p.value.first else { continue }
            sol[Hex(q: p.q, r: p.r)] = c
        }
        self.init(
            id: wire.id,
            difficulty: wire.difficulty,
            sideLength: wire.sideLength,
            alphabet: Array(wire.alphabet),
            solution: sol,
            clues: wire.clues
        )
    }

    func encode(to encoder: Encoder) throws {
        let pairs = solution.map { (hex, ch) in
            HexPair<String>(q: hex.q, r: hex.r, value: String(ch))
        }
        let wire = Wire(
            id: id,
            difficulty: difficulty,
            sideLength: sideLength,
            alphabet: String(alphabet),
            solution: pairs,
            clues: clues
        )
        try wire.encode(to: encoder)
    }
}
