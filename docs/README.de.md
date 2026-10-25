<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="App-Symbol"></p>

<h1 align="center">Konfigurator für Makrotastaturen am Mac</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <b>Deutsch</b> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

Eine macOS-App, die Tastenbelegungen auf kleine USB-Makrotastaturen schreibt – auf die Modelle, die es
vom einzelnen Drehknopf bis zu 21 Tasten und mit bis zu vier Drehknöpfen zu kaufen gibt. Für jede Aktion
einer Taste oder eines Drehknopfs (nach links drehen, drücken, nach rechts drehen) legt sie auf den Ebenen
1–3 Tastendrücke, eine Multimedia-Taste oder eine Mausaktion fest, außerdem die Beleuchtung der Tastatur.

| Tastatur | Anordnung | Auslesen | Verzögerung | Beleuchtung | Getestet |
|---|---|---|---|---|---|
| `1189:8890` | legst du fest – Tasten (bis zu 12), Tasten pro Reihe, Drehknöpfe (bis zu 2) | nein | keine | drei Modi | ja – 6 Tasten und ein Drehknopf |
| Hersteller `1189` oder `514C`, Produkt `8840` · `8842` · `8830`–`8833` · `8850` (und `514C:8851`), neuere Firmware | wie die Tastatur sie meldet – 26 Anordnungen | sofort beim Verbinden | vor jedem Tastendruck | ein Modus und eine Farbe für jede der Tasten 1–16 | nein |
| dieselben, ältere Firmware | wie die Tastatur sie meldet | auf Anfrage | eine pro Taste | eine Farbe und ein Modus | nein |
| dieselben, ohne Angabe ihres Typs | wählst du – 26 Anordnungen | nein | keine | eine Farbe und ein Modus | nein |

Die `1189:8890` ist die Tastatur, mit der das Windows-Tool des Herstellers, „MINI KeyBoard“, arbeitet; die
übrigen sind die, nach denen die plattformübergreifende App des Herstellers, „MINI_KEYBOARD“, sucht. Die App
verwendet die Befehle beider Tools. Die meisten Tastaturen der zweiten Art melden, wie viele Tasten und
Drehknöpfe sie haben und welche Firmware darauf läuft – dann zeichnet die App die Anordnung so, wie die App des
Herstellers sie zeichnen würde. Eine Tastatur, die das nicht meldet, bekommt die Anordnung, die du unter diesen
auswählst. Die App des Herstellers kennt die `1189:8890` nicht, und ihr eigenes Tool zeichnet keine Form, daher
ist ihre tatsächliche Form unbekannt: Du gibst an, wie viele Tasten und Drehknöpfe sie hat und wie viele Tasten
in einer Reihe liegen, und die App zeichnet daraus eine ordentliche Anordnung.

Die App gibt es in 13 Sprachen – Englisch, Koreanisch, Japanisch, Chinesisch (vereinfacht und traditionell),
Deutsch, Spanisch, Französisch, Italienisch, Portugiesisch (Brasilien), Polnisch, Indonesisch und
Vietnamesisch. Sie folgt den Spracheinstellungen von macOS; in allen anderen Sprachen erscheint sie auf Englisch.

Der Quellcode in diesem Repository steht unter der MIT-Lizenz. Einige Teile der veröffentlichten App – ihr Name
und ihr Symbol – sind nicht in diesem Quellcode enthalten. Das Symbol ganz oben dient nur der Anschauung: Es
fällt nicht unter die MIT-Lizenz und ist in Builds aus diesem Repository nicht enthalten.

## Herunterladen

Die signierte und notarisierte App findest du unter [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases):
Öffne `MINIKeyboard-<Version>.dmg` und ziehe MINIKeyboard in den Ordner „Programme“. Die App sucht selbst nach
Updates (Einstellungen ▸ Allgemein) – du kannst aber auch im App-Menü **Nach Updates suchen…** wählen.

## Voraussetzungen

- macOS 14.0 (Sonoma) oder neuer
- Die `1189:8890` braucht keine Berechtigung: Die App schreibt direkt über USB auf ihre
  Konfigurationsschnittstelle und liest nie mit, was du tippst.
- Die übrigen Tastaturen werden wie in der App des Herstellers über ihre erste USB-Schnittstelle konfiguriert.
  Hält macOS diese Schnittstelle für eine Tastatur, gibt es sie für eine App erst frei, wenn ihr die
  Eingabeüberwachung erlaubt wurde; bis dahin weist die App darauf hin und bietet an, „Datenschutz & Sicherheit“
  zu öffnen.

## Build

```sh
make build          # Build mit Xcode (Warnungen gelten als Fehler)
make package-test   # Tests des Pakets – die App startet nicht
make test           # Tests der App, mit der App als Host
make check          # schlägt fehl, wenn eine Team-ID in die Projektdatei geraten ist
```

Build und Tests wurden mit Xcode 27.2 geprüft.

Signatur- und Identitätseinstellungen liegen nicht im Repository. Kopiere vor dem ersten Build die Vorlage und
trage deine Team-ID aus dem Apple Developer Program, einen Namen für die App und eine eigene Bundle-ID ein. Ohne
diese Datei bricht der Build bei `Unable to open base configuration reference file ... Signing.xcconfig` ab.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

Der Symbolname ist optional. Ohne Symbolgrafik bekommt die App das allgemeine Symbol des Systems.

Auch Updates sind optional. Die App bindet [Sparkle](https://sparkle-project.org) über den Swift Package
Manager ein – Xcode lädt es beim ersten Build –, sucht aber nur dann nach Updates, wenn `Signing.xcconfig`
sowohl einen Feed (`BRAND_FEED_URL`) als auch dessen öffentlichen EdDSA-Schlüssel (`BRAND_FEED_PUBLIC_KEY`)
angibt. Ohne beides gibt es in der App nirgends einen Menüpunkt für Updates.

Wenn Xcode das Projekt öffnet, ersetzt es den Produktnamen im gemeinsamen Schema
(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) durch deinen. Das ist so vorgesehen; du musst die Änderung
nicht committen.

Die Tests der App laufen mit der App selbst als Host. Währenddessen sucht die App wie gewohnt nach der Tastatur
und verbindet sich mit ihr. Die Tests des Pakets verwenden Fakes und simulierte Tastaturen und öffnen nie eine
echte Tastatur.

Debug-Builds haben ein Menü **Simulator**, mit dem du die App ohne die betreffende Tastatur ausprobieren kannst:
Wähle eine `1189:8890` mit beliebiger Report-ID, eine Tastatur mit beliebiger Anordnung auf einer der beiden
Firmware-Varianten oder eine, die ihren Typ nicht angibt – dann verhält sich die App, als wäre sie angeschlossen,
mit denselben Befehlen, nur dass nichts über USB hinausgeht. **Fenster ▸ Geräteprotokoll** zeigt jeden
geschriebenen Report und jede Antwort.

## Verwendung

1. Schließe die Tastatur über USB an. Die App findet sie und fragt eine Tastatur der zweiten Art nach ihrem Typ;
   eine mit neuerer Firmware wird sofort ausgelesen.
2. Bei einer Tastatur, die ihre Form nicht angibt, legst du beim ersten Mal die Anordnung fest – eine der
   Anordnungen aus der App des Herstellers, bei der `1189:8890` die Zahl der Tasten, der Tasten pro Reihe und der
   Drehknöpfe – und wie sie vor dir liegt. Die App merkt sich beides für diese USB-ID. Später änderst du das mit
   **Form…** und **Drehen** (⌘T); eine Tastatur, die ihre Form angegeben hat, lässt sich nur drehen.
3. Wähle eine Ebene und dann auf der Tastatur die Taste oder die Drehknopf-Aktion.
4. Gib ihr eine Aktion:
   - **Tasten** – Halte Sondertasten gedrückt (⌃ ⌥ ⇧ ⌘ und die rechten), dann klicke auf Tasten; jeder Klick
     fügt einen Tastendruck hinzu. **Nur Sondertasten** macht die Taste zur Sondertaste. **QWERTY** ordnet die
     Tasten wie auf einer Tastatur in voller Größe an, **ABC** in Gruppen; anklicken lassen sich nur Tasten, die
     die Tastatur annimmt.
   - **Multimedia**, **Maus** – ersetzen, was die Taste vorher tat.
   - **LED** – die Beleuchtung der Ebene; bei neuerer Firmware wählst du eine der Tasten 1–16 aus, um ihr eine
     Farbe zu geben.
   - **Verzögerung** – bei Firmware, die Wartezeiten speichert.
5. **Sichern** (⌘S) schreibt, was sich geändert hat. **Lesen** (⌘R) holt bei einer Tastatur, die sich auslesen
   lässt, die aktuellen Einstellungen.

In den **Einstellungen** (⌘,) wählst du die Sprache der Oberfläche (eine der 13 oder die des Systems) und Hell
oder Dunkel; unter „Über“ stehen die Version und die Open-Source-Lizenzen. Mit einem Update-Feed (siehe oben)
steht **Nach Updates suchen…** im App-Menü direkt unter „Einstellungen…“.

**Tastenwiederholung nach dem Ändern der Beleuchtung verhindern** (**Einstellungen ▸ Allgemein ▸ Tastatur**)
ist standardmäßig aktiviert. Die Firmware der `1189:8890` wiederholt nach dem Sichern der Beleuchtung das
erste Zeichen einer Taste endlos – die Software des Herstellers verhält sich genauso –, darum sendet die App
nach der Beleuchtung noch einen Sicherungsbefehl ohne Taste. Ist die Option deaktiviert, sendet die App nur
das, was auch die Software des Herstellers sendet. Diese Tastatur vergisst ihre Beleuchtung außerdem, wenn man
sie absteckt.

## Aufbau

Die Regeln stecken in einem lokalen Swift-Paket, aufgeteilt auf drei Module, deren Abhängigkeiten nach innen
zeigen – eine Schicht, die nach außen greift, lässt sich nicht kompilieren.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        Tastaturen, Aktionen, die Bedienelemente jeder Anordnung und was jede Tastatur aufnehmen kann; die Repository-Protokolle; Use Cases (nur Foundation)
├── Sources/DataLayer/     die Befehle jeder Tastatur und die Nummern ihrer Bedienelemente; Tastatur finden und über USB (IOUSBHost) oder HID (IOHIDDevice) schreiben; simulierte Tastaturen
├── Sources/Presentation/  View-Models und die Werte, die die Ansichten zeichnen – die Geometrie der Anordnungen, Tasten- und Farbtabellen (Observation, kein SwiftUI)
└── Tests/                 Swift Testing – die Bytes jedes Befehls, die Anordnungen, die Bearbeitungen, der Editor
MINIKeyboard/
├── App/                   Einstiegspunkt und Menüs der App, die Composition Root (die einzige Datei, die Domain und DataLayer kennt), Updates (Sparkle), Lizenzen
├── Views/                 SwiftUI (importiert nur Presentation) – die Tastatur, wie sie liegt, die Aktionsseiten, das Sheet für die Anordnung, das Geräteprotokoll; Settings/
├── Resources/Licenses/    Open-Source-Lizenzen, angezeigt unter Einstellungen ▸ Über
└── Localizable.xcstrings  en (Ausgangstext), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    die Info.plist-Schlüssel, die Xcode nicht erzeugen kann – Feed und Schlüssel für Sparkle, die Copyright-Zeile
MINIKeyboardTests/         der Update-Schalter, die Lizenzen und das App-Menü
```

Null Warnungen unter Swift 6 ist der Maßstab. Warnungen werden behoben, nicht abgeschaltet.

## Einschränkungen

- Geschrieben wurde bisher nur auf eine einzige Tastatur, eine `1189:8890` mit sechs Tasten und einem
  Drehknopf – die sich als Tastatur mit nur einer Ebene herausstellte: Egal, auf welche Ebene man schreibt, es
  landet an derselben Stelle. Die übrigen Tastaturen werden so beschrieben, wie die App ihres Herstellers sie
  beschreibt; Tests halten die Bytes fest, aber an einer echten Tastatur wurde noch keine davon ausprobiert.
- Die `1189:8890` und Tastaturen, die ihren Typ nicht angeben, können ihre Einstellungen nicht melden; die App
  zeigt daher nur, was in ihr festgelegt wurde.
- Immer nur eine Tastatur. Sind mehrere angeschlossen, nimmt die App die erste, die sie findet – eine `1189:8890`
  zuerst.
- Mausbewegungen und Ziehen werden nicht angeboten.
