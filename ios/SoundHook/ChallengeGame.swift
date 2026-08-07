import Combine
import Foundation

/// 미션으로 제시된 소리를 실제로 내면 내장 분류기가 판정하는 게임 루프.
@MainActor
final class ChallengeGame: ObservableObject {

    enum Phase: Equatable {
        case ready                  // 시작 전
        case counting(Int)          // 3, 2, 1
        case playing                // 미션 수행 중
        case cleared(Int)           // 성공, 획득 점수
        case missed                 // 시간 초과
        case finished               // 전체 라운드 종료
    }

    // MARK: 상태

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var mission: Mission = MissionDeck.all[0]
    @Published private(set) var round: Int = 0
    @Published private(set) var score: Int = 0
    @Published private(set) var combo: Int = 0
    @Published private(set) var bestCombo: Int = 0
    @Published private(set) var timeLeft: Double = 0
    @Published private(set) var progress: Double = 0        // 목표 대비 달성률 0...1
    @Published private(set) var heardLabel: String = ""     // 지금 들리는 소리
    @Published private(set) var log: [RoundResult] = []
    @Published private(set) var highScore: Int = UserDefaults.standard.integer(forKey: "SoundHook.highScore")

    struct RoundResult: Identifiable {
        let id = UUID()
        let mission: Mission
        let cleared: Bool
        let peak: Double
    }

    // MARK: 규칙

    let totalRounds = 8
    let roundDuration: Double = 12
    /// 성공 판정 신뢰도. 실험실 탭에서 조정 가능.
    var targetConfidence: Double = 0.45

    var isPlaying: Bool {
        if case .ready = phase { return false }
        if case .finished = phase { return false }
        return true
    }

    // MARK: 내부

    private let classifier: SoundClassifier
    private var cancellables = Set<AnyCancellable>()
    private var ticker: AnyCancellable?
    private var peak: Double = 0
    private static let highScoreKey = "SoundHook.highScore"

    init(classifier: SoundClassifier) {
        self.classifier = classifier
        classifier.$results
            .sink { [weak self] results in self?.consume(results) }
            .store(in: &cancellables)
    }

    // MARK: 제어

    func start() {
        score = 0
        combo = 0
        bestCombo = 0
        round = 0
        log = []
        classifier.start()
        beginRound()
    }

    func stop() {
        ticker?.cancel()
        classifier.stop()
        phase = .ready
        progress = 0
        heardLabel = ""
    }

    func skip() {
        guard case .playing = phase else { return }
        endRound(cleared: false)
    }

    // MARK: 라운드 진행

    private func beginRound() {
        guard round < totalRounds else {
            finish()
            return
        }
        round += 1
        mission = MissionDeck.next(excluding: log.last?.mission)
        peak = 0
        progress = 0
        timeLeft = roundDuration
        countdown(from: 3)
    }

    private func countdown(from value: Int) {
        guard value > 0 else {
            phase = .playing
            runTimer()
            return
        }
        phase = .counting(value)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self, self.isPlaying else { return }
            self.countdown(from: value - 1)
        }
    }

    private func runTimer() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, case .playing = self.phase else { return }
                self.timeLeft = max(self.timeLeft - 0.05, 0)
                if self.timeLeft == 0 { self.endRound(cleared: false) }
            }
    }

    private func consume(_ results: [Classification]) {
        guard case .playing = phase else { return }

        if let top = results.first, top.confidence >= 0.2 {
            heardLabel = top.displayName
        }

        let matched = results
            .filter { mission.identifiers.contains($0.identifier) }
            .map(\.confidence)
            .max() ?? 0

        peak = max(peak, matched)
        progress = min(matched / targetConfidence, 1)

        if matched >= targetConfidence {
            endRound(cleared: true)
        }
    }

    private func endRound(cleared: Bool) {
        ticker?.cancel()
        log.append(RoundResult(mission: mission, cleared: cleared, peak: peak))

        if cleared {
            combo += 1
            bestCombo = max(bestCombo, combo)
            let speedBonus = Int(timeLeft / roundDuration * 60)
            let gained = 100 * mission.difficulty + speedBonus + (combo - 1) * 25
            score += gained
            progress = 1
            phase = .cleared(gained)
        } else {
            combo = 0
            phase = .missed
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self, self.isPlaying else { return }
            self.beginRound()
        }
    }

    private func finish() {
        ticker?.cancel()
        classifier.stop()
        phase = .finished
        heardLabel = ""
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: Self.highScoreKey)
        }
    }

    // MARK: 표시용

    var clearedCount: Int { log.filter(\.cleared).count }

    var grade: String {
        guard totalRounds > 0 else { return "—" }
        switch Double(clearedCount) / Double(totalRounds) {
        case 1: return "완벽"
        case 0.75...: return "우수"
        case 0.5...: return "양호"
        case 0.25...: return "연습 필요"
        default: return "재도전"
        }
    }
}
