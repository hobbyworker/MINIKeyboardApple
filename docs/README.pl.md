<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="Ikona aplikacji"></p>

<h1 align="center">Konfigurator klawiatur makro na Maca</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <b>Polski</b> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

Aplikacja na macOS, która zapisuje ustawienia klawiszy w małych klawiaturach makro USB. Takie klawiatury sprzedaje
się w wielu wersjach: od modeli z jednym pokrętłem po modele z 21 klawiszami, z maksymalnie czterema pokrętłami.
Dla każdego klawisza i każdej akcji pokrętła (obrót w lewo, naciśnięcie, obrót w prawo) aplikacja ustawia na
warstwach 1–3 naciśnięcia klawiszy, klawisz multimedialny lub akcję myszy, a także podświetlenie klawiatury.

<p align="center"><img src="../.github/devices.png" width="560" alt="Dwie małe klawiatury makr USB: sześć klawiszy i pokrętło, dwanaście klawiszy i dwa pokrętła"></p>

| Klawiatura | Układ | Odczyt | Opóźnienie | Podświetlenie | Sprawdzono |
|---|---|---|---|---|---|
| `1189:8890` | ustawiasz go sam — klawisze (do 12), klawisze w rzędzie, pokrętła (do 2) | nie | nie | trzy tryby | tak — 6 klawiszy i pokrętło |
| producent `1189` lub `514C`, produkt `8840` · `8842` · `8830`–`8833` · `8850` (oraz `514C:8851`), nowsze oprogramowanie sprzętowe | według tego, co podaje klawiatura — 26 układów | od razu po podłączeniu | przed każdym naciśnięciem | tryb i kolor dla każdego z klawiszy 1–16 | nie |
| te same, starsze oprogramowanie sprzętowe | według tego, co podaje klawiatura | na żądanie | jedno na klawisz | kolor i tryb | nie |
| te same, niepodające swojego typu | wybierasz go sam — 26 układów | nie | nie | kolor i tryb | nie |

`1189:8890` to klawiatura, z którą współpracuje windowsowe narzędzie konfiguracyjne producenta „MINI KeyBoard”;
pozostałe to te, których szuka wieloplatformowa aplikacja producenta „MINI_KEYBOARD”. Aplikacja korzysta z poleceń
obu narzędzi. Większość klawiatur drugiego rodzaju podaje, ile ma klawiszy i pokręteł oraz jakie ma oprogramowanie
sprzętowe, więc aplikacja rysuje taki sam układ, jaki narysowałaby aplikacja producenta; dla klawiatury, która tego
nie podaje, używa tego z tych układów, który wybierzesz. Aplikacja producenta nie zna klawiatury `1189:8890`,
a narzędzie przeznaczone dla tej klawiatury nie rysuje żadnego kształtu, więc jej rzeczywisty kształt nie jest
znany. Dlatego to ty podajesz, ile ma klawiszy i pokręteł oraz ile klawiszy jest w rzędzie, a aplikacja rysuje je
dokładnie tak, w równym układzie.

Aplikacja jest dostępna w 13 językach — angielskim, koreańskim, japońskim, chińskim (uproszczonym i tradycyjnym),
niemieckim, hiszpańskim, francuskim, włoskim, portugalskim (Brazylia), polskim, indonezyjskim i wietnamskim — i
używa języka ustawionego w macOS. W pozostałych językach wyświetla się po angielsku.

Kod źródłowy w tym repozytorium jest objęty licencją MIT. Niektóre elementy rozpowszechnianej aplikacji — jej nazwa
i ikona — nie wchodzą w skład tego kodu. Ikona na górze jest pokazana wyłącznie poglądowo: nie obejmuje jej licencja
MIT i nie ma jej w aplikacji zbudowanej z tego repozytorium.

## macOS, Windows i Linux

MINIKeyboard ma trzy wydania zbudowane według tych samych zasad — te same klawiatury, te same polecenia, te same 13 języków.

| Repozytorium | GitHub |
|---|---|
| **MINIKeyboardApple**<br><img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white"> <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6"> <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardApple](https://github.com/hobbyworker/MINIKeyboardApple) |
| **MINIKeyboardWin**<br><img alt="Windows 10 (2004)+ · 11" src="https://img.shields.io/badge/Windows-10%20(2004)%2B%20·%2011-0078D4?logo=windows&logoColor=white"> <img alt="x64 · ARM64" src="https://img.shields.io/badge/x64%20·%20ARM64-5E5CE6"> <img alt=".NET 10 · WinUI 3" src="https://img.shields.io/badge/.NET%2010-WinUI%203-512BD4?logo=dotnet&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardWin](https://github.com/hobbyworker/MINIKeyboardWin) |
| **MINIKeyboardLinux**<br><img alt="Linux" src="https://img.shields.io/badge/Linux-GTK%204%20·%20libadwaita-4A86CF?logo=linux&logoColor=white"> <img alt="Flatpak: x86_64 · aarch64" src="https://img.shields.io/badge/Flatpak-x86__64%20·%20aarch64-4A90D9?logo=flatpak&logoColor=white"> <img alt="Rust" src="https://img.shields.io/badge/Rust-2024-B7410E?logo=rust&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardLinux](https://github.com/hobbyworker/MINIKeyboardLinux) |

## Pobieranie

Podpisana i poświadczona notarialnie aplikacja jest dostępna na stronie
[Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases). Otwórz `MINIKeyboard-<wersja>.dmg` i
przeciągnij MINIKeyboard do folderu Aplikacje. Aplikacja sama sprawdza dostępność uaktualnień (Ustawienia ▸ Ogólne),
a możesz też sprawdzić je ręcznie poleceniem **Sprawdź uaktualnienia…** w menu aplikacji.

## Wymagania

- macOS 14.0 (Sonoma) lub nowszy
- Klawiatura `1189:8890` nie wymaga żadnych uprawnień: aplikacja zapisuje dane bezpośrednio przez USB w interfejsie
  konfiguracyjnym tej klawiatury i nigdy nie odczytuje tego, co piszesz.
- Pozostałe klawiatury są konfigurowane przez pierwszy interfejs USB, tak jak robi to aplikacja producenta. Jeśli
  macOS traktuje ten interfejs jako klawiaturę, udostępnia go tylko aplikacjom, którym zezwolono na Monitorowanie
  wprowadzania. Dopóki aplikacja nie ma tego pozwolenia, informuje o tym i proponuje otwarcie ustawień Prywatność i
  ochrona.

## Budowanie

```sh
make build          # buduje przez Xcode (ostrzeżenia są błędami)
make package-test   # testy pakietu — aplikacja się nie uruchamia
make test           # testy aplikacji — hostem testów jest sama aplikacja
make check          # kończy się błędem, jeśli identyfikator zespołu trafił do pliku projektu
```

Budowanie i testy sprawdzono w Xcode 27.2.

Ustawień podpisywania i tożsamości nie ma w repozytorium. Przed pierwszym budowaniem skopiuj przykład i wpisz swój
identyfikator zespołu Apple Developer, nazwę aplikacji i własny identyfikator pakietu. Bez tego pliku budowanie
zatrzymuje się na `Unable to open base configuration reference file ... Signing.xcconfig`.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

Nazwa ikony jest opcjonalna. Bez grafiki ikony aplikacja zostanie zbudowana z ogólną ikoną systemową.

Uaktualnienia też są opcjonalne. Aplikacja dołącza [Sparkle](https://sparkle-project.org) przez Swift Package
Manager — Xcode pobiera go przy pierwszym budowaniu — ale sprawdza uaktualnienia tylko wtedy, gdy `Signing.xcconfig`
podaje zarówno kanał (`BRAND_FEED_URL`), jak i jego klucz publiczny EdDSA (`BRAND_FEED_PUBLIC_KEY`). Bez nich
w aplikacji nigdzie nie ma pozycji dotyczących uaktualnień.

Gdy Xcode otwiera projekt, zmienia nazwę produktu we współdzielonym schemacie
(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) na twoją. To normalne i nie trzeba tego commitować.

Hostem testów aplikacji jest sama aplikacja. Podczas testów aplikacja jak zwykle szuka klawiatury i łączy się z nią.
Testy pakietu korzystają z atrap oraz symulowanych klawiatur i nigdy nie otwierają żadnej klawiatury.

Menu **Symulator** pozwala wypróbować aplikację bez danej klawiatury: wybierz `1189:8890`, układ z nowszym
oprogramowaniem sprzętowym albo klawiaturę, która nie podaje swojego typu, a aplikacja zachowa się tak, jakby klawiatura
była podłączona — z tymi samymi poleceniami, bez wysyłania czegokolwiek przez USB. Gdy symulator jest w użyciu, mówi o tym
pomarańczowy pasek u góry okna, a **Wróć do klawiatury przez USB** przywraca prawdziwą klawiaturę. Kompilacje Debug
oferują każdy rodzaj (pozostałe ID raportu `1189:8890`, starsze oprogramowanie sprzętowe). **Okno ▸ Dziennik urządzenia**
pokazuje wszystkie zapisane raporty i wszystkie odpowiedzi.

## Korzystanie

1. Podłącz klawiaturę przez USB. Aplikacja ją znajduje, a klawiaturę drugiego rodzaju pyta, czym jest; taką
   z nowszym oprogramowaniem sprzętowym od razu odczytuje.
2. Dla klawiatury, która nie podaje swojego kształtu, przy pierwszym podłączeniu wybierasz układ — jeden z układów
   aplikacji producenta, a dla `1189:8890` liczbę klawiszy, klawiszy w rzędzie i pokręteł — oraz to, jak leży przed
   tobą. Aplikacja zapamiętuje oba ustawienia dla danego ID USB. Później zmienisz je poleceniami **Kształt…**
   i **Obróć** (⌘T). Klawiaturę, która podała swój kształt, można tylko obracać.
3. Wybierz warstwę, a potem na rysunku klawiatury klawisz lub akcję pokrętła.
4. Przypisz akcję:
   - **Klawisze** — przytrzymaj modyfikatory (⌃ ⌥ ⇧ ⌘ oraz te po prawej stronie) i klikaj klawisze; każde
     kliknięcie dodaje jedno naciśnięcie. **Tylko modyfikatory** zmienia klawisz w klawisz modyfikujący. **QWERTY**
     rozmieszcza klawisze jak na pełnowymiarowej klawiaturze, a **ABC** — w grupach. Kliknąć można tylko klawisze,
     które klawiatura obsługuje.
   - **Multimedia**, **Mysz** — zastępują to, co robił klawisz.
   - **LED** — podświetlenie warstwy; w nowszym oprogramowaniu sprzętowym wybierz jeden z klawiszy 1–16, aby nadać
     mu kolor.
   - **Opóźnienie** — w oprogramowaniu sprzętowym, które zapamiętuje opóźnienia.
5. **Zachowaj** (⌘S) zapisuje zmiany. **Odczytaj** (⌘R) pobiera bieżące ustawienia z klawiatury, która pozwala
   je odczytać.

**Ustawienia** (⌘,) pozwalają wybrać język interfejsu (jeden z 13 lub język systemu) oraz tryb jasny lub ciemny,
a w sekcji Informacje znajdziesz wersję i licencje open source. Jeśli jest kanał uaktualnień (patrz wyżej), polecenie
**Sprawdź uaktualnienia…** znajduje się tuż pod poleceniem Ustawienia… w menu aplikacji.

Opcja **Zapobiegaj powtarzaniu klawiszy po zmianie podświetlenia** (**Ustawienia ▸ Ogólne ▸ Obejścia błędów
oprogramowania układowego**) jest domyślnie włączona. Oprogramowanie układowe `1189:8890` po zachowaniu
podświetlenia bez końca powtarza pierwszy znak klawisza (oprogramowanie producenta działa tak samo), dlatego
aplikacja po podświetleniu wysyła jeszcze jedno polecenie zapisu, bez żadnego klawisza. Gdy opcja jest
wyłączona, aplikacja wysyła tylko to, co oprogramowanie producenta. Ta klawiatura zapomina też podświetlenie
po odłączeniu.

## Struktura

Reguły znajdują się w lokalnym pakiecie Swift, w trzech modułach, których zależności są skierowane tylko do środka —
warstwa sięgająca na zewnątrz się nie kompiluje.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        klawiatury, akcje, kontrolki każdego układu i to, co mieści każda klawiatura; protokoły repozytoriów; przypadki użycia (tylko Foundation)
├── Sources/DataLayer/     polecenia każdej klawiatury i numeracja jej kontrolek; wyszukiwanie klawiatury i zapis przez USB (IOUSBHost) lub HID (IOHIDDevice); symulowane klawiatury
├── Sources/Presentation/  modele widoków i wartości rysowane przez ekrany — geometria układów, tabele klawiszy i kolorów (Observation, bez SwiftUI)
└── Tests/                 Swift Testing — bajty każdego polecenia, układy, edycje, edytor
MINIKeyboard/
├── App/                   punkt wejścia i menu aplikacji, composition root (jedyny plik, który widzi Domain i DataLayer), uaktualnienia (Sparkle), licencje
├── Views/                 SwiftUI (importuje tylko Presentation) — klawiatura tak, jak leży, strony akcji, arkusz układu, dziennik urządzenia; Settings/
├── Resources/Licenses/    licencje open source widoczne w Ustawienia ▸ Informacje
└── Localizable.xcstrings  en (źródło), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    klucze Info.plist, których Xcode nie potrafi wygenerować — kanał i klucz Sparkle, wiersz z informacją o prawach autorskich
MINIKeyboardTests/         przełącznik uaktualnień, licencje i menu aplikacji
```

Zero ostrzeżeń w Swift 6 to standard. Ostrzeżenia się poprawia, a nie wyłącza.

## Ograniczenia

- Zapis sprawdzono dotąd tylko na jednej klawiaturze — `1189:8890` z sześcioma klawiszami i pokrętłem — która
  okazała się mieć tylko jedną warstwę: to, co zapiszesz na dowolnej warstwie, trafia w to samo miejsce. Pozostałe
  klawiatury są zapisywane tak, jak robi to aplikacja ich producenta; testy pilnują bajtów, ale żadnej z nich nie
  sprawdzono jeszcze na prawdziwej klawiaturze.
- Klawiatura `1189:8890` i klawiatury, które nie podają swojego typu, nie przekazują swoich bieżących ustawień, więc
  aplikacja pokazuje tylko to, co w niej ustawiono.
- Jedna klawiatura naraz. Jeśli podłączonych jest kilka, aplikacja używa pierwszej znalezionej — w pierwszej
  kolejności `1189:8890`.
- Nie ma akcji ruchu myszy ani przeciągania.
