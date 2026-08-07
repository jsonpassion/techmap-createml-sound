import SwiftUI

/// 키노트·튜토리얼 웹앱과 동일한 팔레트에 게임용 상태 색을 더했다.
enum Theme {
    static let background = Color(red: 0.980, green: 0.976, blue: 0.961) // #FAF9F5
    static let surface = Color.white
    static let border = Color(red: 0.898, green: 0.886, blue: 0.859)     // #E5E2DB
    static let ink = Color(red: 0.098, green: 0.098, blue: 0.098)        // #191919
    static let inkMuted = Color(red: 0.435, green: 0.420, blue: 0.396)   // #6F6B65
    static let accent = Color(red: 0.851, green: 0.467, blue: 0.341)     // #D97757
    static let accentDeep = Color(red: 0.761, green: 0.345, blue: 0.184) // #C25830
    static let accentSoft = Color(red: 0.976, green: 0.925, blue: 0.898) // #F9ECE5
    static let success = Color(red: 0.310, green: 0.549, blue: 0.325)    // #4F8C53
    static let successSoft = Color(red: 0.918, green: 0.949, blue: 0.918)

    static let mono = Font.system(.footnote, design: .monospaced)
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static let confetti: [Color] = [
        Color(red: 0.851, green: 0.467, blue: 0.341),
        Color(red: 0.945, green: 0.741, blue: 0.353),
        Color(red: 0.310, green: 0.549, blue: 0.325),
        Color(red: 0.400, green: 0.545, blue: 0.729),
        Color(red: 0.643, green: 0.412, blue: 0.612)
    ]
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
}

/// 성공 시 짧게 터지는 종이 조각. 파티클 위치는 버스트마다 한 번만 계산한다.
struct ConfettiBurst: View {
    let seed: Int
    private let count = 46

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1000)
                var generator = SeededGenerator(seed: UInt64(seed &* 7919 &+ 13))
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.42)

                for index in 0..<count {
                    let angle = Double.random(in: -Double.pi...0, using: &generator)
                    let speed = Double.random(in: 130...330, using: &generator)
                    let spin = Double.random(in: -6...6, using: &generator)
                    let color = Theme.confetti[index % Theme.confetti.count]
                    let life = 1.5
                    let t = min(max(elapsed.truncatingRemainder(dividingBy: 1000) - startTime, 0), life)
                    guard t > 0 else { continue }

                    let x = origin.x + cos(angle) * speed * t
                    let y = origin.y + sin(angle) * speed * t + 420 * t * t
                    let opacity = max(0, 1 - t / life)
                    guard opacity > 0 else { continue }

                    var rect = Path()
                    rect.addRoundedRect(
                        in: CGRect(x: -4, y: -6, width: 8, height: 12),
                        cornerSize: CGSize(width: 2, height: 2)
                    )
                    context.drawLayer { layer in
                        layer.translateBy(x: x, y: y)
                        layer.rotate(by: .radians(spin * t * 2))
                        layer.opacity = opacity
                        layer.fill(rect, with: .color(color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { startTime = Date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000) }
    }

    @State private var startTime: Double = 0
}

/// 파티클 배치를 버스트마다 동일하게 재현하기 위한 결정적 난수원.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
