import SwiftUI

struct HexBoardView: View {
    @Environment(GameViewModel.self) var vm

    // Width of the invisible frame each label is laid out in. Labels with short
    // patterns leave slack inside the frame; the slack is consumed by Spacer so
    // the label always hugs one edge.
    private static let labelFrameWidth: CGFloat = 200

    // Budget for label margins (less than labelFrameWidth — long patterns may
    // overflow their margin allocation but never overlap adjacent labels,
    // because adjacent anchors are >1 hex-width apart along the perpendicular
    // direction).
    private static let labelMarginBudget: CGFloat = 130

    var body: some View {
        GeometryReader { geo in
            let hexSize = computeHexSize(in: geo.size)
            let boardSize = HexGrid.boardSize(hexSize: hexSize)
            let m = margins
            let fontSize = clueFontSize(for: hexSize)

            ZStack {
                ForEach(allIndices(), id: \.self) { index in
                    HexCellView(index: index, hexSize: hexSize)
                        .position(HexGrid.cellCenter(at: index, hexSize: hexSize))
                }

                ForEach(clueDescriptors(hexSize: hexSize)) { clue in
                    clueLabel(for: clue, fontSize: fontSize)
                }
            }
            .frame(width: boardSize.width, height: boardSize.height)
            // Center the board within the area between the (asymmetric) margins
            // rather than centring it in the raw geometry — the left and bottom
            // need a lot more space than the right.
            .position(
                x: (m.left + (geo.size.width - m.right)) / 2,
                y: (m.top + (geo.size.height - m.bottom)) / 2
            )
        }
    }

    // MARK: - Label rendering

    /// Lays the label out so its *inner* edge (the edge nearest the board) sits
    /// exactly at `clue.anchorPoint`, and the label extends outward along the
    /// rotated axis. Horizontal labels anchor on their trailing (right) edge;
    /// diagonal labels anchor on their leading (left) edge and rotate about it,
    /// so the text reads naturally along the clue line.
    @ViewBuilder
    private func clueLabel(for clue: ClueDescriptor, fontSize: CGFloat) -> some View {
        let W = Self.labelFrameWidth
        let anchorEdge: UnitPoint = (clue.axis == .horizontal) ? .trailing : .leading
        let label = RegexClueLabel(
            pattern: clue.pattern,
            state: clue.state,
            isActive: clue.isActive,
            fontSize: fontSize
        )

        Group {
            if anchorEdge == .leading {
                HStack(spacing: 0) {
                    label
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    label
                }
            }
        }
        .frame(width: W, alignment: anchorEdge == .leading ? .leading : .trailing)
        .rotationEffect(.degrees(clue.rotationDegrees), anchor: anchorEdge)
        // .position centres the frame; offset so the anchor edge lands on
        // clue.anchorPoint. The rotation pivots around that same edge.
        .position(
            x: clue.anchorPoint.x + (anchorEdge == .leading ? +W / 2 : -W / 2),
            y: clue.anchorPoint.y
        )
        .contentShape(Rectangle())
        .onTapGesture {
            vm.selectClue(axis: clue.axis, lineIndex: clue.lineIndex)
        }
    }

    // MARK: - Hex size & margins

    private struct Margins {
        let left: CGFloat
        let top: CGFloat
        let right: CGFloat
        let bottom: CGFloat
    }

    private var margins: Margins {
        let m = Self.labelMarginBudget
        let sin60: CGFloat = CGFloat(3.0.squareRoot()) / 2.0 // ≈ 0.866
        return Margins(
            left:   m + 8,          // horizontal labels extend left
            top:    m * sin60 + 8,  // diagLeft labels extend up-right (up component)
            right:  m * 0.5 + 8,    // diagLeft labels extend up-right (right component)
            bottom: m * sin60 + 8   // diagRight labels extend down-right (down component)
        )
    }

    private func computeHexSize(in size: CGSize) -> CGFloat {
        let m = margins
        let availW = size.width  - m.left - m.right
        let availH = size.height - m.top  - m.bottom
        let W = CGFloat(3).squareRoot()
        let byWidth  = availW / (CGFloat(HexGrid.rowSizes.max() ?? 5) * W)
        let byHeight = availH / (CGFloat(HexGrid.rowSizes.count - 1) * 1.5 + 2.0)
        return max(18, min(52, min(byWidth, byHeight)))
    }

    private func clueFontSize(for hexSize: CGFloat) -> CGFloat {
        max(10, min(14, hexSize * 0.42))
    }

    // MARK: - Index helpers

    private func allIndices() -> [GridIndex] {
        HexGrid.rowSizes.enumerated().flatMap { (row, count) in
            (0..<count).map { GridIndex(row: row, col: $0) }
        }
    }

    // MARK: - Clue descriptors
    //
    // Layout convention (pointy-top hexes, y+ is down on screen):
    //   • Horizontal:  anchor at LEFT edge of first cell, label extends left,    rotation 0°.
    //   • DiagRight:   anchor at LOWER-RIGHT edge of last cell (bottom-right end of
    //                  the line), label extends down-right at +60°.
    //   • DiagLeft:    anchor at UPPER-RIGHT edge of top cell (line.last), label
    //                  extends up-right at −60°.
    //
    // For diagonals, the rotation angle is chosen so the label's leading edge stays
    // pinned to the anchor and the body unrolls along the outward unit vector
    // (cos θ, sin θ) — which exactly equals the rotation in screen coordinates.
    private func clueDescriptors(hexSize: CGFloat) -> [ClueDescriptor] {
        var result: [ClueDescriptor] = []

        let sin60: CGFloat = CGFloat(3.0.squareRoot()) / 2.0
        let edgeGap = hexSize * 1.05

        // Horizontal — label to the left of each row
        for i in 0..<5 {
            let line = HexGrid.horizontalLines[i]
            guard let firstIdx = line.first else { continue }
            let c = HexGrid.cellCenter(at: firstIdx, hexSize: hexSize)
            let anchor = CGPoint(x: c.x - edgeGap, y: c.y)
            result.append(ClueDescriptor(
                id: "h_\(i)",
                pattern: vm.puzzle.horizontal[i],
                state: vm.horizontalStates[i],
                anchorPoint: anchor,
                rotationDegrees: 0,
                axis: .horizontal,
                lineIndex: i,
                isActive: isClueActive(axis: .horizontal, lineIndex: i)
            ))
        }

        // DiagRight — label past the bottom-right end of each diagonal
        for i in 0..<5 {
            let line = HexGrid.diagRightLines[i]
            guard let lastIdx = line.last else { continue }
            let c = HexGrid.cellCenter(at: lastIdx, hexSize: hexSize)
            let anchor = CGPoint(x: c.x + 0.5 * edgeGap, y: c.y + sin60 * edgeGap)
            result.append(ClueDescriptor(
                id: "dr_\(i)",
                pattern: vm.puzzle.diagRight[i],
                state: vm.diagRightStates[i],
                anchorPoint: anchor,
                rotationDegrees: 60,
                axis: .diagRight,
                lineIndex: i,
                isActive: isClueActive(axis: .diagRight, lineIndex: i)
            ))
        }

        // DiagLeft — label past the top (upper-right) end of each diagonal
        // (lines are stored bottom→top, so line.last is the visual top).
        for i in 0..<5 {
            let line = HexGrid.diagLeftLines[i]
            guard let topIdx = line.last else { continue }
            let c = HexGrid.cellCenter(at: topIdx, hexSize: hexSize)
            let anchor = CGPoint(x: c.x + 0.5 * edgeGap, y: c.y - sin60 * edgeGap)
            result.append(ClueDescriptor(
                id: "dl_\(i)",
                pattern: vm.puzzle.diagLeft[i],
                state: vm.diagLeftStates[i],
                anchorPoint: anchor,
                rotationDegrees: -60,
                axis: .diagLeft,
                lineIndex: i,
                isActive: isClueActive(axis: .diagLeft, lineIndex: i)
            ))
        }

        return result
    }

    private func isClueActive(axis: TraversalAxis, lineIndex: Int) -> Bool {
        vm.traversal.activeAxis == axis && vm.traversal.activeLineIndex == lineIndex
    }
}
