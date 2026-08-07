# TechMap · Create ML 사운드 분류 세션

세 산출물이 동일한 파라미터 집합(`windowDuration`, `overlapFactor`, 신뢰도 임계값)을 공유한다.
수치는 Xcode 26.0 SDK에서 직접 조회한 값 기준이다.

| 산출물 | 위치 | 역할 |
|---|---|---|
| 키노트 (PPTX) | `deck/TechMap_CreateML_Sound.pptx` | 18장. Keynote·PowerPoint에서 편집 |
| 키노트 (웹) | `deck/slides.html` | 방향키·클릭으로 넘기는 슬라이드 덱 |
| 튜토리얼 웹앱 | `web/index.html` | 재현 가능한 절차, 코드, 분석 윈도 시뮬레이터 |
| 데모 앱 | `ios/SoundHook.xcodeproj` | SwiftUI. 챌린지 게임 + 파라미터 실험실 |

## 배포된 링크

- 튜토리얼: https://claude.ai/code/artifact/98250d23-b9ec-443c-86d7-398cf0baeb84
- 키노트: https://claude.ai/code/artifact/a172de88-ff40-4fd5-8c2c-0e1a51df6ddc

## 데모 앱 실행

```bash
open "ios/SoundHook.xcodeproj"
```

시뮬레이터는 Mac의 마이크를 사용하므로 별도 기기 없이 시연할 수 있다.
모델 파일이 없으며 Apple 내장 분류기(`SNClassifierIdentifier.version1`, 303개 클래스)를 사용한다.

직접 학습한 모델로 교체하려면 `ios/SoundHook/SoundClassifier.swift`의 요청 생성 한 줄만 바꾼다.

```swift
let request = try SNClassifySoundRequest(mlModel: EventSound().model)
```

## 확인된 기본값

| 대상 | 값 |
|---|---|
| 내장 분류기 클래스 수 | 303 |
| 내장 분류기 기본 `windowDuration` | 3.0초 (허용 0.5–15.0초) |
| 내장 분류기 기본 `overlapFactor` | 0.5 |
| `MLSoundClassifier` `maxIterations` | 25 |
| `MLSoundClassifier` `featureExtractionTimeWindowSize` | 0.975초 |
| `MLSoundClassifier` `validation` | `.split(strategy: .automatic)` |
| `MLSoundClassifier` `algorithm` | `.transferLearning(featureExtractor: .audioFeaturePrint(type: .sound, revision: 1), classifier: .logisticRegressor)` |
| `MLSoundClassifier` `batchSize` | 32 |
