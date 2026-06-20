# Privacy Policy Webpage Deployment

## Purpose

이 문서는 Google Play Console에 입력할 WorkLedger 개인정보처리방침 공개 URL의 관리 위치를 기록한다.

## Source Files

| File | Purpose |
|---|---|
| `docs/02-design/privacy-policy-webpage.md` | UI 설계, 카피 구조, 반응형 규칙 |
| `web/privacy-policy/index.html` | 정적 HTML/CSS 구현 산출물 |

## Public URL

최종 공개 URL은 GitHub Pages 기준으로 사용한다.

Pages workflow가 `main`에 병합되어 성공하면 아래 URL을 Play Console에 입력한다.

- 공개 URL: `https://zzocojoa.github.io/MyWorkLedger/privacy-policy/`
- 호스팅 위치: GitHub Pages, `.github/workflows/privacy-policy-pages.yml`
- Play Console 입력 위치: Policy and programs > App content > Privacy policy
- 마지막 로컬 검증일: `2026-06-20`

## Pre-Submission Checks

- `web/privacy-policy/index.html`은 로그인 없이 접근 가능해야 한다.
- 공개 페이지는 PDF가 아닌 HTML이어야 한다.
- 공개 URL은 지역 제한이 없어야 한다.
- 개인정보 문의 이메일: `kmksla2@gmail.com`
- Google Play 개발자명: `HOIHOU`
- 시행일은 실제 공개 배포일 기준으로 확인해야 한다.

## Remaining Deployment Blockers

- GitHub Pages는 원격 저장소에서 GitHub Actions 배포 방식으로 활성화되었다.
- `.github/workflows/privacy-policy-pages.yml`이 아직 `main`에 병합되지 않았다.
- Pages workflow 성공 여부를 아직 확인하지 않았다.
- 공개 URL 기준 375px, 768px, 1024px, 1440px 검증은 배포 후 다시 실행해야 한다.
