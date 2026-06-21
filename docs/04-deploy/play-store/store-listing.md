# Google Play Store Listing Draft

## App Identity

| Item | Value |
|---|---|
| App name | 내근무장부 |
| English name | WorkLedger |
| Package name | `com.workledger.workledger` |
| Category | Productivity |

## Short Description

```text
출근·퇴근과 연차를 기기 안에 빠르게 기록하는 근무 장부
```

## Full Description

```text
내근무장부는 계정 없이 바로 사용하는 근무 기록 앱입니다.

출근과 퇴근을 빠르게 기록하고, 월별 근무 시간과 연차 사용 내역을 한 화면에서 확인할 수 있습니다. 정해진 출퇴근 시간이 있으면 빠른 설정으로 기준 시간을 저장하고, 필요할 때는 저장 전 시각을 직접 선택할 수 있습니다.

주요 기능
- 오늘 출근/퇴근 1탭 기록
- 저장 전 현재 시각, 정시 후보, 직접 입력 선택
- 상시 알림에서 빠른 출근/퇴근 기록
- 월간 총 근무 시간과 근무일 요약
- 총 연차와 사용 연차 직접 관리
- 계정, 서버 동기화, 광고, 실제 결제 없음

내근무장부는 사용자의 근무 기록과 연차 기록을 기기 안에 저장합니다. 회사 근태 시스템 연동, 법률 증빙 보장, 자동 수당 계산은 제공하지 않습니다.
```

## Release Notes

```text
- 빠른 기록 방식을 추가했습니다.
- 저장 전 현재 시각, 정시 후보, 직접 입력 중 선택할 수 있습니다.
- 자정 근처에서 선택한 근무 날짜가 바뀌지 않도록 수정했습니다.
- 상시 알림 기록 흐름과 로컬 저장 안정성을 개선했습니다.
```

## Data Safety Draft

| Console Item | Draft Answer |
|---|---|
| Account required | No |
| App access restriction | No login or paid access |
| Ads | No |
| Data shared with third parties | No |
| Data sent to developer server | No |
| Location collected | No |
| Payment information collected | No |
| User deletion path | In-app record deletion and Android app data deletion |

## Store Assets

| Asset | Path | Status |
|---|---|---|
| Play app icon | `assets/brand/google-play/workledger-play-icon-512.png` | Ready |
| Feature graphic | `assets/brand/google-play/workledger-feature-graphic-1024x500.jpg` | Ready |
| Home screenshot | `docs/04-deploy/play-store/screenshots/phone-upload/01-home.jpg` | Ready |
| Settings screenshot | `docs/04-deploy/play-store/screenshots/phone-upload/02-settings.jpg` | Ready |
| Quick record settings screenshot | `docs/04-deploy/play-store/screenshots/phone-upload/03-quick-record-settings.jpg` | Ready |
| Monthly summary screenshot | `docs/04-deploy/play-store/screenshots/phone-upload/04-monthly-summary.jpg` | Ready |
| Leave management screenshot | `docs/04-deploy/play-store/screenshots/phone-upload/05-leave-management.jpg` | Ready |

## Manual Console Checks

- Store listing copy must be pasted into Play Console and saved.
- Screenshots and feature graphic must be uploaded in Play Console.
- Play Console may crop or preview assets differently; review the final console preview before submitting.
- Data safety answers must be reviewed against the final Play Console questionnaire wording.
