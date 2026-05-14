import SwiftUI
import SwiftData

@MainActor
struct ResultsView: View {
    @Environment(GameViewModel.self) var vm
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showCopiedAlert = false

    var shareText: String {
"""
HEXEX — \(vm.difficulty.displayName)
\(String(repeating: "⬢", count: vm.difficulty.sideLength))
Checks: \(vm.checksUsed) | Reveals: \(vm.revealsUsed)
Time: \(timeString)
"""
    }

    var timeString: String {
        let t = Int(vm.elapsedSeconds)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("HEXEX")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .tracking(2)
                    Text(vm.difficulty.displayName.uppercased())
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .tracking(3)
                        .foregroundColor(.secondary)
                    Text(String(repeating: "⬢", count: vm.difficulty.sideLength))
                        .font(.title2)
                        .foregroundColor(.hexActiveBorder)
                }

                VStack(spacing: 16) {
                    StatRow(label: "Time", value: timeString)
                    StatRow(label: "Checks", value: "\(vm.checksUsed)")
                    StatRow(label: "Reveals", value: "\(vm.revealsUsed)")
                }
                .padding(.horizontal, 40)

                VStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = shareText
                        showCopiedAlert = true
                    } label: {
                        Label("Share Result", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primary)
                            .foregroundColor(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .alert("Copied to clipboard!", isPresented: $showCopiedAlert) {
                        Button("OK") {}
                    }

                    Button {
                        let context = modelContext
                        Task {
                            await vm.newPuzzle(context: context)
                            dismiss()
                        }
                    } label: {
                        Label("New Puzzle", systemImage: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.hexActiveBorder)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
            }
            .padding(.top, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.system(size: 15))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
        }
    }
}
