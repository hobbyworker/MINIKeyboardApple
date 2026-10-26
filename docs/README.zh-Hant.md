<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="App 圖像"></p>

<h1 align="center">Mac 巨集鍵盤設定工具</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <b>繁體中文</b></p>

這是一款將按鍵設定寫入小型 USB 巨集鍵盤的 macOS App。這類鍵盤在市面上從只有一個旋鈕到多達 21 個按鍵都有，旋鈕最多 4 個。可以為每個按鍵和旋鈕的動作（向左旋轉、按下、向右旋轉）在第 1–3 層設定按鍵輸入、多媒體鍵或滑鼠動作，也可以設定鍵盤的燈光。

<p align="center"><img src="../.github/devices.png" width="560" alt="兩台小型 USB 巨集鍵盤：6 個按鍵和 1 個旋鈕，12 個按鍵和 2 個旋鈕"></p>

| 鍵盤 | 佈局 | 讀取 | 延遲 | 燈光 | 實機驗證 |
|---|---|---|---|---|---|
| `1189:8890` | 由使用者設定：按鍵（最多 12 個）、每列按鍵數、旋鈕（最多 2 個） | 不支援 | 無 | 三種模式 | 已驗證（6 個按鍵、1 個旋鈕） |
| 廠商 `1189` 或 `514C`，產品 `8840`、`8842`、`8830`–`8833`、`8850`（以及 `514C:8851`），新版韌體 | 依鍵盤告知的佈局（26 種） | 連接後立即讀取 | 每個輸入 | 一種模式，以及按鍵 1–16 的顏色 | 未驗證 |
| 同類鍵盤，舊版韌體 | 依鍵盤告知的佈局 | 要求時 | 每個按鍵一個 | 顏色和模式 | 未驗證 |
| 同類鍵盤，不告知類型者 | 由使用者選擇（26 種） | 不支援 | 無 | 顏色和模式 | 未驗證 |

`1189:8890` 是廠商的 Windows 設定工具「MINI KeyBoard」所支援的鍵盤，其餘則是廠商的跨平台 App「MINI_KEYBOARD」會尋找的鍵盤。本 App 兩種工具的指令都會使用。第二類鍵盤大多會告知自己有幾個按鍵和旋鈕、使用哪種韌體，因此 App 會照樣繪製廠商 App 所繪製的佈局；不告知的鍵盤則採用使用者從這些佈局中選擇的那一種。`1189:8890` 是廠商 App 不認得的鍵盤，它自己的工具也不繪製外形，因此無從得知實際形狀。所以只要設定按鍵和旋鈕的數量以及每列的按鍵數，App 就會照此繪製出整齊的排列。

App 提供 13 種語言：英文、韓文、日文、中文（簡體、繁體）、德文、西班牙文、法文、義大利文、葡萄牙文（巴西）、波蘭文、印尼文和越南文。App 會依照 macOS 的語言設定顯示，其他語言則顯示英文。

本儲存庫的原始碼採用 MIT 授權條款。發佈的 App 有一部分（名稱和圖像）不包含在此原始碼中。最上方的圖像僅供展示，不在 MIT 授權條款的範圍內，以本儲存庫建置的 App 也不包含它。

## macOS、Windows 和 Linux

MINIKeyboard 有三個依相同規則製作的版本——相同的鍵盤、相同的指令、相同的 13 種語言。

| 儲存庫 | 下載 |
|---|---|
| [**MINIKeyboardApple**](https://github.com/hobbyworker/MINIKeyboardApple)<br><img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white"> <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6"> <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases/latest) 中的 `.dmg`——會自動更新 |
| [**MINIKeyboardWin**](https://github.com/hobbyworker/MINIKeyboardWin)<br><img alt="Windows 10 (2004)+ · 11" src="https://img.shields.io/badge/Windows-10%20(2004)%2B%20·%2011-0078D4?logo=windows&logoColor=white"> <img alt="x64 · ARM64" src="https://img.shields.io/badge/x64%20·%20ARM64-5E5CE6"> <img alt=".NET 10 · WinUI 3" src="https://img.shields.io/badge/.NET%2010-WinUI%203-512BD4?logo=dotnet&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [Releases](https://github.com/hobbyworker/MINIKeyboardWin/releases/latest) 中的 `Setup.exe`——會自動更新 |
| [**MINIKeyboardLinux**](https://github.com/hobbyworker/MINIKeyboardLinux)<br><img alt="Linux" src="https://img.shields.io/badge/Linux-GTK%204%20·%20libadwaita-4A86CF?logo=linux&logoColor=white"> <img alt="Flatpak: x86_64 · aarch64" src="https://img.shields.io/badge/Flatpak-x86__64%20·%20aarch64-4A90D9?logo=flatpak&logoColor=white"> <img alt="Rust" src="https://img.shields.io/badge/Rust-2024-B7410E?logo=rust&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [Flatpak](https://github.com/hobbyworker/MINIKeyboardLinux#download)，或 [Releases](https://github.com/hobbyworker/MINIKeyboardLinux/releases/latest) 中的 Flatpak 套件——透過軟體中心更新 |

## 下載

經過簽署和公證的 App 可在 [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases) 取得。開啟 `MINIKeyboard-<版本>.dmg`，將 MINIKeyboard 拖移到「應用程式」檔案夾。App 會自動檢查更新（設定 ▸ 一般），也可以在 App 選單中手動選擇**檢查更新…**。

## 系統需求

- macOS 14.0（Sonoma）或以上版本
- `1189:8890` 不需要另外允許任何權限。App 會透過 USB 直接寫入該鍵盤的設定介面，不會讀取你輸入的內容。
- 其餘鍵盤和廠商 App 一樣，透過第一個 USB 介面進行設定。如果 macOS 將該介面視為鍵盤，只會讓已獲准輸入監控的 App 開啟它。獲准之前，App 會告知這一點，並可為你開啟「隱私權與安全性」。

## 建置

```sh
make build          # 透過 Xcode 建置（警告視為錯誤）
make package-test   # 套件測試 — 不會啟動 App
make test           # App 測試 — App 本身就是測試主機
make check          # 專案檔中混入團隊 ID 時失敗
```

已在 Xcode 27.2 上確認建置與測試。

簽署與識別設定不在儲存庫中。第一次建置前，請複製範例檔，填入你自己的 Apple Developer 團隊 ID、App 名稱和 Bundle ID。缺少這個檔案時，建置會停在 `Unable to open base configuration reference file ... Signing.xcconfig`。

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

圖像名稱可以不填。若沒有圖像的圖片，App 會以系統的通用圖像建置。

更新同樣是選用的。App 透過 Swift Package Manager 連結 [Sparkle](https://sparkle-project.org)（第一次建置時由 Xcode 下載），但只有在 `Signing.xcconfig` 同時提供更新來源（`BRAND_FEED_URL`）及其 EdDSA 公開金鑰（`BRAND_FEED_PUBLIC_KEY`）時才會檢查更新。若沒有，任何地方都不會出現更新項目。

Xcode 開啟專案時，會把共享 Scheme（`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`）中的產品名稱改寫成你自己的。這是正常現象，不需要提交。

App 測試的主機就是 App 本身。測試期間，App 會像平常一樣尋找並連接鍵盤。套件測試使用假物件和模擬鍵盤，不會開啟鍵盤。

在**模擬器**選單中，可以在沒有該鍵盤的情況下試用 App。選擇 `1189:8890`、新韌體的佈局，或不告知類型的鍵盤之一，App 就會像鍵盤已經插上一樣，以相同的指令運作，而不會向 USB 送出任何內容。使用期間，視窗頂端的橘色橫條會提示這一點，按下**返回 USB 上的鍵盤**即可返回。Debug 建置提供所有種類（`1189:8890` 的其他報告 ID、舊韌體）。在**視窗 ▸ 裝置日誌**中可以查看所有寫入的報告和收到的回應。

## 使用方式

1. 用 USB 連接鍵盤。App 會找到鍵盤，並詢問第二類鍵盤的類型；若是新版韌體，會立即讀取設定。
2. 對於不告知形狀的鍵盤，第一次使用時要設定佈局（廠商 App 的佈局之一；`1189:8890` 則是按鍵、每列按鍵數和旋鈕的數量）以及它擺在你面前的方向。App 會依 USB ID 記住這些設定。之後可以透過**形狀…**、**旋轉**（⌘T）變更。已告知形狀的鍵盤只能旋轉。
3. 選擇層，然後在鍵盤圖上選擇按鍵或旋鈕動作。
4. 指定動作：
   - **按鍵**：按住變更鍵（⌃ ⌥ ⇧ ⌘ 及右側的變更鍵）再按一下按鍵，每按一下就加入一個輸入。**僅變更鍵**會將該按鍵變成變更鍵。**QWERTY** 依全尺寸鍵盤的樣子排列按鍵，**ABC** 則分組排列。只能按一下鍵盤支援的按鍵。
   - **多媒體**、**滑鼠**：取代按鍵原有的動作。
   - **LED**：該層的燈光。新版韌體可以從按鍵 1–16 中選擇一個並為它設定顏色。
   - **延遲**：適用於會記住延遲的韌體。
5. **儲存**（⌘S）會寫入變更的內容。**讀取**（⌘R）會從支援讀取的鍵盤取得目前的設定。

在**設定**（⌘,）中可以選擇介面語言（13 種之一，或跟隨系統）以及淺色或深色，並在「關於」中查看版本和開放原始碼授權。有更新來源時（見上文），App 選單中「設定…」的正下方會出現**檢查更新…**。

**設定 ▸ 一般 ▸ 韌體問題規避**中的**變更燈光後防止按鍵重複**預設為開啟。`1189:8890` 的韌體在儲存燈光後，會讓按鍵的第一個字元不停重複（廠商軟體也一樣），所以 App 會在燈光之後再送出一次不含按鍵的儲存指令。關閉後，App 只會送出與廠商軟體相同的內容。另外，這款鍵盤拔掉後會忘記燈光設定。

## 架構

規則位於本機的 Swift 套件中。三個模組的相依性只指向內側，向外依賴的層無法通過編譯。

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        鍵盤、動作、佈局的控制項、各鍵盤可儲存的內容，Repository 協定，使用案例（僅 Foundation）
├── Sources/DataLayer/     各鍵盤的指令和控制項編號，尋找鍵盤以及透過 USB（IOUSBHost）、HID（IOHIDDevice）寫入，模擬鍵盤
├── Sources/Presentation/  視圖模型和畫面繪製的值 — 佈局的圖形、按鍵和顏色表（Observation，不含 SwiftUI）
└── Tests/                 Swift Testing — 所有指令的位元組、佈局、編輯、編輯器
MINIKeyboard/
├── App/                   App 進入點和選單，組裝（composition root — 唯一知道 Domain 和 DataLayer 的檔案），更新（Sparkle），授權條款
├── Views/                 SwiftUI（只 import Presentation）— 依擺放方向顯示的鍵盤、動作頁面、佈局表單、裝置日誌、Settings/
├── Resources/Licenses/    顯示於設定 ▸ 關於的開放原始碼授權
└── Localizable.xcstrings  en（原文）、de、es、fr、id、it、ja、ko、pl、pt-BR、vi、zh-Hans、zh-Hant
MINIKeyboard-Info.plist    Xcode 無法產生的 Info.plist 鍵 — Sparkle 的更新來源和金鑰、版權聲明
MINIKeyboardTests/         更新開關、授權條款、App 選單
```

在 Swift 6 下以零警告為標準。警告要修正，而不是關閉。

## 限制

- 目前只在一台鍵盤上確認過寫入：一台有 6 個按鍵、1 個旋鈕的 `1189:8890`。這台鍵盤只有一層，因此寫入任何一層都會寫到同一個地方。其餘鍵盤依廠商 App 的方式寫入；測試確保了位元組內容，但還沒有在任何一台實機上確認過。
- `1189:8890` 和不告知類型的鍵盤不會告知目前的設定，因此只會顯示在 App 中設定的內容。
- 一次只能使用一個鍵盤。插上多個時，會使用最先找到的那個（`1189:8890` 優先）。
- 不支援滑鼠移動和拖移。
