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

                Spacer()

                GeometryReader { geo in
                    HexBoardView()
                        .environment(vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer(minLength: 8)

                HexKeyboardView()
                    .environment(vm)
                    .frame(height: 180)
            }
        }
        .sheet(isPresented: $vm.showResults) {
            ResultsView()
                .environment(vm)
        }
        .onAppear {
            vm.startTimer()
        }
        .onDisappear {
            vm.stopTimer()
            vm.saveProgress(context: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                if !vm.isComplete { vm.startTimer() }
            case .inactive, .background:
                vm.stopTimer()
                vm.saveProgress(context: modelContext)
            @unknown default:
                break
            }
        }
    }
}
