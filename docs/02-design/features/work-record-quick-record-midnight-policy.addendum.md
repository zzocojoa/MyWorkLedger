# Work Record Quick Record Midnight Policy Addendum

Date: 2026-06-21
Status: Check-ready addendum

## Decision

`chooseBeforeSave`는 선택창을 연 시점의 업무 날짜를 저장 완료까지 고정한다.

## Scope

- 현재 시각 후보는 선택창을 연 시점의 `DateTime` 값을 그대로 사용한다.
- 정시 후보는 선택창을 연 시점의 업무 날짜와 `WorkRule`의 정시 분 값을 조합한다.
- 직접 입력 후보는 선택창을 연 시점의 업무 날짜와 사용자가 입력한 `HH:mm` 값을 조합한다.
- `clockInAt()`과 `clockOutAt()`은 선택된 기록 시각의 날짜를 저장 대상 `workDate`로 사용한다.
- `createdAt`과 `updatedAt`은 저장 작업이 실제 수행된 repository clock을 사용한다.

## Explicit Non-Goal

날짜를 넘는 야간근무 모델링 제외. 이 addendum은 자정 근처 선택 UI의 저장 대상 날짜만 고정하며, 전날 출근 후 다음 날 퇴근을 하나의 근무 기록으로 표현하는 정책은 다루지 않는다.

## Verification

- Domain: 정시 후보와 직접 입력 후보가 선택창을 연 날짜를 사용하는지 확인한다.
- Repository: 저장 clock이 다음 날이어도 `clockInAt()`과 `clockOutAt()`이 선택된 시각의 날짜에 기록을 생성하거나 수정하는지 확인한다.
- Widget: 자정 전에 선택창을 열고 자정 후 후보를 확정해도 전날 날짜의 선택 시각으로 저장되는지 확인한다.
