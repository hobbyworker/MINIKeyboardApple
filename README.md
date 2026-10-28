<p align="center"><img src=".github/icon.png" width="128" height="128" alt="App icon"></p>

<h1 align="center">Macro keyboard configurator for the Mac</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><b>English</b> · <a href="docs/README.ko.md">한국어</a> · <a href="docs/README.de.md">Deutsch</a> · <a href="docs/README.es.md">Español</a> · <a href="docs/README.fr.md">Français</a> · <a href="docs/README.id.md">Bahasa Indonesia</a> · <a href="docs/README.it.md">Italiano</a> · <a href="docs/README.ja.md">日本語</a> · <a href="docs/README.pl.md">Polski</a> · <a href="docs/README.pt-BR.md">Português (Brasil)</a> · <a href="docs/README.vi.md">Tiếng Việt</a> · <a href="docs/README.zh-Hans.md">简体中文</a> · <a href="docs/README.zh-Hant.md">繁體中文</a></p>

A macOS app that writes key settings to small USB macro keyboards — the ones sold with anything
from a single knob to 21 keys, and up to four knobs. For each key and knob action
(rotate left, press, rotate right) it sets key presses, a media key or a mouse action on layers
1–3, and the keyboard's lighting.

<p align="center"><img src=".github/devices.png" width="560" alt="Two small USB macro keyboards: six keys and a knob, twelve keys and two knobs"></p>

| Keyboard | Layout | Reads back | Waits | Lighting | Tried |
|---|---|---|---|---|---|
| `1189:8890` | arranged by you — keys (up to 12), keys per row, knobs (up to 2) | no | no | three modes | yes — 6 keys and a knob |
| vendor `1189` or `514C`, product `8840` · `8842` · `8830`–`8833` · `8850` · `8851`, newer firmware | from what the keyboard says — 26 layouts | when connected | before each press | a mode, and a colour for each of keys 1–16 | yes — `514C:8850`, 12 keys and 2 knobs |
| the same, older firmware | from what the keyboard says | when connected | one per key | a colour and a mode | no |
| the same, not saying what it is | chosen by you — 26 layouts | no | no | a colour and a mode | no |

The `1189:8890` is the keyboard the vendor's Windows tool "MINI KeyBoard" works with; the others
are the ones the vendor's cross-platform app "MINI_KEYBOARD" looks for. The app speaks both tools'
commands. Most of the second kind say how many keys and knobs they have and which firmware they
run, and the app draws the layout the vendor's app would; one that doesn't say gets the one of those
layouts you pick. The vendor's app doesn't know the `1189:8890` and its own tool draws no shape, so its
real shape isn't known: you tell the app how many keys and knobs it has and how many keys are in a
row, and it draws a tidy arrangement of that.

The app is available in 13 languages — English, Korean, Japanese, Chinese (Simplified and
Traditional), German, Spanish, French, Italian, Portuguese (Brazil), Polish, Indonesian and
Vietnamese — and follows the language settings of macOS. Other languages get English.

The source in this repository is MIT licensed. A few parts of the shipped app are not part of
this source — its name and its icon. The icon at the top is shown for reference only: it is not
covered by the MIT license, and builds from this repository don't include it.

## macOS, Windows and Linux

MINIKeyboard comes in three editions built on the same rules — the same keyboards, the same commands, the same 13 languages.

| Repository | GitHub |
|---|---|
| **MINIKeyboardApple**<br><img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white"> <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6"> <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardApple](https://github.com/hobbyworker/MINIKeyboardApple) |
| **MINIKeyboardWin**<br><img alt="Windows 10 (2004)+ · 11" src="https://img.shields.io/badge/Windows-10%20(2004)%2B%20·%2011-0078D4?logo=windows&logoColor=white"> <img alt="x64 · ARM64" src="https://img.shields.io/badge/x64%20·%20ARM64-5E5CE6"> <img alt=".NET 10 · WinUI 3" src="https://img.shields.io/badge/.NET%2010-WinUI%203-512BD4?logo=dotnet&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardWin](https://github.com/hobbyworker/MINIKeyboardWin) |
| **MINIKeyboardLinux**<br><img alt="Linux" src="https://img.shields.io/badge/Linux-GTK%204%20·%20libadwaita-4A86CF?logo=linux&logoColor=white"> <img alt="Flatpak: x86_64 · aarch64" src="https://img.shields.io/badge/Flatpak-x86__64%20·%20aarch64-4A90D9?logo=flatpak&logoColor=white"> <img alt="Rust" src="https://img.shields.io/badge/Rust-2024-B7410E?logo=rust&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardLinux](https://github.com/hobbyworker/MINIKeyboardLinux) |

## Download

The signed and notarized app is on the [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases) page:
open `MINIKeyboard-<version>.dmg` and drag MINIKeyboard to Applications. The app checks for updates by itself
(Settings ▸ General) — or choose **Check for Updates…** in the app menu.

## Requirements

- macOS 14.0 (Sonoma) or later
- The `1189:8890` needs no permission: the app writes to its configuration interface directly over
  USB and never reads what you type.
- The other keyboards are configured through their first USB interface, as the vendor's app does.
  Where macOS takes that interface for a keyboard, it opens it for an app only once Input
  Monitoring is allowed for it; until then the app says so and offers to open Privacy & Security.

## Building

```sh
make build          # build through Xcode (warnings are errors)
make package-test   # the package's tests — the app doesn't launch
make test           # the app's tests, hosted by the app
make check          # fails if a team ID slipped into the project file
```

Building and testing have been checked with Xcode 27.2.

Signing and identity settings are not in the repository. Before your first build, copy the
example and fill in your Apple Developer team ID, a name for the app and a bundle ID of your
own. Without that file the build stops at `Unable to open base configuration reference file
... Signing.xcconfig`.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

The icon name is optional. Without icon artwork the app gets the system's generic icon.

Updates are optional too. The app links [Sparkle](https://sparkle-project.org) through Swift
Package Manager — Xcode fetches it on the first build — but checks for updates only when
`Signing.xcconfig` names both a feed (`BRAND_FEED_URL`) and its EdDSA public key
(`BRAND_FEED_PUBLIC_KEY`). Without them the app has no update item anywhere.

When Xcode opens the project it rewrites the product name inside the shared scheme
(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) to yours. That is expected; there is no need
to commit it.

The app's tests are hosted by the app itself. While they run, the app looks for the keyboard and
connects to it as it always does. The package's tests use fakes and simulated keyboards, and never
open one.

The **Simulator** menu lets you try the app without the keyboard in question: pick a `1189:8890`,
a layout on newer firmware, or a keyboard that doesn't say what it is, and the app acts as if it
were plugged in — through the same commands, nothing going to USB. While one is in use, an orange
bar at the top of the window says so, and **Back to the Keyboard on USB** returns. Debug builds
offer every kind (the `1189:8890`'s other report IDs, older firmware). **Window ▸ Device Log**
shows every report written and every answer.

## Using it

1. Connect the keyboard over USB. The app finds it, and asks a keyboard of the second kind what it
   is; one that answers is read at once.
2. A keyboard that doesn't say its shape asks for its layout the first time — one of the vendor app's
   layouts, or for the `1189:8890` its keys, keys per row and knobs — and how it sits in front of you. The app remembers both for that USB ID. **Shape…**
   and **Rotate** (⌘T) change them later; a keyboard that said its shape only turns.
3. Pick a layer, then the key or knob action on the keyboard.
4. Give it an action:
   - **Keys** — hold modifiers (⌃ ⌥ ⇧ ⌘, and the right-hand ones), then click keys; each click adds
     a press. **Modifiers Only** turns the key into a modifier key. **QWERTY** lays the keys out as on a
     full-size keyboard, **ABC** in groups; only the keys the keyboard takes can be clicked.
   - **Multimedia**, **Mouse** — replace what the key did.
   - **LED** — the layer's lights; on newer firmware, select one of keys 1–16 to give it a colour.
   - **Delay** — on firmware that keeps waits.
5. **Save** (⌘S) writes what changed. **Read** (⌘R) asks a keyboard that reads back what it holds.

**Settings** (⌘,) picks the interface language (one of the 13, or the system's) and light or dark,
and has About — the version and the open source licenses. With an update feed (above), **Check
for Updates…** sits right under Settings… in the app menu.

**Settings ▸ General ▸ Firmware Workarounds** has **Prevent key repeat after changing the lighting**, on by
default. After its lighting is saved, the `1189:8890`'s firmware repeats a key's first stroke without end —
its maker's software does the same — so the app sends one more save, with no key in it, after the lighting.
Off, the app sends just what the maker's software sends. That keyboard also forgets its lighting when it's
unplugged.

## Structure

The rules live in a local Swift package, in three modules whose dependencies point inwards — a layer
that reaches outwards doesn't compile.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        keyboards, actions, the controls of each layout and what each keyboard can hold; the repository protocols; use cases (Foundation only)
├── Sources/DataLayer/     the commands of each keyboard and the numbers its controls go by; finding it and writing over USB (IOUSBHost) or HID (IOHIDDevice); simulated keyboards
├── Sources/Presentation/  view models and the values the screens draw — the layouts' geometry, key and colour tables (Observation, no SwiftUI)
└── Tests/                 Swift Testing — the bytes of every command, the layouts, the edits, the editor
MINIKeyboard/
├── App/                   app entry point and menus, the composition root (the only file that sees Domain and DataLayer), updates (Sparkle), licenses
├── Views/                 SwiftUI (imports Presentation only) — the keyboard as it sits, the action pages, the layout sheet, the device log; Settings/
├── Resources/Licenses/    open source licenses, shown in Settings ▸ About
└── Localizable.xcstrings  en (source), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    the Info.plist keys Xcode can't generate — Sparkle's feed and key, the copyright line
MINIKeyboardTests/         the update switch, the licenses and the app menu
```

Zero warnings under Swift 6 is the bar. Warnings are fixed, not switched off.

## Limitations

- Writing has been tried on two keyboards so far: a `1189:8890` with six keys and a knob — which
  turned out to have a single layer: what is written to any layer applies — and a `514C:8850` with
  twelve keys and two knobs, on newer firmware. The other keyboards are written as their vendor's
  app writes them; tests pin the bytes, but none has been tried yet.
- The `1189:8890`, and keyboards that don't say what they are, can't report their settings, so the
  app shows only what was set in it.
- One keyboard is open at a time. With several plugged in, the button beside the connection status
  chooses which; the app opens the one chosen last time, or else the first it finds, a `1189:8890`
  first.
- Mouse movement and dragging are not offered.
