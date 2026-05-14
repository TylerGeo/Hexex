import Foundation
import SwiftData

/// One saved game slot per difficulty. Holds the procedurally generated puzzle
/// alongside the player's progress, so a resumed session matches its original
/// clues exactly.
@Model
final class GameRecord {
    /// Unique slot key — currently `Difficulty.rawValue`.
    @Attribute(.unique) var slotKey: String

    /// JSON-encoded `Puzzle`.
    var puzzleData: Data
    /// JSON-encoded `[HexPair<CellState>]`.
    var cellData: Data

    var checksUsed: Int
    var revealsUsed: Int
    var startTime: Date
    var elapsedSeconds: Double
    var isComplete: Bool
    var completionDate: Date?

    init(
        slotKey: String,
        puzzleData: Data = Data(),
        cellData: Data = Data(),
        checksUsed: Int = 0,
        revealsUsed: Int = 0,
        startTime: Date = Date(),
        elapsedSeconds: Double = 0,
        isComplete: Bool = false,
        completionDate: Date? = nil
    ) {
        self.slotKey = slotKey
        self.puzzleData = puzzleData
        self.cellData = cellData
        self.checksUsed = checksUsed
        self.revealsUsed = revealsUsed
        self.startTime = startTime
        self.elapsedSeconds = elapsedSeconds
        self.isComplete = isComplete
        self.completionDate = completionDate
    }

    // MARK: - Serialization helpers

    static func encode(puzzle: Puzzle) -> Data {
        (try? JSONEncoder().encode(puzzle)) ?? Data()
    }

    static func decodePuzzle(_ data: Data) -> Puzzle? {
        try? JSONDecoder().decode(Puzzle.self, from: data)
    }

    static func encode(cells: [Hex: CellState]) -> Data {
        let pairs = cells.map { (hex, state) in
            HexPair<CellState>(q: hex.q, r: hex.r, value: state)
        }
        return (try? JSONEncoder().encode(pairs)) ?? Data()
    }

    static func decodeCells(_ data: Data) -> [Hex: CellState]? {
        guard let pairs = try? JSONDecoder().decode([HexPair<CellState>].self, from: data) else {
            return nil
        }
        var dict: [Hex: CellState] = [:]
        dict.reserveCapacity(pairs.count)
        for p in pairs {
            dict[Hex(q: p.q, r: p.r)] = p.value
        }
        return dict
    }
}
