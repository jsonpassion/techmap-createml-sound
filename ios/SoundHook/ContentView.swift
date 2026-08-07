import SwiftUI

struct ContentView: View {
    @StateObject private var classifier: SoundClassifier
    @StateObject private var game: ChallengeGame
    @State private var selection = 0

    @MainActor init() {
        let classifier = SoundClassifier()
        _classifier = StateObject(wrappedValue: classifier)
        _game = StateObject(wrappedValue: ChallengeGame(classifier: classifier))
    }

    var body: some View {
        TabView(selection: $selection) {
            ChallengeView(classifier: classifier, game: game)
                .tabItem { Label("챌린지", systemImage: "gamecontroller.fill") }
                .tag(0)

            LabView(classifier: classifier, game: game)
                .tabItem { Label("실험실", systemImage: "slider.horizontal.3") }
                .tag(1)
        }
        .tint(Theme.accent)
        .onChange(of: selection) { _, _ in
            // 탭을 옮기면 진행 중인 게임을 정리해 마이크 사용을 명확히 한다.
            if game.isPlaying { game.stop() }
        }
    }
}

#Preview {
    ContentView()
}
