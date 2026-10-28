<p align="center"><img src="../.github/icon.png" width="128" height="128" alt="Icono de la app"></p>

<h1 align="center">Configurador de teclados de macros para Mac</h1>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white">
  <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
  <a href="../LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"></a>
</p>

<p align="center"><a href="../README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.de.md">Deutsch</a> · <b>Español</b> · <a href="README.fr.md">Français</a> · <a href="README.id.md">Bahasa Indonesia</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.pl.md">Polski</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.vi.md">Tiếng Việt</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

Una app para macOS que escribe la configuración de las teclas en pequeños teclados de macros USB. Se venden en
muchos tamaños: desde los que solo tienen un botón giratorio hasta los de 21 teclas, con hasta cuatro botones
giratorios. Para cada tecla y cada acción de un botón giratorio (girar a la izquierda, pulsar, girar a la derecha),
define en las capas 1–3 pulsaciones de teclas, una tecla multimedia o una acción del ratón, y también la
iluminación del teclado.

<p align="center"><img src="../.github/devices.png" width="560" alt="Dos pequeños teclados de macros USB: seis teclas y un botón giratorio, doce teclas y dos botones giratorios"></p>

| Teclado | Disposición | Lectura | Demora | Iluminación | Probado |
|---|---|---|---|---|---|
| `1189:8890` | la defines tú — teclas (hasta 12), teclas por fila, botones giratorios (hasta 2) | no | no | tres modos | sí — 6 teclas y un botón giratorio |
| fabricante `1189` o `514C`, producto `8840` · `8842` · `8830`–`8833` · `8850` · `8851`, firmware nuevo | según lo que indica el teclado — 26 disposiciones | al conectarlo | antes de cada pulsación | un modo y un color para cada una de las teclas 1–16 | sí — `514C:8850`, 12 teclas y 2 botones giratorios |
| los mismos, firmware antiguo | según lo que indica el teclado | al conectarlo | una por tecla | un color y un modo | no |
| los mismos, sin indicar su tipo | la eliges tú — 26 disposiciones | no | no | un color y un modo | no |

El `1189:8890` es el teclado con el que trabaja la herramienta de configuración para Windows del fabricante,
“MINI KeyBoard”; los demás son los que busca la app multiplataforma del fabricante, “MINI_KEYBOARD”. La app usa los
comandos de ambas herramientas. La mayoría de los teclados del segundo tipo indican cuántas teclas y botones
giratorios tienen y qué firmware usan, así que la app dibuja la misma disposición que dibujaría la app del
fabricante; si un teclado no lo indica, usa la que elijas entre esas disposiciones. La app del fabricante no conoce
el `1189:8890` y su propia herramienta no dibuja ninguna forma, así que no se sabe cuál es su forma real. Por eso,
tú indicas cuántas teclas y botones giratorios tiene y cuántas teclas hay en cada fila, y la app los dibuja tal
cual, bien ordenados.

La app está disponible en 13 idiomas: inglés, coreano, japonés, chino (simplificado y tradicional), alemán, español,
francés, italiano, portugués (Brasil), polaco, indonesio y vietnamita. Sigue la configuración de idioma de macOS; en
cualquier otro idioma, aparece en inglés.

El código fuente de este repositorio tiene licencia MIT. Algunas partes de la app que se distribuye —su nombre y su
icono— no están incluidas en este código. El icono de arriba se muestra solo como referencia: no está cubierto por
la licencia MIT y la app que compiles desde este repositorio no lo incluye.

## macOS, Windows y Linux

MINIKeyboard tiene tres ediciones hechas con las mismas reglas: los mismos teclados, los mismos comandos y los mismos 13 idiomas.

| Repositorio | GitHub |
|---|---|
| **MINIKeyboardApple**<br><img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple&logoColor=white"> <img alt="Universal: Apple Silicon + Intel" src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-5E5CE6"> <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardApple](https://github.com/hobbyworker/MINIKeyboardApple) |
| **MINIKeyboardWin**<br><img alt="Windows 10 (2004)+ · 11" src="https://img.shields.io/badge/Windows-10%20(2004)%2B%20·%2011-0078D4?logo=windows&logoColor=white"> <img alt="x64 · ARM64" src="https://img.shields.io/badge/x64%20·%20ARM64-5E5CE6"> <img alt=".NET 10 · WinUI 3" src="https://img.shields.io/badge/.NET%2010-WinUI%203-512BD4?logo=dotnet&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardWin](https://github.com/hobbyworker/MINIKeyboardWin) |
| **MINIKeyboardLinux**<br><img alt="Linux" src="https://img.shields.io/badge/Linux-GTK%204%20·%20libadwaita-4A86CF?logo=linux&logoColor=white"> <img alt="Flatpak: x86_64 · aarch64" src="https://img.shields.io/badge/Flatpak-x86__64%20·%20aarch64-4A90D9?logo=flatpak&logoColor=white"> <img alt="Rust" src="https://img.shields.io/badge/Rust-2024-B7410E?logo=rust&logoColor=white"> <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow"> | [github.com/hobbyworker/MINIKeyboardLinux](https://github.com/hobbyworker/MINIKeyboardLinux) |

## Descarga

La app firmada y notarizada está en [Releases](https://github.com/hobbyworker/MINIKeyboardApple/releases).
Abre `MINIKeyboard-<versión>.dmg` y arrastra MINIKeyboard a la carpeta Aplicaciones. La app busca actualizaciones
por sí sola (Ajustes ▸ General), y también puedes buscarlas tú con **Buscar actualizaciones…** en el menú de la app.

## Requisitos

- macOS 14.0 (Sonoma) o posterior
- El `1189:8890` no necesita ningún permiso: la app escribe directamente por USB en su interfaz de configuración y
  nunca lee lo que tecleas.
- Los demás teclados se configuran a través de su primera interfaz USB, como hace la app del fabricante. Si macOS
  considera esa interfaz un teclado, solo la abre a las apps que tienen permiso de Monitorización de los
  dispositivos de entrada. Hasta que se concede, la app te lo indica y te ofrece abrir Privacidad y seguridad.

## Compilación

```sh
make build          # compila con Xcode (las advertencias son errores)
make package-test   # pruebas del paquete — la app no se abre
make test           # pruebas de la app — la propia app aloja las pruebas
make check          # falla si se ha colado un ID de equipo en el archivo del proyecto
```

La compilación y las pruebas se han comprobado con Xcode 27.2.

Los ajustes de firma e identidad no están en el repositorio. Antes de compilar por primera vez, copia el ejemplo y
rellena tu ID de equipo de Apple Developer, un nombre para la app y tu propio ID de paquete. Sin ese archivo, la
compilación se detiene en `Unable to open base configuration reference file ... Signing.xcconfig`.

```sh
cp Signing.xcconfig.example Signing.xcconfig
```

El nombre del icono es opcional. Sin la imagen del icono, la app se compila con el icono genérico del sistema.

Las actualizaciones también son opcionales. La app enlaza [Sparkle](https://sparkle-project.org) mediante Swift
Package Manager —Xcode lo descarga en la primera compilación—, pero solo busca actualizaciones si
`Signing.xcconfig` indica tanto un feed (`BRAND_FEED_URL`) como su clave pública EdDSA (`BRAND_FEED_PUBLIC_KEY`).
Sin ellos, la opción de actualizar no aparece en ningún sitio.

Cuando Xcode abre el proyecto, cambia el nombre del producto dentro del esquema compartido
(`MINIKeyboard.xcodeproj/xcshareddata/xcschemes/`) por el tuyo. Es lo esperado y no hace falta incluirlo en ningún
commit.

Las pruebas de la app se ejecutan dentro de la propia app. Durante las pruebas, la app busca el teclado y se
conecta a él como siempre. Las pruebas del paquete usan objetos falsos y teclados simulados, y nunca abren un
teclado.

El menú **Simulador** permite probar la app sin el teclado en cuestión: elige un `1189:8890`, una disposición del
firmware más reciente o un teclado que no indique su tipo, y la app actúa como si estuviera conectado, con los mismos
comandos y sin enviar nada por USB. Mientras se usa, una barra naranja en la parte superior de la ventana lo indica, y
**Volver al teclado por USB** vuelve atrás. Las compilaciones Debug ofrecen todos los tipos (los otros ID de informe del
`1189:8890` y el firmware antiguo). **Ventana ▸ Registro del dispositivo** muestra todos los informes escritos y todas las
respuestas.

## Uso

1. Conecta el teclado por USB. La app lo encuentra y, si es del segundo tipo, le pregunta qué teclado es; si
   responde, lo lee enseguida.
2. Si un teclado no indica su forma, la primera vez eliges su disposición —una de las de la app del fabricante o,
   para el `1189:8890`, el número de teclas, de teclas por fila y de botones giratorios— y cómo está colocado delante
   de ti. La app recuerda ambas cosas para ese ID USB. Más adelante puedes cambiarlas con **Forma…** y **Girar**
   (⌘T). Un teclado que indica su forma solo se puede girar.
3. Elige una capa y, en el dibujo del teclado, una tecla o una acción de un botón giratorio.
4. Asígnale una acción:
   - **Teclas** — mantén pulsadas las teclas de modificación (⌃ ⌥ ⇧ ⌘ y las de la derecha) y haz clic en las
     teclas; cada clic añade una pulsación. **Solo modificadores** convierte la tecla en una tecla de modificación.
     **QWERTY** coloca las teclas como en un teclado completo y **ABC**, por grupos. Solo puedes hacer clic en las
     teclas que admite el teclado.
   - **Multimedia**, **Ratón** — sustituyen lo que hacía la tecla.
   - **LED** — la iluminación de la capa. En el firmware nuevo, elige una de las teclas 1–16 para darle un color.
   - **Demora** — en el firmware que guarda las demoras.
5. **Guardar** (⌘S) escribe lo que ha cambiado. **Leer** (⌘R) trae la configuración actual de los teclados que
   permiten leerla.

En **Ajustes** (⌘,) eliges el idioma de la interfaz (uno de los 13 o el del sistema) y el modo claro u oscuro, y en
Acerca de ves la versión y las licencias de código abierto. Si hay un feed de actualizaciones (ver arriba),
**Buscar actualizaciones…** aparece justo debajo de Ajustes… en el menú de la app.

En **Ajustes ▸ General ▸ Soluciones para fallos del firmware**, **Evitar la repetición de teclas tras cambiar
la iluminación** está activado de forma predeterminada. El firmware del `1189:8890` repite sin parar el primer
carácter de una tecla después de guardar la iluminación (el software del fabricante hace lo mismo), así que la
app envía una orden de guardado más, sin ninguna tecla, después de la iluminación. Si lo desactivas, la app
envía solo lo mismo que el software del fabricante. Además, este teclado olvida su iluminación al
desconectarlo.

## Estructura

Las reglas están en un paquete Swift local, dividido en tres módulos cuyas dependencias apuntan solo hacia dentro:
una capa que intente alcanzar algo de fuera no compila.

```
Packages/MINIKeyboardKit/
├── Sources/Domain/        teclados, acciones, los controles de cada disposición y lo que admite cada teclado; protocolos de repositorio; casos de uso (solo Foundation)
├── Sources/DataLayer/     los comandos de cada teclado y la numeración de sus controles; búsqueda del teclado y escritura por USB (IOUSBHost) o HID (IOHIDDevice); teclados simulados
├── Sources/Presentation/  modelos de vista y los valores que dibujan las pantallas — la geometría de las disposiciones, tablas de teclas y colores (Observation, sin SwiftUI)
└── Tests/                 Swift Testing — los bytes de cada comando, las disposiciones, las ediciones, el editor
MINIKeyboard/
├── App/                   punto de entrada y menús de la app, la raíz de composición (composition root, el único archivo que ve Domain y DataLayer), actualizaciones (Sparkle), licencias
├── Views/                 SwiftUI (solo importa Presentation) — el teclado tal como está colocado, las páginas de acciones, la hoja de disposición, el registro del dispositivo; Settings/
├── Resources/Licenses/    licencias de código abierto, que se muestran en Ajustes ▸ Acerca de
└── Localizable.xcstrings  en (original), de, es, fr, id, it, ja, ko, pl, pt-BR, vi, zh-Hans, zh-Hant
MINIKeyboard-Info.plist    las claves de Info.plist que Xcode no puede generar — el feed y la clave de Sparkle, la línea de copyright
MINIKeyboardTests/         el interruptor de actualizaciones, las licencias y el menú de la app
```

El objetivo es cero advertencias con Swift 6. Las advertencias se corrigen, no se desactivan.

## Limitaciones

- Hasta ahora, la escritura solo se ha probado en un teclado: un `1189:8890` con seis teclas y un botón giratorio,
  que resultó tener una sola capa, así que lo que se escribe en cualquier capa va al mismo sitio. Los demás teclados
  se escriben tal como lo hace la app de su fabricante; las pruebas fijan los bytes, pero todavía no se ha
  comprobado ninguno con un teclado real.
- El `1189:8890` y los teclados que no indican su tipo no pueden informar de su configuración, así que la app solo
  muestra lo que se ha definido en ella.
- Un teclado cada vez. Si hay varios conectados, la app usa el primero que encuentra, empezando por un `1189:8890`.
- No hay acciones para mover el ratón ni para arrastrar.
