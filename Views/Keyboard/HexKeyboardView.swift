import SwiftUI

@MainActor
struct HexKeyboardView: View {
    @Environment(GameViewModel.self) var vm

    var body: some View {
        let letters = vm.puzzle?.alphabet ?? []
        let rows = layout(for: letters)

        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { char in
                        KeyButton(char: char) { vm.inputCharacter(char) }
                    }
                    if rowIdx == rows.count - 1 {
                        DeleteKeyButton { vm.deleteCharacter() }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    /// One row if the alphabet is short, otherwise two roughly even rows.
    /// Delete key is appended at the trailing end of the last row.
    private func layout(for letters: [Character]) -> [[Character]] {
        guard !letters.isEmpty else { return [[]] }
        if letters.count <= 6 { return [letters] }
        let mid = (letters.count + 1) / 2
        return [Array(letters.prefix(mid)), Array(letters.suffix(letters.count - mid))]
    }
}

private struct KeyButton: View {
    let char: Character
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(char))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color(.systemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.hexActiveBorder.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 0, x: 0, y: 1)
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
                .frame(width: 50, height: 46)
                .background(Color(.systemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(.systemGray3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
