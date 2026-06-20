# WorkLedger Privacy Policy Webpage Design

## Scope

이 문서는 Google Play Console 개인정보처리방침 URL로 사용할 `내근무장부` / `WorkLedger` 공개 웹페이지의 UI 설계 기준이다. 이번 단계의 산출물은 HTML/CSS 구현 전 설계 문서이며, 앱 코드, Google Play Console 설정, 배포 URL은 변경하지 않는다.

페이지의 1차 사용자는 Google Play 심사자이고, 2차 사용자는 앱 설치 전후에 개인정보 처리 방식을 확인하려는 일반 사용자다. 두 사용자 모두 10초 안에 다음 내용을 이해해야 한다.

- 앱은 계정 없이 시작한다.
- 서버 동기화, 로그인, GPS 자동 추적, 회사 근태 시스템 연동을 하지 않는다.
- 핵심 근무 기록과 연차 기록은 기기 안에 저장된다.
- 월간 리포트 `관심 있음` 클릭은 기능 수요 확인용 로컬 기록이며 실제 결제나 구독이 아니다.
- 사용자는 앱 안에서 기록을 삭제하거나 Android 앱 데이터 삭제로 로컬 데이터를 지울 수 있다.

## Source Materials

| Source | Design use |
|---|---|
| `DESIGN-airtable.md` | Airtable식 white canvas, near-black ink, 96px section rhythm, restrained CTA, 10-12px radius 적용 |
| `docs/01-plan/schema.md` | 로컬 저장 데이터 범위와 non-goal 확인 |
| `docs/02-design/mockup.md` | 앱 화면의 실제 문구와 fake-door 가격 화면 톤 확인 |
| `docs/02-design/design-system-rules.md` | WorkLedger의 Airtable 기반 디자인 규칙 확인 |
| `lib/features/pricing/presentation/pricing_fake_door_screen.dart` | `관심 있음`, `실제 결제는 진행되지 않습니다.` 문구 확인 |
| `lib/features/monthly_summary/presentation/monthly_summary_screen.dart` | 월간 요약에서 Report 클릭이 가격 fake-door로 이어지는 흐름 확인 |
| [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en) | 개인정보처리방침 URL 요구사항 확인 |
| [Google Play Data safety guide](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) | Data safety와 개인정보처리방침 간 일관성 요구 확인 |

## Google Play Constraints

공식 문서 기준으로 설계에 반영할 요구사항은 다음이다.

- Play Console 지정 필드에 개인정보처리방침 링크가 필요하다.
- 개인정보처리방침은 앱 이름 또는 개발자 정보를 포함해야 한다.
- 문의할 수 있는 개인정보 연락 수단이 필요하다.
- 앱이 접근, 수집, 사용, 공유하는 사용자 데이터 유형을 설명해야 한다.
- 데이터 보관 및 삭제 방침을 설명해야 한다.
- URL은 활성 상태의 공개 접근 URL이어야 하며, 지역 제한이 없어야 하고, PDF가 아니어야 한다.
- Data safety 선언과 개인정보처리방침 문구는 서로 모순되면 안 된다.

법률 자문 문구는 이 문서에서 확정하지 않는다. 구현 전 실제 개발자 정보, 개인정보 문의 이메일, 최종 시행일은 소유자가 확인해야 한다.

## Applied Design Principles

1. **White canvas first**: 전체 배경은 흰 캔버스로 둔다. 개인정보 페이지는 신뢰 문서이므로 배경 장식, 그라데이션, 강한 이미지를 쓰지 않는다.
2. **Near-black ink as authority**: 제목, 핵심 요약, 주요 CTA는 `#181d26`을 사용한다. 파란색은 링크에만 쓴다.
3. **Editorial rhythm**: 주요 섹션은 96px 단위의 큰 수직 리듬으로 구분한다. 긴 정책 문서처럼 보이되, 사용자가 스캔할 수 있게 요약 블록을 앞에 둔다.
4. **Restrained signature color**: 코럴과 포레스트는 장식이 아니라 중요한 신뢰 메시지 표면에만 제한적으로 쓴다. 이 페이지에서는 코럴 1회, 다크 표면 1회만 허용한다.
5. **No fake SaaS decoration**: 아이콘 3개짜리 기능 카드, 보라색 그라데이션, 장식용 일러스트, 과한 그림자, 마케팅식 hero copy를 쓰지 않는다.
6. **Readable policy copy**: 본문은 짧은 제목, 2-4줄 설명, 요약 목록으로 나눈다. 법률 문서처럼 숨기지 않고 일반 사용자가 읽을 수 있게 쓴다.
7. **One primary action**: 첫 화면의 유일한 CTA는 `문의하기` 또는 `앱으로 돌아가기`가 아니라 `개인정보 문의` 링크다. 심사자에게 필요한 행동은 연락 수단 확인이다.
8. **Card radius discipline**: 본문 카드와 요약 박스는 10px, CTA와 강조 표면은 12px을 사용한다. pill radius는 pricing fake-door 전용이므로 이 페이지에서 쓰지 않는다.

## Page Information Architecture

```text
 개인정보처리방침 공개 웹페이지
  + Header
  |  + WorkLedger brand
  |  + Last updated / effective date
  |
  + Hero summary
  |  + Page title
  |  + One-sentence promise
  |  + 3 핵심 요약
  |
  + Local-first summary card
  |  + 계정 없음
  |  + 서버 동기화 없음
  |  + 기기 안 저장
  |
  + Main policy sections
  |  + 저장되는 정보
  |  + 서버로 수집하지 않는 정보
  |  + 월간 리포트 관심 표시
  |  + 데이터 사용 목적
  |  + 보관 및 삭제
  |  + 제3자 제공 및 외부 전송
  |
  + Contact section
  |  + 개인정보 문의
  |  + 개발자 정보 placeholder
  |
  + Footer
     + App name
     + Effective date
     + Public URL note
```

## Desktop Wireframe

```text
--------------------------------------------------------------------------------+
| WorkLedger                                                         시행일 2026-06-20 |
+--------------------------------------------------------------------------------+
|                                                                                |
| 개인정보처리방침                                                               |
| 내근무장부는 계정 없이, 서버 동기화 없이, 사용자의 근무 기록을 기기 안에 저장합니다. |
|                                                                                |
| [개인정보 문의]                                                                |
|                                                                                |
|  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐       |
|  | 계정 없음          |  | 서버 동기화 없음    |  | 실제 결제 없음      |       |
|  | 로그인 정보를 만들 |  | 근무 기록을 개발자  |  | 관심 있음 클릭은    |       |
|  | 지 않습니다.       |  | 서버로 보내지 않음  |  | 결제가 아닙니다.    |       |
|  └────────────────────┘  └────────────────────┘  └────────────────────┘       |
|                                                                                |
+--------------------------------------------------------------------------------+
|                                                                                |
| ┌────────────────────────────────────────────────────────────────────────────┐ |
| | 로컬 저장 중심                                                             | |
| | 사용자가 입력한 출근, 퇴근, 메모, 연차, 근무 기준은 앱 내부 저장소에 보관됩니다. |
| └────────────────────────────────────────────────────────────────────────────┘ |
|                                                                                |
+--------------------------------------------------------------------------------+
|                                                                                |
| 저장되는 정보                         수집하지 않는 정보                       |
| ┌──────────────────────────────┐      ┌──────────────────────────────┐        |
| | 근무 기록                    |      | 로그인 계정                  |        |
| | 근무 기준                    |      | 위치 정보/GPS                |        |
| | 연차 입력값                  |      | 회사명 필수 입력             |        |
| | 가격 관심 클릭 이벤트        |      | 실제 결제 정보               |        |
| └──────────────────────────────┘      └──────────────────────────────┘        |
|                                                                                |
+--------------------------------------------------------------------------------+
|                                                                                |
| 월간 리포트 관심 표시                                                          |
| ┌────────────────────────────────────────────────────────────────────────────┐ |
| | Report Pass 또는 Pro의 관심 있음 버튼은 기능 수요를 확인하기 위한 로컬 이벤트입니다. |
| | 실제 결제, 구독 활성화, 리포트 생성 완료를 의미하지 않습니다.                  |
| └────────────────────────────────────────────────────────────────────────────┘ |
|                                                                                |
+--------------------------------------------------------------------------------+
|                                                                                |
| 보관 및 삭제                                                                   |
| 사용자가 앱에서 기록을 삭제하거나 Android 설정에서 앱 데이터를 삭제할 수 있습니다. |
| 계정이 없으므로 별도 계정 삭제 절차는 없습니다.                                  |
|                                                                                |
+--------------------------------------------------------------------------------+
|                                                                                |
| 개인정보 문의                                                                  |
| kmksla2@gmail.com                                                               |
| 개발자명: HOIHOU                                                                |
|                                                                                |
| Footer: WorkLedger · 개인정보처리방침 · 시행일 2026-06-20                       |
+--------------------------------------------------------------------------------+
```

## Mobile Wireframe

```text
+--------------------------------+
| WorkLedger                     |
| 시행일 2026-06-20              |
+--------------------------------+
| 개인정보처리방침               |
| 내근무장부는 계정 없이, 서버   |
| 동기화 없이, 근무 기록을 기기  |
| 안에 저장합니다.               |
|                                |
| [개인정보 문의]                |
|                                |
| ┌────────────────────────────┐ |
| | 계정 없음                  | |
| | 로그인 정보를 만들지 않음  | |
| └────────────────────────────┘ |
| ┌────────────────────────────┐ |
| | 서버 동기화 없음           | |
| | 근무 기록을 서버로 보내지  | |
| | 않음                       | |
| └────────────────────────────┘ |
| ┌────────────────────────────┐ |
| | 실제 결제 없음             | |
| | 관심 있음 클릭은 결제가    | |
| | 아님                       | |
| └────────────────────────────┘ |
+--------------------------------+
| 로컬 저장 중심                 |
| 사용자가 입력한 정보는 앱 내부 |
| 저장소에 보관됩니다.           |
+--------------------------------+
| 저장되는 정보                  |
| - 근무 기록                    |
| - 근무 기준                    |
| - 연차 입력값                  |
| - 가격 관심 클릭 이벤트        |
+--------------------------------+
| 수집하지 않는 정보             |
| - 로그인 계정                  |
| - 위치 정보/GPS                |
| - 회사명 필수 입력             |
| - 실제 결제 정보               |
+--------------------------------+
| 월간 리포트 관심 표시          |
| 관심 있음 버튼은 기능 수요를   |
| 확인하기 위한 로컬 이벤트이며, |
| 결제나 구독이 아닙니다.        |
+--------------------------------+
| 삭제 방법                      |
| 앱 안에서 기록을 삭제하거나    |
| Android 설정에서 앱 데이터를   |
| 삭제할 수 있습니다.            |
+--------------------------------+
| 개인정보 문의                  |
| kmksla2@gmail.com              |
| HOIHOU                         |
+--------------------------------+
```

## Section-by-Section Copy Structure

### 1. Header

Purpose: 사용자가 페이지가 WorkLedger 공식 개인정보처리방침임을 즉시 확인한다.

Copy:

- Brand: `WorkLedger`
- Korean brand support: `내근무장부`
- Meta: `개인정보처리방침 · 시행일 2026년 6월 20일`

Layout:

- Desktop: 1280px max container, brand left, 시행일 right.
- Mobile: brand and 시행일을 2줄로 쌓는다.

### 2. Hero Summary

Purpose: 심사자와 사용자가 페이지의 핵심 결론을 먼저 읽는다.

Copy:

- H1: `개인정보처리방침`
- Lead: `내근무장부는 계정 없이, 서버 동기화 없이, 사용자의 근무 기록을 기기 안에 저장합니다.`
- CTA: `개인정보 문의`

Summary cards:

| Card | Title | Body |
|---|---|---|
| 1 | `계정 없음` | `로그인 정보나 회원 계정을 만들지 않습니다.` |
| 2 | `서버 동기화 없음` | `근무 기록을 개발자 서버로 전송하지 않습니다.` |
| 3 | `실제 결제 없음` | `월간 리포트 관심 표시는 결제나 구독이 아닙니다.` |

Design:

- H1은 desktop 40px/400, mobile 32px/400.
- CTA는 near-black 12px radius button.
- 카드 3개는 desktop 3-column, mobile 1-column.

### 3. Local-First Highlight

Purpose: 이 앱의 개인정보 처리 방식을 한 문장으로 고정한다.

Copy:

```text
로컬 저장 중심
사용자가 입력한 출근, 퇴근, 메모, 연차, 근무 기준은 앱 내부 저장소에 보관됩니다. 내근무장부는 이 정보를 개발자 서버로 동기화하지 않습니다.
```

Design:

- 코럴 표면 1회 사용.
- 흰 글자, 12px radius, 48px padding.
- 모바일에서는 24px padding.

### 4. Stored Information

Purpose: 앱 내부에 저장될 수 있는 정보를 명확히 열거한다.

Copy:

```text
앱 내부에 저장되는 정보
- 근무 기록: 근무일, 출근 시각, 퇴근 시각, 기록 사유, 메모
- 근무 기준: 정시 출퇴근, 연장/야간 기준, 휴게시간, 근무 요일
- 연차 정보: 사용자가 직접 입력한 총 연차와 사용 내역
- 월간 리포트 관심 표시: Report Pass 또는 Pro의 관심 있음 클릭 기록
```

UI note:

- 월간 요약값은 저장 정보 목록에 넣지 않는다. 저장된 근무 기록과 연차 기록에서 화면 표시 시 계산되는 값으로 설명한다.
- `월간 리포트 관심 표시`는 결제와 분리해 같은 줄에 `실제 결제 아님` 배지를 둔다.

### 5. Information Not Collected or Sent

Purpose: 앱의 non-goal을 개인정보 언어로 표현한다.

Copy:

```text
서버로 수집하거나 전송하지 않는 정보
- 로그인 계정, 비밀번호, 소셜 계정 정보
- GPS 위치 정보 또는 자동 위치 추적 정보
- 회사명, 회사 위치, 회사 근태 시스템 계정
- 실제 결제 카드, 영수증, 구독 상태
- 법률 분쟁, 소송, 노무 자문 상태
```

Copy rule:

- `수집하지 않습니다`만 단독으로 쓰지 않는다. 로컬 저장과 혼동될 수 있으므로 `서버로 수집하거나 전송하지 않는 정보`라고 쓴다.

### 6. Monthly Report Interest Explanation

Purpose: fake-door가 결제처럼 보이지 않게 한다.

Copy:

```text
월간 리포트 관심 표시
월간 요약 화면의 Report 버튼과 가격 화면의 관심 있음 버튼은 월간 리포트 기능에 대한 관심을 확인하기 위한 기능입니다. 이 클릭은 앱 내부에 이벤트로 저장되며, 실제 결제, 구독 활성화, 리포트 생성 완료를 의미하지 않습니다.
```

Design:

- 다크 표면 또는 surface-soft callout 중 하나를 사용한다.
- 추천은 surface-soft다. 개인정보 페이지에서 다크 CTA가 너무 강하면 결제 페이지처럼 보일 수 있다.
- `실제 결제 아님`을 작은 text badge로 제공한다.

### 7. Data Use

Purpose: 저장 정보가 어떤 화면 기능에 쓰이는지 설명한다.

Copy:

```text
정보 사용 목적
앱 내부에 저장된 정보는 오늘 출근/퇴근 기록 표시, 달력 보기, 잔여 연차 계산, 월간 요약 표시, 월간 리포트 기능 수요 확인에만 사용됩니다. 광고, 외부 분석, 회사 근태 시스템 제출, 법률 자문 판단에는 사용되지 않습니다.
```

### 8. Retention and Deletion

Purpose: 사용자 삭제 방법을 명확히 한다.

Copy:

```text
보관 및 삭제
기록은 사용자가 삭제하기 전까지 앱 내부 저장소에 남아 있습니다. 사용자는 앱 안의 기록 삭제 기능으로 개별 근무 기록이나 연차 사용 기록을 삭제할 수 있습니다. 앱을 삭제하거나 Android 설정에서 내근무장부의 앱 데이터를 삭제하면 기기 안에 저장된 데이터도 삭제됩니다.

내근무장부는 계정을 만들지 않으므로 별도의 계정 삭제 절차는 없습니다.
```

Implementation note:

- 실제 구현 전 앱 안에서 삭제 가능한 범위를 한 번 더 확인한다. 개별 삭제가 없는 데이터 유형은 문구에서 빼야 한다.

### 9. Third Parties and Transfer

Purpose: 외부 공유 여부를 명확히 한다.

Copy:

```text
제3자 제공 및 외부 전송
현재 버전의 내근무장부는 사용자의 근무 기록, 연차 기록, 월간 리포트 관심 표시를 개발자 서버나 제3자 서버로 전송하지 않습니다. 서버, 로그인, 클라우드 동기화, 광고 SDK, 실제 결제 SDK는 현재 버전에 포함되지 않습니다.
```

### 10. Contact and Effective Date

Purpose: Play Console 요구사항의 개인정보 연락 수단과 시행일을 제공한다.

Copy:

```text
개인정보 문의
개인정보 처리와 관련한 문의는 아래 연락처로 보내주세요.

이메일: kmksla2@gmail.com
개발자명: HOIHOU
앱 이름: 내근무장부 / WorkLedger

시행일: 2026년 6월 20일
```

Confirmed values:

- 개인정보 문의 이메일: `kmksla2@gmail.com`
- Google Play 개발자명: `HOIHOU`
- 시행일: `2026년 6월 20일`

## Design Tokens for Implementation

| Token | Value | Usage |
|---|---|---|
| `canvas` | `#ffffff` | Page background |
| `ink` | `#181d26` | H1, H2, primary text, primary CTA |
| `body` | `#333840` | Body copy |
| `muted` | `#41454d` | Meta, footer, secondary text |
| `hairline` | `#dddddd` | Card borders, dividers |
| `surface-soft` | `#f8fafc` | Low emphasis policy cards |
| `signature-coral` | `#aa2d00` | One local-first highlight card |
| `surface-dark` | `#181d26` | Optional final CTA, use sparingly |
| `link` | `#1b61c9` | Email and source links only |
| `radius-md` | `10px` | Content cards |
| `radius-lg` | `12px` | CTA and highlight cards |
| `space-section` | `96px` | Desktop major section padding |

Typography:

| Role | Desktop | Mobile | Weight |
|---|---:|---:|---:|
| H1 | 40px / 1.2 | 32px / 1.2 | 400 |
| H2 | 32px / 1.2 | 24px / 1.35 | 400 |
| H3 | 20px / 1.5 | 18px / 1.4 | 400-500 |
| Body | 14px / 1.5 for web policy readability | 15-16px / 1.5 | 400 |
| Button | 16px / 1.4 | 16px / 1.4 | 500 |
| Meta | 14px / 1.35 | 14px / 1.35 | 500 |

Web readability adjustment:

- `DESIGN-airtable.md` body token is 14px / 1.25. 개인정보처리방침 본문은 긴 문장이 많으므로 웹 구현에서는 line-height를 1.5로 늘린다.
- 모바일 본문은 최소 15px, 가능하면 16px로 둔다.

## Responsive Rules

| Breakpoint | Width | Layout |
|---|---:|---|
| Mobile | `< 768px` | Single column, 24px horizontal padding, hero cards stacked, 64px section rhythm |
| Tablet | `768-1023px` | 2-column for stored/not-collected sections, summary cards 3-up only if readable |
| Desktop | `1024-1439px` | 12-column grid, 1280px max width, 96px section rhythm, hero summary cards 3-up |
| Wide | `>= 1440px` | Max content width remains 1280px. Do not scale type with viewport width |

Rules:

- No horizontal scroll at 375px.
- Summary cards use stable min-height so copy length does not create uneven accidental emphasis.
- Contact email must wrap safely with `overflow-wrap: anywhere`.
- Long Korean section titles must not overlap right-side meta text. Header stacks when width is tight.
- Table-like lists become stacked definition blocks on mobile.
- The first viewport must show brand, page title, lead, and at least part of the three summary cards.

## Accessibility Rules

- Use semantic headings in order: one `h1`, then `h2`, then `h3`.
- Primary CTA must be a real link or button with visible focus state.
- Text contrast must meet WCAG AA.
- Link text must be descriptive. Avoid `여기`.
- Do not rely on color alone for `실제 결제 아님`; use text badge.
- Body width should stay around 60-75 Korean characters on desktop.

## Implementation-Ready Component Inventory

| Component | Purpose | Visual style |
|---|---|---|
| `PolicyHeader` | Brand and 시행일 | White canvas, no sticky behavior required |
| `HeroSummary` | H1, lead, primary contact CTA | 96px section padding |
| `SummaryCard` | 계정 없음 / 서버 동기화 없음 / 실제 결제 없음 | White card, 1px hairline, 10px radius |
| `LocalFirstCallout` | 로컬 저장 중심 강조 | Coral surface, 12px radius |
| `PolicySection` | Standard text section | H2 + paragraph + optional list |
| `PolicyTwoColumn` | 저장되는 정보 / 수집하지 않는 정보 | Desktop two-column, mobile stacked |
| `Badge` | 실제 결제 아님 | Surface-soft, hairline, 6px radius |
| `ContactBlock` | 문의 이메일 and developer info | Surface-soft or white card |
| `PolicyFooter` | App name, 시행일, source note | Muted text |

## Implementation Pre-Review Checklist

### Product and Policy Accuracy

- [ ] 개발자명은 Google Play 스토어 등록 개발자명과 일치한다.
- [ ] 개인정보 문의 이메일은 실제 수신 가능한 주소다.
- [ ] 시행일은 배포일 기준으로 확정했다.
- [ ] 문서 제목에 `개인정보처리방침`이 명확히 들어간다.
- [ ] 앱 이름 `내근무장부`와 `WorkLedger`가 모두 들어간다.
- [ ] 계정 없음, 서버 동기화 없음, GPS 없음, 실제 결제 없음 문구가 앱 실제 동작과 일치한다.
- [ ] `관심 있음`은 결제/구독/리포트 생성 완료가 아니라고 명확히 쓴다.
- [ ] Data safety 선언과 모순되는 데이터 수집/공유 문구가 없다.
- [ ] 법률 자문, 증거 효력, 급여 정확성 보장 문구가 없다.

### UI and Responsive Quality

- [ ] 375px, 768px, 1024px, 1440px에서 가로 스크롤이 없다.
- [ ] 첫 화면에서 브랜드, 제목, 핵심 요약이 바로 보인다.
- [ ] 코럴 또는 다크 표면을 과하게 반복하지 않는다.
- [ ] 본문 line-height가 정책 문서 읽기에 충분하다.
- [ ] 이메일 주소와 긴 문장이 모바일에서 안전하게 줄바꿈된다.
- [ ] CTA는 한 화면에 하나만 강하게 보인다.
- [ ] 버튼과 링크에 focus-visible 상태가 있다.
- [ ] 그라데이션, 장식 blob, 3-column feature grid 아이콘 패턴을 쓰지 않는다.

### Deployment Readiness

- [ ] 최종 페이지는 PDF가 아닌 HTML 페이지다.
- [ ] URL은 로그인 없이 공개 접근 가능하다.
- [ ] URL은 지역 제한이 없다.
- [ ] URL의 콘텐츠는 사용자가 임의 수정할 수 없는 배포 산출물이다.
- [ ] Play Console에 입력할 최종 URL을 README 또는 배포 문서에 기록한다.
- [ ] 앱 내부에서도 개인정보처리방침 링크 또는 텍스트 접근 경로를 제공할지 별도 설계한다.

## Design Review Notes

- 이 페이지는 정책 문서이므로 아름다움보다 신뢰와 정확성이 우선이다.
- 다크 CTA를 하단에 넣을 수 있지만, 현재 추천은 하단 CTA 없이 문의 블록으로 끝내는 것이다. 결제 페이지가 아니기 때문이다.
- `Report Pass`, `Pro` 같은 가격 용어는 월간 리포트 관심 표시 설명 안에서만 사용한다.
- Play 심사자가 보는 페이지이므로 `MVP`, `fake-door` 같은 내부 용어는 본문 사용자 카피에서 피하고, `기능 수요 확인`, `실제 결제 아님`으로 표현한다.
- 설계 문서에서는 내부 이해를 위해 `fake-door`를 사용해도 되지만, 공개 페이지 본문에는 쓰지 않는다.

## Final Copy Skeleton

```text
WorkLedger
개인정보처리방침 · 시행일 2026년 6월 20일

개인정보처리방침
내근무장부는 계정 없이, 서버 동기화 없이, 사용자의 근무 기록을 기기 안에 저장합니다.

계정 없음
로그인 정보나 회원 계정을 만들지 않습니다.

서버 동기화 없음
근무 기록을 개발자 서버로 전송하지 않습니다.

실제 결제 없음
월간 리포트 관심 표시는 결제나 구독이 아닙니다.

로컬 저장 중심
사용자가 입력한 출근, 퇴근, 메모, 연차, 근무 기준은 앱 내부 저장소에 보관됩니다. 내근무장부는 이 정보를 개발자 서버로 동기화하지 않습니다.

앱 내부에 저장되는 정보
근무 기록, 근무 기준, 연차 정보, 월간 리포트 관심 표시가 앱 내부에 저장될 수 있습니다. 월간 요약은 저장된 기록을 바탕으로 앱 안에서 계산해 표시합니다.

서버로 수집하거나 전송하지 않는 정보
내근무장부는 로그인 계정, GPS 위치 정보, 회사 근태 시스템 계정, 실제 결제 정보, 법률 분쟁 정보를 개발자 서버로 수집하거나 전송하지 않습니다.

월간 리포트 관심 표시
월간 요약 화면의 Report 버튼과 가격 화면의 관심 있음 버튼은 월간 리포트 기능에 대한 관심을 확인하기 위한 기능입니다. 이 클릭은 앱 내부에 이벤트로 저장되며, 실제 결제, 구독 활성화, 리포트 생성 완료를 의미하지 않습니다.

정보 사용 목적
앱 내부에 저장된 정보는 오늘 출근/퇴근 기록 표시, 달력 보기, 잔여 연차 계산, 월간 요약 표시, 월간 리포트 기능 수요 확인에만 사용됩니다.

보관 및 삭제
기록은 사용자가 삭제하기 전까지 앱 내부 저장소에 남아 있습니다. 사용자는 앱 안에서 기록을 삭제하거나 Android 설정에서 앱 데이터를 삭제할 수 있습니다. 내근무장부는 계정을 만들지 않으므로 별도의 계정 삭제 절차는 없습니다.

제3자 제공 및 외부 전송
현재 버전의 내근무장부는 사용자의 근무 기록, 연차 기록, 월간 리포트 관심 표시를 개발자 서버나 제3자 서버로 전송하지 않습니다.

개인정보 문의
이메일: kmksla2@gmail.com
개발자명: HOIHOU
앱 이름: 내근무장부 / WorkLedger

시행일: 2026년 6월 20일
```

## Next Implementation Step

다음 단계는 이 문서를 기준으로 정적 HTML/CSS 페이지를 구현하는 것이다. 구현 파일 위치는 배포 방식에 따라 결정한다. 후보는 `web/privacy-policy/index.html` 또는 별도 정적 호스팅 프로젝트다. Flutter 앱 코드는 이 단계에서 수정하지 않는다.
