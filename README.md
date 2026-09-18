# 🎴 GME — Compendio de Juegos Tradicionales

<p align="center">
  <img src="assets/cards/REV-CARD.png" width="120" alt="GME Card Back" />
</p>

<p align="center">
  <strong>GME</strong> es una aplicación multiplataforma moderna de alto rendimiento desarrollada en <strong>Flutter</strong> y <strong>Dart 3</strong> que rinde tributo a los juegos de mesa y naipes más representativos de la cultura hispana y venezolana: <strong>La Caída (con Baraja Española de 40 naipes)</strong> y el <strong>Dominó Tradicional (Doble 6)</strong>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.29+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.7+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Plataformas-Android%20%7C%20Windows%20%7C%20Web%20%7C%20macOS%20%7C%20Linux-4CAF50" alt="Platforms" />
  <img src="https://img.shields.io/badge/Tests-101%20Passed-brightgreen" alt="Tests" />
  <img src="https://img.shields.io/badge/Linter-0%20Issues-brightgreen" alt="Linter" />
  <img src="https://img.shields.io/badge/Licencia-Libre%20%2F%20Cultural-blue" alt="License" />
</p>

---

## 📑 Tabla de Contenidos

1. [Novedades y Actualizaciones Recientes](#-novedades-y-actualizaciones-recientes)
2. [Juegos y Dinámicas Incluidas](#-juegos-y-dinámicas-incluidas)
   - [1. La Caída Tradicional](#1-la-caída-tradicional-baraja-española-de-40-naipes)
   - [2. Dominó Tradicional (Doble 6)](#2-dominó-tradicional-doble-6)
3. [Economía, Niveles y Mesas VIP](#-economía-niveles-y-mesas-vip)
4. [Tutorial Interactivo (Tour de Novatos)](#-tutorial-interactivo-tour-de-novatos)
5. [Requisitos del Sistema](#-requisitos-del-sistema)
6. [Instalación y Configuración Paso a Paso](#-instalación-y-configuración-paso-a-paso)
7. [Modos de Ejecución y Compilación](#-modos-de-ejecución-y-compilación)
   - [Modo Web (Navegador)](#1-modo-web-google-chrome--edge)
   - [Modo Windows Desktop (.exe)](#2-modo-windows-desktop-ejecutable-nativo)
   - [Modo Android (APK y App Bundle)](#3-modo-dispositivos-android-apk--aab)
   - [Modo macOS / Linux / iOS](#4-otros-sistemas-macos-linux-e-ios)
8. [Pruebas Automatizadas y Calidad de Código](#-pruebas-automatizadas-y-calidad-de-código)
9. [Arquitectura del Proyecto](#-arquitectura-del-proyecto)
10. [Licencia](#-licencia)

---

## 🌟 Novedades y Actualizaciones Recientes

* 🎓 **Tutorial Interactivo Paso a Paso (Tour de Novatos)**:
  * Sistema guiado de 8 misiones consecutivas que enseñan desde la Caída elemental hasta el clímax de Trivilín.
  * Overlay de foco dinámico (`TutorialSpotlightOverlay`) con fondo oscurecido y halo pulsante sobre la carta o zona a interactuar.
  * Validación reactiva de jugadas: no permite descartes erróneos durante el entrenamiento.
  * Recompensa de graduación: **+1000 monedas** y activación de bandera persistente.
* 💰 **Sistema de Economía y Progresión Persistente**:
  * Gestión de saldo en **Monedas** y **Tickets Dorados**.
  * Curva de experiencia (XP) y niveles de jugador con desbloqueo de salas de mayor prestigio.
  * Reclamación de tickets gratuitos mediante anuncios simulados/videos patrocinados.
* 🏆 **Mesas y Salas VIP (1v1 y Parejas 2v2)**:
  * 4 niveles de competición: **Novato**, **Bronce**, **Plata** y **Oro**.
  * Cálculo dinámico de pozos acumulados y deducción de comisión de la casa (**8%**).
* 💾 **Persistencia Local Automática (`SharedPreferences`)**:
  * `UserProfileService`: conserva el nombre de usuario, nivel actual, experiencia y avatar seleccionado (entre más de 20 avatares temáticos).
  * `StatsRepository`: historial detallado de partidas jugadas, victorias, derrotas, tasa de éxito y cantos ejecutados.
  * `PlayerSession`: sincronización inmediata de finanzas, tickets y progreso tutorial.
* 🎵 **Sistema de Sonido y Feedback Háptico**:
  * Integración con `audioplayers` para efectos de cantos (Ronda, Patrulla, Vigía, Registro, Trivilín), caídas, victorias y derrotas.
  * Botón de silencio/desilencio reactivo en tiempo real en lobby y mesa de juego.
* 🎨 **Baraja Española Completa (40 naipes en alta definición)**:
  * Palos de **Oros**, **Copas**, **Espadas** y **Bastos** (1 al 7, Sota [S], Caballo [C] y Rey [R]).
  * Reverso oficial con textura clásica azul marino y orla dorada (`REV-CARD.png`).
  * Descarte orgánico en mesa con dispersión natural, inclinación aleatoria y zonas de aterrizaje anti-solapamiento.

---

## 🎮 Juegos y Dinámicas Incluidas

### 1. La Caída Tradicional (Baraja Española de 40 Naipes)
Fiel adaptación de las reglas oficiales y populares de La Caída venezolana, gobernada por un motor de reglas desacoplado (`CaidaRulesEngine`).

#### 🎴 Jerarquía de Cantos Polimórficos (`sealed class Canto`)
Al recibir las 3 cartas de cada mano, el sistema evalúa y canta automáticamente según la jerarquía reglamentaria:

| Canto | Combinación Requerida | Puntos | Prioridad |
| :--- | :--- | :---: | :---: |
| 🌟 **Trivilín** | 3 cartas del mismo valor nominal | **+24 pts** (Gana la partida) | 5 (Máxima) |
| 👁️ **Vigía** | 2 cartas iguales + 1 consecutiva | **+8 pts** | 4 |
| 🎖️ **Registro** | Exactamente As, Caballo y Rey (`[1, 11, 12]`) | **+12 pts** | 3 |
| 🛡️ **Patrulla** | 3 cartas en escalera consecutiva | **+4 pts** | 2 |
| 🎴 **Ronda** | 2 cartas del mismo número | **+2 a +5 pts** (`+2` de 1-7, `+3` Sota, `+4` Caballo, `+5` Rey) | 1 |

* **Resolución y cobro de cantos**: Los cantos se muestran al repartir la mano, pero se resuelven y cobran al agotarse las 3 cartas de cada jugador, aplicando la regla de jerarquía (sólo cobra el canto de mayor rango en la mesa) y proximidad a la Mano en caso de empate.

#### ⚔️ Mecánicas de Mesa
* **Canto de Mesa Inicial**: Al arrancar la primera mano con 4 cartas en el tapete, el repartidor canta en dirección **Ascendente** (1 a 4) o **Descendente** (4 a 1). Las coincidencias suman puntos inmediatos al repartidor; cartas repetidas o ausencia total de aciertos otorgan `+1` punto al rival.
* **Caída**: Responder inmediatamente a la carta del jugador previo con el mismo número otorga puntos según la figura (`+1` cartas 1-7, `+2` Sota, `+3` Caballo, `+4` Rey).
* **Arrastre y Seguidilla**: Al emparejar con una carta de la mesa, se captura dicha carta más todas las correlativas continuas presentes (`1..7, 10..12`).
* **Mesa Limpia**: Vaciar por completo la mesa otorga `+4` puntos (durante el mazo) o `+2` puntos (en la última mano).
* **Conteo por Volumen**: Al vaciar el mazo de 40 naipes, las cartas sobrantes van al último en recoger. Quien supere 20 cartas físicas suma `(Total Cartas - 20)` puntos extra.
* **Meta de Victoria**: 24 puntos oficiales.

---

### 2. Dominó Tradicional (Doble 6)
* 28 fichas completas desde la blanca doble `[0|0]` hasta el doble seis `[6|6]`.
* Modos para 2, 3 o 4 jugadores (individual o por parejas).
* Apertura oficial con la mula mayor (`[6|6]`).
* Algoritmo de detección de **Tranque** con sumatoria matemática automática de pintas para dictaminar el bando ganador.

---

## 💰 Economía, Niveles y Mesas VIP

El juego integra un bucle económico y de progresión competitivo:

| Nivel de Mesa VIP | Cuota de Entrada | Nivel Requerido | Pozo 1v1 (2 Jugadores) | Pozo Parejas (4 Jugadores) |
| :--- | :---: | :---: | :---: | :---: |
| 🟢 **Novato** | 100 🪙 | Nivel 1 | 184 🪙 *(92 c/u)* | 368 🪙 *(184 c/u)* |
| 🥉 **Bronce** | 500 🪙 | Nivel 3 | 920 🪙 *(460 c/u)* | 1,840 🪙 *(920 c/u)* |
| 🥈 **Plata** | 2,500 🪙 | Nivel 5 | 4,600 🪙 *(2,300 c/u)* | 9,200 🪙 *(4,600 c/u)* |
| 🥇 **Oro** | 10,000 🪙 | Nivel 10 | 18,400 🪙 *(9200 c/u)* | 36,800 🪙 *(18,400 c/u)* |

* *Nota*: Los pozos de premios ya descuentan el **8%** reglamentario de comisión de la casa.
* Las partidas tradicionales amistosas contra la máquina están siempre disponibles sin costo.

---

## 🎓 Tutorial Interactivo (Tour de Novatos)

El módulo `features/la_caida/tutorial` ofrece una escuela interactiva guiada para aprender a jugar La Caída:

1. **Etapa 1 - Caída Básica**: Conoce el concepto de tirar la misma carta que el rival inmediato y suma tu primer punto.
2. **Etapa 2 - Arrastre y Seguidilla**: Aprende a levantar cartas consecutivas en escalera de una sola jugada.
3. **Etapa 3 - Mesa Limpia**: Descubre el valor estratégico de dejar el tapete vacío (`+4` pts).
4. **Etapa 4 - Canto de Ronda**: Formación y cobro de una pareja de cartas iguales.
5. **Etapa 5 - Canto de Patrulla**: Formación de una seguidilla consecutiva de 3 cartas (`+4` pts).
6. **Etapa 6 - Canto de Vigía**: Par más carta consecutiva (`+8` pts).
7. **Etapa 7 - Canto de Registro**: Trío real sagrado As, Caballo y Rey (`+12` pts).
8. **Etapa 8 - Clímax de Trivilín**: 3 cartas idénticas para una victoria fulminante con premio de graduación (+1000 monedas).

---

## 🛠️ Requisitos del Sistema

Antes de comenzar, asegúrate de contar con el siguiente entorno:

* **Flutter SDK**: Versión `3.29.0` o superior (Canal `stable`).
* **Dart SDK**: Versión `3.7.0` o superior (incluido en Flutter).
* **Git**: Para clonar y gestionar el repositorio.
* **Herramientas según la plataforma**:
  * **Para Web**: Google Chrome, Mozilla Firefox o Microsoft Edge.
  * **Para Windows Desktop**: Visual Studio 2022 con la carga de trabajo *"Desarrollo para el escritorio con C++"*.
  * **Para Android**: Android Studio, Android SDK (API 21+) y Java JDK 17+.
  * **Para macOS / iOS**: Xcode 15+ y CocoaPods (en entornos Apple).

---

## 📥 Instalación y Configuración Paso a Paso

### Paso 1: Clonar el Repositorio
Abre tu terminal y clona el código fuente:
```bash
git clone https://github.com/eizy-c/GME.git
cd GME
```

### Paso 2: Verificar el Entorno Flutter
Verifica que las herramientas y dispositivos estén listos:
```bash
flutter doctor
```

### Paso 3: Descargar Paquetes y Dependencias
Descarga e indexa las dependencias del proyecto:
```bash
flutter pub get
```

---

## 🚀 Modos de Ejecución y Compilación

### 1. Modo Web (Google Chrome / Edge)
Ideal para probar el juego de forma instantánea sin configuraciones de compiladores nativos.

* **Ejecutar en desarrollo**:
  ```bash
  flutter run -d chrome
  ```
* **Compilar para producción (HTML/WASM/JS)**:
  ```bash
  flutter build web --release
  ```
  Los archivos generados se ubicarán en `build/web/`, listos para ser desplegados en Firebase Hosting, Vercel, Netlify o GitHub Pages.

---

### 2. Modo Windows Desktop (Ejecutable Nativo)
Permite correr la aplicación con máximo rendimiento acelerado por GPU en Windows.

* **Ejecutar en desarrollo**:
  ```bash
  flutter run -d windows
  ```
* **Compilar archivo ejecutable `.exe` para distribución**:
  ```bash
  flutter build windows --release
  ```
  El binario compilado y sus bibliotecas `.dll` se generarán en:
  `build/windows/x64/runner/Release/`

---

### 3. Modo Dispositivos Android (APK / AAB)
Permite instalar la aplicación en teléfonos, tablets o emuladores Android.

* **Ejecutar en dispositivo conectado o emulador**:
  ```bash
  flutter run -d <id_del_dispositivo>
  ```
  *(Puedes listar los dispositivos disponibles con `flutter devices`)*

* **Generar APK instalable universal**:
  ```bash
  flutter build apk --release
  ```
  El instalador resultante estará en:
  `build/app/outputs/flutter-apk/app-release.apk`

* **Generar APKs divididos por arquitectura (recomendado para menor peso)**:
  ```bash
  flutter build apk --split-per-abi --release
  ```

* **Generar App Bundle (AAB para Google Play Store)**:
  ```bash
  flutter build appbundle --release
  ```
  Ubicación: `build/app/outputs/bundle/release/app-release.aab`

---

### 4. Otros Sistemas (macOS, Linux e iOS)

* **macOS**:
  ```bash
  flutter run -d macos
  flutter build macos --release
  ```
* **Linux**:
  ```bash
  flutter run -d linux
  flutter build linux --release
  ```
* **iOS** *(Requiere macOS y Xcode)*:
  ```bash
  flutter run -d ios
  flutter build ipa --release
  ```

---

## 🧪 Pruebas Automatizadas y Calidad de Código

El proyecto se mantiene con altos estándares de ingeniería de software, contando con suites de pruebas unitarias, de integración y widgets que cubren cada regla de negocio y estado de la aplicación.

### Ejecutar las 101 Pruebas Unitarias y de Widgets
```bash
flutter test
```
*Resultado*: **101 tests pasando exitosamente (100% pass rate)**.

### Ejecutar Análisis Estático de Código (Linter)
```bash
flutter analyze
```
*Resultado*: **0 issues / 0 advertencias**.

---

## 📂 Arquitectura del Proyecto

El código está estructurado siguiendo los principios de **Clean Architecture** y organización modular por dominios de juego (*Feature-First*):

```text
GME/
├── assets/
│   ├── audio/                 # Efectos sonoros (cantos, victorias, caídas, etc.)
│   └── cards/                 # Naipes en alta definición
│       ├── REV-CARD.png       # Reverso oficial azul marino y dorado
│       ├── BASTON/            # Cartas de Bastos (B-1 a B-R)
│       ├── COPAS/             # Cartas de Copas (C-1 a C-R)
│       ├── ESPADAS/           # Cartas de Espadas (E-1 a E-R)
│       └── OROS/              # Cartas de Oros (O-1 a O-R)
├── lib/
│   ├── core/
│   │   ├── audio/             # AudioService y control de reproducción
│   │   ├── models/cards/      # SpanishCard, CardSuit, SpanishDeck
│   │   ├── presentation/      # SpanishCardView, widgets reutilizables
│   │   ├── rules/             # GameRulesData y glosario de jugadas
│   │   ├── services/          # UserProfileService (persistencia SharedPreferences)
│   │   ├── stats/             # StatsRepository y GameStats
│   │   └── theme/             # Colores, tipografías y estética de tapete
│   ├── features/
│   │   ├── compendium/        # Menú principal y navegación
│   │   ├── domino/            # Motor y pantalla de Dominó (Doble 6)
│   │   └── la_caida/
│   │       ├── domain/        # CaidaRulesEngine y Cantos POO (Trivilin, Vigia, etc.)
│   │       ├── economy/       # PlayerSession, VipTierOffer y finanzas
│   │       ├── presentation/  # CaidaScreen, CaidaLobbyScreen, modales y widgets de mesa
│   │       └── tutorial/      # TutorialEngine, TutorialStep y TutorialScreen
│   └── main.dart              # Punto de entrada y precarga asíncrona de servicios
└── test/                      # 101 pruebas unitarias, de reglas, persistencia y widgets
```

---

## 📜 Licencia

Desarrollado como una obra lúdica y cultural de libre distribución basada en las tradiciones populares hispanas e iberoamericanas. Las mecánicas tradicionales de Dominó y La Caída forman parte del patrimonio cultural de dominio público. Todos los recursos gráficos y de audio han sido creados o seleccionados bajo licencias libres de derechos comerciales.
