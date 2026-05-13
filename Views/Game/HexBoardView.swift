import SwiftUI

struct HexBoardView: View {
    @Environment(GameViewModel.self) var vm

    var body: some View {
        GeometryReader { geo in
            let hexSize = computeHexSize(in: geo.size)
            let boardSize = HexGrid.boardSize(hexSize: hexSize)

            ZStack {
                // All hex cells
                ForEach(allIndices(), id: \.self) { index in
                    HexCellView(index: index, hexSize: hexSize)
                        .position(HexGrid.cellCenter(at: index, hexSize: hexSize))
                }

                // Clue labels
                ForEach(clueDescriptors(hexSize: hexSize)) { clue in
                    RegexClueLabel(
                        pattern: clue.pattern,
                        state: clue.state,
                        isActive: clue.isActive
                    )
                    .position(clue.anchorPoint)
                    .rotationEffect(.degrees(clue.rotationDegrees))
                    .onTapGesture {
                        vm.selectClue(axis: clue.axis, lineIndex: clue.lineIndex)
                    }
                }
            }
            .frame(width: boardSize.width, height: boardSize.height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    // MARK: - Hex Size Calculation

    /// Computes a hex size that lets the board + clue labels fit in the available space.
    /// Labels need roughly 2.8 * hexSize of extra margin on each side.
    private func computeHexSize(in size: CGSize) -> CGFloat {
        // Reserve fixed margins for labels instead of scaling them with hexSize.
        // Horizontal labels need ~110pt on the left.
        // Diagonal labels need ~70pt on top and right.
        let leftMargin:   CGFloat = 110
        let topMargin:    CGFloat = 70
        let rightMargin:  CGFloat = 70
        let bottomMargin: CGFloat = 40

        let availW = size.width  - leftMargin - rightMargin
        let availH = size.height - topMargin  - bottomMargin

        let W = CGFloat(3).squareRoot()
        // Board cell area: width = 5*W*s, height = (nRows-1)*1.5*s + 2*s
        let byWidth  = availW / (CGFloat(HexGrid.rowSizes.max() ?? 5) * W)
        let byHeight = availH / (CGFloat(HexGrid.rowSizes.count - 1) * 1.5 + 2.0)

        return max(20, min(52, min(byWidth, byHeight)))
    }

    // MARK: - Index Helpers

    private func allIndices() -> [GridIndex] {
        HexGrid.rowSizes.enumerated().flatMap { (row, count) in
            (0..<count).map { GridIndex(row: row, col: $0) }
        }
    }

    // MARK: - Clue Descriptors

    private func clueDescriptors(hexSize: CGFloat) -> [ClueDescriptor] {
        var result: [ClueDescriptor] = []

        // Horizontal clues (5) — labels sit to the left of each row
        for i in 0..<5 {
            let line = HexGrid.horizontalLines[i]
            guard let firstIdx = line.first else { continue }
            let firstCenter = HexGrid.cellCenter(at: firstIdx, hexSize: hexSize)
            // Place label to the left
            let anchor = CGPoint(x: firstCenter.x - hexSize * 1.2, y: firstCenter.y)
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

        // DiagRight clues (5) — labels sit past the bottom-right end of each diagonal
        // The diagonal direction goes right and down at 60° from horizontal.
        for i in 0..<5 {
            let line = HexGrid.diagRightLines[i]
            guard let lastIdx = line.last else { continue }
            let lastCenter = HexGrid.cellCenter(at: lastIdx, hexSize: hexSize)
            let angleRad = 60.0 * Double.pi / 180.0
            let dx = CGFloat(cos(angleRad)) * hexSize * 1.2
            let dy = CGFloat(sin(angleRad)) * hexSize * 1.2
            let anchor = CGPoint(x: lastCenter.x + dx, y: lastCenter.y + dy)
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

        // DiagLeft clues (5) — stored bottom→top, label sits above the top cell (last in array)
        // These diagonals go from lower-left to upper-right; the "top" cell is last in the array.
        for i in 0..<5 {
            let line = HexGrid.diagLeftLines[i]
            guard let topIdx = line.last else { continue }
            let topCenter = HexGrid.cellCenter(at: topIdx, hexSize: hexSize)
            // Upper-right direction: -60° from horizontal
            let angleRad = -60.0 * Double.pi / 180.0
            let dx = CGFloat(cos(angleRad)) * hexSize * 1.2
            let dy = CGFloat(sin(angleRad)) * hexSize * 1.2
            let anchor = CGPoint(x: topCenter.x + dx, y: topCenter.y + dy)
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
