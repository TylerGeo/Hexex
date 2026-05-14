import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class GameViewModel {

    // MARK: - Game identity

    let difficulty: Difficulty

    // MARK: - Loading

    enum LoadingPhase: Equatable {
        case generating
        case ready
    }
    var loadingPhase: LoadingPhase = .generating

    // MARK: - Puzzle (set after generation/load)

    private(set) var puzzle: Puzzle?
    private(set) var board: HexBoard?
    private(set) var traversal: TraversalEngine?

    // MARK: - Cell state

    var cells: [Hex: CellState] = [:]
    var selectedCell: Hex?
    var checkOverlay: [Hex: Bool] = [:]

    // MARK: - Clue state

    /// Keyed by `RegexClue.id`. Defaults to `.incomplete`.
    var clueStates: [String: ClueState] = [:]

    func clueState(for clue: RegexClue) -> ClueState {
        clueStates[clue.id] ?? .incomplete
    }

    // MARK: - Progress

    var elapsedSeconds: Double = 0
    var checksUsed: Int = 0
    var revealsUsed: Int = 0
    var isComplete: Bool = false
    var showResults: Bool = false

    // MARK: - Owned services

    let evaluator = RegexEvaluator()
    private var timer: Timer?

    // MARK: - Init

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
    }

    // MARK: - Boot

    /// Load any saved state for this difficulty slot, otherwise generate a
    /// fresh puzzle (off the main actor). Idempotent.
    func start(context: ModelContext) async {
        guard loadingPhase == .generating else { return }

        if let record = fetchRecord(context: context),
           !record.isComplete,
           let savedPuzzle = GameRecord.decodePuzzle(record.puzzleData),
           savedPuzzle.difficulty == difficulty {
            let savedCells = GameRecord.decodeCells(record.cellData) ?? [:]
            adopt(puzzle: savedPuzzle, savedCells: savedCells, savedRecord: record)
        } else {
            let fresh = await PuzzleGenerator.generate(difficulty: difficulty)
            adopt(puzzle: fresh, savedCells: nil, savedRecord: nil)
            // Replace any stale completed/abandoned record with the fresh puzzle.
            persist(context: context, force: true)
        }

        loadingPhase = .ready
    }

    private func adopt(puzzle: Puzzle, savedCells: [Hex: CellState]?, savedRecord: GameRecord?) {
        let board = HexBoard(sideLength: puzzle.sideLength)
        self.puzzle = puzzle
        self.board = board

        let traversal = TraversalEngine(board: board)
        traversal.setLine(axis: .horizontal, key: -(puzzle.sideLength - 1))
        self.traversal = traversal

        var initial: [Hex: CellState] = [:]
        initial.reserveCapacity(board.hexes.count)
        for h in board.hexes {
            initial[h] = savedCells?[h] ?? .empty
        }
        self.cells = initial

        if let r = savedRecord {
            self.checksUsed = r.checksUsed
            self.revealsUsed = r.revealsUsed
            self.elapsedSeconds = r.elapsedSeconds
        }

        validateAll()
        checkCompletion(silent: true)
    }

    // MARK: - Timer

    func startTimer() {
        guard timer == nil, !isComplete, loadingPhase == .ready else { return }
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isComplete else { return }
                self.elapsedSeconds += 1
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Selection

    func selectCell(_ hex: Hex) {
        if selectedCell == hex {
            traversal?.cycleAxis(for: hex)
        } else {
            selectedCell = hex
            checkOverlay.removeAll()
            traversal?.selectCell(hex)
        }
    }

    func selectClue(axis: TraversalAxis, lineKey: Int) {
        guard let board, let traversal else { return }
        traversal.setLine(axis: axis, key: lineKey)
        let line = board.line(axis: axis, key: lineKey)
        if let s = selectedCell, line.contains(s) { return }
        selectedCell = line.first
    }

    // MARK: - Input

    func inputCharacter(_ char: Character) {
        guard let hex = selectedCell else { return }
        if case .revealed = cells[hex] ?? .empty { return }

        cells[hex] = .filled(char)
        checkOverlay[hex] = nil
        HapticManager.shared.keyPress()

        revalidate(touching: hex)
        checkCompletion()

        if let next = traversal?.nextCell(from: hex) {
            selectedCell = next
        }
    }

    func deleteCharacter() {
        guard let hex = selectedCell else { return }
        if case .filled = cells[hex] ?? .empty {
            cells[hex] = .empty
        }
        checkOverlay[hex] = nil
        revalidate(touching: hex)
    }

    // MARK: - Check / reveal

    func checkCurrentState() {
        guard let puzzle else { return }
        checksUsed += 1

        var anyCorrect = false
        var anyIncorrect = false
        for (hex, state) in cells {
            switch state {
            case .empty:
                break
            case .revealed:
                checkOverlay[hex] = true
                anyCorrect = true
            case .filled(let c):
                guard let truth = puzzle.solution[hex] else { continue }
                let ok = String(c).uppercased() == String(truth).uppercased()
                checkOverlay[hex] = ok
                if ok { anyCorrect = true } else { anyIncorrect = true }
            }
        }

        if anyIncorrect {
            HapticManager.shared.incorrect()
        } else if anyCorrect {
            HapticManager.shared.correct()
        }
    }

    func revealOneCell() {
        guard let puzzle, let board else { return }
        revealsUsed += 1

        for hex in board.hexes {
            if case .empty = cells[hex] ?? .empty,
               let truth = puzzle.solution[hex] {
                cells[hex] = .revealed(truth)
                HapticManager.shared.keyPress()
                revalidate(touching: hex)
                checkCompletion()
                return
            }
        }
    }

    // MARK: - Validation

    private func revalidate(touching hex: Hex) {
        for (axis, key) in [
            (TraversalAxis.horizontal, hex.r),
            (TraversalAxis.diagRight,  hex.q),
            (TraversalAxis.diagLeft,   hex.s)
        ] {
            validateLine(axis: axis, key: key)
        }
    }

    private func validateAll() {
        guard let puzzle else { return }
        for clue in puzzle.clues {
            validateLine(axis: clue.axis, key: clue.lineKey)
        }
    }

    private func validateLine(axis: TraversalAxis, key: Int) {
        guard let puzzle, let board,
              let clue = puzzle.clue(axis: axis, lineKey: key) else { return }
        let line = board.line(axis: axis, key: key)
        let lineCells = line.map { cells[$0] ?? .empty }
        clueStates[clue.id] = evaluator.evaluateLine(pattern: clue.pattern, cells: lineCells)
    }

    // MARK: - Completion

    private func checkCompletion(silent: Bool = false) {
        guard let puzzle, !isComplete else { return }
        let allCorrect = puzzle.clues.allSatisfy { clueStates[$0.id] == .correct }
        guard allCorrect else { return }

        isComplete = true
        stopTimer()
        if silent { return }

        HapticManager.shared.solved()
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            self?.showResults = true
        }
    }

    // MARK: - Persistence

    private func fetchRecord(context: ModelContext) -> GameRecord? {
        let key = difficulty.rawValue
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.slotKey == key }
        )
        return (try? context.fetch(descriptor))?.first
    }

    func saveProgress(context: ModelContext) {
        persist(context: context, force: false)
    }

    private func persist(context: ModelContext, force: Bool) {
        guard let puzzle else { return }
        let record: GameRecord
        if let existing = fetchRecord(context: context) {
            record = existing
            if force {
                record.startTime = Date()
                record.completionDate = nil
            }
        } else {
            record = GameRecord(slotKey: difficulty.rawValue, startTime: Date())
            context.insert(record)
        }

        record.puzzleData     = GameRecord.encode(puzzle: puzzle)
        record.cellData       = GameRecord.encode(cells: cells)
        record.checksUsed     = checksUsed
        record.revealsUsed    = revealsUsed
        record.elapsedSeconds = elapsedSeconds
        record.isComplete     = isComplete
        if isComplete {
            record.completionDate = record.completionDate ?? Date()
        }

        try? context.save()
    }

    // MARK: - Reset

    /// Discard the current saved record and generate a fresh puzzle.
    func newPuzzle(context: ModelContext) async {
        stopTimer()
        if let existing = fetchRecord(context: context) {
            context.delete(existing)
            try? context.save()
        }

        loadingPhase = .generating
        puzzle = nil
        board = nil
        traversal = nil
        cells.removeAll()
        clueStates.removeAll()
        checkOverlay.removeAll()
        selectedCell = nil
        checksUsed = 0
        revealsUsed = 0
        elapsedSeconds = 0
        isComplete = false
        showResults = false

        await start(context: context)
        startTimer()
    }
}
