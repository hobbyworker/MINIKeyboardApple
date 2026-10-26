<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="Icône de l’app"></p>

<h1 align="center">Configurateur de claviers macro pour Mac</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <b>Français</b> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

Une app macOS qui écrit les réglages des touches sur de petits claviers macro USB – ceux que l’on trouve
dans le commerce, d’un seul bouton rotatif jusqu’à 21 touches, avec au plus quatre boutons rotatifs. Pour
chaque action d’une touche ou d’un bouton rotatif (rotation à gauche, appui, rotation à droite), elle définit
sur les couches 1 à 3 des frappes, une touche multimédia ou une action de la souris, ainsi que l’éclairage du
clavier.

<p align="center"><img src="../.github/devices.png" width="560" alt="Deux petits claviers de macros USB : six touches et un bouton rotatif, douze touches et deux boutons rotatifs"></p>

| Clavier | Disposition | Lecture | Délai | Éclairage | Testé |
|---|---|---|---|---|---|
| `1189:8890` | définie par vous – touches (jusqu’à 12), touches par rangée, boutons rotatifs (jusqu’à 2) | non | aucun | trois modes | oui – 6 touches et un bouton rotatif |
| fabricant `1189` ou `514C`, produit `8840` · `8842` · `8830`–`8833` · `8850` (et `514C:8851`), programme interne récent | selon ce qu’indique le clavier – 26 dispositions | dès la connexion | avant chaque frappe | un mode, et une couleur pour chacune des touches 1–16 | non |
| les mêmes, ancien programme interne | selon ce qu’indique le clavier | à la demande | un par touche | une couleur et un mode | non |
| les mêmes, sans indiquer leur type | choisie par vous – 26 dispositions | non | aucun | une couleur et un mode | non |

Le `1189:8890` est le clavier que prend en charge l’outil Windows du fabricant, « MINI KeyBoard » ; les
autres sont ceux que recherche l’app multiplateforme du fabricant, « MINI_KEYBOARD ». L’app utilise les
commandes des deux outils. La plupart des claviers du second type indiquent combien de touches et de boutons
rotatifs ils possèdent et quel programme interne ils exécutent : l’app dessine alors la disposition que
dessinerait l’app du fabricant. Un clavier qui ne l’indique pas reçoit celle de ces dispositions que vous
choisissez. L’app du fabricant ne connaît pas le `1189:8890` et son propre outil ne dessine aucune forme, si
bien que sa forme réelle est inconnue : vous indiquez à l’app combien de touches et de boutons rotatifs il
possède et combien de touches compte une rangée, et elle en dessine une disposition bien ordonnée.

L’app est disponible en 13 langues – anglais, coréen, japonais, chinois (simplifié et traditionnel), allemand,
espagnol, français, italien, portugais (Brésil), polonais, indonésien et vietnamien – et suit les réglages de
langue de macOS. Dans les autres langues, elle s’affiche en anglais.

Le code source de ce dépôt est sous licence MIT. Certaines parties de l’app distribuée ne font pas partie de ce
code source : son nom et son icône. L’icône en haut de la page n’est présentée qu’à titre d’illustration : elle
n’est pas couverte par la licence MIT et n’est pas incluse dans les compilations issues de ce dépôt.

## macOS, Windows et Linux

MINIKeyboard existe en trois éditions construites sur les mêmes règles – les mêmes claviers, les mêmes commandes, les mêmes 13 langues.

| Dépôt | GitHub |
|---|---|
| **MINIKeyboardApple**<br><img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white"> <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6"> <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardApple](https://github.com/hobbyworker/MINIKeyboardApple) |
| **MINIKeyboardWin**<br><img alt="Windows 10 (2004)+ · 11" src="https://img.shields.io/badge/Windows-10%20(2004)%2B%20·%2011-0078D4?logo=windows&logoColor=white"> <img alt="x64 · ARM64" src="https://img.shields.io/badge/x64%20·%20ARM64-5E5CE6"> <img alt=".NET 10 · WinUI 3" src="https://img.shields.io/badge/.NET%2010-WinUI%203-512BD4?logo=dotnet&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardWin](https://github.com/hobbyworker/MINIKeyboardWin) |
| **MINIKeyboardLinux**<br><img alt="Linux" src="https://img.shields.io/badge/Linux-GTK%204%20·%20libadwaita-4A86CF?logo=linux&logoColor=white"> <img alt="Flatpak: x86_64 · aarch64" src="https://img.shields.io/badge/Flatpak-x86__64%20·%20aarch64-4A90D9?logo=flatpak&logoColor=white"> <img alt="Rust" src="https://img.shields.io/badge/Rust-2024-B7410E?logo=rust&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardLinux](https://github.com/hobbyworker/MINIKeyboardLinux) |

## Téléchargement

L’app signée et notariée se trouve sur la page [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases) :
ouvrez `MINIKeyboard-<version>.dmg` et faites glisser MINIKeyboard dans le dossier Applications. L’app recherche
elle-même les mises à jour (Réglages ▸ Général) – vous pouvez aussi choisir **Rechercher les mises à jour…**
dans le menu de l’app.

## Configuration requise

- macOS 14.0 (Sonoma) ou version ultérieure
- Le `1189:8890` ne nécessite aucune autorisation : l’app écrit directement sur son interface de configuration
  via USB et ne lit jamais ce que vous tapez.
- Les autres claviers se configurent par leur première interface USB, comme le fait l’app du fabricant. Lorsque
  macOS considère cette interface comme un clavier, il ne l’ouvre à une app qu’une fois la surveillance de
  l’entrée autorisée pour celle-ci ; d’ici là, l’app vous le signale et propose d’ouvrir « Confidentialité et
  sécurité ».

## Compilation

```sh
make build          # compile avec Xcode (les avertissements sont des erreurs)
make package-test   # tests du paquet – l’app ne se lance pas
make test           # tests de l’app, hébergés par l’app
make check          # échoue si un identifiant d’équipe s’est glissé dans le fichier de projet
```

La compilation et les tests ont été vérifiés avec Xcode 27.2.

Les réglages de signature et d’identité ne figurent pas dans le dépôt. Avant votre première compilation, copiez
l’exemple et renseignez votre identifiant d’équipe Apple Developer, un nom pour l’app et votre propre
identifiant de bundle. Sans ce fichier, la compilation s’arrête sur `Unable to open base configuration reference file ... Signing.xcconfig`.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

Le nom de l’icône est facultatif. Sans illustration d’icône, l’app reçoit l’icône générique du système.

Les mises à jour sont elles aussi facultatives. L’app intègre [Sparkle](https://sparkle-project.org) via Swift
Package Manager – Xcode le récupère lors de la première compilation –, mais ne recherche les mises à jour que si
`Signing.xcconfig` indique à la fois un flux (`BRAND_FEED_URL`) et sa clé publique EdDSA
(`BRAND_FEED_PUBLIC_KEY`). Sans eux, l’app n’affiche nulle part d’élément de mise à jour.

Quand Xcode ouvre le projet, il remplace le nom du produit dans le schéma partagé
(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) par le vôtre. C’est normal ; inutile de committer ce
changement.

Les tests de l’app sont hébergés par l’app elle-même. Pendant leur exécution, l’app recherche le clavier et s’y
connecte comme d’habitude. Les tests du paquet utilisent des doublures et des claviers simulés, et n’ouvrent
jamais de vrai clavier.

Le menu **Simulateur** permet d’essayer l’app sans le clavier concerné : choisissez un `1189:8890`, une disposition du
programme interne récent ou un clavier qui n’indique pas son type, et l’app se comporte comme s’il était branché – avec
les mêmes commandes, sans que rien ne parte vers l’USB. Tant qu’il est utilisé, une barre orange en haut de la fenêtre le
signale, et **Revenir au clavier en USB** permet de revenir. Les compilations Debug proposent tous les types (les autres
ID de rapport du `1189:8890`, l’ancien programme interne). **Fenêtre ▸ Journal de l’appareil** affiche chaque rapport
écrit et chaque réponse.

## Utilisation

1. Branchez le clavier en USB. L’app le trouve et, s’il est du second type, lui demande ce qu’il est ; s’il a un
   programme interne récent, il est lu aussitôt.
2. Pour un clavier qui n’indique pas sa forme, vous choisissez la première fois sa disposition – l’une des
   dispositions de l’app du fabricant ou, pour le `1189:8890`, le nombre de touches, de touches par rangée et de
   boutons rotatifs – et son orientation devant vous. L’app retient les deux pour cet ID USB. **Forme…** et
   **Faire pivoter** (⌘T) permettent de les modifier par la suite ; un clavier qui a indiqué sa forme peut
   seulement pivoter.
3. Choisissez une couche, puis la touche ou l’action du bouton rotatif sur le clavier.
4. Attribuez-lui une action :
   - **Touches** – maintenez des touches de modification (⌃ ⌥ ⇧ ⌘, et celles de droite), puis cliquez sur des
     touches ; chaque clic ajoute une frappe. **Modificateurs seuls** fait de la touche une touche de
     modification. **QWERTY** dispose les touches comme sur un clavier complet, **ABC** par groupes ; seules les
     touches que le clavier accepte peuvent être cliquées.
   - **Multimédia**, **Souris** – remplacent ce que faisait la touche.
   - **LED** – l’éclairage de la couche ; avec un programme interne récent, sélectionnez l’une des touches 1–16
     pour lui donner une couleur.
   - **Délai** – avec un programme interne qui conserve les attentes.
5. **Enregistrer** (⌘S) écrit ce qui a changé. **Lire** (⌘R) récupère les réglages actuels d’un clavier qui
   permet de les relire.

Dans les **Réglages** (⌘,), vous choisissez la langue de l’interface (l’une des 13, ou celle du système) et
l’apparence claire ou sombre ; la section À propos affiche la version et les licences open source. Avec un flux
de mises à jour (voir plus haut), **Rechercher les mises à jour…** se trouve juste sous Réglages… dans le menu
de l’app.

Dans **Réglages ▸ Général ▸ Contournements des bogues du firmware**, **Empêcher la répétition des touches
après un changement d’éclairage** est activé par défaut. Après l’enregistrement de l’éclairage, le firmware du
`1189:8890` répète sans fin le premier caractère d’une touche (le logiciel du fabricant fait de même) ; l’app
envoie donc une commande d’enregistrement supplémentaire, sans touche, après l’éclairage. Désactivé, l’app
envoie uniquement ce qu’envoie le logiciel du fabricant. Ce clavier oublie aussi son éclairage quand on le
débranche.

## Structure

Les règles se trouvent dans un paquet Swift local, réparties en trois modules dont les dépendances pointent
vers l’intérieur – une couche qui cherche à atteindre l’extérieur ne compile pas.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        claviers, actions, les contrôles de chaque disposition et ce que chaque clavier peut contenir ; les protocoles de dépôt ; cas d’utilisation (Foundation uniquement)
├── Sources/DataLayer/     les commandes de chaque clavier et les numéros de ses contrôles ; trouver le clavier et écrire via USB (IOUSBHost) ou HID (IOHIDDevice) ; claviers simulés
├── Sources/Presentation/  modèles de vue et valeurs que dessinent les écrans – la géométrie des dispositions, les tables de touches et de couleurs (Observation, sans SwiftUI)
└── Tests/                 Swift Testing – les octets de chaque commande, les dispositions, les modifications, l’éditeur
MINIKeyboard/
├── App/                   point d’entrée et menus de l’app, la racine de composition (le seul fichier qui voit Domain et DataLayer), mises à jour (Sparkle), licences
├── Views/                 SwiftUI (n’importe que Presentation) – le clavier tel qu’il est posé, les pages d’action, la feuille de disposition, le journal de l’appareil ; Settings/
├── Resources/Licenses/    licences open source, affichées dans Réglages ▸ À propos
└── Localizable.xcstrings  en (source), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    les clés Info.plist que Xcode ne peut pas générer – le flux et la clé de Sparkle, la ligne de copyright
MINIKeyboardTests/         l’interrupteur des mises à jour, les licences et le menu de l’app
```

Zéro avertissement avec Swift 6 : c’est la règle. Les avertissements sont corrigés, pas désactivés.

## Limites

- L’écriture n’a été essayée jusqu’ici que sur un seul clavier, un `1189:8890` à six touches et un bouton
  rotatif – qui s’est révélé n’avoir qu’une seule couche : quelle que soit la couche où l’on écrit, tout arrive
  au même endroit. Les autres claviers sont écrits comme l’app de leur fabricant les écrit ; des tests figent les
  octets, mais aucun n’a encore été essayé sur un vrai clavier.
- Le `1189:8890` et les claviers qui n’indiquent pas leur type ne peuvent pas communiquer leurs réglages ;
  seuls ceux définis dans l’app sont donc affichés.
- Un seul clavier à la fois. Si plusieurs sont branchés, l’app prend le premier qu’elle trouve – un `1189:8890`
  en priorité.
- Le déplacement de la souris et le glissement ne sont pas proposés.
