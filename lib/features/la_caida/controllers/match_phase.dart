/// Fases canónicas de una partida de La Caída controladas por la Máquina de Estados.
enum MatchPhase {
  /// Esperando inicio o configuración de partida
  idle,

  /// Sorteo interactivo de la Mano en mesa ("¡ELIGE UNA CARTA!")
  dealerSelection,

  /// Reparto de 4 cartas iniciales a la mesa y evaluación del Canto de Mesa
  tableDeal,

  /// Reparto secuencial de 3 cartas a cada jugador
  dealingHands,

  /// Detección y resolución de cantos ("Matando Cantos")
  cantosResolution,

  /// Turno activo de un jugador (Humano o Bot)
  playerTurn,

  /// Evaluación y animación de la tirada (Caída, arrastre, limpia)
  evaluatingMove,

  /// Fin de la mano de 3 cartas (si quedan cartas en mazo, vuelve a dealingHands)
  roundOver,

  /// Fin definitivo de la partida (un jugador o equipo alcanzó 24 pts o cantó Trivilín)
  matchEnd,
}
