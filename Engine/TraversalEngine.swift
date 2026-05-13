import Foundation

@Observable
final class TraversalEngine: @unchecked Sendable {

    // MARK: - State

    var activeAxis: TraversalAxis = .horizontal
    var activeLineIndex: Int = 0

    // MARK: - Computed

    /// The ordered list of cells on the currently active line.
    var activeLine: [GridIndex] {
        switch activeAxis {
        case .horizontal: return HexGrid.horizontalLines[activeLineIndex]
        case .diagRight:  return HexGrid.diagRightLines[activeLineIndex]
        case .diagLeft:   return HexGrid.diagLeftLines[activeLineIndex]
        }
    }

    // MARK: - Navigation

    /// Returns the cell after `current` on the active line, or `nil` if `current`
    /// is the last cell on the line.
    func nextCell(from current: GridIndex) -> GridIndex? {
        let line = activeLine
        guard let idx = line.firstIndex(of: current), idx + 1 < line.count else { return nil }
        return line[idx + 1]
    }

    /// Returns the cell before `current` on the active line, or `nil` if `current`
    /// is the first cell.
    func previousCell(from current: GridIndex) -> GridIndex? {
        let line = activeLine
        guard let idx = line.firstIndex(of: current), idx > 0 else { return nil }
        return line[idx - 1]
    }

    // MARK: - Axis / line selection

    /// Change the active axis and line index together.
    func setAxis(_ axis: TraversalAxis, lineIndex: Int) {
        activeAxis = axis
        activeLineIndex = lineIndex
    }

    /// Which line index does `cell` belong to for a given axis?
    /// Returns `nil` if the cell is not part of any line on that axis.
    func lineIndex(for cell: GridIndex, axis: TraversalAxis) -> Int? {
        let lines: [[GridIndex]]
        switch axis {
        case .horizontal: lines = HexGrid.horizontalLines
        case .diagRight:  lines = HexGrid.diagRightLines
        case .diagLeft:   lines = HexGrid.diagLeftLines
        }
        return lines.firstIndex { $0.contains(cell) }
    }

    /// All (axis, lineIndex) pairs that `cell` participates in, across all three axes.
    func allLineIndices(for cell: GridIndex) -> [(axis: TraversalAxis, lineIndex: Int)] {
        var result: [(TraversalAxis, Int)] = []
        if let i = lineIndex(for: cell, axis: .horizontal) { result.append((.horizontal, i)) }
        if let i = lineIndex(for: cell, axis: .diagRight)  { result.append((.diagRight,  i)) }
        if let i = lineIndex(for: cell, axis: .diagLeft)   { result.append((.diagLeft,   i)) }
        return result
    }

    // MARK: - Tap-to-cycle axis selection

    /// When a player taps a cell that is already selected, cycle to the next axis
    /// that the cell participates in.
    func cycleAxis(for cell: GridIndex) {
        let memberships = allLineIndices(for: cell)
        guard memberships.count > 1 else { return }

        // Find current membership index
        if let currentPos = memberships.firstIndex(where: { $0.axis == activeAxis && $0.lineIndex == activeLineIndex }) {
            let next = memberships[(currentPos + 1) % memberships.count]
            setAxis(next.axis, lineIndex: next.lineIndex)
        } else if let first = memberships.first {
            setAxis(first.axis, lineIndex: first.lineIndex)
        }
    }

    // MARK: - Select cell

    /// Select a cell, choosing the axis automatically.
    ///
    /// - If the cell is already on the active line, keep the current axis and do nothing
    ///   (the caller should advance the cursor separately).
    /// - Otherwise, prefer to keep the current axis if the cell belongs to it;
    ///   otherwise pick the first available axis.
    func selectCell(_ cell: GridIndex) {
        if activeLine.contains(cell) { return }

        let memberships = allLineIndices(for: cell)
        if let match = memberships.first(where: { $0.axis == activeAxis }) {
            activeLineIndex = match.lineIndex
        } else if let first = memberships.first {
            setAxis(first.axis, lineIndex: first.lineIndex)
        }
    }
}
