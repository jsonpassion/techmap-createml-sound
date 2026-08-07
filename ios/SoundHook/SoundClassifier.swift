import AVFoundation
import Combine
import CoreMedia
import Foundation
import SoundAnalysis

struct Classification: Identifiable, Equatable {
    let identifier: String
    let confidence: Double
    var id: String { identifier }
    var displayName: String { LabelCatalog.displayName(for: identifier) }
}

/// 마이크 입력 → SNAudioStreamAnalyzer → SNClassifySoundRequest(.version1) 파이프라인.
///
/// 학습 없이 Apple 내장 사운드 분류기를 사용한다. 내장 분류기는 Create ML의
/// `MLSoundClassifier`와 동일한 구조(오디오 특징 추출기 + 분류기)로 만들어졌으며,
/// `windowDuration`·`overlapFactor`는 Create ML 학습 파라미터와 1:1로 대응한다.
@MainActor
final class SoundClassifier: NSObject, ObservableObject {

    // MARK: 출력

    @Published private(set) var results: [Classification] = []
    @Published private(set) var isRunning = false
    @Published private(set) var level: Double = 0          // 입력 레벨 0...1
    @Published private(set) var statusMessage: String = "대기 중"
    @Published private(set) var analyzedWindows: Int = 0

    /// 내장 분류기가 알고 있는 레이블 수(현행 SDK 기준 303개).
    let knownClassificationCount: Int
    /// 내장 분류기가 허용하는 분석 윈도 길이 범위(초).
    let windowDurationRange: ClosedRange<Double>

    // MARK: 조절 가능한 추론 파라미터

    /// 분석 윈도 길이. 길수록 문맥이 넓어지고 결과 빈도는 낮아진다.
    @Published var windowDuration: Double = 1.5 { didSet { restartIfNeeded() } }
    /// 윈도 겹침 비율 [0.0, 1.0). 0.5는 모든 소리가 최소 한 윈도의 중앙 근처에 놓이도록 한다.
    @Published var overlapFactor: Double = 0.5 { didSet { restartIfNeeded() } }
    /// 이 값 미만의 신뢰도는 표시하지 않는다.
    @Published var confidenceThreshold: Double = 0.30
    /// 상위 몇 개까지 표시할지.
    @Published var topK: Int = 5

    // MARK: 내부

    private let engine = AVAudioEngine()
    private let analysisQueue = DispatchQueue(label: "com.techmap.soundhook.analysis")
    private var analyzer: SNAudioStreamAnalyzer?
    private var observer: ResultsObserver?
    private var inputFormat: AVAudioFormat?
    /// 사용자가 분석을 원하는 상태인지. 슬라이더 조작으로 잠시 멈춘 것과 정지 버튼을 구분한다.
    private var wantsRunning = false
    private var restartWorkItem: DispatchWorkItem?
    /// 정지 직후 completeAnalysis()가 마지막 버퍼를 흘려보내며 결과를 하나 더 만듭니다.
    /// 그 결과가 화면에 남지 않도록 수신 여부를 따로 관리합니다.
    private var acceptsResults = false

    override init() {
        // 요청을 한 번 만들어 내장 분류기의 정적 정보를 읽는다.
        let probe = try? SNClassifySoundRequest(classifierIdentifier: .version1)
        knownClassificationCount = probe?.knownClassifications.count ?? 0
        switch probe?.windowDurationConstraint {
        case .durationRange(let range):
            // 상한이 15.0000625처럼 딱 떨어지지 않으면 슬라이더 눈금이 어긋난다.
            let lower = (CMTimeGetSeconds(range.start) * 4).rounded(.up) / 4
            let upper = (CMTimeGetSeconds(range.end) * 4).rounded(.down) / 4
            windowDurationRange = lower...upper
        case .enumeratedDurations(let durations):
            let seconds = durations.map(CMTimeGetSeconds)
            windowDurationRange = (seconds.min() ?? 0.5)...(seconds.max() ?? 15)
        default:
            windowDurationRange = 0.5...15
        }
        super.init()
    }

    // MARK: 제어

    func start() {
        wantsRunning = true
        guard !isRunning else { return }
        Task {
            guard await requestPermission() else {
                statusMessage = "마이크 권한이 거부되었습니다"
                return
            }
            // 권한 대기 중에 정지 버튼을 눌렀다면 시작하지 않는다.
            guard wantsRunning else { return }
            do {
                try configureSession()
                try startEngine()
                isRunning = true
                statusMessage = "분석 중"
            } catch {
                statusMessage = "시작 실패: \(error.localizedDescription)"
            }
        }
    }

    func stop() {
        wantsRunning = false
        acceptsResults = false
        restartWorkItem?.cancel()
        restartWorkItem = nil
        results = []
        guard isRunning || engine.isRunning else {
            isRunning = false
            statusMessage = "정지됨"
            return
        }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        analyzer?.completeAnalysis()
        analyzer = nil
        observer = nil
        isRunning = false
        level = 0
        statusMessage = "정지됨"
    }

    func reset() {
        results = []
        analyzedWindows = 0
    }

    /// 슬라이더를 드래그하는 동안 파이프라인을 매 단계 재구성하면 입력이 끊긴다.
    /// 마지막 변경으로부터 잠시 기다렸다가 한 번만 다시 만든다.
    private func restartIfNeeded() {
        guard isRunning || wantsRunning else { return }
        restartWorkItem?.cancel()
        teardownEngine()
        statusMessage = "파라미터 적용 중"
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.wantsRunning else { return }
            do {
                try self.startEngine()
                self.isRunning = true
                self.statusMessage = "분석 중"
            } catch {
                self.statusMessage = "재시작 실패: \(error.localizedDescription)"
            }
        }
        restartWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    /// 오디오 그래프만 정리한다. 세션과 사용자 의도는 그대로 둔다.
    private func teardownEngine() {
        acceptsResults = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        analyzer?.completeAnalysis()
        analyzer = nil
        observer = nil
        isRunning = false
        level = 0
        results = []
    }

    // MARK: 파이프라인

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startEngine() throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(domain: "SoundHook", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "사용 가능한 입력 장치가 없습니다"])
        }
        inputFormat = format

        let analyzer = SNAudioStreamAnalyzer(format: format)
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        // 분석 윈도 길이는 분류기의 제약 범위 안에서만 유효하다.
        request.windowDuration = CMTime(seconds: windowDuration, preferredTimescale: 48_000)
        request.overlapFactor = overlapFactor

        let observer = ResultsObserver { [weak self] classifications in
            Task { @MainActor in
                guard let self, self.acceptsResults else { return }
                self.analyzedWindows += 1
                self.results = classifications
            }
        }
        try analyzer.add(request, withObserver: observer)

        self.analyzer = analyzer
        self.observer = observer

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 8_192, format: format) { [weak self] buffer, time in
            guard let self else { return }
            self.analysisQueue.async {
                analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
            let rms = Self.rms(of: buffer)
            Task { @MainActor in self.level = rms }
        }

        engine.prepare()
        try engine.start()
        acceptsResults = true
    }

    private static func rms(of buffer: AVAudioPCMBuffer) -> Double {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum: Float = 0
        for index in 0..<count { sum += channel[index] * channel[index] }
        let rms = sqrt(sum / Float(count))
        let db = 20 * log10(max(rms, 1e-7))
        return Double(min(max((db + 60) / 60, 0), 1)) // -60dB ~ 0dB 를 0...1 로
    }

    // MARK: 표시용 파생값

    var visibleResults: [Classification] {
        results
            .filter { $0.confidence >= confidenceThreshold }
            .prefix(topK)
            .map { $0 }
    }

    /// 새 결과가 나오는 간격 = windowDuration × (1 − overlapFactor).
    var hopSeconds: Double { windowDuration * (1 - overlapFactor) }
}

/// SNResultsObserving 는 클래스 전용 프로토콜이므로 별도 옵저버로 분리한다.
private final class ResultsObserver: NSObject, SNResultsObserving {
    private let onResult: ([Classification]) -> Void

    init(onResult: @escaping ([Classification]) -> Void) {
        self.onResult = onResult
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        let classifications = result.classifications.prefix(10).map {
            Classification(identifier: $0.identifier, confidence: $0.confidence)
        }
        onResult(Array(classifications))
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        onResult([])
    }
}
