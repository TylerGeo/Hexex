import Foundation

/// Procedural puzzle generation. Pure functions — safe to call off the main
/// actor. Use `generate(difficulty:)` from a `Task.detached` to avoid blocking
/// the UI on larger boards.
enum PuzzleGenerator {

    // MARK: - Public entry points

    /// Generate a fresh puzzle for the given difficulty.
    /// Off-loads the work to a detached `userInitiated` task so the UI stays
    /// responsive while clues are computed.
    static func generate(difficulty: Difficulty) async -> Puzzle {
        await Task.detached(priority: .userInitiated) {
            generateSync(difficulty: difficulty)
        }.value
    }

    /// Synchronous form, useful for tests and preview content.
    static func generateSync(difficulty: Difficulty) -> Puzzle {
        let board = HexBoard(sideLength: difficulty.sideLength)
        let alphabet = chooseAlphabet(size: difficulty.alphabetSize)

        var solution: [Hex: Character] = [:]
        solution.reserveCapacity(board.hexes.count)
        for h in board.hexes {
            solution[h] = alphabet.randomElement() ?? "A"
        }

        var clues: [RegexClue] = []
        clues.reserveCapacity(3 * board.lineKeys.count)

        for axis in TraversalAxis.allCases {
            for key in board.lineKeys {
                let lineCells = board.line(axis: axis, key: key)
                guard !lineCells.isEmpty else { continue }
                let solutionString = String(lineCells.map { solution[$0] ?? "?" })
                let pattern = makeRegex(
                    for: solutionString,
                    alphabet: alphabet,
                    complexity: difficulty.regexComplexity
                )
                clues.append(RegexClue(axis: axis, lineKey: key, pattern: pattern))
            }
        }

        return Puzzle(
            difficulty: difficulty,
            sideLength: difficulty.sideLength,
            alphabet: alphabet,
            solution: solution,
            clues: clues
        )
    }

    // MARK: - Alphabet selection

    private static func chooseAlphabet(size: Int) -> [Character] {
        // Skip letters that look ambiguous in monospaced fonts.
        let pool: [Character] = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
        let clamped = max(2, min(size, pool.count))
        return Array(pool.shuffled().prefix(clamped)).sorted()
    }

    // MARK: - Regex composition

    /// Build a regex for `solution`. Tries several random recipes and returns
    /// the first one that fully matches the solution string; if all fail
    /// (rare), falls back to the literal.
    static func makeRegex(
        for solution: String,
        alphabet: [Character],
        complexity: Double
    ) -> String {
        guard !solution.isEmpty else { return "" }
        for _ in 0..<12 {
            let candidate = composeOnce(
                for: solution,
                alphabet: alphabet,
                complexity: complexity
            )
            if fullMatches(pattern: candidate, input: solution) {
                return candidate
            }
        }
        return solution // safe literal fallback
    }

    /// Walk the solution emitting one "unit" per character (or per run of
    /// repeated characters). At each step, pick literal vs. char-class vs.
    /// alternation, weighted by `complexity`.
    private static func composeOnce(
        for solution: String,
        alphabet: [Character],
        complexity: Double
    ) -> String {
        let chars = Array(solution)
        var out = ""
        var pos = 0
        while pos < chars.count {
            let c = chars[pos]
            // Detect run
            var runLen = 1
            while pos + runLen < chars.count && chars[pos + runLen] == c {
                runLen += 1
            }

            // Maybe collapse a run with a quantifier
            let allowQuantifier = runLen >= 2 && chars.count >= 3
            if allowQuantifier && Double.random(in: 0..<1) < complexity * 0.55 {
                let body = unitFor(c, alphabet: alphabet, complexity: complexity, allowGroup: true)
                out += body + quantifierFor(runLength: runLen)
                pos += runLen
            } else {
                // Emit each char individually
                for _ in 0..<runLen {
                    out += unitFor(c, alphabet: alphabet, complexity: complexity, allowGroup: false)
                    pos += 1
                }
            }
        }
        return out
    }

    /// One "atom" of the pattern that must match exactly the character `c`.
    /// - `allowGroup`: when true, the unit may be wrapped in `(…)` so a trailing
    ///   quantifier applies to it as a group.
    private static func unitFor(
        _ c: Character,
        alphabet: [Character],
        complexity: Double,
        allowGroup: Bool
    ) -> String {
        let roll = Double.random(in: 0..<1)
        if roll < 1.0 - complexity {
            return String(c)
        } else if roll < 1.0 - complexity * 0.45 {
            return charClass(containing: c, alphabet: alphabet)
        } else {
            return alternation(containing: c, alphabet: alphabet, allowGroup: allowGroup)
        }
    }

    private static func charClass(containing c: Character, alphabet: [Character]) -> String {
        let extras = alphabet.filter { $0 != c }.shuffled().prefix(Int.random(in: 1...2))
        let members = ([c] + Array(extras)).shuffled()
        return "[" + String(members) + "]"
    }

    private static func alternation(
        containing c: Character,
        alphabet: [Character],
        allowGroup: Bool
    ) -> String {
        let other = alphabet.filter { $0 != c }.randomElement() ?? c
        let opts = [String(c), String(other)].shuffled()
        // Non-capturing group `(?:…)` keeps semantics tidy and groups well for
        // a trailing quantifier when `allowGroup` is true.
        return allowGroup
            ? "(?:" + opts.joined(separator: "|") + ")"
            : "(?:" + opts.joined(separator: "|") + ")"
    }

    private static func quantifierFor(runLength n: Int) -> String {
        // All forms must match exactly `n` of the preceding atom.
        // `+`     — 1-or-more (matches any positive run including the actual one
        //           inside a fixed-length context the surrounding pattern enforces).
        // `{n}`   — exactly n.
        // `{n,m}` — bounded range straddling n.
        let pick = Int.random(in: 0..<3)
        switch pick {
        case 0:  return "+"
        case 1:  return "{\(n)}"
        default: return "{\(max(1, n - 1)),\(n + 1)}"
        }
    }

    // MARK: - Verification

    private static func fullMatches(pattern: String, input: String) -> Bool {
        guard !input.isEmpty else { return false }
        guard let r = try? NSRegularExpression(pattern: "^(?:\(pattern))$") else { return false }
        let range = NSRange(input.startIndex..., in: input)
        return r.firstMatch(in: input, range: range) != nil
    }
}
