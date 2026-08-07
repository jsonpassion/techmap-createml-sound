import Foundation

/// 챌린지 미션 하나. `identifiers`는 내장 분류기(`.version1`)의 레이블이며,
/// 하나라도 목표 신뢰도를 넘으면 성공으로 판정한다.
struct Mission: Identifiable, Equatable {
    let id: String
    let title: String
    let hint: String
    let symbol: String
    let identifiers: [String]
    let difficulty: Int          // 1...3, 점수 배수

    static func == (lhs: Mission, rhs: Mission) -> Bool { lhs.id == rhs.id }
}

enum MissionDeck {

    /// 사람이 즉석에서 만들 수 있는 소리만 선별했다.
    static let all: [Mission] = [
        Mission(id: "clapping", title: "박수", hint: "손뼉을 리듬 있게",
                symbol: "hands.clap.fill", identifiers: ["clapping", "applause"], difficulty: 1),
        Mission(id: "speech", title: "말하기", hint: "아무 문장이나 또박또박",
                symbol: "text.bubble.fill", identifiers: ["speech"], difficulty: 1),
        Mission(id: "laughter", title: "웃음", hint: "하하하 소리 내어",
                symbol: "face.smiling.fill", identifiers: ["laughter", "giggling", "chuckle_chortle", "belly_laugh"], difficulty: 2),
        Mission(id: "whistling", title: "휘파람", hint: "한 음을 길게",
                symbol: "wind", identifiers: ["whistling"], difficulty: 3),
        Mission(id: "singing", title: "노래", hint: "아무 멜로디나",
                symbol: "music.microphone", identifiers: ["singing", "humming"], difficulty: 2),
        Mission(id: "cough", title: "기침", hint: "가볍게 두세 번",
                symbol: "lungs.fill", identifiers: ["cough", "throat_clearing"], difficulty: 2),
        Mission(id: "finger_snapping", title: "손가락 튕기기", hint: "마이크 가까이서",
                symbol: "hand.point.up.left.fill", identifiers: ["finger_snapping"], difficulty: 3),
        Mission(id: "knock", title: "노크", hint: "책상을 똑똑",
                symbol: "hand.tap.fill", identifiers: ["knock", "tap", "thump_thud"], difficulty: 2),
        Mission(id: "typing", title: "타자", hint: "키보드를 빠르게",
                symbol: "keyboard.fill", identifiers: ["typing", "typing_computer_keyboard", "writing"], difficulty: 2),
        Mission(id: "shout", title: "고함", hint: "짧고 크게",
                symbol: "exclamationmark.bubble.fill", identifiers: ["shout", "yell", "screaming"], difficulty: 1),
        Mission(id: "whispering", title: "속삭임", hint: "숨소리를 섞어 작게",
                symbol: "ear.fill", identifiers: ["whispering", "breathing"], difficulty: 3),
        Mission(id: "sneeze", title: "재채기", hint: "에취 소리를 흉내",
                symbol: "wind.snow", identifiers: ["sneeze", "nose_blowing"], difficulty: 3),
        Mission(id: "crumpling", title: "종이 구기기", hint: "종이나 비닐을 손에 쥐고",
                symbol: "doc.fill", identifiers: ["crumpling_crinkling", "tearing"], difficulty: 3),
        Mission(id: "silence", title: "완전한 정적", hint: "3초간 아무 소리도 내지 않기",
                symbol: "speaker.slash.fill", identifiers: ["silence"], difficulty: 1)
    ]

    /// 직전 미션과 겹치지 않게 뽑는다.
    static func next(excluding previous: Mission?) -> Mission {
        let pool = all.filter { $0.id != previous?.id }
        return pool.randomElement() ?? all[0]
    }
}
