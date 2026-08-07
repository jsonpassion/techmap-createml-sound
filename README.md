# TechMap, Create ML 사운드 분류 세션

세 산출물이 같은 파라미터 집합(`windowDuration`, `overlapFactor`, 신뢰도 임계값)을 공유합니다.
모든 수치는 Xcode 26.0 SDK와 실제 학습 결과에서 직접 확인한 값입니다.

## 배포된 링크 (GitHub Pages)

- 튜토리얼 웹앱: https://jsonpassion.github.io/techmap-createml-sound/
- 키노트 45장: https://jsonpassion.github.io/techmap-createml-sound/deck/slides.html
- 키노트 PPTX: https://jsonpassion.github.io/techmap-createml-sound/deck/TechMap_CreateML_Sound.pptx

## 구성

| 산출물 | 위치 | 역할 |
|---|---|---|
| 키노트 (PPTX) | `deck/TechMap_CreateML_Sound.pptx` | 45장, Keynote와 PowerPoint에서 편집 |
| 키노트 (웹) | `deck/slides.html` | 방향키와 클릭으로 넘기는 슬라이드 |
| 튜토리얼 웹앱 | `web/index.html` | 절차, 인터랙션 위젯 4종, Lottie 애니메이션 2종 |
| 데모 앱 | `ios/SoundHook.xcodeproj` | SwiftUI, 챌린지 게임과 파라미터 실험실 |
| 배포본 | `docs/` | GitHub Pages가 서빙하는 사본 |

## 데모 앱 실행

```bash
open "ios/SoundHook.xcodeproj"
```

시뮬레이터가 Mac의 마이크를 사용하므로 별도 기기 없이 시연할 수 있습니다.
모델 파일이 없고 Apple 내장 분류기(`SNClassifierIdentifier.version1`, 303클래스)를 사용합니다.
직접 학습한 모델로 교체하려면 `ios/SoundHook/SoundClassifier.swift`의 요청 생성 한 줄만 바꾸면 됩니다.

## 실습용 공개 데이터셋

| 데이터셋 | 규모 | 라이선스 |
|---|---|---|
| [UrbanSound8K](https://huggingface.co/datasets/danavery/urbansound8K) | 10클래스, 8,732클립, 4초 이하 | CC BY-NC 4.0 |
| [ESC-50 (ESC-10 부분집합 포함)](https://huggingface.co/datasets/ashraq/esc50) | 50클래스, 2,000클립, 5초 | CC BY-NC |
| [Google Speech Commands](https://huggingface.co/datasets/google/speech_commands) | 코어 10단어, 10만 클립 이상, 1초 | CC BY 4.0 |

앞의 둘은 비상업 라이선스입니다. `background` 클래스는 어느 데이터셋에도 없으므로 직접 녹음해 추가해야 합니다.

## 확인된 기본값

| 대상 | 값 |
|---|---|
| 내장 분류기 클래스 수 | 303 |
| 내장 분류기 기본 `windowDuration` | 3.0초 (허용 0.5–15.0초) |
| 내장 분류기 기본 `overlapFactor` | 0.5 |
| 학습된 `.mlmodel` 입력 | `audioSamples [15600]`, `sampleRate 16000` |
| `MLSoundClassifier` `maxIterations` | 25 |
| `MLSoundClassifier` `featureExtractionTimeWindowSize` | 0.975초 |
| `MLSoundClassifier` `validation` | `.split(strategy: .automatic)` |
| `MLSoundClassifier` `algorithm` | `.transferLearning(featureExtractor: .audioFeaturePrint(type: .sound, revision: 1), classifier: .logisticRegressor)` |
| `MLSoundClassifier` `batchSize` | 32 |
