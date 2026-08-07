import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ChallengeView: View {
    @ObservedObject var classifier: SoundClassifier
    @ObservedObject var game: ChallengeGame
    @State private var burstSeed = 0
    @State private var cardScale: CGFloat = 1

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch game.phase {
            case .ready:
                startScreen
            case .finished:
                resultScreen
            default:
                playScreen
            }

            if case .cleared = game.phase {
                ConfettiBurst(seed: burstSeed).ignoresSafeArea()
            }
        }
        .onChange(of: game.phase) { _, phase in
            if case .cleared = phase {
                burstSeed += 1
                impact(.heavy)
                bump()
            }
            if case .missed = phase { impact(.rigid) }
        }
    }

    // MARK: 시작 화면

    private var startScreen: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(spacing: 10) {
                waveMark
                Text("사운드 챌린지")
                    .font(Theme.display(38))
                    .foregroundStyle(Theme.ink)
                Text("제시된 소리를 직접 내면\n온디바이스 분류기가 실시간으로 판정한다.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkMuted)
            }

            VStack(spacing: 10) {
                ruleRow("1", "\(game.totalRounds)라운드, 라운드당 \(Int(game.roundDuration))초")
                ruleRow("2", "신뢰도 \(Int(game.targetConfidence * 100))% 이상이면 성공")
                ruleRow("3", "빠르게 성공할수록, 연속 성공할수록 고득점")
            }
            .frame(maxWidth: .infinity)
            .card()
            .padding(.horizontal, 24)

            if game.highScore > 0 {
                Text("최고 점수 \(game.highScore)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accentDeep)
            }

            Spacer()

            Button { game.start() } label: {
                Text("시작하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)

            Text("마이크 입력은 기기 밖으로 전송되지 않는다.")
                .font(.caption2)
                .foregroundStyle(Theme.inkMuted)
                .padding(.bottom, 8)
        }
    }

    private var waveMark: some View {
        HStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Theme.accent.opacity(0.55 + Double(index % 3) * 0.15))
                    .frame(width: 7, height: [18.0, 38, 54, 34, 22][index])
            }
        }
        .frame(height: 56)
    }

    private func ruleRow(_ number: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accentDeep)
                .frame(width: 22, height: 22)
                .background(Theme.accentSoft)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }

    // MARK: 진행 화면

    private var playScreen: some View {
        VStack(spacing: 14) {
            scoreBar
            Spacer(minLength: 0)
            missionCard
            Spacer(minLength: 0)
            listeningStrip
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var scoreBar: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 1) {
                Text("점수")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.inkMuted)
                Text("\(game.score)")
                    .font(Theme.display(26))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: game.score)
            }
            Spacer()
            if game.combo > 1 {
                Text("\(game.combo) 연속")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accentDeep)
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            }
            VStack(alignment: .trailing, spacing: 1) {
                Text("라운드")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.inkMuted)
                Text("\(game.round) / \(game.totalRounds)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
        }
        .animation(.spring(duration: 0.3), value: game.combo)
        .padding(.top, 6)
    }

    private var missionCard: some View {
        VStack(spacing: 18) {
            ZStack {
                // 진행률에 따라 차오르는 배경
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.surface)
                GeometryReader { geometry in
                    VStack {
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(fillColor.opacity(0.22))
                            .frame(height: geometry.size.height * game.progress)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                VStack(spacing: 14) {
                    Image(systemName: game.mission.symbol)
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(fillColor)
                        .symbolEffect(.bounce, value: game.round)
                    Text(game.mission.title)
                        .font(Theme.display(34))
                        .foregroundStyle(Theme.ink)
                    Text(game.mission.hint)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkMuted)
                    difficultyDots
                }
                .padding(24)

                overlayBadge
            }
            .frame(minHeight: 280, maxHeight: 390)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(strokeColor, lineWidth: 2)
            )
            .scaleEffect(cardScale)
            .animation(.easeOut(duration: 0.25), value: game.progress)

            timerBar
        }
    }

    private var difficultyDots: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { level in
                Circle()
                    .fill(level <= game.mission.difficulty ? Theme.accent : Theme.border)
                    .frame(width: 6, height: 6)
            }
        }
    }

    @ViewBuilder
    private var overlayBadge: some View {
        switch game.phase {
        case .counting(let value):
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.background.opacity(0.92))
                Text("\(value)")
                    .font(Theme.display(76))
                    .foregroundStyle(Theme.accent)
                    .transition(.scale)
                    .id(value)
            }
        case .cleared(let gained):
            badge(text: "성공  +\(gained)", color: Theme.success)
        case .missed:
            badge(text: "시간 초과", color: Theme.inkMuted)
        default:
            EmptyView()
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.display(24))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.3), radius: 12, y: 4)
            .transition(.scale.combined(with: .opacity))
    }

    private var timerBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.border)
                    Capsule()
                        .fill(game.timeLeft < 3 ? Theme.accentDeep : Theme.accent)
                        .frame(width: geometry.size.width * (game.timeLeft / game.roundDuration))
                }
            }
            .frame(height: 8)
            .animation(.linear(duration: 0.05), value: game.timeLeft)

            HStack {
                Text(String(format: "%.1f초 남음", game.timeLeft))
                    .font(.caption2)
                    .foregroundStyle(Theme.inkMuted)
                    .monospacedDigit()
                Spacer()
                Button("건너뛰기") { game.skip() }
                    .font(.caption2.weight(.semibold))
                    .tint(Theme.inkMuted)
            }
        }
    }

    private var listeningStrip: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.variableColor.iterative, isActive: classifier.isRunning)
                Text(game.heardLabel.isEmpty ? "소리를 기다리는 중" : "인식: \(game.heardLabel)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Spacer()
                Text(String(format: "%.0f%%", game.progress * 100))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(fillColor)
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.border.opacity(0.6))
                    Capsule()
                        .fill(Theme.accent.opacity(0.7))
                        .frame(width: geometry.size.width * classifier.level)
                }
            }
            .frame(height: 4)
            .animation(.linear(duration: 0.08), value: classifier.level)
        }
        .card()
    }

    // MARK: 결과 화면

    private var resultScreen: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(game.grade)
                        .font(Theme.display(40))
                        .foregroundStyle(Theme.accent)
                    Text("\(game.score)점 · \(game.clearedCount)/\(game.totalRounds) 성공 · 최고 연속 \(game.bestCombo)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkMuted)
                    if game.score >= game.highScore, game.score > 0 {
                        Text("최고 기록 경신")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Theme.success)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 30)

                VStack(spacing: 0) {
                    ForEach(Array(game.log.enumerated()), id: \.element.id) { index, result in
                        HStack(spacing: 12) {
                            Image(systemName: result.cleared ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(result.cleared ? Theme.success : Theme.inkMuted)
                            Text(result.mission.title)
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(String(format: "최고 신뢰도 %.0f%%", result.peak * 100))
                                .font(.caption)
                                .foregroundStyle(Theme.inkMuted)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 10)
                        if index < game.log.count - 1 {
                            Rectangle().fill(Theme.border).frame(height: 1)
                        }
                    }
                }
                .card()

                Text("실패한 미션은 실험실 탭에서 windowDuration과 임계값을 조정해 다시 확인할 수 있다.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button { game.start() } label: {
                    Text("다시 도전")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: 보조

    private var fillColor: Color {
        if case .cleared = game.phase { return Theme.success }
        return Theme.accent
    }

    private var strokeColor: Color {
        switch game.phase {
        case .cleared: return Theme.success
        case .missed: return Theme.border
        default: return game.progress > 0.6 ? Theme.accent : Theme.border
        }
    }

    private func bump() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.45)) { cardScale = 1.06 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cardScale = 1 }
        }
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
}
