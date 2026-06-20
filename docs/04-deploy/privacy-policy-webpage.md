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

아래 URL은 Play Console 개인정보처리방침 URL로 입력할 수 있다.

- 공개 URL: `https://zzocojoa.github.io/MyWorkLedger/privacy-policy/`
- 호스팅 위치: GitHub Pages, `.github/workflows/privacy-policy-pages.yml`
- Pages workflow run: `https://github.com/zzocojoa/MyWorkLedger/actions/runs/27864863929`
- Play Console 입력 위치: Policy and programs > App content > Privacy policy
- 마지막 로컬 검증일: `2026-06-20`
- 마지막 공개 URL 검증일: `2026-06-20`

## Pre-Submission Checks

- `web/privacy-policy/index.html`은 로그인 없이 접근 가능해야 한다.
- 공개 페이지는 PDF가 아닌 HTML이어야 한다.
- 공개 URL은 지역 제한이 없어야 한다.
- 공개 URL은 HTTP 200으로 응답한다.
- 공개 URL 기준 375px, 768px, 1024px, 1440px 렌더링 검증을 통과했다.
- 공개 URL 기준 브라우저 콘솔 오류와 가로 스크롤 문제가 없다.
- 개인정보 문의 이메일: `kmksla2@gmail.com`
- Google Play 개발자명: `HOIHOU`
- 시행일은 실제 공개 배포일 기준으로 확인해야 한다.

## Remaining Deployment Blockers

- 공개 배포 blocker는 없다.
- Play Console 개인정보처리방침 URL 입력은 아직 사용자가 별도로 진행해야 한다.
