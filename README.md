# Create ML 사운드 분류 튜토리얼

CreateML 스터디 4주차 세션 자료입니다. 오디오 분류 모델의 학습 파라미터가
실제 앱의 동작을 어떻게 결정하는지, 슬라이더를 움직여 눈으로 확인할 수 있습니다.

**https://jsonpassion.github.io/techmap-createml-sound/**

- 학습 없이 시작하는 내장 분류기 303클래스
- 템플릿 기본 파라미터와 분석 윈도, 오버랩 시뮬레이터
- 임계값, 연속 판정 시뮬레이터와 배포 체크리스트
- 실습용 공개 데이터셋 안내 (UrbanSound8K, ESC-50, Speech Commands)

모든 수치는 Xcode 26.0 SDK와 실제 학습 결과에서 직접 확인한 값입니다.

## 구조

| 경로 | 역할 |
|---|---|
| `web/index.html` | 튜토리얼 원본 |
| `docs/index.html` | GitHub Pages 배포 사본 |

원본을 수정한 뒤 `docs/`로 복사해 푸시하면 사이트에 반영됩니다.
