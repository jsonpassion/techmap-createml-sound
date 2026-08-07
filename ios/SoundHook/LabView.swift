import SwiftUI

/// 실험실 탭. 챌린지에서 쓰는 것과 동일한 분류기를 파라미터를 바꿔가며 직접 관찰한다.
struct LabView: View {
    @ObservedObject var classifier: SoundClassifier
    @ObservedObject var game: ChallengeGame
    @State private var showsParameterSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headline
                    topResult
                    resultList
                    parameterPanel
                    pipelineFootnote
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("실험실")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showsParameterSheet = true } label: {
                        Image(systemName: "info.circle")
                    }
                    .tint(Theme.accent)
                }
            }
            .sheet(isPresented: $showsParameterSheet) {
                ParameterReferenceView()
            }
            .safeAreaInset(edge: .bottom) { transportBar }
        }
        .onDisappear { if !game.isPlaying { classifier.stop() } }
    }

    // MARK: 섹션

    private var headline: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("학습 없이 시작하는 온디바이스 사운드 분류")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text("Apple 내장 분류기 \(classifier.knownClassificationCount)개 클래스 · SNAudioStreamAnalyzer 실시간 추론")
                .font(.subheadline)
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var topResult: some View {
        let top = classifier.visibleResults.first
        return VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: top?.confidence ?? 0)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.25), value: top?.confidence ?? 0)
                VStack(spacing: 4) {
                    Image(systemName: LabelCatalog.symbolName(for: top?.identifier ?? "waveform"))
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Theme.accent)
                    Text(top.map { String(format: "%.0f%%", $0.confidence * 100) } ?? "—")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                }
            }
            .frame(width: 148, height: 148)

            Text(top?.displayName ?? (classifier.isRunning ? "임계값을 넘는 결과 없음" : "정지 상태"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(top?.identifier ?? "—")
                .font(Theme.mono)
                .foregroundStyle(Theme.inkMuted)

            levelMeter
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private var levelMeter: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.border)
                Capsule()
                    .fill(Theme.accent.opacity(0.75))
                    .frame(width: geometry.size.width * classifier.level)
            }
        }
        .frame(height: 6)
        .animation(.linear(duration: 0.08), value: classifier.level)
    }

    private var resultList: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("상위 \(classifier.topK)개 후보", trailing: "윈도 \(classifier.analyzedWindows)개 분석")
            if classifier.visibleResults.isEmpty {
                Text("신뢰도 \(Int(classifier.confidenceThreshold * 100))% 이상인 결과가 아직 없습니다.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(classifier.visibleResults) { item in
                    ResultRow(item: item)
                }
            }
        }
        .card()
    }

    private var parameterPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("추론 파라미터", trailing: String(format: "결과 간격 %.2fs", classifier.hopSeconds))

            ParameterSlider(
                title: "windowDuration",
                caption: "분석 윈도 길이. 길수록 문맥이 넓어지고 결과는 드물게 나온다.",
                value: $classifier.windowDuration,
                range: classifier.windowDurationRange,
                step: 0.25,
                format: "%.2f s"
            )
            ParameterSlider(
                title: "overlapFactor",
                caption: "윈도 겹침 비율. 0.5는 모든 소리가 최소 한 윈도의 중앙 근처에 놓이게 한다.",
                value: $classifier.overlapFactor,
                range: 0...0.9,
                step: 0.05,
                format: "%.2f"
            )
            ParameterSlider(
                title: "confidenceThreshold",
                caption: "표시 임계값. 모델이 아닌 앱 레벨의 후처리 파라미터다.",
                value: $classifier.confidenceThreshold,
                range: 0...0.95,
                step: 0.05,
                format: "%.2f"
            )

            Divider().overlay(Theme.border)

            ParameterSlider(
                title: "challenge.targetConfidence",
                caption: "챌린지 성공 판정 기준. 올리면 난이도가 상승한다.",
                value: Binding(
                    get: { game.targetConfidence },
                    set: { game.targetConfidence = $0 }
                ),
                range: 0.2...0.9,
                step: 0.05,
                format: "%.2f"
            )
        }
        .card()
    }

    private var pipelineFootnote: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("파이프라인", trailing: nil)
            Text("AVAudioEngine 탭 → SNAudioStreamAnalyzer → SNClassifySoundRequest(.version1) → SNClassificationResult")
                .font(Theme.mono)
                .foregroundStyle(Theme.inkMuted)
            Text("허용 윈도 길이 \(String(format: "%.1f", classifier.windowDurationRange.lowerBound))–\(String(format: "%.1f", classifier.windowDurationRange.upperBound))초. 범위를 벗어난 값은 가장 가까운 지원 값으로 자동 조정된다.")
                .font(.footnote)
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var transportBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(classifier.isRunning ? Theme.accent : Theme.inkMuted)
                    .frame(width: 6, height: 6)
                Text(classifier.statusMessage)
                    .font(.caption2)
                    .foregroundStyle(Theme.inkMuted)
                Spacer()
            }
            HStack(spacing: 12) {
                Button {
                    classifier.isRunning ? classifier.stop() : classifier.start()
                } label: {
                    Label(classifier.isRunning ? "정지" : "분석 시작",
                          systemImage: classifier.isRunning ? "stop.fill" : "mic.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(classifier.isRunning ? Theme.ink : Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                Button {
                    classifier.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(width: 52, height: 52)
                        .background(Theme.surface)
                        .foregroundStyle(Theme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(Theme.border).frame(height: 1) }
    }

    private func sectionTitle(_ title: String, trailing: String?) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - 구성 요소

struct ResultRow: View {
    let item: Classification

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: LabelCatalog.symbolName(for: item.identifier))
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 18)
                Text(item.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(String(format: "%.1f%%", item.confidence * 100))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.inkMuted)
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.accentSoft)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: geometry.size.width * item.confidence)
                }
            }
            .frame(height: 5)
        }
        .animation(.easeOut(duration: 0.2), value: item.confidence)
    }
}

struct ParameterSlider: View {
    let title: String
    let caption: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(Theme.mono)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(String(format: format, value))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(Theme.accent)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(Theme.inkMuted)
        }
    }
}

/// SoundAnalysis 추론 파라미터와 Create ML 학습 파라미터의 대응표.
struct ParameterReferenceView: View {
    @Environment(\.dismiss) private var dismiss

    private let rows: [(String, String, String)] = [
        ("windowDuration", "featureExtractionTimeWindowSize", "특징 추출 단위 시간. Create ML 기본 0.975초, 내장 분류기 기본 3.0초."),
        ("overlapFactor", "overlapFactor", "윈도 겹침 비율. 양쪽 모두 기본값 0.5."),
        ("knownClassifications", "trainingData 레이블", "출력 클래스 목록. 내장 분류기는 303개로 고정."),
        ("—", "maxIterations", "학습 반복 횟수. 기본 25."),
        ("—", "validation", "검증 데이터 분할. 기본 .split(strategy: .automatic)."),
        ("—", "algorithm", "기본 .transferLearning(featureExtractor: .audioFeaturePrint(type: .sound, revision: 1), classifier: .logisticRegressor).")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("추론(SoundAnalysis)과 학습(Create ML)은 같은 파라미터 이름을 공유한다. 이 앱의 슬라이더는 학습 시 결정되는 값을 추론 쪽에서 체험하기 위한 것이다.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkMuted)

                    ForEach(rows, id: \.1) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(row.0).font(Theme.mono).foregroundStyle(Theme.accent)
                                Image(systemName: "arrow.left.arrow.right").font(.caption2).foregroundStyle(Theme.inkMuted)
                                Text(row.1).font(Theme.mono).foregroundStyle(Theme.ink)
                            }
                            Text(row.2)
                                .font(.caption)
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                    }
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("파라미터 대응표")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }.tint(Theme.accent)
                }
            }
        }
    }
}
