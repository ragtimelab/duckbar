# DuckBar

macOS 메뉴바에서 Claude Code / Codex 세션을 실시간으로 모니터링하는 상태 앱입니다. 활성 세션, API 사용률, 토큰 소비, 비용, 업적, 주간 리포트를 한눈에 확인할 수 있습니다.

![macOS 14+](https://img.shields.io/badge/macOS-14+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

> 🇺🇸 [English README](README.en.md)

## 스크린샷

![DuckBar](screenshot.png)

### 메뉴바
| 라이트모드 | 다크모드 |
|:-:|:-:|
| ![Menubar Light](screenshot_menubar_light.png) | ![Menubar Dark](screenshot_menubar_dark.png) |

### 팝오버
| 라이트모드 | 다크모드 |
|:-:|:-:|
| ![Light](screenshot_light.png) | ![Dark](screenshot_dark.png) |

### 주요 기능 화면
| 업적 | 주간 리포트 |
|:-:|:-:|
| ![Badges](screenshot_badges.png) | ![Weekly Report](screenshot_weekly_report.png) |

| 뱃지 공유 카드 | 사용량 알림 |
|:-:|:-:|
| ![Badge Share](screenshot_badge_share.png) | ![Usage Alert](screenshot_usage_alert.png) |

### 설정
![Settings](screenshot_settings_v4.png)

## 요구 사항

- **macOS 14 (Sonoma)** 이상
- **Apple Silicon (arm64)** 및 **Intel (x86_64)** 모두 지원

## 설치

### 직접 다운로드
1. [최신 릴리스](https://github.com/rofeels/duckbar/releases/latest)에서 `DuckBar-x.x.x.zip` 다운로드
2. zip 압축 해제 후 `DuckBar.app`을 `/Applications` 폴더로 드래그
3. 처음 실행 시 우클릭 → 열기로 실행 (Gatekeeper 우회)

> 이후 업데이트는 앱 내 **우클릭 → 업데이트 확인...** 으로 자동 설치됩니다.

### Homebrew
```bash
brew tap rofeels/duckbar https://github.com/rofeels/duckbar
brew install --cask duckbar
```

## 기능

### 멀티 Provider (Claude + Codex)
- **Claude Code / OpenAI Codex** 세션 데이터를 각각 또는 통합해서 모니터링
- 설정에서 **Claude / Codex / Both** 중 선택
- Provider별로 토큰, 비용, 세션 통계를 분리 집계

### 세션 모니터링
- **자동 세션 감지**: 터미널, VS Code, Cursor, Xcode, Zed, iTerm2, Warp, Ghostty 등 지원
- **세션 상태**: 활성(실시간 작업), 대기(최근 활동), 컴팩팅(캐시 정리), 유휴(비활성)
- **세부 정보**: 작업 디렉토리, 실행 시간, 사용 모델, 도구 호출 통계
- **실시간 업데이트**: 파일 시스템 감시 + 폴링으로 즉각적인 상태 반영

### API 사용률 & 토큰 추적
- **5시간 / 1주 사용률**: Rate Limit 소비 비율 (계정 기준, 서버에서 직접 조회)
- **토큰 분리 집계**: 입력, 출력, 캐시 생성, 캐시 읽기 토큰 각각 표시
- **캐시 효율 분석**: 캐시 히트율(%) 시각화
- **토큰 포맷팅**: 1K / 1.2M 등 자동 스케일 포맷

### 비용 추적
- **5시간 및 1주일 추정 비용**: USD 기준 실시간 계산
- **모델별 비용**: Opus, Sonnet, Haiku / gpt-4.1 구분 계산
- **누적 비용**: 전체 사용 이력 기반 누적 집계

### 히트맵 차트
- **7일 시간별 활동 히트맵**: 요일 × 시간대 활동 밀도 시각화
- **라인 차트 / 히트맵** 전환 가능, 기본값 설정 지원

### 업적 시스템
- **13개 뱃지**: 일간 최고 기록(1M~500M 토큰), 연속 사용(3~100일), 누적 비용($100~$10,000)
- 조건 달성 시 macOS 알림 자동 발송
- **연속 사용 스트릭** 추적 (날짜 기반, 끊기면 리셋)
- **뱃지 공유 카드**: 달성 뱃지를 이미지로 내보내기 (클립보드 복사 / PNG 저장)

### 주간 리포트
- **매주 월요일** 앱 시작 시 지난주 사용량 자동 집계 및 알림 발송
- 전주 대비 토큰/비용 증감(+/-%) 표시
- **요일별 막대 차트**: 가장 활발한 요일 하이라이트
- **리포트 공유 카드**: 이미지로 내보내기 지원

### 사용량 알림
- **임계값 알림**: 5시간/주간 사용률이 설정값(기본 50%, 80%, 90%) 도달 시 macOS 알림
- 60분 쿨다운, 세션 내 중복 방지, Rate Limit 리셋 후 재발동 허용

### 알림 이력
- 마일스톤(업적), 주간 리포트, 사용량 알림 전체 이력 보관 (최대 50개)
- 타입별 아이콘/색상 구분, 상대 시간 표시, 전체 삭제

### 공유 카드
- **스냅샷 카드**: 현재 토큰/비용/모델 사용량을 이미지로 내보내기
- Provider별 분기 렌더링 (Claude / Codex / Both)
- 클립보드 복사 또는 PNG 저장

### 컨텍스트 창 모니터링
- **현재 세션 사용량**: 입력 토큰 + 캐시 읽기 토큰
- **모델별 최대 컨텍스트**: 200K 또는 1M 토큰
- **색상 진행바**: 파란색 → 주황색 → 빨간색

### 메뉴바 커스터마이징
실시간으로 메뉴바에 표시할 항목을 설정에서 선택:
- `5h 42%` / `1w 68%` — 5시간/1주 사용률
- `12.3K` / `1.2M` — 5시간/1주 토큰
- `$1.23` / `$15.40` — 5시간/1주 비용
- `ctx 65%` — 컨텍스트 사용률

### 기타
- **다크모드**: 시스템 설정 자동 추적
- **다국어**: 한국어(기본) / 영어 선택
- **로그인 시 자동 실행**: ServiceManagement API (macOS 13+)
- **팝오버 크기**: 작게 / 보통 / 크게, 콘텐츠에 맞게 자동 조정
- **갱신 주기**: 1초 ~ 5분 선택

## 빌드 (개발자용)

```bash
git clone https://github.com/rofeels/duckbar.git
cd duckbar
./build.sh
cp -r .build/app/DuckBar.app /Applications/
```

## 사용 방법

1. 앱 실행 → 메뉴바에 오리발 아이콘 표시
2. 아이콘 클릭 → 팝오버에서 세부 정보 확인
3. 우클릭 → 새로고침 / 설정 / 종료

### 설정 진입
팝오버 우상단 톱니바퀴 아이콘:
- **Provider**: Claude / Codex / Both 선택
- **언어**: 한국어 / English
- **팝오버 크기**: 작게 / 보통 / 크게
- **갱신 주기**: 1초 ~ 5분
- **표시 섹션**: 각 섹션별 표시/숨김 토글
- **기본 차트**: 라인 차트 / 히트맵
- **사용량 알림**: 임계값 설정 (3단계)
- **자동 업데이트**: 확인 / 자동 설치 토글
- **메뉴바 표시 항목**: 항목별 활성화 및 미리보기

### 업적 & 알림 이력
팝오버 하단 트로피/벨 아이콘으로 접근:
- **업적**: 달성한 뱃지 확인 및 공유 카드 생성
- **알림 이력**: 모든 알림 이력 조회

## 기술 스택

| 기술 | 용도 |
|-----|------|
| **Swift 5.9** | 메인 프로그래밍 언어 |
| **SwiftUI** | UI 개발 |
| **AppKit** | 메뉴바 및 팝오버 관리 |
| **SPM** | 의존성 관리 |

## 의존성

- **[Sparkle](https://sparkle-project.org)**: 자동 업데이트
- **[HotKey](https://github.com/soffes/HotKey)**: 글로벌 핫키

## 프로젝트 구조

```
Sources/DuckBar/
├── AppMain.swift                  # 앱 진입점
├── AppDelegate.swift              # 메뉴바 아이콘, 애니메이션, 팝오버 관리
├── AppSettings.swift              # 설정 모델 및 저장소
├── Models.swift                   # 데이터 모델 (세션, 토큰, Provider 등)
├── Localization.swift             # 다국어 문자열
├── SessionMonitor.swift           # 세션 모니터링 및 폴링
├── SessionDiscovery.swift         # 세션 감지 및 JSONL 파싱
├── StatusMenuView.swift           # 팝오버 메인 UI
├── SessionRowView.swift           # 세션 행 컴포넌트
├── SettingsView.swift             # 설정 화면
├── HelpView.swift                 # 도움말 화면
├── TokenChartView.swift           # 토큰 차트 (라인/히트맵)
├── PopoverPanel.swift             # 팝오버 패널 관리
├── ShareCardView.swift            # 공유 카드 뷰
├── ShareCardWindow.swift          # 공유 카드 윈도우
├── BadgeView.swift                # 업적 뱃지 화면
├── BadgeShareCardView.swift       # 뱃지 공유 카드
├── MilestoneManager.swift         # 업적 조건 검사 및 달성 처리
├── WeeklyReportManager.swift      # 주간 리포트 생성 및 발송
├── WeeklyReportCardView.swift     # 주간 리포트 공유 카드
├── UsageAlertManager.swift        # 사용량 임계값 알림
├── NotificationHistoryManager.swift # 알림 이력 저장소
└── NotificationHistoryView.swift  # 알림 이력 화면

Resources/
├── Info.plist                     # 앱 메타데이터
├── AppIcon.icns                   # 앱 아이콘
└── duck_icon.png                  # 공유 카드용 오리 아이콘
```

## 알려진 제한사항

- Claude Code 세션이 없으면 "세션 없음" 상태 표시
- 토큰 카운트는 이 기기에서 사용한 데이터만 집계 (Rate Limit %는 계정 전체 기준)
- Codex 세션은 `~/.codex/sessions/` 디렉토리가 있어야 감지 가능
- 주간 리포트는 매주 월요일 앱 최초 실행 시 한 번만 발송
- API 사용률은 최대 5분 캐시 지연 가능

## 라이선스

MIT License — [LICENSE](LICENSE) 참조

## 지원

문제가 발생하면 [GitHub Issues](https://github.com/rofeels/duckbar/issues)에 등록해주세요.

1. 앱을 재시작해보세요
2. **설정 > 갱신 주기**를 확인하세요
3. Claude Code(`~/.claude`) / Codex(`~/.codex`)가 올바르게 설치되어 있는지 확인하세요
