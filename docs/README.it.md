<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="Icona dell’app"></p>

<h1 align="center">Configuratore di tastiere macro per Mac</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <b>Italiano</b> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

Un’app per macOS che scrive le impostazioni dei tasti su piccole tastiere macro USB – quelle in commercio
che vanno da una sola manopola fino a 21 tasti, con al massimo quattro manopole. Per ogni azione di un tasto o
di una manopola (ruota a sinistra, premi, ruota a destra) imposta sui livelli 1–3 pressioni di tasti, un tasto
multimediale o un’azione del mouse, oltre all’illuminazione della tastiera.

<p align="center"><img src="../.github/devices.png" width="560" alt="Due piccole tastiere macro USB: sei tasti e una manopola, dodici tasti e due manopole"></p>

| Tastiera | Disposizione | Lettura | Ritardo | Illuminazione | Provata |
|---|---|---|---|---|---|
| `1189:8890` | la decidi tu – tasti (fino a 12), tasti per riga, manopole (fino a 2) | no | nessuno | tre modalità | sì – 6 tasti e una manopola |
| produttore `1189` o `514C`, prodotto `8840` · `8842` · `8830`–`8833` · `8850` (e `514C:8851`), firmware più recente | secondo quanto indica la tastiera – 26 disposizioni | subito alla connessione | prima di ogni pressione | una modalità e un colore per ciascuno dei tasti 1–16 | no |
| le stesse, firmware precedente | secondo quanto indica la tastiera | su richiesta | uno per tasto | un colore e una modalità | no |
| le stesse, senza indicare il proprio tipo | la scegli tu – 26 disposizioni | no | nessuno | un colore e una modalità | no |

La `1189:8890` è la tastiera gestita dallo strumento Windows del produttore, “MINI KeyBoard”; le altre sono
quelle che cerca l’app multipiattaforma del produttore, “MINI_KEYBOARD”. L’app usa i comandi di entrambi gli
strumenti. La maggior parte delle tastiere del secondo tipo indica quanti tasti e manopole ha e quale firmware
usa, e l’app disegna la disposizione che disegnerebbe l’app del produttore; una tastiera che non lo indica
riceve, tra queste disposizioni, quella che scegli tu. L’app del produttore non conosce la `1189:8890` e il suo
stesso strumento non ne disegna la forma, quindi la sua forma reale non è nota: indichi all’app quanti tasti e
manopole ha e quanti tasti ci sono in una riga, e l’app ne disegna una disposizione ordinata.

L’app è disponibile in 13 lingue – inglese, coreano, giapponese, cinese (semplificato e tradizionale), tedesco,
spagnolo, francese, italiano, portoghese (Brasile), polacco, indonesiano e vietnamita – e segue le impostazioni
della lingua di macOS. Nelle altre lingue appare in inglese.

Il codice sorgente di questo repository è distribuito con licenza MIT. Alcune parti dell’app distribuita non
fanno parte di questo codice: il nome e l’icona. L’icona in alto è mostrata solo a titolo illustrativo: non è
coperta dalla licenza MIT e non è inclusa nelle build ottenute da questo repository.

## Download

L’app firmata e notarizzata si trova nella pagina [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases):
apri `MINIKeyboard-<versione>.dmg` e trascina MINIKeyboard nella cartella Applicazioni. L’app cerca da sola gli
aggiornamenti (Impostazioni ▸ Generali), ma puoi anche scegliere **Cerca aggiornamenti…** nel menu dell’app.

## Requisiti

- macOS 14.0 (Sonoma) o versioni successive
- La `1189:8890` non richiede alcuna autorizzazione: l’app scrive direttamente sulla sua interfaccia di
  configurazione tramite USB e non legge mai ciò che digiti.
- Le altre tastiere si configurano tramite la loro prima interfaccia USB, come fa l’app del produttore. Se macOS
  considera quell’interfaccia una tastiera, la apre a un’app solo dopo che le è stato consentito il monitoraggio
  input; fino ad allora l’app te lo segnala e ti propone di aprire “Privacy e sicurezza”.

## Compilazione

```sh
make build          # compila con Xcode (gli avvisi sono errori)
make package-test   # test del pacchetto – l’app non si avvia
make test           # test dell’app, ospitati dall’app stessa
make check          # fallisce se un ID team è finito nel file di progetto
```

Compilazione e test sono stati verificati con Xcode 27.2.

Le impostazioni di firma e di identità non si trovano nel repository. Prima di compilare per la prima volta,
copia l’esempio e inserisci il tuo ID team dell’Apple Developer Program, un nome per l’app e un tuo bundle ID.
Senza quel file la compilazione si ferma su `Unable to open base configuration reference file ... Signing.xcconfig`.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

Il nome dell’icona è facoltativo. Senza la grafica dell’icona, l’app riceve l’icona generica del sistema.

Anche gli aggiornamenti sono facoltativi. L’app include [Sparkle](https://sparkle-project.org) tramite Swift
Package Manager – Xcode lo scarica alla prima compilazione – ma cerca gli aggiornamenti solo se
`Signing.xcconfig` indica sia un feed (`BRAND_FEED_URL`) sia la sua chiave pubblica EdDSA
(`BRAND_FEED_PUBLIC_KEY`). Senza di essi, nell’app non compare da nessuna parte una voce per gli aggiornamenti.

Quando Xcode apre il progetto, sostituisce il nome del prodotto nello schema condiviso
(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) con il tuo. È normale; non serve farne il commit.

I test dell’app sono ospitati dall’app stessa. Mentre vengono eseguiti, l’app cerca la tastiera e vi si
collega come fa sempre. I test del pacchetto usano oggetti fittizi e tastiere simulate, e non aprono mai una
tastiera vera.

Il menu **Simulatore** permette di provare l’app senza la tastiera in questione: scegli una `1189:8890`, una
disposizione del firmware più recente oppure una tastiera che non indica il proprio tipo, e l’app si comporta come se
fosse collegata – con gli stessi comandi, senza che nulla passi per l’USB. Mentre è in uso, una barra arancione in cima
alla finestra lo segnala, e **Torna alla tastiera via USB** riporta indietro. Le build Debug offrono ogni tipo (gli altri
ID report della `1189:8890`, il firmware più vecchio). **Finestra ▸ Registro dispositivo** mostra ogni report scritto e
ogni risposta.

## Utilizzo

1. Collega la tastiera tramite USB. L’app la trova e, se è del secondo tipo, le chiede che tastiera è; se ha un
   firmware più recente, viene letta subito.
2. Per una tastiera che non indica la propria forma, la prima volta scegli la disposizione – una di quelle
   dell’app del produttore oppure, per la `1189:8890`, il numero di tasti, di tasti per riga e di manopole – e
   come è posizionata davanti a te. L’app ricorda entrambe le cose per quell’ID USB. In seguito le cambi con
   **Forma…** e **Ruota** (⌘T); una tastiera che ha indicato la propria forma si può solo ruotare.
3. Scegli un livello, poi il tasto o l’azione della manopola sulla tastiera.
4. Assegna un’azione:
   - **Tasti** – tieni premuti i modificatori (⌃ ⌥ ⇧ ⌘ e quelli a destra), poi fai clic sui tasti; ogni clic
     aggiunge una pressione. **Solo modificatori** trasforma il tasto in un tasto modificatore. **QWERTY**
     dispone i tasti come su una tastiera completa, **ABC** per gruppi; si può fare clic solo sui tasti che la
     tastiera accetta.
   - **Multimedia**, **Mouse** – sostituiscono ciò che faceva il tasto.
   - **LED** – l’illuminazione del livello; con il firmware più recente, seleziona uno dei tasti 1–16 per
     assegnargli un colore.
   - **Ritardo** – con i firmware che memorizzano le attese.
5. **Salva** (⌘S) scrive ciò che è cambiato. **Leggi** (⌘R) recupera le impostazioni attuali da una tastiera
   che consente di rileggerle.

Nelle **Impostazioni** (⌘,) scegli la lingua dell’interfaccia (una delle 13, oppure quella del sistema) e
l’aspetto chiaro o scuro; in Informazioni trovi la versione e le licenze open source. Con un feed degli
aggiornamenti (vedi sopra), **Cerca aggiornamenti…** si trova subito sotto Impostazioni… nel menu dell’app.

In **Impostazioni ▸ Generali ▸ Soluzioni per i bug del firmware**, **Evita la ripetizione dei tasti dopo aver
cambiato l’illuminazione** è attivo per impostazione predefinita. Dopo il salvataggio dell’illuminazione, il
firmware della `1189:8890` ripete all’infinito il primo carattere di un tasto (il software del produttore fa
lo stesso), quindi l’app invia un ulteriore comando di salvataggio, senza tasti, dopo l’illuminazione. Se lo
disattivi, l’app invia solo ciò che invia il software del produttore. Questa tastiera, inoltre, dimentica
l’illuminazione quando la scolleghi.

## Struttura

Le regole stanno in un pacchetto Swift locale, suddiviso in tre moduli le cui dipendenze puntano verso
l’interno: uno strato che cerca di raggiungere l’esterno non compila.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        tastiere, azioni, i controlli di ogni disposizione e ciò che ogni tastiera può contenere; i protocolli dei repository; casi d’uso (solo Foundation)
├── Sources/DataLayer/     i comandi di ogni tastiera e i numeri dei suoi controlli; trovare la tastiera e scrivere via USB (IOUSBHost) o HID (IOHIDDevice); tastiere simulate
├── Sources/Presentation/  view model e valori che le schermate disegnano – la geometria delle disposizioni, le tabelle di tasti e colori (Observation, niente SwiftUI)
└── Tests/                 Swift Testing – i byte di ogni comando, le disposizioni, le modifiche, l’editor
MINIKeyboard/
├── App/                   punto d’ingresso e menu dell’app, la composition root (l’unico file che vede Domain e DataLayer), aggiornamenti (Sparkle), licenze
├── Views/                 SwiftUI (importa solo Presentation) – la tastiera così com’è posizionata, le pagine delle azioni, il foglio della disposizione, il registro dispositivo; Settings/
├── Resources/Licenses/    licenze open source, mostrate in Impostazioni ▸ Informazioni
└── Localizable.xcstrings  en (testo originale), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    le chiavi Info.plist che Xcode non sa generare – il feed e la chiave di Sparkle, la riga del copyright
MINIKeyboardTests/         l’interruttore degli aggiornamenti, le licenze e il menu dell’app
```

Zero avvisi con Swift 6 è il requisito. Gli avvisi si correggono, non si disattivano.

## Limiti

- Finora la scrittura è stata provata su una sola tastiera, una `1189:8890` con sei tasti e una manopola – che
  si è rivelata avere un solo livello: su qualunque livello si scriva, finisce tutto nello stesso posto. Le altre
  tastiere vengono scritte come le scrive l’app del loro produttore; i test fissano i byte, ma nessuna è stata
  ancora provata su una tastiera reale.
- La `1189:8890` e le tastiere che non indicano il proprio tipo non possono riferire le loro impostazioni,
  quindi si vede solo ciò che è stato impostato nell’app.
- Una tastiera alla volta. Se ne sono collegate diverse, l’app prende la prima che trova – prima una
  `1189:8890`.
- Lo spostamento del mouse e il trascinamento non sono disponibili.
