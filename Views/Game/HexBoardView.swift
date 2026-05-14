import SwiftUI

struct HexBoardView: View {
    @Environment(GameViewModel.self) var vm

    private static let labelFrameWidth: CGFloat = 220
    private static let labelMarginBudget: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            if let board = vm.board {
                content(in: geo.size, board: board)
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private func content(in size: CGSize, board: HexBoard) -> some View {
        let m = margins
        let hexSize = computeHexSize(in: size, board: board)
        let boardSize = board.pixelSize(hexSize: hexSize)
        let fontSize = clueFontSize(for: hexSize)
        let cx = boardSize.width / 2
        let cy = boardSize.height / 2

        ZStack {
            ForEach(board.hexes, id: \.self) { hex in
                HexCellView(hex: hex, hexSize: hexSize)
                    .position(
                        x: cx + hex.cartesian(size: hexSize).x,
                        y: cy + hex.cartesian(size: hexSize).y
                    )
            }

            ForEach(labelDescriptors(board: board, hexSize: hexSize, center: CGPoint(x: cx, y: cy))) { d in
                clueLabel(for: d, fontSize: fontSize)
            }
        }
        .frame(width: boardSize.width, height: boardSize.height)
        .position(
            x: (m.left + (size.width - m.right)) / 2,
            y: (m.top + (size.height - m.bottom)) / 2
        )
    }

    // MARK: - Label rendering

    private struct LabelDescriptor: Identifiable {
        let id: String
        let clue: RegexClue
        let state: ClueState
        let isActive: Bool
        let anchorPoint: CGPoint
        let rotationDegrees: Double
    }

    @ViewBuilder
    private func clueLabel(for d: LabelDescriptor, fontSize: CGFloat) -> some View {
        let W = Self.labelFrameWidth
        let anchorEdge: UnitPoint = (d.clue.axis == .horizontal) ? .trailing : .leading

        let label = RegexClueLabel(
            pattern: d.clue.pattern,
            state: d.state,
            isActive: d.isActive,
            fontSize: fontSize
        )

        Group {
            if anchorEdge == .leading {
                HStack(spacing: 0) { label; Spacer(minLength: 0) }
            } else {
                HStack(spacing: 0) { Spacer(minLength: 0); label }
            }
        }
        .frame(width: W, alignment: anchorEdge == .leading ? .leading : .trailing)
        .rotationEffect(.degrees(d.rotationDegrees), anchor: anchorEdge)
        .position(
            x: d.anchorPoint.x + (anchorEdge == .leading ? +W / 2 : -W / 2),
            y: d.anchorPoint.y
        )
        .contentShape(Rectangle())
        .onTapGesture {
            vm.selectClue(axis: d.clue.axis, lineKey: d.clue.lineKey)
        }
    }

    // MARK: - Label descriptors

    private func labelDescriptors(
        board: HexBoard,
        hexSize: CGFloat,
        center: CGPoint
    ) -> [LabelDescriptor] {
        guard let puzzle = vm.puzzle, let traversal = vm.traversal else { return [] }

        var out: [LabelDescriptor] = []
        let sin60 = CGFloat(3.0).squareRoot() / 2.0
        let gap = hexSize * 1.05

        for key in board.lineKeys {
            // Horizontal — anchor at LEFT edge of first cell, label extends left
            if let clue = puzzle.clue(axis: .horizontal, lineKey: key),
               let first = board.line(axis: .horizontal, key: key).first {
                let p = first.cartesian(size: hexSize)
                let anchor = CGPoint(x: center.x + p.x - gap, y: center.y + p.y)
                out.append(LabelDescriptor(
                    id: clue.id,
                    clue: clue,
                    state: vm.clueState(for: clue),
                    isActive: traversal.activeAxis == .horizontal && traversal.activeLineKey == key,
                    anchorPoint: anchor,
                    rotationDegrees: 0
                ))
            }

            // DiagRight — anchor at LOWER-RIGHT edge of last cell, extends down-right
            if let clue = puzzle.clue(axis: .diagRight, lineKey: key),
               let last = board.line(axis: .diagRight, key: key).last {
                let p = last.cartesian(size: hexSize)
                let anchor = CGPoint(
                    x: center.x + p.x + 0.5 * gap,
                    y: center.y + p.y + sin60 * gap
                )
                out.append(LabelDescriptor(
                    id: clue.id,
                    clue: clue,
                    state: vm.clueState(for: clue),
                    isActive: traversal.activeAxis == .diagRight && traversal.activeLineKey == key,
                    anchorPoint: anchor,
                    rotationDegrees: 60
                ))
            }

            // DiagLeft — anchor at UPPER-RIGHT edge of top cell (line.last, r descending),
            // extends up-right
            if let clue = puzzle.clue(axis: .diagLeft, lineKey: key),
               let top = board.line(axis: .diagLeft, key: key).last {
                let p = top.cartesian(size: hexSize)
                let anchor = CGPoint(
                    x: center.x + p.x + 0.5 * gap,
                    y: center.y + p.y - sin60 * gap
                )
                out.append(LabelDescriptor(
                    id: clue.id,
                    clue: clue,
                    state: vm.clueState(for: clue),
                    isActive: traversal.activeAxis == .diagLeft && traversal.activeLineKey == key,
                    anchorPoint: anchor,
                    rotationDegrees: -60
                ))
            }
        }
        return out
    }

    // MARK: - Hex sizing

    private struct Margins {
        let left, top, right, bottom: CGFloat
    }

    private var margins: Margins {
        let m = Self.labelMarginBudget
        let sin60: CGFloat = CGFloat(3.0).squareRoot() / 2.0
        return Margins(
            left:   m + 8,
            top:    m * sin60 + 8,
            right:  m * 0.5 + 8,
            bottom: m * sin60 + 8
        )
    }

    private func computeHexSize(in size: CGSize, board: HexBoard) -> CGFloat {
        let m = margins
        let availW = max(40, size.width  - m.left - m.right)
        let availH = max(40, size.height - m.top  - m.bottom)
        let unit = board.unitBoundingBox
        let byW = availW / unit.width
        let byH = availH / unit.height
        return max(14, min(54, min(byW, byH)))
    }

    private func clueFontSize(for hexSize: CGFloat) -> CGFloat {
        max(9, min(13, hexSize * 0.42))
    }
}
