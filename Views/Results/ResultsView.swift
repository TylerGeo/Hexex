import SwiftUI

@MainActor
struct ResultsView: View {
    @Environment(GameViewModel.self) var vm
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false

    var shareText: String {
"""
HEXEX #\(vm.puzzleNumber)
⬢⬢⬢⬢⬢
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
                // Title
                VStack(spacing: 8) {
                    Text("HEXEX #\(vm.puzzleNumber)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .tracking(2)

                    Text("⬢⬢⬢⬢⬢")
                        .font(.title2)
                }

                // Stats
                VStack(spacing: 16) {
                    StatRow(label: "Time", value: timeString)
                    StatRow(label: "Checks", value: "\(vm.checksUsed)")
                    StatRow(label: "Reveals", value: "\(vm.revealsUsed)")
                }
                .padding(.horizontal, 40)

                // Share button
                Button {
                    UIPasteboard.general.string = shareText
                    showShareSheet = true
                } label: {
                    Label("Share Result", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.primary)
                        .foregroundColor(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .alert("Copied to clipboard!", isPresented: $showShareSheet) {
                    Button("OK") {}
                }
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
