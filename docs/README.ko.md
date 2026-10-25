<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="앱 아이콘"></p>

<h1 align="center">Mac 용 매크로 키보드 설정 도구</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <b>한국어</b> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

작은 USB 매크로 키보드에 키 설정을 쓰는 macOS 앱입니다. 노브 하나뿐인 것부터 키 21개까지, 노브는 4개까지로
팔리는 키보드들입니다. 키와 노브의 동작(왼쪽으로 회전 · 누르기 · 오른쪽으로 회전)마다 레이어 1–3 에 키 입력 ·
멀티미디어 키 · 마우스 동작을 정하고, 키보드의 조명도 정합니다.

| 키보드 | 배열 | 읽어 오기 | 지연 | 조명 | 실기 확인 |
|---|---|---|---|---|---|
| `1189:8890` | 사용자가 정함 — 키(12개까지) · 한 줄의 키 · 노브(2개까지) | 안 됨 | 없음 | 모드 셋 | 했음 — 키 6개 · 노브 하나 |
| 제조사 `1189` 또는 `514C`, 제품 `8840` · `8842` · `8830`–`8833` · `8850` (그리고 `514C:8851`), 새 펌웨어 | 키보드가 알려 준 대로 — 26가지 | 연결하면 바로 | 입력마다 | 모드 하나와 키 1–16 의 색 | 안 했음 |
| 같은 키보드, 옛 펌웨어 | 키보드가 알려 준 대로 | 요청할 때 | 키마다 하나 | 색과 모드 | 안 했음 |
| 같은 키보드, 종류를 알려 주지 않는 것 | 사용자가 고름 — 26가지 | 안 됨 | 없음 | 색과 모드 | 안 했음 |

`1189:8890` 은 제조사의 Windows 설정 도구 "MINI KeyBoard" 가 다루는 키보드이고, 나머지는 제조사의 여러 운영체제용 앱
"MINI_KEYBOARD" 가 찾는 키보드입니다. 앱은 두 도구의 명령을 모두 씁니다. 두 번째 쪽 키보드는 대개 키와 노브가 몇 개인지,
펌웨어가 무엇인지 알려 주므로 제조사 앱이 그리는 배열을 그대로 그리고, 알려 주지 않는 키보드는 그 배열 가운데 사용자가
고른 것을 씁니다. `1189:8890` 은 제조사 앱이 모르는 키보드이고 그 자신의 도구도 모양을 그리지 않아 실제 모양을 알 수
없습니다. 그래서 키와 노브가 몇 개인지, 한 줄에 키가 몇 개인지를 정하면 앱이 그대로 반듯하게 그립니다.

앱은 13개 언어로 나옵니다 — 영어 · 한국어 · 일본어 · 중국어(간체 · 번체) · 독일어 · 스페인어 · 프랑스어 · 이탈리아어 ·
포르투갈어(브라질) · 폴란드어 · 인도네시아어 · 베트남어. macOS 의 언어 설정을 따르고, 그 밖의 언어에서는 영어로 나옵니다.

이 저장소의 소스는 MIT 라이선스입니다. 배포되는 앱의 일부 — 이름과 아이콘 — 는 이 소스에 들어 있지 않습니다. 맨 위의
아이콘은 보여 드리려고 둔 그림으로, MIT 라이선스에 포함되지 않고 이 저장소로 빌드한 앱에도 들어가지 않습니다.

## 내려받기

서명과 공증을 거친 앱은 [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases) 에 있습니다.
`MINIKeyboard-<버전>.dmg` 를 열고 MINIKeyboard 를 응용 프로그램 폴더로 끌어다 놓습니다. 앱이 스스로 업데이트를
확인하고(설정 ▸ 일반), 앱 메뉴의 **업데이트 확인…** 으로 직접 확인할 수도 있습니다.

## 요구 사항

- macOS 14.0 (Sonoma) 이상
- `1189:8890` 에는 따로 허용할 권한이 없습니다. 앱은 그 키보드의 설정 통로에 USB 로 직접 쓰고, 입력하는 내용은 읽지
  않습니다.
- 나머지 키보드는 제조사 앱처럼 첫 번째 USB 인터페이스로 설정합니다. macOS 가 그 인터페이스를 키보드로 여기면 입력
  모니터링이 허용된 앱에만 열어 줍니다. 허용되기 전에는 앱이 그렇다고 알리고 개인정보 보호 및 보안을 열어 줍니다.

## 빌드

```sh
make build          # Xcode 로 빌드 (경고는 에러)
make package-test   # 패키지 테스트 — 앱이 뜨지 않는다
make test           # 앱 테스트 — 앱이 테스트 호스트다
make check          # 프로젝트 파일에 팀 ID 가 들어갔으면 실패
```

Xcode 27.2 에서 빌드와 테스트를 확인했습니다.

서명 · 식별 설정은 저장소에 없습니다. 처음 빌드하기 전에 예시를 복사해 자신의 Apple Developer 팀 ID · 앱 이름 ·
번들 ID 를 채웁니다. 이 파일이 없으면 빌드가 `Unable to open base configuration reference file ...
Signing.xcconfig` 에서 멈춥니다.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

아이콘 이름은 넣지 않아도 됩니다. 아이콘 그림이 없으면 앱은 시스템 기본 아이콘으로 빌드됩니다.

업데이트도 선택입니다. 앱은 [Sparkle](https://sparkle-project.org) 을 Swift Package Manager 로 링크하지만 — 첫 빌드 때
Xcode 가 받아 옵니다 — `Signing.xcconfig` 에 피드(`BRAND_FEED_URL`)와 그 EdDSA 공개키(`BRAND_FEED_PUBLIC_KEY`)가 둘 다
있을 때만 업데이트를 확인합니다. 없으면 업데이트 항목이 어디에도 나오지 않습니다.

Xcode 가 프로젝트를 열면 공유 스킴(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) 안의 제품 이름을 자기 것으로
고쳐 씁니다. 정상이고, 커밋할 필요는 없습니다.

앱 테스트의 호스트는 앱 자신입니다. 테스트하는 동안 앱이 평소처럼 키보드를 찾아 연결합니다. 패키지 테스트는 가짜와
시뮬레이터 키보드를 쓰고, 키보드를 열지 않습니다.

**시뮬레이터** 메뉴로 그 키보드 없이 앱을 써 볼 수 있습니다. `1189:8890`, 새 펌웨어의 배열들, 종류를 알려 주지 않는
키보드 가운데 하나를 고르면 앱이 꽂힌 것처럼 같은 명령으로 동작하고, USB 로는 아무것도 나가지 않습니다. 쓰는 동안은 창 위의
주황 띠가 그렇다고 알리고, **USB에 꽂힌 키보드로 돌아가기** 로 돌아옵니다. Debug 빌드는 모든 종류(`1189:8890` 의 다른 리포트
ID · 옛 펌웨어)를 고를 수 있습니다. **윈도우 ▸ 장치 기록** 에서 쓴 리포트와 받은 답을 모두 볼 수 있습니다.

## 쓰는 법

1. 키보드를 USB 로 연결합니다. 앱이 키보드를 찾고, 두 번째 쪽 키보드에는 종류를 묻습니다. 새 펌웨어면 바로 읽어 옵니다.
2. 모양을 알려 주지 않는 키보드는 처음에 배열 — 제조사 앱의 배열 가운데 하나, `1189:8890` 은 키 · 한 줄의 키 · 노브의
   개수 — 과 앞에 놓인 방향을 정합니다. 앱은 USB ID
   마다 기억합니다. 나중에 **모양…** 과 **회전**(⌘T)으로 바꿉니다. 모양을 알려 준 키보드는 돌리기만 합니다.
3. 레이어를 고르고, 키보드 그림에서 키나 노브 동작을 고릅니다.
4. 동작을 줍니다.
   - **키** — 보조 키(⌃ ⌥ ⇧ ⌘ 와 오른쪽 것들)를 잡고 키를 누릅니다. 누를 때마다 입력이 하나씩 붙습니다. **보조 키만** 은
     그 키를 보조 키로 만듭니다. **QWERTY** 는 키를 풀사이즈 키보드처럼, **ABC** 는 묶음으로 늘어놓습니다. 키보드가 받는 키만
     누를 수 있습니다.
   - **멀티미디어** · **마우스** — 키에 있던 동작을 대신합니다.
   - **LED** — 레이어의 조명. 새 펌웨어는 키 1–16 가운데 하나를 골라 색을 줍니다.
   - **지연** — 지연을 기억하는 펌웨어에서.
5. **저장**(⌘S)이 바뀐 것을 씁니다. **읽기**(⌘R)는 읽어 올 수 있는 키보드에서 지금 설정을 가져옵니다.

**설정**(⌘,)에서 화면 언어(13개 가운데 하나, 또는 시스템 언어)와 라이트 · 다크를 고르고, 정보에서 버전과 오픈소스
라이선스를 봅니다. 업데이트 피드가 있으면(위) 앱 메뉴의 설정… 바로 아래에 **업데이트 확인…** 이 있습니다.

**설정 ▸ 일반 ▸ 펌웨어 버그 우회** 의 **조명을 바꾼 뒤 키 반복 막기** 는 처음부터 켜져 있습니다.
`1189:8890` 은 조명을 저장하면 그 뒤로 키의 첫 입력이 끝없이 반복되는 펌웨어 버그가 있어서(제조사
프로그램도 같습니다), 앱이 조명 뒤에 키 없는 저장을 한 번 더 보냅니다. 끄면 제조사 프로그램과 똑같이 보냅니다.
이 키보드는 뽑았다 꽂으면 조명이 꺼집니다.

## 구조

규칙은 로컬 Swift 패키지에 있습니다. 세 모듈의 의존은 안쪽으로만 향하고, 바깥으로 손을 뻗는 레이어는 컴파일되지 않습니다.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        키보드 · 동작 · 배열의 컨트롤 · 키보드마다 담을 수 있는 것, 리포지토리 프로토콜, 유스케이스 (Foundation 만)
├── Sources/DataLayer/     키보드마다의 명령과 컨트롤의 번호, 키보드 찾기와 USB(IOUSBHost) · HID(IOHIDDevice)로 쓰기, 시뮬레이터 키보드
├── Sources/Presentation/  뷰모델과 화면이 그리는 값 — 배열의 그림, 키 · 색 표 (Observation, SwiftUI 없음)
└── Tests/                 Swift Testing — 모든 명령의 바이트, 배열, 편집, 편집기
MINIKeyboard/
├── App/                   앱 진입점 · 메뉴, 조립(composition root — Domain · DataLayer 를 아는 유일한 파일), 업데이트(Sparkle), 라이선스
├── Views/                 SwiftUI (Presentation 만 import) — 놓인 대로의 키보드, 동작 쪽, 배열 시트, 장치 기록, Settings/
├── Resources/Licenses/    설정 ▸ 정보에 보이는 오픈소스 라이선스
└── Localizable.xcstrings  en(원문) · de · es · fr · id · it · ja · ko · pl · pt-BR · vi · zh-Hans · zh-Hant
MINIKeyboard-Info.plist    Xcode 가 만들지 못하는 Info.plist 키 — Sparkle 의 피드와 키, 저작권 줄
MINIKeyboardTests/         업데이트 스위치 · 라이선스 · 앱 메뉴
```

Swift 6 에서 경고 0 이 기준입니다. 경고는 끄지 않고 고칩니다.

## 한계

- 쓰기는 지금까지 키보드 한 대, 키 6개 · 노브 하나의 `1189:8890` 으로만 확인했습니다 — 이 키보드는 레이어가 하나뿐이어서
  어느 레이어에 써도 같은 곳에 들어갑니다. 나머지 키보드는 제조사 앱이 쓰는 대로 씁니다. 테스트가 바이트를 지키지만 실기로는
  아직 하나도 확인하지 못했습니다.
- `1189:8890` 과 종류를 알려 주지 않는 키보드는 지금 설정을 알려 주지 않으므로, 앱에서 정한 것만 보입니다.
- 한 번에 키보드 하나. 여럿을 꽂으면 먼저 찾은 것 — `1189:8890` 이 먼저 — 을 씁니다.
- 마우스 이동과 끌기는 없습니다.
