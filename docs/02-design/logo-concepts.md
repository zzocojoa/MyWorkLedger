# WorkLedger Logo Concepts

## 1. 목적

이 문서는 `내근무장부` / `WorkLedger` 로고 시안 3개를 비교하고, 실제 asset 반영 전 선택 기준과 변환 계획을 정리한다.

이번 단계에서는 앱 코드, Android 리소스, Play Console export 파일을 만들지 않는다. 실제 반영은 최종 시안 승인 후 별도 작업으로 진행한다.

기준 문서:

- `DESIGN-airtable.md`
- `docs/02-design/logo-asset-spec.md`
- `docs/02-design/design-system-rules.md`
- `docs/02-design/mockup.md`

공식 기준 확인:

- Google Play icon: https://developer.android.com/distribute/google-play/resources/icon-design-specifications
- Android adaptive icon: https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
- Google Play feature graphic: https://support.google.com/googleplay/android-developer/answer/9866151

## 2. 시안 파일

시안 SVG는 PR에서 보존되도록 repo 내부 문서 asset 경로에 저장한다.

```text
docs/02-design/assets/logo-concepts/
├── concept-a-ledger-check.svg
├── concept-b-time-line.svg
└── concept-c-month-cards.svg
```

비교 보드는 작업용 preview로 gstack 디자인 작업 영역에 보관한다. PR 보존 대상은 SVG 시안과 이 문서다.

## 3. 평가 기준

| 기준 | 설명 |
|---|---|
| 48px 가독성 | Android 런처와 Play Store 작은 노출에서 심볼이 읽히는지 확인한다. |
| 66dp 안전 영역 | adaptive icon foreground 핵심 요소가 중앙 안전 영역 안에 들어가는지 본다. |
| 단색화 가능성 | themed icon으로 변환했을 때 의미가 유지되는지 본다. |
| WorkLedger 의미 적합성 | 개인 근무 기록, 장부, 빠른 완료감을 표현하되 감시, 급여 확정, 법적 증빙처럼 보이지 않아야 한다. |
| 디자인 시스템 적합성 | `#181d26`, `#ffffff`, `#aa2d00`, `#0a2e0e`, `#f5e9d4`, `#fcab79` 안에서 조용한 업무 도구 톤을 유지한다. |
| Android vector 적합성 | path, rect, line 중심으로 구성되어 vector drawable 변환이 쉬운지 본다. |

## 4. 시안 비교

| 시안 | 개념 | 장점 | 리스크 | 판단 |
|---|---|---|---|---|
| A. Ledger Check | 장부 한 장과 체크 표시 | 가장 직관적이고 48px에서 읽힘이 좋다. Play icon, adaptive icon, themed icon을 같은 구조로 가져가기 쉽다. | 체크 표시가 일반 할 일 앱처럼 보일 수 있다. | 1순위 추천 |
| B. Time Line | 짧은 시간선과 체크 표시 | 10초 기록, 빠른 완료감을 표현한다. 선 기반이라 vector 변환이 쉽다. | 작은 크기에서 근무 장부 의미가 약하고, 타임라인 앱처럼 보일 수 있다. | 보조 후보 |
| C. Monthly Cards | 겹친 월간 카드와 체크 표시 | 월간 요약, 다시 보기 가치를 표현한다. feature graphic 배경 요소로 활용하기 좋다. | 48px와 themed icon에서 정보가 뭉칠 수 있다. | feature graphic 요소로만 추천 |

## 5. 추천 방향

최종 로고 방향은 **A. Ledger Check**를 추천한다.

이유:

- `logo-asset-spec.md`의 추천 방향인 `장부 + 체크`와 가장 직접적으로 맞다.
- 48px, 72px, 96px 축소에서도 장부와 체크가 분리되어 보인다.
- Android adaptive icon의 foreground/background 분리가 단순하다.
- themed icon에서는 장부 외곽과 체크만 단색으로 남길 수 있다.
- Play icon에서 텍스트 없이 앱 의미를 전달한다.

보완 방향:

- 체크 표시가 일반 할 일 앱처럼 보이지 않도록 장부 상단의 짧은 기록선 2-3개를 유지한다.
- foreground 심볼은 66dp 안전 영역 안에서 장부 실루엣이 먼저 보이게 둔다.
- C 시안의 겹친 월간 카드 motif는 feature graphic의 배경 카드로 활용한다.

## 6. 선택 후 변환 계획

### 6.1 원본 source

승인 후 다음 source asset을 만든다.

```text
assets/brand/source/workledger-logo-master.svg
```

원본에는 다음 레이어를 명확히 분리한다.

| 레이어 | 역할 |
|---|---|
| background | Play icon 및 adaptive icon 배경색 |
| foreground-ledger | 장부 외곽과 기록선 |
| foreground-check | 체크 표시 |
| monochrome | themed icon 전용 단색 심볼 |

### 6.2 Google Play app icon

export 대상:

```text
assets/brand/google-play/workledger-play-icon-512.png
```

규칙:

- `512px x 512px`, `32-bit PNG`, `sRGB`, `1024KB` 이하로 export한다.
- 배경은 투명하게 두지 않고 `#181d26`을 채운다.
- export 파일에 둥근 모서리와 외부 shadow를 넣지 않는다.
- 텍스트, 순위, 가격, 다운로드 유도 문구를 넣지 않는다.

### 6.3 Android adaptive icon

리소스 대상:

```text
android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
android/app/src/main/res/drawable/ic_launcher_background.xml
android/app/src/main/res/drawable/ic_launcher_foreground.xml
android/app/src/main/res/drawable/ic_launcher_monochrome.xml
```

규칙:

- background, foreground, monochrome을 분리한다.
- 각 layer는 `108dp x 108dp` 기준으로 만든다.
- 핵심 로고는 중앙 `66dp x 66dp` 안전 영역 안에 둔다.
- foreground에는 mask, rounded corner, 외곽 shadow를 넣지 않는다.
- 가능하면 vector drawable을 우선한다.

### 6.4 Google Play feature graphic

export 대상:

```text
assets/brand/google-play/workledger-feature-graphic-1024x500.png
```

방향:

- app icon 확대판이 아니라 앱의 실제 가치인 10초 근무 기록, 월간 요약, 연차 관리를 보여준다.
- white canvas와 dark ink를 기본으로 두고, C 시안의 월간 카드 motif를 보조 배경으로 사용한다.
- 핵심 요소는 중앙에 두고 가장자리는 잘려도 되는 배경 요소만 둔다.
- 큰 문구는 1개만 사용한다.

문구 후보:

```text
근무 기록을 빠르게 남기고, 월말에 다시 본다.
```

alt text 후보:

```text
WorkLedger의 근무 기록, 월간 요약, 연차 관리 화면을 조용한 업무 도구 톤으로 보여주는 그래픽
```

## 7. 승인 후 작업 순서

1. `A. Ledger Check`를 기준으로 master SVG를 정리한다.
2. 48px, 72px, 96px, 512px 축소 미리보기를 만든다.
3. 원형, squircle, 둥근 사각형 mask 미리보기를 확인한다.
4. monochrome layer를 별도로 검토한다.
5. Play icon PNG와 Android vector drawable을 생성한다.
6. feature graphic을 별도 composition으로 만든다.
7. Flutter/Android 리소스 반영 후 아래 명령을 실행한다.

```bash
$HOME/.local/share/flutter-stable/bin/dart format .
$HOME/.local/share/flutter-stable/bin/flutter analyze --no-pub
$HOME/.local/share/flutter-stable/bin/flutter test
$HOME/.local/share/flutter-stable/bin/flutter build apk --debug
```

8. Android 실기기에서 launcher icon, themed icon, 앱 실행을 확인한다.

## 8. 현재 결론

현재 단계의 결론은 다음과 같다.

- 로고 시안은 3개를 만들었다.
- 최종 방향은 `A. Ledger Check`를 추천한다.
- 실제 앱 리소스와 Play export는 아직 만들지 않았다.
- 앱 코드와 Android 리소스 반영은 별도 승인 후 진행한다.
