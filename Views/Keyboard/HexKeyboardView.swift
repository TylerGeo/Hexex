import SwiftUI

@MainActor
struct HexKeyboardView: View {
    @Environment(GameViewModel.self) var vm

    private let rows: [[Character]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 5) {
                    if rowIdx == 2 {
                        Spacer()
                    }
                    ForEach(row, id: \.self) { char in
                        KeyButton(char: char) {
                            vm.inputCharacter(char)
                        }
                    }
                    if rowIdx == 2 {
                        DeleteKeyButton {
                            vm.deleteCharacter()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}

private struct KeyButton: View {
    let char: Character
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(char))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

private struct DeleteKeyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "delete.left")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 44, height: 44)
                .background(Color(.systemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
