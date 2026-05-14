import SwiftUI

/// Pointy-top hexagon shape.
struct HexShape: Shape {
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for i in 0..<6 {
            let angleDeg = Double(i) * 60.0 - 30.0
            let angleRad = angleDeg * .pi / 180.0
            let pt = CGPoint(
                x: center.x + size * CGFloat(cos(angleRad)),
                y: center.y + size * CGFloat(sin(angleRad))
            )
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

extension HexShape: InsettableShape {
    func inset(by amount: CGFloat) -> HexShape {
        HexShape(size: max(0, size - amount))
    }
}

struct HexCellView: View {
    @Environment(GameViewModel.self) var vm

    let hex: Hex
    let hexSize: CGFloat

    var cellState: CellState { vm.cells[hex] ?? .empty }
    var isSelected: Bool { vm.selectedCell == hex }
    var checkResult: Bool? { vm.checkOverlay[hex] }

    var letter: String {
        switch cellState {
        case .empty:                return ""
        case .filled(let c):        return String(c)
        case .revealed(let c):      return String(c)
        }
    }

    var body: some View {
        let shape = HexShape(size: hexSize)
        ZStack {
            shape.fill(backgroundColor)
            shape.strokeBorder(borderColor, lineWidth: isSelected ? 3.0 : 1.25)

            if !letter.isEmpty {
                Text(letter)
                    .font(.system(
                        size: hexSize * 0.55,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundColor(letterColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(
            width: hexSize * CGFloat(3.0).squareRoot(),
            height: hexSize * 2.0
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .onTapGesture { vm.selectCell(hex) }
    }

    private var backgroundColor: Color {
        if let result = checkResult {
            return result
                ? Color.hexCorrect.opacity(0.35)
                : Color.orange.opacity(0.30)
        }
        switch cellState {
        case .empty:
            return isSelected ? Color.hexFillFilled : Color.hexFillEmpty
        case .filled:
            return Color.hexFillFilled
        case .revealed:
            return Color.hexReveal
        }
    }

    private var borderColor: Color {
        if let result = checkResult {
            return result ? Color.hexCorrect : Color.orange
        }
        if isSelected { return Color.hexActiveBorder }
        switch cellState {
        case .empty:    return Color(white: 0.78)
        case .filled:   return Color(white: 0.68)
        case .revealed: return Color.indigo
        }
    }

    private var letterColor: Color {
        if case .revealed = cellState { return .indigo }
        return Color(.label)
    }
}
