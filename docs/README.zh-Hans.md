<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="应用图标"></p>

<h1 align="center">Mac 宏键盘设置工具</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <b>简体中文</b> · <a href="README.zh-Hant.md">繁體中文</a></p>

这是一款向小型 USB 宏键盘写入按键设置的 macOS 应用。这类键盘在售的型号从只有一个旋钮到多达 21 个按键不等，旋钮最多 4 个。对于每个按键和旋钮的动作（向左旋转、按下、向右旋转），可以在第 1–3 层设置按键输入、多媒体键或鼠标动作，还可以设置键盘的灯光。

| 键盘 | 布局 | 读取 | 延迟 | 灯光 | 实机验证 |
|---|---|---|---|---|---|
| `1189:8890` | 由用户设定：按键（最多 12 个）、每行按键数、旋钮（最多 2 个） | 不支持 | 无 | 三种模式 | 已验证（6 个按键、1 个旋钮） |
| 厂商 `1189` 或 `514C`，产品 `8840`、`8842`、`8830`–`8833`、`8850`（以及 `514C:8851`），新版固件 | 按键盘告知的布局（26 种） | 连接后立即读取 | 每个输入 | 一种模式，以及按键 1–16 的颜色 | 未验证 |
| 同类键盘，旧版固件 | 按键盘告知的布局 | 请求时 | 每个按键一个 | 颜色和模式 | 未验证 |
| 同类键盘，不告知类型的 | 由用户选择（26 种） | 不支持 | 无 | 颜色和模式 | 未验证 |

`1189:8890` 是厂商的 Windows 设置工具“MINI KeyBoard”所支持的键盘，其余则是厂商的跨平台应用“MINI_KEYBOARD”会查找的键盘。本应用同时使用这两个工具的命令。第二类键盘大多会告知自己有几个按键和旋钮、使用什么固件，因此应用会照原样绘制厂商应用所绘制的布局；不告知的键盘则采用用户从这些布局中选择的那一种。`1189:8890` 是厂商应用不认识的键盘，它自己的工具也不绘制外形，因此无法得知其实际形状。所以只要设定按键和旋钮的数量以及每行的按键数，应用就会照此绘制出整齐的排列。

应用提供 13 种语言：英语、韩语、日语、中文（简体、繁体）、德语、西班牙语、法语、意大利语、葡萄牙语（巴西）、波兰语、印度尼西亚语和越南语。应用跟随 macOS 的语言设置，其他语言则显示为英语。

本仓库的源代码采用 MIT 许可证。所发布应用的一部分（名称和图标）不包含在此源代码中。顶部的图标仅供展示，不在 MIT 许可证的范围内，用本仓库构建的应用中也不包含它。

## 下载

经过签名和公证的应用可在 [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases) 获取。打开 `MINIKeyboard-<版本>.dmg`，将 MINIKeyboard 拖到“应用程序”文件夹。应用会自动检查更新（设置 ▸ 通用），也可以在应用菜单中手动选择**检查更新…**。

## 系统要求

- macOS 14.0（Sonoma）或更高版本
- `1189:8890` 无需额外授予任何权限。应用通过 USB 直接写入该键盘的设置接口，不会读取你输入的内容。
- 其余键盘与厂商应用一样，通过第一个 USB 接口进行设置。如果 macOS 将该接口视为键盘，则只允许已获得输入监控权限的应用打开它。获得权限之前，应用会提示这一点，并可为你打开“隐私与安全”。

## 构建

```sh
make build          # 通过 Xcode 构建（警告视为错误）
make package-test   # 软件包测试 — 不会启动应用
make test           # 应用测试 — 应用本身就是测试宿主
make check          # 如果工程文件中混入了团队 ID 则失败
```

已在 Xcode 27.2 上验证构建和测试。

签名和身份设置不在仓库中。首次构建前，请复制示例文件，并填入你自己的 Apple Developer 团队 ID、应用名称和 Bundle ID。没有这个文件时，构建会停在 `Unable to open base configuration reference file ... Signing.xcconfig`。

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

图标名称可以不填。没有图标图片时，应用会以系统的通用图标构建。

更新同样是可选的。应用通过 Swift Package Manager 链接 [Sparkle](https://sparkle-project.org)（首次构建时由 Xcode 获取），但只有当 `Signing.xcconfig` 中同时提供了更新源（`BRAND_FEED_URL`）及其 EdDSA 公钥（`BRAND_FEED_PUBLIC_KEY`）时才会检查更新。否则，任何地方都不会出现更新相关的项目。

Xcode 打开工程时，会把共享 Scheme（`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`）中的产品名称改写成你自己的。这是正常现象，无需提交。

应用测试的宿主就是应用本身。测试期间，应用会像平常一样查找并连接键盘。软件包测试使用假对象和模拟键盘，不会打开键盘。

Debug 构建中有**模拟器**菜单，可以在没有对应键盘的情况下试用应用。选择任一报告 ID 的 `1189:8890`、两种固件的任一布局，或者不告知类型的键盘中的一个，应用就会像键盘已经插上一样，用同样的命令运行，而不会向 USB 发送任何内容。在**窗口 ▸ 设备日志**中可以查看写入的所有报告和收到的所有回复。

## 使用方法

1. 通过 USB 连接键盘。应用会找到键盘，并询问第二类键盘的类型；如果是新版固件，会立即读取设置。
2. 对于不告知形状的键盘，首次使用时要设定布局（厂商应用的布局之一；`1189:8890` 则是按键、每行按键数和旋钮的数量）以及它在你面前的摆放方向。应用会按 USB ID 记住这些设置。之后可以通过**形状…**、**旋转**（⌘T）更改。已告知形状的键盘只能旋转。
3. 选择层，然后在键盘图上选择按键或旋钮动作。
4. 指定动作：
   - **按键**：按住修饰键（⌃ ⌥ ⇧ ⌘ 以及右侧的修饰键）再点按按键，每点按一次就添加一个输入。**仅修饰键**会把该按键变成修饰键。**QWERTY** 按全尺寸键盘的样子排列按键，**ABC** 则分组排列。只能点按键盘支持的按键。
   - **多媒体**、**鼠标**：替换按键原有的动作。
   - **LED**：该层的灯光。新版固件可以从按键 1–16 中选择一个并为其设置颜色。
   - **延迟**：适用于能记住延迟的固件。
5. **保存**（⌘S）会写入更改的内容。**读取**（⌘R）会从支持读取的键盘获取当前设置。

在**设置**（⌘,）中可以选择界面语言（13 种之一，或跟随系统）以及浅色或深色外观，并在“关于”中查看版本和开源许可证。有更新源时（见上文），应用菜单中“设置…”的正下方会出现**检查更新…**。

**设置 ▸ 通用 ▸ 键盘**中的**更改灯光后防止按键重复**默认开启。`1189:8890` 的固件在保存灯光后会让按键的第一个字符不停重复（厂商软件也是如此），所以应用会在灯光之后再发送一次不含按键的保存命令。关闭后，应用只发送与厂商软件相同的内容。另外，这款键盘拔下后会忘记灯光设置。

## 结构

规则位于本地 Swift 软件包中。三个模块的依赖只指向内侧，向外依赖的层无法通过编译。

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        键盘、动作、布局的控件、每种键盘能存储的内容，Repository 协议，用例（仅 Foundation）
├── Sources/DataLayer/     各键盘的命令与控件编号，键盘查找以及通过 USB（IOUSBHost）、HID（IOHIDDevice）写入，模拟键盘
├── Sources/Presentation/  视图模型和界面绘制的值 — 布局的图形、按键和颜色表（Observation，不含 SwiftUI）
└── Tests/                 Swift Testing — 所有命令的字节、布局、编辑、编辑器
MINIKeyboard/
├── App/                   应用入口和菜单，组装（composition root — 唯一知道 Domain 和 DataLayer 的文件），更新（Sparkle），许可证
├── Views/                 SwiftUI（只 import Presentation）— 按摆放方向显示的键盘、动作页面、布局表单、设备日志、Settings/
├── Resources/Licenses/    显示在设置 ▸ 关于中的开源许可证
└── Localizable.xcstrings  en（原文）、de、es、fr、id、it、ja、ko、pl、pt-BR、vi、zh-Hans、zh-Hant
MINIKeyboard-Info.plist    Xcode 无法生成的 Info.plist 键 — Sparkle 的更新源和密钥、版权声明
MINIKeyboardTests/         更新开关、许可证、应用菜单
```

以 Swift 6 下零警告为标准。警告要修复，而不是关闭。

## 限制

- 目前只在一台键盘上验证过写入：一台有 6 个按键、1 个旋钮的 `1189:8890`。这台键盘只有一层，因此写入任何一层都会进入同一个位置。其余键盘按厂商应用的方式写入；测试保证了字节内容，但还没有在任何一台实机上验证过。
- `1189:8890` 和不告知类型的键盘不会告知当前设置，因此只会显示在应用中设定的内容。
- 一次只能使用一个键盘。插入多个时，使用最先找到的那个（`1189:8890` 优先）。
- 不支持鼠标移动和拖动。
