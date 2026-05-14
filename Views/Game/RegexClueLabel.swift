import SwiftUI

struct RegexClueLabel: View {
    let pattern: String
    let state: ClueState
    let isActive: Bool
    var fontSize: CGFloat = 14

    var body: some View {
        Text(pattern)
            .font(.custom("JetBrainsMono-Regular", size: fontSize)
                .weight(isActive ? .bold : .regular))
            .foregroundColor(textColor)
            .underline(isActive)
            .lineLimit(1)
            .fixedSize()
    }

    var textColor: Color {
        switch state {
        case .incomplete: return Color(.secondaryLabel)
        case .correct:    return .hexCorrect
        case .incorrect:  return .hexIncorrect
        }
    }
}
