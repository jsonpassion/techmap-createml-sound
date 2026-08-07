import Foundation

/// 내장 분류기(`SNClassifierIdentifier.version1`)의 레이블은 영문 스네이크 케이스다.
/// 데모에서 자주 잡히는 레이블만 한국어 표기와 아이콘을 붙이고, 나머지는 자동 변환한다.
enum LabelCatalog {

    private static let korean: [String: String] = [
        "speech": "말소리",
        "shout": "고함",
        "screaming": "비명",
        "whispering": "속삭임",
        "laughter": "웃음",
        "singing": "노래",
        "humming": "허밍",
        "whistling": "휘파람",
        "breathing": "숨소리",
        "cough": "기침",
        "sneeze": "재채기",
        "chatter": "여러 명의 대화",
        "crowd": "군중",
        "babble": "웅성거림",
        "finger_snapping": "손가락 튕기기",
        "clapping": "박수",
        "applause": "박수 갈채",
        "cheering": "환호",
        "typing": "타자",
        "typing_computer_keyboard": "키보드 타자",
        "writing": "필기",
        "music": "음악",
        "piano": "피아노",
        "guitar": "기타",
        "acoustic_guitar": "어쿠스틱 기타",
        "electric_guitar": "일렉트릭 기타",
        "drum": "드럼",
        "drum_kit": "드럼 세트",
        "violin_fiddle": "바이올린",
        "synthesizer": "신시사이저",
        "dog": "개",
        "dog_bark": "개 짖는 소리",
        "cat": "고양이",
        "cat_meow": "고양이 울음",
        "bird": "새",
        "bird_chirp_tweet": "새 지저귐",
        "water": "물",
        "rain": "비",
        "water_tap_faucet": "수도꼭지",
        "liquid_pouring": "액체 따르는 소리",
        "wind": "바람",
        "thunder": "천둥",
        "fire_crackle": "불 타는 소리",
        "door": "문",
        "door_slam": "문 닫는 소리",
        "knock": "노크",
        "door_bell": "초인종",
        "telephone_bell_ringing": "전화벨",
        "ringtone": "벨소리",
        "alarm_clock": "알람",
        "siren": "사이렌",
        "smoke_detector": "화재 감지기",
        "car_horn": "자동차 경적",
        "engine": "엔진",
        "engine_idling": "엔진 공회전",
        "traffic_noise": "교통 소음",
        "train": "기차",
        "aircraft": "항공기",
        "helicopter": "헬리콥터",
        "vacuum_cleaner": "청소기",
        "hair_dryer": "헤어드라이어",
        "microwave_oven": "전자레인지",
        "blender": "블렌더",
        "dishes_pots_pans": "그릇·냄비",
        "cutlery_silverware": "식기",
        "chopping_food": "재료 써는 소리",
        "frying_food": "튀기는 소리",
        "toilet_flush": "변기 물 내림",
        "toothbrush": "칫솔질",
        "mechanical_fan": "선풍기",
        "air_conditioner": "에어컨",
        "printer": "프린터",
        "camera": "카메라",
        "hammer": "망치",
        "drill": "드릴",
        "power_tool": "전동 공구",
        "glass_clink": "유리잔 부딪힘",
        "glass_breaking": "유리 깨짐",
        "beep": "비프음",
        "click": "클릭",
        "tap": "톡 치는 소리",
        "squeak": "삐걱임",
        "keys_jangling": "열쇠 소리",
        "zipper": "지퍼",
        "scissors": "가위",
        "clock": "시계",
        "tick_tock": "초침 소리",
        "whoosh_swoosh_swish": "휙 지나가는 소리",
        "thump_thud": "둔탁한 충격음",
        "crumpling_crinkling": "구기는 소리",
        "tearing": "찢는 소리",
        "silence": "무음"
    ]

    private static let icons: [(prefix: String, symbol: String)] = [
        ("speech", "text.bubble"), ("shout", "text.bubble"), ("scream", "text.bubble"),
        ("whisper", "text.bubble"), ("laugh", "face.smiling"), ("sing", "music.microphone"),
        ("chatter", "person.2.wave.2"), ("crowd", "person.3"), ("babble", "person.3"),
        ("clap", "hands.clap"), ("applause", "hands.clap"), ("cheer", "hands.clap"),
        ("typing", "keyboard"), ("music", "music.note"), ("piano", "pianokeys"),
        ("guitar", "guitars"), ("drum", "music.note"), ("violin", "music.note"),
        ("dog", "dog"), ("cat", "cat"), ("bird", "bird"), ("insect", "ant"),
        ("water", "drop"), ("rain", "cloud.rain"), ("liquid", "drop"), ("wind", "wind"),
        ("thunder", "cloud.bolt"), ("fire", "flame"), ("door", "door.left.hand.open"),
        ("knock", "hand.tap"), ("telephone", "phone"), ("ringtone", "bell"),
        ("alarm", "alarm"), ("siren", "light.beacon.max"), ("car", "car"),
        ("engine", "engine.combustion"), ("traffic", "car.2"), ("train", "tram"),
        ("aircraft", "airplane"), ("helicopter", "airplane"), ("vacuum", "wind"),
        ("glass", "wineglass"), ("beep", "waveform"), ("click", "cursorarrow.click"),
        ("clock", "clock"), ("tick", "clock"), ("silence", "speaker.slash")
    ]

    static func displayName(for identifier: String) -> String {
        if let name = korean[identifier] { return name }
        return identifier.replacingOccurrences(of: "_", with: " ")
    }

    static func symbolName(for identifier: String) -> String {
        for entry in icons where identifier.contains(entry.prefix) {
            return entry.symbol
        }
        return "waveform"
    }
}
