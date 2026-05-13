import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class GameViewModel {

    // MARK: - Grid State

    var cells: [[CellState]]
    var selectedCell: GridIndex?
    var checkOverlay: [GridIndex: Bool] = [:]

    // MARK: - Clue States

    var horizontalStates: [ClueState] = Array(repeating: .incomplete, count: 5)
    var diagRightStates: [ClueState]  = Array(repeating: .incomplete, count: 5)
    var diagLeftStates: [ClueState]   = Array(repeating: .incomplete, count: 5)

    // MARK: - Game Progress

    var elapsedSeconds: Double = 0
    var checksUsed: Int = 0
    var revealsUsed: Int = 0
    var isComplete: Bool = false
    var showResults: Bool = false

    // MARK: - Owned Objects

    let puzzle: Puzzle
    let puzzleNumber: Int
    let traversal: TraversalEngine
    let evaluator: RegexEvaluator

    // MARK: - Timer

    private var timer: Timer?

    // MARK: - Init

    init(puzzle: Puzzle, puzzleNumber: Int) {
        self.puzzle = puzzle
        self.puzzleNumber = puzzleNumber
        self.traversal = TraversalEngine()
        self.evaluator = RegexEvaluator()

        // Build jagged cell grid from row sizes
        self.cells = HexGrid.rowSizes.map { count in
            Array(repeating: CellState.empty, count: count)
        }
    }

    // MARK: - Timer

    func startTimer() {
        guard timer == nil, !isComplete else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isComplete else { return }
                self.elapsedSeconds += 1
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Cell Selection

    func selectCell(_ index: GridIndex) {
        selectedCell = index
        checkOverlay.removeAll()

        // Pick the best axis for this cell:
        // keep current axis if cell is on it, otherwise prefer horizontal
        let memberships = traversal.allLineIndices(for: index)
        let alreadyOnActive = memberships.contains {
            $0.axis == traversal.activeAxis && $0.lineIndex == traversal.activeLineIndex
        }
        if !alreadyOnActive, let first = memberships.first {
            traversal.setAxis(first.axis, lineIndex: first.lineIndex)
        }
    }

    // MARK: - Input

    func inputCharacter(_ char: Character) {
        guard let idx = selectedCell else { return }
        // Don't overwrite revealed cells
        if case .revealed = cells[idx.row][idx.col] { return }

        cells[idx.row][idx.col] = .filled(char)
        checkOverlay[idx] = nil
        HapticManager.shared.keyPress()

        validateAll()
        checkCompletion()

        // Advance to next cell in traversal
        if let next = traversal.nextCell(from: idx) {
            selectedCell = next
        }
    }

    func deleteCharacter() {
        guard let idx = selectedCell else { return }
        // Only delete .filled cells; leave .revealed intact
        if case .filled = cells[idx.row][idx.col] {
            cells[idx.row][idx.col] = .empty
        }
        checkOverlay[idx] = nil
        validateAll()
    }

    // MARK: - Clue Selection

    func selectClue(axis: TraversalAxis, lineIndex: Int) {
        traversal.setAxis(axis, lineIndex: lineIndex)

        // If selected cell is not on this line, jump to first cell of the line
        let line: [GridIndex]
        switch axis {
        case .horizontal: line = HexGrid.horizontalLines[lineIndex]
        case .diagRight:  line = HexGrid.diagRightLines[lineIndex]
        case .diagLeft:   line = HexGrid.diagLeftLines[lineIndex]
        }

        let cellOnLine = selectedCell.map { line.contains($0) } ?? false
        if !cellOnLine, let first = line.first {
            selectedCell = first
        }
    }

    // MARK: - Check

    func checkCurrentState() {
        checksUsed += 1

        var anyCorrect = false
        var anyIncorrect = false

        for row in 0..<cells.count {
            for col in 0..<cells[row].count {
                let idx = GridIndex(row: row, col: col)
                let state = cells[row][col]
                switch state {
                case .empty:
                    break
                case .revealed:
                    checkOverlay[idx] = true
                    anyCorrect = true
                case .filled(let ch):
                    let solRow = puzzle.solution[row]
                    guard col < solRow.count else { continue }
                    let solChar = solRow[col]
                    let correct = String(ch).uppercased() == solChar.uppercased()
                    checkOverlay[idx] = correct
                    if correct { anyCorrect = true } else { anyIncorrect = true }
                }
            }
        }

        if anyIncorrect {
            HapticManager.shared.incorrect()
        } else if anyCorrect {
            HapticManager.shared.correct()
        }
    }

    // MARK: - Reveal

    func revealOneCell() {
        revealsUsed += 1

        // Scan rows left-to-right for first empty cell
        outer: for row in 0..<cells.count {
            for col in 0..<cells[row].count {
                if case .empty = cells[row][col] {
                    let solRow = puzzle.solution[row]
                    guard col < solRow.count, !solRow[col].isEmpty else { continue }
                    let solChar = Character(solRow[col].uppercased())
                    cells[row][col] = .revealed(solChar)
                    HapticManager.shared.keyPress()
                    validateAll()
                    checkCompletion()
                    break outer
                }
            }
        }
    }

    // MARK: - Validation

    private func validateAll() {
        // Horizontal lines — left to right
        for i in 0..<5 {
            let lineCells = HexGrid.horizontalLines[i].map { cells[$0.row][$0.col] }
            horizontalStates[i] = evaluator.evaluateLine(
                pattern: puzzle.horizontal[i],
                cells: lineCells
            )
        }

        // DiagRight lines — top-left to bottom-right
        for i in 0..<5 {
            let lineCells = HexGrid.diagRightLines[i].map { cells[$0.row][$0.col] }
            diagRightStates[i] = evaluator.evaluateLine(
                pattern: puzzle.diagRight[i],
                cells: lineCells
            )
        }

        // DiagLeft lines — stored bottom→top, so lineString matches pattern directly
        for i in 0..<5 {
            let lineCells = HexGrid.diagLeftLines[i].map { cells[$0.row][$0.col] }
            diagLeftStates[i] = evaluator.evaluateLine(
                pattern: puzzle.diagLeft[i],
                cells: lineCells
            )
        }
    }

    // MARK: - Completion

    private func checkCompletion() {
        let allCorrect =
            horizontalStates.allSatisfy { $0 == .correct } &&
            diagRightStates.allSatisfy  { $0 == .correct } &&
            diagLeftStates.allSatisfy   { $0 == .correct }

        guard allCorrect, !isComplete else { return }

        isComplete = true
        stopTimer()
        HapticManager.shared.solved()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.showResults = true
        }
    }

    // MARK: - Persistence

    func saveProgress(context: ModelContext) {
        // Fetch existing record or create new one
        let puzzleID = puzzle.id
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.puzzleID == puzzleID }
        )
        let existing = try? context.fetch(descriptor)

        let record: GameRecord
        if let found = existing?.first {
            record = found
        } else {
            record = GameRecord()
            record.puzzleID = puzzleID
            record.startTime = Date()
            context.insert(record)
        }

        record.cellData        = GameRecord.encode(cells: cells)
        record.checksUsed      = checksUsed
        record.revealsUsed     = revealsUsed
        record.elapsedSeconds  = elapsedSeconds
        record.isComplete      = isComplete
        if isComplete {
            record.completionDate = record.completionDate ?? Date()
        }

        try? context.save()
    }

    func loadProgress(from record: GameRecord) {
        if let decoded = GameRecord.decode(data: record.cellData) {
            // Validate dimensions match before restoring
            let valid = decoded.count == cells.count &&
                zip(decoded, cells).allSatisfy { $0.count == $1.count }
            if valid {
                cells = decoded
            }
        }
        checksUsed     = record.checksUsed
        revealsUsed    = record.revealsUsed
        elapsedSeconds = record.elapsedSeconds
        isComplete     = record.isComplete

        validateAll()
    }
}
