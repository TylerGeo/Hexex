import Foundation
import SwiftData

@Model
final class GameRecord {
    /// Unique identifier matching `Puzzle.id`.
    @Attribute(.unique) var puzzleID: String
    /// JSON-encoded `[[CellState]]`.
    var cellData: Data
    var checksUsed: Int
    var revealsUsed: Int
    var startTime: Date
    var elapsedSeconds: Double
    var isComplete: Bool
    var completionDate: Date?

    init(
        puzzleID: String = "",
        cellData: Data = Data(),
        checksUsed: Int = 0,
        revealsUsed: Int = 0,
        startTime: Date = Date(),
        elapsedSeconds: Double = 0,
        isComplete: Bool = false,
        completionDate: Date? = nil
    ) {
        self.puzzleID = puzzleID
        self.cellData = cellData
        self.checksUsed = checksUsed
        self.revealsUsed = revealsUsed
        self.startTime = startTime
        self.elapsedSeconds = elapsedSeconds
        self.isComplete = isComplete
        self.completionDate = completionDate
    }

    // MARK: - Cell data helpers

    /// Encode a 2-D array of `CellState` to `Data` for storage.
    static func encode(cells: [[CellState]]) -> Data {
        (try? JSONEncoder().encode(cells)) ?? Data()
    }

    /// Decode `Data` back to a 2-D array of `CellState`.
    /// Returns `nil` if the data is malformed.
    static func decode(data: Data) -> [[CellState]]? {
        try? JSONDecoder().decode([[CellState]].self, from: data)
    }
}
