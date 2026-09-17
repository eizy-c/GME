/// Fases del ciclo de vida de cualquier juego de cartas o tablero.
///
/// Permite estructurar una máquina de estados clara para:
/// - [initial]: Configuración y preparación previa.
/// - [dealing]: Reparto de cartas o asignación de fichas iniciales.
/// - [playing]: Fase principal donde los jugadores ejecutan sus turnos.
/// - [evaluatingRound]: Evaluación de bazas, cantos o rondas intermedias.
/// - [gameOver]: Partida finalizada con resultado definitivo.
enum GamePhase {
  initial,
  dealing,
  playing,
  evaluatingRound,
  gameOver,
}
