import SwiftUI

// MARK: - HexShape

/// A pointy-top hexagon Shape.
struct HexShape: Shape {
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for i in 0..<6 {
            // Pointy-top: start at -30° (top-right vertex), step by 60°
            let angleDeg = Double(i) * 60.0 - 30.0
            let angleRad = angleDeg * .pi / 180.0
            let pt = CGPoint(
                x: center.x + size * CGFloat(cos(angleRad)),
                y: center.y + size * CGFloat(sin(angleRad))
            )
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
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

// MARK: - HexCellView

struct HexCellView: View {
    @Environment(GameViewModel.self) var vm

    let index: GridIndex
    let hexSize: CGFloat

    // MARK: Derived State

    var isSelected: Bool {
        vm.selectedCell == index
    }

    var cellState: CellState {
        vm.cells[index.row][index.col]
    }

    var checkState: Bool? {
        vm.checkOverlay[index]
    }

    var letter: String {
        switch cellState {
        case .empty:                   return ""
        case .filled(let c):           return String(c)
        case .revealed(let c):         return String(c)
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            // Background fill
            HexShape(size: hexSize)
                .fill(backgroundColor)

            // Border
            HexShape(size: hexSize)
                .strokeBorder(borderColor, lineWidth: isSelected ? 2.5 : 1.5)

            // Letter
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
        // Pointy-top hex frame: width = sqrt(3)*size, height = 2*size
        .frame(
            width: hexSize * CGFloat(3.0).squareRoot(),
            height: hexSize * 2.0
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            vm.selectCell(index)
        }
    }

    // MARK: Colors

    var backgroundColor: Color {
        if let check = checkState {
            return check
                ? Color.hexCorrect.opacity(0.3)
                : Color.orange.opacity(0.25)
        }
        switch cellState {
        case .empty:
            return isSelected
                ? Color.blue.opacity(0.12)
                : Color(.systemGray5)
        case .filled:
            return isSelected
                ? Color.blue.opacity(0.12)
                : Color(.systemBackground)
        case .revealed:
            return Color.hexReveal
        }
    }

    var borderColor: Color {
        if let check = checkState {
            return check ? Color.hexCorrect : Color.orange
        }
        if isSelected { return .blue }
        switch cellState {
        case .empty:    return Color.clear
        case .filled:   return Color(.systemGray3)
        case .revealed: return Color.indigo
        }
    }

    var letterColor: Color {
        if case .revealed = cellState { return .indigo }
        return Color(.label)
    }
}
