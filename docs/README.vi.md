<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="Biểu tượng ứng dụng"></p>

<h1 align="center">Công cụ cấu hình bàn phím macro cho Mac</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <b>Tiếng Việt</b> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

Ứng dụng macOS dùng để ghi thiết lập phím vào những bàn phím macro USB cỡ nhỏ — loại được bán từ bản chỉ có một núm
xoay cho đến bản 21 phím, với tối đa bốn núm xoay. Với từng phím và từng thao tác của núm xoay (xoay sang trái, nhấn,
xoay sang phải), bạn có thể gán thao tác nhấn phím, phím đa phương tiện hoặc tác vụ chuột cho lớp 1–3, và đặt cả đèn
của bàn phím.

| Bàn phím | Bố cục | Đọc lại | Độ trễ | Đèn | Thử thực tế |
|---|---|---|---|---|---|
| `1189:8890` | bạn tự đặt — phím (tối đa 12), số phím mỗi hàng, núm xoay (tối đa 2) | không | không có | ba chế độ | đã thử — 6 phím, 1 núm xoay |
| nhà sản xuất `1189` hoặc `514C`, sản phẩm `8840` · `8842` · `8830`–`8833` · `8850` (và `514C:8851`), chương trình cơ sở mới | theo thông tin bàn phím báo — 26 bố cục | ngay khi kết nối | cho từng lần nhấn | một chế độ, và màu cho từng phím 1–16 | chưa |
| cùng loại bàn phím, chương trình cơ sở cũ | theo thông tin bàn phím báo | khi bạn yêu cầu | mỗi phím một giá trị | màu và chế độ | chưa |
| cùng loại bàn phím, không cho biết loại | bạn tự chọn — 26 bố cục | không | không có | màu và chế độ | chưa |

`1189:8890` là bàn phím mà công cụ cấu hình Windows của nhà sản xuất, "MINI KeyBoard", hỗ trợ; các bàn phím còn lại là
những bàn phím mà ứng dụng đa nền tảng của nhà sản xuất, "MINI_KEYBOARD", tìm kiếm. Ứng dụng dùng lệnh của cả hai công
cụ. Bàn phím loại thứ hai thường cho biết có bao nhiêu phím, bao nhiêu núm xoay và đang chạy chương trình cơ sở nào,
nên ứng dụng vẽ đúng bố cục mà ứng dụng của nhà sản xuất vẽ; bàn phím không cho biết thì dùng bố cục bạn chọn trong số
đó. Ứng dụng của nhà sản xuất không biết đến `1189:8890`, và chính công cụ của nó cũng không vẽ hình dạng, nên không thể
biết hình dạng thực tế. Vì vậy, bạn chỉ cần đặt số phím, số núm xoay và số phím trên mỗi hàng, ứng dụng sẽ vẽ ra một
bố cục ngay ngắn đúng như vậy.

Ứng dụng có 13 ngôn ngữ — tiếng Anh, tiếng Hàn, tiếng Nhật, tiếng Trung (Giản thể và Phồn thể), tiếng Đức, tiếng Tây
Ban Nha, tiếng Pháp, tiếng Ý, tiếng Bồ Đào Nha (Brazil), tiếng Ba Lan, tiếng Indonesia và tiếng Việt. Ứng dụng theo cài
đặt ngôn ngữ của macOS; với các ngôn ngữ khác, ứng dụng hiển thị bằng tiếng Anh.

Mã nguồn trong kho này được cấp phép MIT. Một số phần của ứng dụng phát hành — tên và biểu tượng — không nằm trong mã
nguồn này. Biểu tượng ở đầu trang chỉ để minh họa: biểu tượng này không thuộc phạm vi giấy phép MIT và cũng không có
trong ứng dụng được build từ kho này.

## Tải xuống

Ứng dụng đã được ký và công chứng có trên trang [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases).
Mở `MINIKeyboard-<phiên bản>.dmg` rồi kéo MINIKeyboard vào thư mục Ứng dụng. Ứng dụng tự kiểm tra bản cập nhật
(Cài đặt ▸ Chung), và bạn cũng có thể tự kiểm tra bằng **Kiểm tra bản cập nhật…** trong menu ứng dụng.

## Yêu cầu

- macOS 14.0 (Sonoma) trở lên
- `1189:8890` không cần cấp quyền gì. Ứng dụng ghi trực tiếp vào kênh cấu hình của bàn phím đó qua USB và không bao giờ
  đọc nội dung bạn gõ.
- Các bàn phím còn lại được cấu hình qua giao diện USB đầu tiên, giống như ứng dụng của nhà sản xuất. Nếu macOS coi giao
  diện đó là bàn phím, macOS chỉ mở nó cho ứng dụng đã được cho phép Giám sát đầu vào. Khi chưa được cho phép, ứng dụng
  sẽ báo cho bạn biết và đề nghị mở Quyền riêng tư & Bảo mật.

## Build

```sh
make build          # build bằng Xcode (cảnh báo được coi là lỗi)
make package-test   # kiểm thử package — ứng dụng không khởi chạy
make test           # kiểm thử ứng dụng — ứng dụng là host kiểm thử
make check          # thất bại nếu ID nhóm lọt vào tệp dự án
```

Đã kiểm tra việc build và kiểm thử với Xcode 27.2.

Thiết lập ký và định danh không có trong kho. Trước lần build đầu tiên, hãy sao chép tệp mẫu rồi điền ID nhóm Apple
Developer, tên ứng dụng và bundle ID của riêng bạn. Nếu thiếu tệp này, quá trình build sẽ dừng ở
`Unable to open base configuration reference file ... Signing.xcconfig`.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

Tên biểu tượng là tùy chọn. Nếu không có hình biểu tượng, ứng dụng được build với biểu tượng mặc định của hệ thống.

Cập nhật cũng là tùy chọn. Ứng dụng liên kết [Sparkle](https://sparkle-project.org) qua Swift Package Manager — Xcode
tải về ở lần build đầu tiên — nhưng chỉ kiểm tra bản cập nhật khi `Signing.xcconfig` có cả feed (`BRAND_FEED_URL`) lẫn
khóa công khai EdDSA của feed đó (`BRAND_FEED_PUBLIC_KEY`). Nếu thiếu, mục cập nhật sẽ không xuất hiện ở bất kỳ đâu.

Khi mở dự án, Xcode sẽ ghi lại tên sản phẩm trong scheme dùng chung (`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`)
thành tên của bạn. Điều này là bình thường và không cần commit.

Host của kiểm thử ứng dụng chính là ứng dụng. Trong lúc kiểm thử, ứng dụng vẫn tìm và kết nối với bàn phím như bình
thường. Kiểm thử package dùng đối tượng giả và bàn phím mô phỏng, và không mở bàn phím nào.

Menu **Trình mô phỏng** giúp dùng thử ứng dụng mà không cần bàn phím đó. Chọn `1189:8890`, một bố cục của chương
trình cơ sở mới, hoặc bàn phím không cho biết loại, ứng dụng sẽ hoạt động như thể bàn phím đang được cắm vào — với cùng
các lệnh, không có gì được gửi qua USB. Trong lúc dùng, thanh màu cam ở đầu cửa sổ cho biết điều đó, và **Quay lại bàn
phím qua USB** để trở lại. Bản build Debug cho chọn mọi loại (các ID báo cáo khác của `1189:8890`, chương trình cơ sở cũ).
Trong **Cửa sổ ▸ Nhật ký thiết bị**, bạn có thể xem mọi báo cáo đã ghi và mọi phản hồi nhận được.

## Cách dùng

1. Kết nối bàn phím qua USB. Ứng dụng tìm bàn phím và hỏi loại nếu đó là bàn phím loại thứ hai. Nếu là chương trình cơ
   sở mới, thiết lập được đọc ngay.
2. Với bàn phím không cho biết hình dạng, lần đầu bạn chọn bố cục — một trong các bố cục của ứng dụng nhà sản xuất,
   hoặc với `1189:8890` là số phím, số phím mỗi hàng và số núm xoay — cùng hướng đặt bàn phím trước mặt bạn. Ứng dụng
   ghi nhớ theo từng USB ID. Sau này bạn có thể đổi bằng **Hình dạng…** và **Xoay** (⌘T). Bàn phím đã cho biết hình
   dạng thì chỉ xoay được.
3. Chọn lớp, rồi chọn phím hoặc thao tác núm xoay trên hình bàn phím.
4. Gán tác vụ.
   - **Phím** — giữ phím bổ trợ (⌃ ⌥ ⇧ ⌘ và các phím bên phải), rồi nhấp vào phím. Mỗi lần nhấp thêm một lần nhấn.
     **Chỉ phím bổ trợ** biến phím đó thành phím bổ trợ. **QWERTY** xếp phím như bàn phím đầy đủ, còn **ABC** xếp theo
     nhóm. Chỉ nhấp được những phím mà bàn phím nhận.
   - **Đa phương tiện**, **Chuột** — thay thế tác vụ trước đó của phím.
   - **LED** — đèn của lớp. Với chương trình cơ sở mới, chọn một trong các phím 1–16 để đặt màu cho phím đó.
   - **Độ trễ** — trên chương trình cơ sở có ghi nhớ độ trễ.
5. **Lưu** (⌘S) ghi những gì đã thay đổi. **Đọc** (⌘R) lấy thiết lập hiện tại từ bàn phím đọc được.

Trong **Cài đặt** (⌘,), bạn chọn ngôn ngữ giao diện (một trong 13 ngôn ngữ, hoặc ngôn ngữ hệ thống) và chế độ sáng hoặc
tối; trong Giới thiệu, bạn xem được phiên bản và giấy phép nguồn mở. Nếu có feed cập nhật (xem ở trên),
**Kiểm tra bản cập nhật…** nằm ngay dưới Cài đặt… trong menu ứng dụng.

Trong **Cài đặt ▸ Chung ▸ Khắc phục lỗi firmware**, **Ngăn lặp phím sau khi thay đổi đèn** được bật sẵn.
Firmware của `1189:8890` lặp lại không ngừng ký tự đầu tiên của phím sau khi lưu đèn (phần mềm của nhà sản
xuất cũng vậy), nên ứng dụng gửi thêm một lệnh lưu không kèm phím nào sau đèn. Khi tắt, ứng dụng chỉ gửi đúng
những gì phần mềm của nhà sản xuất gửi. Bàn phím này cũng quên cài đặt đèn khi rút ra.

## Cấu trúc

Các quy tắc nằm trong một Swift package cục bộ. Phụ thuộc giữa ba module chỉ hướng vào trong, và lớp nào vươn ra ngoài
sẽ không biên dịch được.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        bàn phím, tác vụ, các nút điều khiển của từng bố cục và những gì mỗi bàn phím chứa được; giao thức repository; use case (chỉ Foundation)
├── Sources/DataLayer/     lệnh của từng bàn phím và số hiệu các nút điều khiển; tìm bàn phím và ghi qua USB (IOUSBHost) hoặc HID (IOHIDDevice); bàn phím mô phỏng
├── Sources/Presentation/  view model và các giá trị màn hình vẽ — hình vẽ bố cục, bảng phím và màu (Observation, không có SwiftUI)
└── Tests/                 Swift Testing — byte của mọi lệnh, bố cục, chỉnh sửa, trình chỉnh sửa
MINIKeyboard/
├── App/                   điểm vào ứng dụng và menu, composition root (tệp duy nhất biết Domain và DataLayer), cập nhật (Sparkle), giấy phép
├── Views/                 SwiftUI (chỉ import Presentation) — bàn phím theo hướng đặt, các trang tác vụ, sheet bố cục, nhật ký thiết bị; Settings/
├── Resources/Licenses/    giấy phép nguồn mở hiển thị trong Cài đặt ▸ Giới thiệu
└── Localizable.xcstrings  en (gốc), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    các khóa Info.plist mà Xcode không tạo được — feed và khóa của Sparkle, dòng bản quyền
MINIKeyboardTests/         công tắc cập nhật, giấy phép, menu ứng dụng
```

Tiêu chuẩn là không có cảnh báo nào với Swift 6. Cảnh báo được sửa chứ không bị tắt đi.

## Hạn chế

- Đến nay, việc ghi mới chỉ được kiểm tra trên một bàn phím là `1189:8890` có 6 phím và 1 núm xoay — bàn phím này hóa
  ra chỉ có một lớp, nên ghi vào lớp nào cũng vào cùng một chỗ. Các bàn phím còn lại được ghi đúng theo cách ứng dụng
  của nhà sản xuất ghi. Kiểm thử giữ đúng từng byte, nhưng chưa bàn phím nào được thử trên thiết bị thật.
- `1189:8890` và các bàn phím không cho biết loại không báo lại thiết lập hiện tại, nên chỉ thấy được những gì đã đặt
  trong ứng dụng.
- Mỗi lần chỉ một bàn phím. Nếu cắm nhiều bàn phím, ứng dụng dùng bàn phím tìm thấy đầu tiên — `1189:8890` được ưu
  tiên.
- Không hỗ trợ di chuyển chuột và kéo thả.
