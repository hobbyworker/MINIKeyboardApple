<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="Ikon aplikasi"></p>

<h1 align="center">Alat pengatur papan ketik makro untuk Mac</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <b>Bahasa Indonesia</b> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

Aplikasi macOS untuk menulis pengaturan tombol ke papan ketik makro USB berukuran kecil — papan ketik yang dijual
mulai dari yang hanya punya satu kenop hingga yang punya 21 tombol, dengan kenop sampai empat buah. Untuk setiap
tombol dan setiap tindakan kenop (putar ke kiri, tekan, putar ke kanan), Anda dapat mengatur tekanan tombol, tombol
multimedia, atau tindakan tetikus di lapisan 1–3, serta pencahayaan papan ketik.

<p align="center"><img src="../.github/devices.png" width="560" alt="Dua papan ketik makro USB kecil: 6 tombol dan 1 kenop, 12 tombol dan 2 kenop"></p>

| Papan ketik | Tata letak | Membaca kembali | Tunda | Pencahayaan | Diuji langsung |
|---|---|---|---|---|---|
| `1189:8890` | Anda atur sendiri — tombol (hingga 12), tombol per baris, kenop (hingga 2) | tidak bisa | tidak ada | tiga mode | sudah — 6 tombol, 1 kenop |
| produsen `1189` atau `514C`, produk `8840` · `8842` · `8830`–`8833` · `8850` (dan `514C:8851`), firmware baru | sesuai yang dilaporkan papan ketik — 26 tata letak | langsung saat terhubung | per tekanan | satu mode, dan warna untuk tombol 1–16 | belum |
| papan ketik yang sama, firmware lama | sesuai yang dilaporkan papan ketik | saat Anda minta | satu per tombol | warna dan mode | belum |
| papan ketik yang sama, tidak memberi tahu jenisnya | Anda pilih sendiri — 26 tata letak | tidak bisa | tidak ada | warna dan mode | belum |

`1189:8890` adalah papan ketik yang ditangani alat pengaturan Windows dari produsen, "MINI KeyBoard"; sisanya adalah
papan ketik yang dicari oleh aplikasi lintas platform dari produsen, "MINI_KEYBOARD". Aplikasi ini memakai perintah dari
kedua alat tersebut. Papan ketik jenis kedua biasanya memberi tahu jumlah tombol dan kenopnya serta firmware yang
dipakainya, sehingga aplikasi menggambar tata letaknya persis seperti aplikasi produsen; papan ketik yang tidak memberi
tahu memakai salah satu tata letak itu yang Anda pilih. `1189:8890` tidak dikenal oleh aplikasi produsen, dan alatnya
sendiri pun tidak menggambar bentuknya, jadi bentuk aslinya tidak diketahui. Karena itu, cukup tentukan jumlah tombol
dan kenopnya serta jumlah tombol dalam satu baris, lalu aplikasi akan menggambarnya dengan rapi sesuai angka itu.

Aplikasi ini tersedia dalam 13 bahasa — Inggris, Korea, Jepang, Tionghoa (Sederhana dan Tradisional), Jerman, Spanyol,
Prancis, Italia, Portugis (Brasil), Polandia, Indonesia, dan Vietnam. Aplikasi mengikuti pengaturan bahasa macOS; untuk
bahasa lainnya, aplikasi tampil dalam bahasa Inggris.

Kode sumber di repositori ini berlisensi MIT. Sebagian dari aplikasi yang didistribusikan — nama dan ikonnya — tidak
termasuk dalam kode sumber ini. Ikon di bagian atas hanya ditampilkan sebagai gambaran: ikon itu tidak dicakup lisensi
MIT dan tidak disertakan dalam aplikasi yang dibangun dari repositori ini.

## macOS, Windows, dan Linux

MINIKeyboard hadir dalam tiga edisi yang dibuat dengan aturan yang sama — papan ketik yang sama, perintah yang sama, 13 bahasa yang sama.

| Repositori | Unduh |
|---|---|
| [**MINIKeyboardApple**](https://github.com/hobbyworker/MINIKeyboardApple)<br><img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white"> <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6"> <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | `.dmg` dari [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases/latest) — memperbarui dirinya sendiri |
| [**MINIKeyboardWin**](https://github.com/hobbyworker/MINIKeyboardWin)<br><img alt="Windows 10 (2004)+ · 11" src="https://img.shields.io/badge/Windows-10%20(2004)%2B%20·%2011-0078D4?logo=windows&logoColor=white"> <img alt="x64 · ARM64" src="https://img.shields.io/badge/x64%20·%20ARM64-5E5CE6"> <img alt=".NET 10 · WinUI 3" src="https://img.shields.io/badge/.NET%2010-WinUI%203-512BD4?logo=dotnet&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | `Setup.exe` dari [Releases](https://github.com/hobbyworker/MINIKeyboardWin/releases/latest) — memperbarui dirinya sendiri |
| [**MINIKeyboardLinux**](https://github.com/hobbyworker/MINIKeyboardLinux)<br><img alt="Linux" src="https://img.shields.io/badge/Linux-GTK%204%20·%20libadwaita-4A86CF?logo=linux&logoColor=white"> <img alt="Flatpak: x86_64 · aarch64" src="https://img.shields.io/badge/Flatpak-x86__64%20·%20aarch64-4A90D9?logo=flatpak&logoColor=white"> <img alt="Rust" src="https://img.shields.io/badge/Rust-2024-B7410E?logo=rust&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [Flatpak](https://github.com/hobbyworker/MINIKeyboardLinux#download) atau paket dari [Releases](https://github.com/hobbyworker/MINIKeyboardLinux/releases/latest) — pembaruan lewat pusat perangkat lunak |

## Unduh

Aplikasi yang sudah ditandatangani dan dinotarisasi tersedia di [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases).
Buka `MINIKeyboard-<versi>.dmg`, lalu seret MINIKeyboard ke folder Aplikasi. Aplikasi memeriksa pembaruan dengan
sendirinya (Pengaturan ▸ Umum), dan Anda juga bisa memeriksanya sendiri lewat **Periksa Pembaruan…** di menu aplikasi.

## Persyaratan

- macOS 14.0 (Sonoma) atau yang lebih baru
- `1189:8890` tidak memerlukan izin apa pun. Aplikasi menulis langsung ke saluran konfigurasi papan ketik itu melalui
  USB dan tidak pernah membaca apa yang Anda ketik.
- Papan ketik lainnya diatur melalui antarmuka USB pertamanya, seperti yang dilakukan aplikasi produsen. Jika macOS
  menganggap antarmuka itu sebagai papan ketik, macOS hanya membukanya untuk aplikasi yang diizinkan di
  Pengawasan Input. Selama belum diizinkan, aplikasi memberi tahu Anda dan menawarkan untuk membuka Privasi & Keamanan.

## Build

```sh
make build          # build lewat Xcode (peringatan dianggap galat)
make package-test   # tes paket — aplikasi tidak dijalankan
make test           # tes aplikasi — aplikasi menjadi host tes
make check          # gagal jika ID tim masuk ke file proyek
```

Proses build dan pengujian sudah diperiksa dengan Xcode 27.2.

Pengaturan penandatanganan dan identitas tidak ada di repositori. Sebelum build pertama, salin contohnya lalu isi ID tim
Apple Developer, nama aplikasi, dan ID bundel milik Anda sendiri. Tanpa file ini, build akan berhenti di
`Unable to open base configuration reference file ... Signing.xcconfig`.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

Nama ikon tidak wajib diisi. Tanpa gambar ikon, aplikasi dibangun dengan ikon bawaan sistem.

Pembaruan juga opsional. Aplikasi menautkan [Sparkle](https://sparkle-project.org) melalui Swift Package Manager — Xcode
mengunduhnya saat build pertama — tetapi hanya memeriksa pembaruan jika `Signing.xcconfig` berisi feed
(`BRAND_FEED_URL`) sekaligus kunci publik EdDSA-nya (`BRAND_FEED_PUBLIC_KEY`). Tanpa keduanya, item pembaruan tidak
muncul di mana pun.

Saat membuka proyek, Xcode menulis ulang nama produk di dalam skema bersama
(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) menjadi nama milik Anda. Itu normal, dan tidak perlu di-commit.

Host untuk tes aplikasi adalah aplikasi itu sendiri. Selama tes berjalan, aplikasi mencari papan ketik dan terhubung
seperti biasa. Tes paket memakai objek tiruan dan papan ketik simulasi, dan tidak pernah membuka papan ketik.

Menu **Simulator** memungkinkan Anda mencoba aplikasi tanpa papan ketik tersebut. Pilih `1189:8890`, tata letak dari
firmware baru, atau papan ketik yang tidak memberi tahu jenisnya, dan aplikasi akan bekerja seolah-olah papan ketik itu
tercolok — dengan perintah yang sama, tanpa ada yang dikirim ke USB. Selama digunakan, bilah oranye di bagian atas jendela
memberi tahu hal itu, dan **Kembali ke papan ketik di USB** mengembalikannya. Build Debug menawarkan semua jenis (ID laporan
lain dari `1189:8890`, firmware lama). Di **Jendela ▸ Log Perangkat**, Anda bisa melihat semua laporan yang ditulis dan
semua jawaban yang diterima.

## Cara menggunakan

1. Hubungkan papan ketik melalui USB. Aplikasi menemukan papan ketik dan menanyakan jenisnya jika papan ketik itu dari
   jenis kedua. Jika firmware-nya baru, pengaturannya langsung dibaca.
2. Untuk papan ketik yang tidak memberi tahu bentuknya, pertama kali Anda menentukan tata letaknya — salah satu tata
   letak aplikasi produsen, atau untuk `1189:8890`, jumlah tombol, tombol per baris, dan kenop — serta arah posisinya
   di depan Anda. Aplikasi mengingatnya untuk setiap ID USB. Nanti Anda bisa mengubahnya dengan **Bentuk…** dan
   **Putar** (⌘T). Papan ketik yang sudah memberi tahu bentuknya hanya bisa diputar.
3. Pilih lapisan, lalu pilih tombol atau tindakan kenop pada gambar papan ketik.
4. Berikan tindakannya.
   - **Tombol** — tahan tombol pengubah (⌃ ⌥ ⇧ ⌘ dan yang di sisi kanan), lalu klik tombol. Setiap klik menambahkan
     satu tekanan. **Hanya pengubah** menjadikan tombol itu sebagai tombol pengubah. **QWERTY** menata tombol seperti
     pada papan ketik ukuran penuh, sedangkan **ABC** menatanya per kelompok. Hanya tombol yang diterima papan ketik
     yang bisa diklik.
   - **Multimedia**, **Tetikus** — menggantikan tindakan tombol sebelumnya.
   - **LED** — pencahayaan lapisan. Pada firmware baru, pilih salah satu tombol 1–16 untuk memberinya warna.
   - **Tunda** — pada firmware yang menyimpan tunda.
5. **Simpan** (⌘S) menulis perubahan. **Baca** (⌘R) mengambil pengaturan saat ini dari papan ketik yang bisa dibaca.

Di **Pengaturan** (⌘,), Anda memilih bahasa antarmuka (salah satu dari 13 bahasa, atau bahasa sistem) serta tampilan
terang atau gelap, dan di Tentang, Anda bisa melihat versi dan lisensi sumber terbuka. Jika ada feed pembaruan (lihat di
atas), **Periksa Pembaruan…** muncul tepat di bawah Pengaturan… di menu aplikasi.

Di **Pengaturan ▸ Umum ▸ Penanganan bug firmware**, **Cegah pengulangan tombol setelah mengubah pencahayaan**
aktif secara bawaan. Firmware `1189:8890` mengulang karakter pertama sebuah tombol tanpa henti setelah
pencahayaannya disimpan (perangkat lunak pabrikannya juga begitu), jadi aplikasi mengirim satu perintah simpan
lagi, tanpa tombol, setelah pencahayaan. Jika dinonaktifkan, aplikasi hanya mengirim hal yang sama dengan
perangkat lunak pabrikan. Papan ketik ini juga melupakan pencahayaannya saat dicabut.

## Struktur

Aturannya berada di paket Swift lokal. Ketergantungan ketiga modulnya hanya mengarah ke dalam, dan lapisan yang
menjangkau ke luar tidak akan terkompilasi.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        papan ketik, tindakan, kontrol setiap tata letak, dan apa yang bisa ditampung tiap papan ketik; protokol repositori; use case (hanya Foundation)
├── Sources/DataLayer/     perintah setiap papan ketik dan nomor kontrolnya; menemukan papan ketik dan menulis lewat USB (IOUSBHost) atau HID (IOHIDDevice); papan ketik simulasi
├── Sources/Presentation/  view model dan nilai yang digambar layar — gambar tata letak, tabel tombol dan warna (Observation, tanpa SwiftUI)
└── Tests/                 Swift Testing — byte setiap perintah, tata letak, pengeditan, editor
MINIKeyboard/
├── App/                   titik masuk aplikasi dan menu, composition root (satu-satunya file yang mengenal Domain dan DataLayer), pembaruan (Sparkle), lisensi
├── Views/                 SwiftUI (hanya mengimpor Presentation) — papan ketik sesuai posisinya, halaman tindakan, lembar tata letak, log perangkat; Settings/
├── Resources/Licenses/    lisensi sumber terbuka yang ditampilkan di Pengaturan ▸ Tentang
└── Localizable.xcstrings  en (sumber), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    kunci Info.plist yang tidak bisa dibuat Xcode — feed dan kunci Sparkle, baris hak cipta
MINIKeyboardTests/         sakelar pembaruan, lisensi, menu aplikasi
```

Standarnya adalah nol peringatan di Swift 6. Peringatan diperbaiki, bukan dimatikan.

## Batasan

- Sejauh ini, penulisan baru diperiksa pada satu papan ketik, yaitu `1189:8890` dengan 6 tombol dan 1 kenop — papan
  ketik ini ternyata hanya punya satu lapisan, jadi apa pun yang ditulis ke lapisan mana pun masuk ke tempat yang sama.
  Papan ketik lainnya ditulis persis seperti cara aplikasi produsennya menulis. Tes menjaga byte-nya, tetapi belum ada
  satu pun yang diperiksa langsung pada perangkatnya.
- `1189:8890` dan papan ketik yang tidak memberi tahu jenisnya tidak melaporkan pengaturan saat ini, jadi yang terlihat
  hanya apa yang diatur di aplikasi.
- Hanya satu papan ketik dalam satu waktu. Jika beberapa papan ketik tercolok, aplikasi memakai yang pertama ditemukan —
  `1189:8890` didahulukan.
- Gerakan dan seret tetikus tidak tersedia.
