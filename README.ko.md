<p align="center">
  <img src="docs/screenshots/icon.png" width="128" alt="TreeScan Size 아이콘">
</p>

<h1 align="center">TreeScan Size</h1>

<p align="center">
  <b>Mac을 가득 채우는 것이 무엇인지 확인하세요 — 크기 막대가 있는 폴더 트리로.</b><br>
  무료 오픈 소스. 네트워크 없음, 추적 없음. Dropbox, iCloud, OneDrive를 인식합니다.
</p>

<p align="center">
  <a href="https://github.com/gorbarov/treescan-size/releases/latest"><img src="https://img.shields.io/github/v/release/gorbarov/treescan-size?label=download&color=2a78d6" alt="다운로드"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-lightgrey" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Apple%20Silicon-native-lightgrey" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/SwiftUI-100%25-orange" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT"></a>
  <img src="https://img.shields.io/badge/languages-9-blueviolet" alt="9개 언어">
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ru.md">Русский</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português</a> · <b>한국어</b> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <img src="docs/screenshots/pie-en.png" width="900" alt="TreeScan Size: 크기 막대와 차트가 있는 폴더 트리">
</p>

---

## 왜 필요한가요

Finder는 어떤 폴더가 디스크를 잡아먹었는지 알려주지 않습니다. 대부분의 Mac용 디스크 분석기는 원형 그래프나 트리맵을 그립니다. **TreeScan Size는 Windows 사용자가 TreeSize에서 보던 화면을 보여줍니다:** 모든 행에 크기 막대와 상위 항목 대비 비율이 표시되는 평범한 폴더 트리입니다. 아래로 스크롤하면 — 정리할 것을 바로 알 수 있습니다.

## 주요 기능

|  |  |
|---|---|
| 🌳 **크기 막대가 있는 트리** | 각 폴더의 크기와 상위 항목 대비 %를 큰 것부터 순서대로 표시합니다. 방향키 지원, 행 어디든 클릭 가능. |
| ⚡ **실시간 스캔** | 스캔하는 동안 트리가 실시간으로 채워지며 실제 진행률(사용된 디스크 공간의 퍼센트)을 보여줍니다. 로딩만 기다릴 필요가 없습니다. |
| ☁️ **클라우드 인식** | Dropbox, iCloud, OneDrive의 "온라인 전용" 파일은 별도로 표시됩니다: 클라우드 요금제에는 포함되지만 Mac에서는 공간을 차지하지 않습니다. 메뉴에서 Dropbox 폴더를 **동기화 안 함**으로 설정할 수 있습니다. |
| ⚖️ **크기 vs 디스크상 용량** | *크기*는 파일 자체의 무게이며 클라우드 할당량 기준입니다. *디스크상 용량*은 이 Mac에서 실제로 차지하는 공간입니다. Docker 또는 VM 디스크는 "무게"가 460GB이고 39GB만 사용할 수 있습니다 — 두 가지 모두 볼 수 있습니다. |
| 🔍 **6가지 뷰** | 차트, 세부 정보, 확장자, 파일 연령, 최대 파일, 중복 후보(클라우드 파일 다운로드 없이 찾음). |
| 🛡️ **안전하고 개인정보 보호** | 휴지통 이동만 가능하며 확인 절차가 있고 시스템 폴더는 보호됩니다. 네트워크 접근 완전히 없음, 분석 없음, 계정 없음. [PRIVACY.md](PRIVACY.md) 참조. |
| 🌍 **9개 언어** | 영어, 简体中文, 日本語, 한국어, 독일어, 스페인어, 프랑스어, 포르투갈어, 러시아어. 라이트 및 다크 테마. |

## 스크린샷

| 실시간 스캔 | 최대 파일 | 중복 후보 |
|---|---|---|
| <img src="docs/screenshots/live-en.png" alt="진행률과 함께 실행되는 실시간 스캔"> | <img src="docs/screenshots/top-en.png" alt="폴더 내 최대 파일들"> | <img src="docs/screenshots/duplicates-en.png" alt="중복 후보"> |

| 무엇을 스캔할까요? | 다크 테마 | 크기 vs 디스크상 용량 설명 |
|---|---|---|
| <img src="docs/screenshots/welcome-en.png" alt="시작 화면"> | <img src="docs/screenshots/details-dark-en.png" alt="세부 정보, 다크 테마"> | <img src="docs/screenshots/mode-help-en.png" alt="크기 vs 디스크상 용량 도움말"> |

## 설치

**Apple Silicon**에서 **macOS 14 Sonoma 이상**이 필요합니다.

1. [Releases](https://github.com/gorbarov/treescan-size/releases/latest)에서 **TreeScan-Size.zip**을 다운로드하여 압축을 풀고 응용 프로그램 폴더로 옮깁니다.
2. 빌드는 아직 **공증되지 않았으므로** macOS가 첫 실행을 차단합니다:
   - **macOS 15 이상:** 앱을 한 번 열었다가 *완료(Done)* 를 클릭한 다음, **시스템 설정 → 개인정보 보호 및 보안 → 확인 없이 열기**를 선택합니다.
   - **macOS 14:** 앱을 우클릭 → **열기** → **열기**.
   - 또는 터미널에서: `xattr -dr com.apple.quarantine "/Applications/TreeScan Size.app"`
3. 처음 실행 시 앱이 **전체 디스크 접근 권한**을 요청합니다 — 데스크톱, 문서, iCloud 및 다른 앱 데이터에 대해 여러 번 묻는 대신 시스템 설정에서 하나만 켜면 됩니다. 건너뛸 수도 있으며, 그러면 보호된 폴더는 단순히 🔒로 표시되고 읽지 않습니다.

### 소스에서 빌드하기

```bash
git clone https://github.com/gorbarov/treescan-size && cd treescan-size
scripts/make_app.sh          # Command Line Tools 만 있으면 충분함(Swift 5.9+), Xcode 불필요
open "build/TreeScan Size.app"
```

## 다른 도구와 비교

| | TreeScan Size | DaisyDisk | GrandPerspective | OmniDiskSweeper | Disk Inventory X |
|---|---|---|---|---|---|
| 기본 뷰 | 크기 막대가 있는 트리 + 차트 | 선버스트 링 | 트리맵 | 컬럼 목록 | 트리맵 + 목록 |
| 가격 | 무료 | 유료 | 무료(App Store 버전 유료) | 무료 | 무료 |
| 소스 코드 | 오픈, MIT | 클로즈드 | 오픈, GPL | 클로즈드 | 오픈, GPL |

그 외에도: 온라인 전용 클라우드 파일 표시, 메뉴에서 Dropbox 동기화 해제, 크기 / 디스크상 용량 토글, 스캔 중 실시간 트리 갱신, 클라우드 파일 다운로드 없는 중복 후보 탐색 등이 있습니다.

*2026년 9월 기준 공개 자료를 바탕으로 작성했습니다 — 정정 환영합니다.*

## 어떻게 만들어졌나요

TreeScan Size는 또한 하나의 실험입니다. **코드는 저렴한 코딩 모델**(DeepSeek V4 Flash)이 작성했으며 Claude Opus가 기술 리드를 담당했습니다: 사양을 작성하고 작업을 약 25개의 작은 태스크로 나누어 미리 계산된 답변을 제공하고 위험한 줄마다 검토했습니다. 파이썬 스크립트와 HTML 보고서([reference/](reference/))가 레퍼런스 구현 역할을 했습니다.

배운 점을 간략히 말씀드리면:
- 저렴한 모델은 잘 짜인 경로에 강합니다: 레퍼런스에서 로직을 이식하고 코드 골격에서 UI를 구축하는 일 같은 경우죠.
- 초록불 테스트만으로는 부족합니다: 모든 테스트가 통과한 상태에서 휴지통 메뉴의 시스템 폴더 보호 기능을 꺼버린 적이 있었는데, 코드 리뷰만이 그것을 발견했습니다.
- 50만 개짜리 테스트 폴더는 290만 개 파일이 드러내는 문제를 숨깁니다: 탭 하나가 실제 디스크에서 그리는 데 9분이나 걸렸거든요. 실제 규모 검사가 이를 발견했고 사람이 나머지를 찾아냈습니다.

전체 이야기 — 태스크, 검사, 교훈, 실행 로그 — 는 [docs/FINDINGS.md](docs/FINDINGS.md)와 [docs/RESEARCH.md](docs/RESEARCH.md)(러시아어)에 있으며 실행 로그는 [릴리스](https://github.com/gorbarov/treescan-size/releases/latest)에 첨부되어 있습니다.

## 기여하기

버그 신고, 번역, 그리고 원어민 검수 언제든 환영합니다 — [CONTRIBUTING.md](CONTRIBUTING.md)를 참고해 주세요.

## 라이선스 및 상표

[MIT](LICENSE). TreeScan Size는 Windows용 TreeSize에서 영감을 받았으나 **JAM Software와 제휴 관계가 없으며 승인받지도 않았습니다.** TreeSize는 Joachim Marder e.K.(JAM Software)의 등록 상표입니다. Dropbox, iCloud, OneDrive 및 macOS는 해당 소유자의 상표입니다.
