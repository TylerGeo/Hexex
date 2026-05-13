import Foundation
import CoreGraphics

// MARK: - ClueDescriptor

struct ClueDescriptor: Sendable, Identifiable {
    let id: String
    let pattern: String
    let state: ClueState
    let anchorPoint: CGPoint
    let rotationDegrees: Double
    let axis: TraversalAxis
    let lineIndex: Int
    let isActive: Bool
}

// MARK: - HexGrid

enum HexGrid {

    // MARK: Row sizes

    /// Number of cells in each row, from top (row 0) to bottom (row 4).
    static let rowSizes: [Int] = [3, 4, 5, 4, 3]

    /// Total number of cells.
    static let cellCount: Int = rowSizes.reduce(0, +) // 19

    // MARK: Line definitions

    /// Horizontal lines, each reading left → right.
    static let horizontalLines: [[GridIndex]] = [
        // Row 0
        [GridIndex(row: 0, col: 0), GridIndex(row: 0, col: 1), GridIndex(row: 0, col: 2)],
        // Row 1
        [GridIndex(row: 1, col: 0), GridIndex(row: 1, col: 1), GridIndex(row: 1, col: 2), GridIndex(row: 1, col: 3)],
        // Row 2
        [GridIndex(row: 2, col: 0), GridIndex(row: 2, col: 1), GridIndex(row: 2, col: 2), GridIndex(row: 2, col: 3), GridIndex(row: 2, col: 4)],
        // Row 3
        [GridIndex(row: 3, col: 0), GridIndex(row: 3, col: 1), GridIndex(row: 3, col: 2), GridIndex(row: 3, col: 3)],
        // Row 4
        [GridIndex(row: 4, col: 0), GridIndex(row: 4, col: 1), GridIndex(row: 4, col: 2)],
    ]

    /// DiagRight lines, each following the lower-right neighbour, read top-left → bottom-right.
    static let diagRightLines: [[GridIndex]] = [
        // solution: G, E, O
        [GridIndex(row: 2, col: 0), GridIndex(row: 3, col: 0), GridIndex(row: 4, col: 0)],
        // solution: P, L, R, L
        [GridIndex(row: 1, col: 0), GridIndex(row: 2, col: 1), GridIndex(row: 3, col: 1), GridIndex(row: 4, col: 1)],
        // solution: M, H, N, J, P
        [GridIndex(row: 0, col: 0), GridIndex(row: 1, col: 1), GridIndex(row: 2, col: 2), GridIndex(row: 3, col: 2), GridIndex(row: 4, col: 2)],
        // solution: W, O, J, Y
        [GridIndex(row: 0, col: 1), GridIndex(row: 1, col: 2), GridIndex(row: 2, col: 3), GridIndex(row: 3, col: 3)],
        // solution: P, T, R
        [GridIndex(row: 0, col: 2), GridIndex(row: 1, col: 3), GridIndex(row: 2, col: 4)],
    ]

    /// DiagLeft lines stored bottom → top (the string read for regex matching is formed in this order).
    /// Visual direction: upper-right ↘ lower-left.
    static let diagLeftLines: [[GridIndex]] = [
        // string: G, P, M → "GPM"
        [GridIndex(row: 2, col: 0), GridIndex(row: 1, col: 0), GridIndex(row: 0, col: 0)],
        // string: E, L, H, W → "ELHW"
        [GridIndex(row: 3, col: 0), GridIndex(row: 2, col: 1), GridIndex(row: 1, col: 1), GridIndex(row: 0, col: 1)],
        // string: O, R, N, O, P → "ORNOP"
        [GridIndex(row: 4, col: 0), GridIndex(row: 3, col: 1), GridIndex(row: 2, col: 2), GridIndex(row: 1, col: 2), GridIndex(row: 0, col: 2)],
        // string: L, J, J, T → "LJJT"
        [GridIndex(row: 4, col: 1), GridIndex(row: 3, col: 2), GridIndex(row: 2, col: 3), GridIndex(row: 1, col: 3)],
        // string: P, Y, R → "PYR"
        [GridIndex(row: 4, col: 2), GridIndex(row: 3, col: 3), GridIndex(row: 2, col: 4)],
    ]

    // MARK: - Geometry

    /// Compute the pixel center of a cell for a given hex size.
    ///
    /// Layout uses pointy-top hexagons.
    /// ```
    /// W             = sqrt(3) * hexSize
    /// H             = 2 * hexSize
    /// vertSpacing   = H * 0.75  (= 1.5 * hexSize)
    /// rowOffset     = (5 - rowSizes[row]) / 2.0 * W
    /// x             = rowOffset + col * W + W / 2
    /// y             = row * vertSpacing + hexSize
    /// ```
    static func cellCenter(row: Int, col: Int, hexSize: CGFloat) -> CGPoint {
        let w = CGFloat(3).squareRoot() * hexSize
        let vertSpacing = 1.5 * hexSize
        let rowOffset = (5.0 - CGFloat(rowSizes[row])) / 2.0 * w
        let x = rowOffset + CGFloat(col) * w + w / 2.0
        let y = CGFloat(row) * vertSpacing + hexSize
        return CGPoint(x: x, y: y)
    }

    /// Returns the six vertices of a pointy-top hexagon centred at `center`.
    ///
    /// Vertex i is at angle `60*i - 30` degrees from the positive-x axis.
    static func hexPath(center: CGPoint, hexSize: CGFloat) -> [CGPoint] {
        (0..<6).map { i in
            let angleDeg = 60.0 * Double(i) - 30.0
            let angleRad = angleDeg * .pi / 180.0
            return CGPoint(
                x: center.x + hexSize * CGFloat(cos(angleRad)),
                y: center.y + hexSize * CGFloat(sin(angleRad))
            )
        }
    }

    // MARK: - Neighbour access

    /// Lower-left neighbour of `cell`, or `nil` if out of bounds.
    static func lowerLeftNeighbour(of cell: GridIndex) -> GridIndex? {
        let r = cell.row
        let c = cell.col
        guard r < rowSizes.count - 1 else { return nil }
        // Expanding section (rows 0–1, going to wider rows 1–2)
        let neighbour: GridIndex
        if r < 2 {
            neighbour = GridIndex(row: r + 1, col: c)
        } else {
            // Contracting section (rows 2–3, going to narrower rows 3–4)
            let nc = c - 1
            guard nc >= 0 else { return nil }
            neighbour = GridIndex(row: r + 1, col: nc)
        }
        guard neighbour.col >= 0, neighbour.col < rowSizes[neighbour.row] else { return nil }
        return neighbour
    }

    /// Lower-right neighbour of `cell`, or `nil` if out of bounds.
    static func lowerRightNeighbour(of cell: GridIndex) -> GridIndex? {
        let r = cell.row
        let c = cell.col
        guard r < rowSizes.count - 1 else { return nil }
        let neighbour: GridIndex
        if r < 2 {
            neighbour = GridIndex(row: r + 1, col: c + 1)
        } else {
            neighbour = GridIndex(row: r + 1, col: c)
        }
        guard neighbour.col >= 0, neighbour.col < rowSizes[neighbour.row] else { return nil }
        return neighbour
    }

    // MARK: - Clue descriptors

    /// Build the full set of `ClueDescriptor` values from a puzzle and current board cells.
    ///
    /// - Parameters:
    ///   - puzzle: The puzzle providing regex patterns.
    ///   - cells:  The current board state (row-major, jagged array matching `rowSizes`).
    ///   - hexSize: The rendering hex size in points.
    ///   - evaluator: A `RegexEvaluator` used to compute `ClueState`.
    static func clueDescriptors(
        puzzle: Puzzle,
        cells: [[CellState]],
        hexSize: CGFloat,
        evaluator: RegexEvaluator
    ) -> [ClueDescriptor] {
        var descriptors: [ClueDescriptor] = []

        // MARK: Horizontal clues
        // Entry direction: left → right.
        // Label sits to the LEFT of the first cell, so outward direction is −x.
        for (lineIndex, line) in horizontalLines.enumerated() {
            guard lineIndex < puzzle.horizontal.count else { continue }
            let pattern = puzzle.horizontal[lineIndex]
            let lineCells = line.map { cells[$0.row][$0.col] }
            let state = evaluator.evaluateLine(pattern: pattern, cells: lineCells)

            // Anchor: first cell center displaced by (-hexSize * 2.5, 0)
            let firstCenter = cellCenter(row: line[0].row, col: line[0].col, hexSize: hexSize)
            let anchor = CGPoint(x: firstCenter.x - hexSize * 2.5, y: firstCenter.y)

            descriptors.append(ClueDescriptor(
                id: "h_\(lineIndex)",
                pattern: pattern,
                state: state,
                anchorPoint: anchor,
                rotationDegrees: 0,
                axis: .horizontal,
                lineIndex: lineIndex,
                isActive: false
            ))
        }

        // MARK: DiagRight clues
        // Lines run upper-left → lower-right.
        // Unit vector along the line (lower-right): (cos(-60°), sin(-60°)) = (0.5, -√3/2)
        // Outward from entry (upper-left end) is the opposite: (-0.5, +√3/2)
        let diagRightOutwardX: CGFloat = -0.5
        let diagRightOutwardY: CGFloat = CGFloat(3.0.squareRoot()) / 2.0 // +√3/2 ≈ 0.866

        for (lineIndex, line) in diagRightLines.enumerated() {
            guard lineIndex < puzzle.diagRight.count else { continue }
            let pattern = puzzle.diagRight[lineIndex]
            let lineCells = line.map { cells[$0.row][$0.col] }
            let state = evaluator.evaluateLine(pattern: pattern, cells: lineCells)

            let firstCenter = cellCenter(row: line[0].row, col: line[0].col, hexSize: hexSize)
            let anchor = CGPoint(
                x: firstCenter.x + diagRightOutwardX * hexSize * 2.5,
                y: firstCenter.y + diagRightOutwardY * hexSize * 2.5
            )

            descriptors.append(ClueDescriptor(
                id: "dr_\(lineIndex)",
                pattern: pattern,
                state: state,
                anchorPoint: anchor,
                rotationDegrees: -60,
                axis: .diagRight,
                lineIndex: lineIndex,
                isActive: false
            ))
        }

        // MARK: DiagLeft clues
        // diagLeftLines are stored bottom → top.
        // The "top" cell (last element) is the visual entry point.
        // The label sits above-right of that top cell.
        // Outward direction: upper-right = (cos(−30°·...)) = (0.5, -√3/2) relative to diagRight.
        // For diagLeft the visual line direction from top-right → bottom-left is (-0.5, +√3/2),
        // so the outward (away from the board) unit vector is (+0.5, -√3/2).
        let diagLeftOutwardX: CGFloat = 0.5
        let diagLeftOutwardY: CGFloat = -CGFloat(3.0.squareRoot()) / 2.0 // -√3/2 ≈ -0.866

        for (lineIndex, line) in diagLeftLines.enumerated() {
            guard lineIndex < puzzle.diagLeft.count else { continue }
            let pattern = puzzle.diagLeft[lineIndex]
            let lineCells = line.map { cells[$0.row][$0.col] }
            let state = evaluator.evaluateLine(pattern: pattern, cells: lineCells)

            // The last element is the top-most cell (entry visual point)
            let topCell = line[line.count - 1]
            let topCenter = cellCenter(row: topCell.row, col: topCell.col, hexSize: hexSize)
            let anchor = CGPoint(
                x: topCenter.x + diagLeftOutwardX * hexSize * 2.5,
                y: topCenter.y + diagLeftOutwardY * hexSize * 2.5
            )

            descriptors.append(ClueDescriptor(
                id: "dl_\(lineIndex)",
                pattern: pattern,
                state: state,
                anchorPoint: anchor,
                rotationDegrees: 60,
                axis: .diagLeft,
                lineIndex: lineIndex,
                isActive: false
            ))
        }

        return descriptors
    }

    // MARK: - Convenience overloads

    /// Convenience overload accepting a `GridIndex`.
    static func cellCenter(at index: GridIndex, hexSize: CGFloat) -> CGPoint {
        cellCenter(row: index.row, col: index.col, hexSize: hexSize)
    }

    /// Total bounding size of the cell grid (not including clue labels).
    static func boardSize(hexSize: CGFloat) -> CGSize {
        let W = CGFloat(3).squareRoot() * hexSize
        let maxCols = CGFloat(rowSizes.max() ?? 5)
        let width  = maxCols * W
        let height = CGFloat(rowSizes.count - 1) * 1.5 * hexSize + 2.0 * hexSize
        return CGSize(width: width, height: height)
    }

    // MARK: - Convenience: all lines for a given axis

    static func lines(for axis: TraversalAxis) -> [[GridIndex]] {
        switch axis {
        case .horizontal: return horizontalLines
        case .diagRight:  return diagRightLines
        case .diagLeft:   return diagLeftLines
        }
    }

    // MARK: - Hit testing

    /// Returns the `GridIndex` of the cell whose center is closest to `point`,
    /// provided the point is within `hexSize` distance of that center.
    /// Returns `nil` if no cell is close enough.
    static func cellIndex(at point: CGPoint, hexSize: CGFloat) -> GridIndex? {
        var best: GridIndex?
        var bestDist = CGFloat.infinity

        for row in 0..<rowSizes.count {
            for col in 0..<rowSizes[row] {
                let center = cellCenter(row: row, col: col, hexSize: hexSize)
                let dx = point.x - center.x
                let dy = point.y - center.y
                let dist = (dx * dx + dy * dy).squareRoot()
                if dist < bestDist {
                    bestDist = dist
                    best = GridIndex(row: row, col: col)
                }
            }
        }

        // Only accept hit if within the hex radius
        return bestDist <= hexSize ? best : nil
    }

    // MARK: - Empty board factory

    /// Returns a fresh jagged board filled with `.empty` cells.
    static func emptyBoard() -> [[CellState]] {
        rowSizes.map { count in Array(repeating: CellState.empty, count: count) }
    }

    // MARK: - Board validation helpers

    /// Returns `true` when every cell in every horizontal, diagRight, and diagLeft line
    /// fully matches its corresponding pattern.
    static func isSolved(puzzle: Puzzle, cells: [[CellState]], evaluator: RegexEvaluator) -> Bool {
        let axes: [(patterns: [String], lines: [[GridIndex]])] = [
            (puzzle.horizontal, horizontalLines),
            (puzzle.diagRight, diagRightLines),
            (puzzle.diagLeft, diagLeftLines),
        ]
        for (patterns, lines) in axes {
            for (lineIndex, line) in lines.enumerated() {
                guard lineIndex < patterns.count else { return false }
                let lineCells = line.map { cells[$0.row][$0.col] }
                if evaluator.evaluateLine(pattern: patterns[lineIndex], cells: lineCells) != .correct {
                    return false
                }
            }
        }
        return true
    }
}
