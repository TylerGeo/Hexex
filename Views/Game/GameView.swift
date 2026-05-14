import SwiftUI
import SwiftData

struct GameView: View {
    @State var vm: GameViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GameStatusBar()
                    .environment(vm)

                Spacer(minLength: 0)

                if vm.loadingPhase == .ready {
                    GeometryReader { _ in
                        HexBoardView()
                            .environment(vm)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    LoadingPlaceholder(difficulty: vm.difficulty)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer(minLength: 8)

                HexKeyboardView()
                    .environment(vm)
                    .frame(height: (vm.puzzle?.alphabet.count ?? 0) > 6 ? 124 : 70)
                    .opacity(vm.loadingPhase == .ready ? 1 : 0)
                    .disabled(vm.loadingPhase != .ready)
            }
        }
        .sheet(isPresented: $vm.showResults) {
            ResultsView()
                .environment(vm)
        }
        .task {
            await vm.start(context: modelContext)
            vm.startTimer()
        }
        .onDisappear {
            vm.stopTimer()
            vm.saveProgress(context: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                if !vm.isComplete && vm.loadingPhase == .ready { vm.startTimer() }
            case .inactive, .background:
                vm.stopTimer()
                vm.saveProgress(context: modelContext)
            @unknown default:
                break
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let context = modelContext
                    Task { await vm.newPuzzle(context: context) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(vm.loadingPhase != .ready)
            }
        }
        .navigationTitle(vm.difficulty.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LoadingPlaceholder: View {
    let difficulty: Difficulty

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Generating \(difficulty.displayName.lowercased()) puzzle…")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
