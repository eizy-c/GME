# GME — Compendio de Juegos Tradicionales

**GME** es una aplicación multiplataforma moderna desarrollada en **Flutter** que rinde homenaje a los juegos de mesa y cartas tradicionales más representativos de la cultura hispana y venezolana: el **Dominó Tradicional (Doble 6)** y **La Caída (con Baraja Española de 40 naipes)**.

El proyecto está diseñado bajo principios de **arquitectura limpia**, **Programación Orientada a Objetos (POO / Sealed Classes en Dart 3)**, motores de reglas puros desacoplados de la interfaz gráfica y una experiencia visual de alta fidelidad con efectos táctiles, animaciones y sonido.

---

## 🎮 Juegos Incluidos

### 1. La Caída Tradicional (Baraja Española)
Simulación completa del clásico juego venezolano con baraja española de 40 cartas (palos de Oros, Copas, Espadas y Bastos; sin 8s ni 9s: 1 al 7, Sota [10], Caballo [11] y Rey [12]).

#### Características y Reglas Oficiales:
* **Reparto Inicial y Canto de Mesa**:
  * En la primera mano del mazo, se colocan 4 cartas abiertas sin números repetidos sobre el tapete.
  * El repartidor elige la dirección del canto: **Ascendente (1 → 2 → 3 → 4)** o **Descendente (4 → 3 → 2 → 1)**.
  * Si el valor nominal de la carta coincide con el número cantado, el repartidor suma inmediatamente el valor exacto de esa carta (`+1` a `+4` pts).
  * Si al repartir sale un número repetido respecto a las presentes, se descarta y otorga `+1` punto al rival.
  * Si tras las 4 cartas no hubo ningún acierto, el rival suma `+1` punto.
* **Modelado POO de Cantos (`sealed class Canto`)**:
  * 🌟 **¡Trivilín!** (`TrivilinCanto`): 3 cartas del mismo número en mano → **+24 pts** (Prioridad 5, partida completa).
  * 🎖️ **¡Registro!** (`RegistroCanto`): Exactamente As, Caballo y Rey `[1, 11, 12]` → **+12 pts** (Prioridad 3, media partida).
  * 👁️ **¡Vigía!** (`VigiaCanto`): Par de cartas iguales + 1 consecutiva → **+8 pts** (Prioridad 4).
  * 🛡️ **¡Patrulla!** (`PatrullaCanto`): 3 cartas consecutivas en escalera → **+4 pts** (Prioridad 2).
  * 🎴 **¡Ronda!** (`RondaCanto`): Par de cartas del mismo número → **+2 pts base** (1 al 7: `+2` pts; Sota 10: `+3` pts; Caballo 11: `+4` pts; Rey 12: `+5` pts, Prioridad 1).
  * **Resolución de Conflictos**: Si rivales tienen cantos simultáneos, solo cobra el bando con mayor jerarquía mediante comparación polimórfica (`compareTo`); en caso de empate nominal, prevalece quien esté más cerca de la Mano.
* **Mecánica de Juego y Capturas**:
  * **Coincidencia Simple y Arrastre**: Al jugar una carta que coincida con una de la mesa, se captura esa carta y todas las consecutivas presentes en seguidilla correlativa (`1..7, 10..12`).
  * **¡Caída!**: Si juegas el mismo número de la carta que acaba de tirar el jugador anterior, cantas Caída y sumas puntos según la figura (`+1` cartas 1-7, `+2` Sota, `+3` Caballo, `+4` Rey).
  * **¡Mesa Limpia!**: Si al capturar dejas la mesa vacía, sumas `+4` puntos con mazo activo o `+2` puntos en la última mano.
* **Conteo por Volumen y Cierre**:
  * Al agotarse el mazo de 40 naipes, las cartas sobrantes en mesa se adjudican al último jugador que realizó una captura.
  * Bono por cartas físicas: Quien supere las 20 cartas recogidas suma `(Total Cartas - 20)` puntos extra.
  * La partida finaliza oficialmente al alcanzar o superar los **24 puntos**.
* **Visuales y Mesa de Juego**:
  * Mazo físico 3D apilado en la mesa (`DeckStackView`) con contador en tiempo real decreciente y el arte oficial de reverso en azul marino y orla dorada (`assets/cards/REV-CARD.png`).
  * Pila de cartas capturadas por jugador (`CapturedPileView`) con resplandor dorado al superar la marca de 20 cartas.
  * Modos: 1 bot (Mano a Mano), 2 bots (3 jugadores), 3 bots (4 jugadores individual o en parejas), selección interactiva de cartas y descarte fluido.

---

### 2. Dominó Tradicional (Doble 6)
El juego de estrategia y conexión por excelencia:
* 28 fichas completas (desde el `[0|0]` hasta el `[6|6]`).
* Modos para 2, 3 o 4 jugadores (individual o en parejas).
* Apertura oficial con el Doble Seis en la primera ronda.
* Detección matemática de "Tranque" / cierre de partida con conteo automático de pintas restantes para definir al ganador de la mano.

---

## 🛠️ Requisitos Previos

Asegúrate de tener instaladas las siguientes herramientas en tu sistema:

1. **Flutter SDK**: Versión `3.29.0` o superior (compatible con **Dart 3.7+**).
   * Comprueba tu instalación con:
     ```bash
     flutter doctor
     ```
2. **Git**: Para clonar y mantener sincronizado el repositorio.
3. **Plataforma de destino**:
   * **Google Chrome / Edge** (para correr en Web).
   * **Visual Studio / Windows Desktop development with C++** (para correr en Windows).
   * **Android Studio & SDK** (para compilar y probar en Android).

---

## 🚀 Instalación y Ejecución

Sigue estos sencillos pasos para poner la aplicación en marcha localmente:

### 1. Clonar el Repositorio
```bash
git clone https://github.com/eizy-c/GME.git
cd GME
```

### 2. Instalar Dependencias
Descarga todos los paquetes y assets requeridos:
```bash
flutter pub get
```

### 3. Ejecutar la Aplicación

#### En Navegador Web (Recomendado para pruebas rápidas):
```bash
flutter run -d chrome
```

#### En Windows Desktop:
```bash
flutter run -d windows
```

#### En Dispositivo o Emulador Android:
```bash
flutter run -d <nombre_del_dispositivo>
```

---

## 🧪 Pruebas Automatizadas y Análisis de Código

El proyecto cuenta con una sólida suite de pruebas unitarias y de widgets que garantizan que todas las reglas oficiales, cantos y dinámicas se cumplan con exactitud matemática.

### Ejecutar todas las pruebas (50 pruebas pasando):
```bash
flutter test
```

### Ejecutar análisis estático (0 advertencias):
```bash
flutter analyze
```

---

## 📂 Arquitectura y Estructura del Código

```text
lib/
├── core/
│   ├── models/cards/           # Modelos de naipe español (SpanishCard, CardSuit, SpanishDeck)
│   ├── presentation/widgets/   # SpanishCardView con renderizado frontal y reverso REV-CARD.png
│   ├── rules/                  # GameRulesData (descripción oficial y tutoriales)
│   └── theme/                  # Paleta de colores, gradientes y tipografías
├── features/
│   ├── compendium/             # Menú principal y navegación entre Dominó y La Caída
│   ├── domino/                 # Motor y pantalla del juego de Dominó (Doble 6)
│   └── la_caida/
│       ├── domain/
│       │   ├── caida_models.dart        # Canto POO (Trivilin, Vigia, Registro, Patrulla, Ronda)
│       │   └── caida_rules_engine.dart  # Motor de reglas puro: Canto de Mesa, Caídas, Limpias, Volumen
│       └── presentation/
│           ├── caida_screen.dart        # Mesa de juego interactiva, animaciones y lobby
│           └── widgets/                 # DeckStackView (mazo 3D), CapturedPileView, TableCantoDialog
assets/
└── cards/
    ├── REV-CARD.png                     # Reverso oficial de cartas en azul marino con orla dorada
    ├── BASTON/                          # Figuras y números del palo de Bastos
    ├── COPAS/                           # Figuras y números del palo de Copas
    ├── ESPADAS/                         # Figuras y números del palo de Espadas
    └── OROS/                            # Figuras y números del palo de Oros
test/
├── caida_rules_engine_test.dart         # Pruebas unitarias completas del motor oficial
├── caida_scoring_test.dart              # Pruebas de selección individual y puntuación
└── widget_test.dart                     # Pruebas de renderizado de mesa y compendio
```

---

## 📜 Licencia y Respeto a Marcas

Este software ha sido desarrollado como una implementación libre y tradicional de juegos culturales de dominio público (Dominó y La Caída). Todos los assets incluidos son propios o libres de derechos de autor de terceros.
