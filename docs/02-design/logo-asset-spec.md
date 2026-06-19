# WorkLedger Logo Asset Spec

## 1. 목적

이 문서는 `내근무장부` / `WorkLedger`의 앱 로고, Android 런처 아이콘, Google Play 등록 그래픽을 만들 때 필요한 규격과 저장 위치를 정리한다.

초기 단계에서는 코드, 이미지, Android 리소스를 만들지 않고 규격만 정리했다. 최종 선택 로고 확정 후 이 문서를 기준으로 source asset, Android launcher icon 리소스, Android splash 리소스, Google Play icon export를 만들었다.

공식 기준 확인일: 2026-06-17

공식 기준:

| 대상 | 공식 문서 |
|---|---|
| Google Play app icon | https://developer.android.com/distribute/google-play/resources/icon-design-specifications |
| Android adaptive launcher icon | https://developer.android.com/develop/ui/compose/system/icon_design_adaptive |
| Google Play feature graphic | https://support.google.com/googleplay/android-developer/answer/9866151 |

## 2. 산출물 목록

| 산출물 | 용도 | 먼저 만들 파일 | 최종 export |
|---|---|---|---|
| 로고 원본 | 모든 로고 산출물의 기준 파일 | `assets/brand/source/workledger-logo-master.svg` 또는 Figma source | 없음 |
| Google Play app icon | Play Console 앱 아이콘 업로드 | 로고 원본에서 export | `assets/brand/google-play/workledger-play-icon-512.png` |
| Android adaptive icon background | Android 홈 화면 런처 아이콘 배경 | 로고 원본에서 분리 | `android/app/src/main/res/drawable/ic_launcher_background.xml` |
| Android adaptive icon foreground | Android 홈 화면 런처 아이콘 전경 | 로고 원본에서 분리 | `android/app/src/main/res/drawable/ic_launcher_foreground.xml` |
| Android themed icon | Android 테마 아이콘용 단색 레이어 | 로고 원본에서 단색화 | `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` |
| Android adaptive icon XML | foreground, background, monochrome 연결 | 개발 단계에서 생성 | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` |
| Android splash mark | 앱 시작 화면 중앙 로고 | 투명 배경 mark vector | `android/app/src/main/res/drawable/ic_splash_mark.xml` |
| Android splash background | 앱 시작 화면 배경 | launch background drawable | `android/app/src/main/res/drawable/launch_background.xml` |
| Google Play feature graphic | Play Store 큰 미리보기 그래픽 | Figma 또는 이미지 편집 원본 | `assets/brand/google-play/workledger-feature-graphic-1024x500.png` |

현재 선택 로고:

```text
assets/brand/source/workledger-logo-master.svg
```

현재 생성된 export:

```text
assets/brand/source/workledger-logo-transparent-1024.png
assets/brand/source/workledger-logo-preview-1024.png
assets/brand/google-play/workledger-play-icon-512.png
android/app/src/main/res/drawable/ic_launcher_background.xml
android/app/src/main/res/drawable/ic_launcher_foreground.xml
android/app/src/main/res/drawable/ic_launcher_monochrome.xml
android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
android/app/src/main/res/drawable/ic_splash_mark.xml
android/app/src/main/res/drawable/launch_background.xml
android/app/src/main/res/drawable-v21/launch_background.xml
android/app/src/main/res/values-v31/styles.xml
android/app/src/main/res/values-night-v31/styles.xml
```

## 3. Google Play app icon 규격

Google Play app icon은 Play Store에서 보이는 앱 대표 아이콘이다. Android 기기 홈 화면 아이콘과 분리해서 관리한다.

요구 형식:

| 항목 | 기준 |
|---|---|
| 크기 | `512px x 512px` |
| 포맷 | `32-bit PNG` |
| 색공간 | `sRGB` |
| 최대 파일 크기 | `1024KB` |
| 형태 | 전체 정사각형 artwork |
| 투명 배경 | 피한다. 브랜드 배경색을 채운다. |

반드시 지킬 것:

- export 파일에 둥근 모서리를 넣지 않는다.
- export 파일 외곽에 drop shadow를 넣지 않는다.
- Google Play가 업로드 후 둥근 마스크와 shadow를 동적으로 적용한다.
- 로고가 작은 장식처럼 보이면 안 된다. 단순 로고는 keyline 안에 안정적으로 배치한다.
- ranking, `#1`, `무료`, `할인`, `다운로드`, Play 프로그램 참여 표시처럼 오해를 줄 수 있는 문구나 그래픽을 넣지 않는다.

WorkLedger 권장 방향:

- 배경은 최종 선택 로고의 `#f5e9d4` 크림 계열을 사용한다.
- 중앙 심볼은 다크 잉크 장부와 코럴 체크를 유지한다.
- 텍스트 `WorkLedger`나 `내근무장부`는 넣지 않는다. 작은 크기에서 읽히지 않고 Play 정책상 promotional copy로 오해될 수 있다.
- 아이콘 형태는 근무 장부, 체크, 시간 기록을 떠올릴 수 있는 단순한 기호 1개로 제한한다.

## 4. Android launcher adaptive icon 규격

Android launcher adaptive icon은 Android 홈 화면, 앱 목록, 설정, 공유 화면 등에서 표시되는 아이콘이다. 기기 제조사와 런처마다 원형, squircle, 둥근 사각형 등 다른 마스크가 적용될 수 있다.

요구 형식:

| 항목 | 기준 |
|---|---|
| 구조 | foreground/background 2-layer |
| layer 크기 | 각 layer `108dp x 108dp` |
| 안전 영역 | 중요한 로고는 중앙 `66dp x 66dp` 안에 둔다 |
| 권장 포맷 | vector drawable 우선 |
| masking 여백 | 바깥쪽 18dp는 마스크와 시각 효과 영역으로 본다 |

권장 Android 리소스:

```text
android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
android/app/src/main/res/drawable/ic_launcher_foreground.xml
android/app/src/main/res/drawable/ic_launcher_background.xml
android/app/src/main/res/drawable/ic_launcher_monochrome.xml
```

반드시 지킬 것:

- foreground와 background를 한 장의 PNG로 합치지 않는다.
- foreground 로고는 66dp 안전 영역을 넘기지 않는다.
- layer 자체에 마스크, 둥근 모서리, 외곽 drop shadow를 넣지 않는다.
- 가능하면 vector drawable로 만든다. 단순한 장부/체크/시간 심볼은 vector에 적합하다.
- legacy fallback PNG는 실제 Android 리소스 생성 단계에서 필요한지 확인한 뒤 만든다.

## 5. Themed/monochrome icon 규격

Themed icon은 사용자가 Android에서 테마 아이콘을 켰을 때 배경화면과 시스템 색상에 맞춰 표시되는 단색 아이콘이다.

요구 형식:

| 항목 | 기준 |
|---|---|
| 구조 | monochrome 단일 layer |
| layer 크기 | `108dp x 108dp` |
| 로고 크기 | 최소 `48dp x 48dp`, 최대 `66dp x 66dp` |
| 색상 | 단색. 시스템이 tint를 적용할 수 있게 만든다. |
| 권장 포맷 | vector drawable |

WorkLedger 권장 방향:

- Play icon과 같은 개념의 심볼을 쓰되, 선과 면이 단색에서도 무너지지 않게 만든다.
- 가는 선, 작은 숫자, 작은 글자는 쓰지 않는다.
- `ic_launcher_foreground.xml`을 그대로 재사용할 수 있으면 좋지만, 단색에서 읽기 어렵다면 `ic_launcher_monochrome.xml`을 별도로 만든다.

## 6. Google Play feature graphic 규격

Feature graphic은 Play Store에서 앱 경험을 크게 보여주는 미리보기 그래픽이다. 앱 아이콘과 다르게, 사용자가 이 앱이 무엇을 하는지 한눈에 이해하게 만드는 asset이다.

요구 형식:

| 항목 | 기준 |
|---|---|
| 크기 | `1024px x 500px` |
| 포맷 | `JPEG` 또는 `24-bit PNG` |
| alpha | 없음 |
| 용도 | Play Store 미리보기, preview video cover, 추천 영역 등 |

반드시 지킬 것:

- app icon과 똑같은 강한 로고 반복을 피한다. Play Store에서 app icon과 함께 보이면 중복된다.
- 핵심 시각 요소는 중앙에 둔다. 가장자리에는 잘려도 되는 배경 요소만 둔다.
- 너무 작은 UI, 작은 글자, 복잡한 표는 피한다. 폰 화면에서 잘 보이지 않는다.
- 순위, 수상, 가격, 프로모션, CTA를 넣지 않는다. 예: `Best`, `#1`, `Top`, `New`, `Free`, `무료`, `할인`, `다운로드`, `설치`.
- 오래 지나면 틀리는 문구를 넣지 않는다. 예: `2026년 한정`, `이번 달 무료`.
- Google Play badge, 다른 스토어 badge, 제3자 로고, 기기 이미지 남용을 피한다.
- Play Console에 올릴 때 alt text를 함께 준비한다. 140자 이하로 핵심 장면을 설명한다.

WorkLedger 권장 방향:

- 앱의 실제 가치인 10초 근무 기록, 월간 요약, 연차 관리 흐름을 보여준다.
- white canvas, dark ink, hairline border, 조용한 업무 도구 톤을 유지한다.
- 다만 feature graphic은 Play Store 배경에서 묻히지 않게 signature-coral, signature-forest, signature-peach 같은 브랜드 색을 보조 배경으로 쓸 수 있다.
- 큰 문구는 1개만 둔다. 예: `근무 기록을 빠르게 남기고, 월말에 다시 본다.`
- 기능 설명을 과장하지 않는다. 급여 정확성, 법적 증빙, 회사 시스템 연동을 암시하지 않는다.

## 6.1 Android splash screen 규격

Android splash는 앱 실행 직후 사용자가 처음 보는 브랜드 화면이다. launcher icon과 표시 크기, 마스크, 배경 처리 목적이 다르므로 launcher PNG를 그대로 재사용하지 않는다.

요구 형식:

| 항목 | 기준 |
|---|---|
| 배경색 | `#f5e9d4` |
| 중앙 mark | 투명 배경 vector drawable |
| Android 12 이상 | `windowSplashScreenBackground`, `windowSplashScreenAnimatedIcon` 사용 |
| Android 11 이하 | `windowBackground` layer-list 사용 |
| dark mode | 같은 크림 배경 유지 |

리소스 대상:

```text
android/app/src/main/res/drawable/ic_splash_mark.xml
android/app/src/main/res/drawable/launch_background.xml
android/app/src/main/res/drawable-v21/launch_background.xml
android/app/src/main/res/values/styles.xml
android/app/src/main/res/values-night/styles.xml
android/app/src/main/res/values-v31/styles.xml
android/app/src/main/res/values-night-v31/styles.xml
```

반드시 지킬 것:

- splash 중앙 mark에 배경 사각형을 포함하지 않는다.
- launcher icon PNG를 splash icon으로 재사용하지 않는다.
- pre-Android 12 launch background와 Android 12 이상 splash background를 같은 색으로 맞춘다.
- Flutter 첫 frame 전후에 흰색 flash가 생기지 않도록 `NormalTheme` 배경도 splash 배경색으로 맞춘다.
- 실제 Android 기기에서 중앙 mark가 잘리지 않는지 확인한다.

## 7. WorkLedger 로고 디자인 방향

WorkLedger는 "업무 기록을 빠르게 남기고 나중에 다시 확인하는 개인 장부"다. 로고는 회계 앱처럼 차갑거나, 출퇴근 통제 시스템처럼 감시하는 느낌이면 안 된다.

추천 방향:

| 방향 | 설명 |
|---|---|
| 장부 + 체크 | 장부 한 장 안에 체크 표시. 가장 직관적이고 작은 크기에서 잘 읽힌다. |
| 시간 기록 + 선 | 짧은 시간선과 체크를 결합. 10초 기록의 속도를 표현한다. |
| 월간 카드 | 작은 카드 2-3개를 겹쳐 월간 요약을 암시한다. 너무 복잡해지면 제외한다. |

피할 방향:

- 시계만 크게 둔 아이콘. 일반 알람/타이머 앱처럼 보인다.
- 돈, 지폐, 계산기 중심 아이콘. 급여 확정 앱처럼 오해될 수 있다.
- 회사 건물, 위치 핀, GPS 느낌. MVP 범위와 충돌한다.
- 법률, 도장, 증명서 느낌. 법적 증빙 보장처럼 보일 수 있다.
- 텍스트 중심 로고. 작은 런처 아이콘에서 읽히지 않는다.

색상 기준:

| 역할 | 권장 색 |
|---|---|
| 기본 배경 | `#f5e9d4` |
| 기본 심볼 | `#181d26`, `#ffffff` |
| 보조 배경 | `#f8fafc`, `#f5e9d4` |
| 강조 | `#aa2d00`, `#0a2e0e`, `#fcab79` |

형태 기준:

- 아이콘은 앱 UI처럼 조용해야 한다. 장식용 gradient blob, 과한 3D, 불필요한 glow는 쓰지 않는다.
- 카드나 장부 모양을 쓰더라도 최종 Play icon export에는 외곽 rounded corner와 drop shadow를 넣지 않는다.
- 작은 크기 검토 기준은 `48px`, `72px`, `96px`, `512px`다.

## 8. 파일명과 저장 경로 규칙

원본 파일:

```text
assets/brand/source/workledger-logo-master.svg
```

Figma를 원본으로 쓸 경우:

```text
Figma file: WorkLedger Brand Assets
Page: Logo Source
Frame: workledger-logo-master
```

Google Play export:

```text
assets/brand/google-play/workledger-play-icon-512.png
assets/brand/google-play/workledger-feature-graphic-1024x500.png
```

Android app resource target:

```text
android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
android/app/src/main/res/drawable/ic_launcher_foreground.xml
android/app/src/main/res/drawable/ic_launcher_background.xml
android/app/src/main/res/drawable/ic_launcher_monochrome.xml
android/app/src/main/res/drawable/ic_splash_mark.xml
android/app/src/main/res/drawable/launch_background.xml
android/app/src/main/res/drawable-v21/launch_background.xml
android/app/src/main/res/values-v31/styles.xml
android/app/src/main/res/values-night-v31/styles.xml
```

이름 규칙:

- 파일명은 lowercase kebab-case를 쓴다.
- 크기가 중요한 PNG는 파일명에 크기를 넣는다. 예: `1024x500`, `512`.
- Android 리소스 파일은 Android 관례인 snake_case를 유지한다.
- 원본 파일은 overwrite하지 않는다. 큰 디자인 변경은 Figma version history 또는 별도 source 파일로 남긴다.

## 9. Export 체크리스트

Google Play app icon:

- [ ] `512px x 512px`이다.
- [ ] `32-bit PNG`이다.
- [ ] `sRGB`이다.
- [ ] `1024KB` 이하이다.
- [ ] 전체 정사각형 artwork다.
- [ ] 둥근 모서리가 없다.
- [ ] 외부 drop shadow가 없다.
- [ ] 투명 배경이 아니다.
- [ ] 순위, 가격, 다운로드 유도 문구가 없다.
- [ ] `48px`, `72px`, `96px` 축소 미리보기에서도 심볼이 읽힌다.

Android adaptive icon:

- [ ] foreground와 background가 분리되어 있다.
- [ ] 각 layer가 `108dp x 108dp` 기준이다.
- [ ] 핵심 로고가 중앙 `66dp x 66dp` 안전 영역 안에 있다.
- [ ] foreground에 외곽 shadow나 mask가 없다.
- [ ] background가 충분히 단순하다.
- [ ] vector drawable로 만들 수 있는지 먼저 확인했다.
- [ ] 원형, squircle, 둥근 사각형 mask 미리보기를 확인했다.

Themed icon:

- [ ] monochrome layer가 있다.
- [ ] 단색에서도 의미가 읽힌다.
- [ ] 로고 크기가 `48dp` 이상, `66dp` 이하이다.
- [ ] 너무 얇은 선과 작은 글자가 없다.

Splash screen:

- [ ] 배경색이 `#f5e9d4`이다.
- [ ] 중앙 mark가 투명 배경이다.
- [ ] launcher icon PNG를 재사용하지 않는다.
- [ ] Android 12 이상 splash 속성이 있다.
- [ ] pre-Android 12 launch background가 같은 배경색과 mark를 쓴다.
- [ ] `NormalTheme` 배경이 splash 배경색과 맞는다.
- [ ] dark mode에서도 의도한 배경색을 유지한다.

Feature graphic:

- [ ] `1024px x 500px`이다.
- [ ] `JPEG` 또는 `24-bit PNG`이다.
- [ ] alpha가 없다.
- [ ] 핵심 요소가 중앙에 있다.
- [ ] app icon과 같은 로고를 크게 반복하지 않는다.
- [ ] 작은 글자와 복잡한 UI가 없다.
- [ ] 순위, 가격, 할인, 다운로드 유도 문구가 없다.
- [ ] alt text 초안을 준비했다.

## 10. Play Console 업로드 전 QA 체크리스트

업로드 전 확인:

- [ ] Play app icon과 Android launcher icon이 서로 다른 목적의 파일로 관리된다.
- [ ] Play app icon에 둥근 모서리와 외부 shadow가 없다.
- [ ] adaptive icon은 Android Studio 또는 실제 Android 기기에서 mask별로 확인했다.
- [ ] themed icon은 Android 13 이상 테마 아이콘 환경에서 확인했다.
- [ ] splash는 Android 12 이상과 pre-Android 12 경로 모두 확인했다.
- [ ] splash 중앙 mark가 잘리지 않는다.
- [ ] splash에서 Flutter 첫 화면으로 넘어갈 때 흰색 flash가 없다.
- [ ] feature graphic이 app icon과 나란히 보여도 중복 branding처럼 보이지 않는다.
- [ ] feature graphic이 WorkLedger의 실제 기능을 보여준다.
- [ ] feature graphic에 과장 문구, 가격 문구, 법적 보장처럼 보이는 문구가 없다.
- [ ] 모든 asset이 최신 앱 상태를 반영한다.
- [ ] source 파일과 export 파일이 지정 경로에 있다.

권장 확인 명령:

```bash
$HOME/.local/share/flutter-stable/bin/dart format .
$HOME/.local/share/flutter-stable/bin/flutter analyze --no-pub
$HOME/.local/share/flutter-stable/bin/flutter test
$HOME/.local/share/flutter-stable/bin/flutter build apk --debug
```

## 11. 다음 단계

1. 실제 Android 기기에서 launcher icon, themed icon, splash 화면을 확인한다.
2. Android 12 이상 기기에서 splash 중앙 mark가 잘리지 않는지 확인한다.
3. dark mode에서 splash 배경이 `#f5e9d4`로 유지되는지 확인한다.
4. feature graphic은 앱 아이콘 확대판이 아니라 실제 앱 가치가 보이는 store preview로 별도 제작한다.
5. Play Console 업로드 전 Play app icon과 feature graphic preview를 확인한다.

로고 source, launcher icon, adaptive icon, themed icon, splash screen, Play app icon은 생성됐다. Google Play feature graphic은 아직 별도 작업으로 남아 있다.
