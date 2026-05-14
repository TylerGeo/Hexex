import Foundation

@Observable
final class TraversalEngine: @unchecked Sendable {

    let board: HexBoard

    var activeAxis: TraversalAxis = .horizontal
    var activeLineKey: Int = 0

    init(board: HexBoard) {
        self.board = board
    }

    var activeLine: [Hex] {
        board.line(axis: activeAxis, key: activeLineKey)
    }

    func setLine(axis: TraversalAxis, key: Int) {
        activeAxis = axis
        activeLineKey = key
    }

    func nextCell(from current: Hex) -> Hex? {
        let line = activeLine
        guard let idx = line.firstIndex(of: current), idx + 1 < line.count else { return nil }
        return line[idx + 1]
    }

    func previousCell(from current: Hex) -> Hex? {
        let line = activeLine
        guard let idx = line.firstIndex(of: current), idx > 0 else { return nil }
        return line[idx - 1]
    }

    /// When a player taps an already-selected cell, rotate to the next axis it
    /// participates in.
    func cycleAxis(for hex: Hex) {
        let members = board.memberships(of: hex)
        guard members.count > 1 else { return }
        if let pos = members.firstIndex(where: { $0.axis == activeAxis && $0.key == activeLineKey }) {
            let next = members[(pos + 1) % members.count]
            setLine(axis: next.axis, key: next.key)
        } else {
            let first = members[0]
            setLine(axis: first.axis, key: first.key)
        }
    }

    /// On selecting a new cell, keep the current axis if the cell is on it,
    /// otherwise jump to whichever line on the current axis the cell lies on.
    func selectCell(_ hex: Hex) {
        if activeLine.contains(hex) { return }
        let members = board.memberships(of: hex)
        if let match = members.first(where: { $0.axis == activeAxis }) {
            activeLineKey = match.key
        } else if let first = members.first {
            setLine(axis: first.axis, key: first.key)
        }
    }
}
