import SwiftUI

struct GameStatusBar: View {
    @Environment(GameViewModel.self) var vm

    var body: some View {
        HStack(spacing: 16) {
            // Timer display
            Text(timeString)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .frame(minWidth: 52, alignment: .leading)

            Spacer()

            // Check button
            Button {
                vm.checkCurrentState()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                    if vm.checksUsed > 0 {
                        Text("\(vm.checksUsed)")
                            .font(.caption2)
                    }
                }
                .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            // Reveal button
            Button {
                vm.revealOneCell()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                    if vm.revealsUsed > 0 {
                        Text("\(vm.revealsUsed)")
                            .font(.caption2)
                    }
                }
                .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    var timeString: String {
        let total   = Int(vm.elapsedSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
