import SwiftUI

struct GameStatusBar: View {
    @Environment(GameViewModel.self) var vm

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.difficulty.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(timeString)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 52, alignment: .leading)
            }

            Spacer()

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
            .disabled(vm.loadingPhase != .ready)

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
            .disabled(vm.loadingPhase != .ready)
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
