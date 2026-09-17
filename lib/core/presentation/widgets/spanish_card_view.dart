import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/cards/card_suit.dart';
import '../../models/cards/spanish_card.dart';

/// Componente visual de alta fidelidad para naipes de la Baraja Española tradicional.
/// Soporta renderizado frontal detallado, reverso ornamental clásico y estado compacto.
class SpanishCardView extends StatelessWidget {
  final SpanishCard card;
  final bool isFaceUp;
  final bool isSelected;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const SpanishCardView({
    super.key,
    required this.card,
    this.isFaceUp = true,
    this.isSelected = false,
    this.width,
    this.height,
    this.onTap,
  });

  /// Factory para representar el reverso de una carta oculta en el mazo o mano rival.
  const SpanishCardView.back({
    super.key,
    this.width,
    this.height,
    this.isSelected = false,
    this.onTap,
  })  : card = const SpanishCard(number: 1, suit: CardSuit.oros),
        isFaceUp = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 86.0;
    final cardHeight = height ?? (cardWidth * 1.55);

    Widget cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardWidth * 0.1),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: isSelected ? 16 : 4,
            offset: Offset(0, isSelected ? 4 : 3),
            spreadRadius: isSelected ? 3 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardWidth * 0.1),
        child: isFaceUp ? _buildFront(context, cardWidth, cardHeight) : _buildBack(cardWidth, cardHeight),
      ),
    );

    if (onTap != null) {
      cardWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(cardWidth * 0.1),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }

  Widget _buildFront(BuildContext context, double w, double h) {
    final candidates = _getCandidateAssetPaths();
    return _buildFrontWithCandidates(context, w, h, candidates, 0);
  }

  Widget _buildFrontWithCandidates(
    BuildContext context,
    double w,
    double h,
    List<String> candidates,
    int index,
  ) {
    if (index >= candidates.length) {
      return _buildVectorFront(context, w, h);
    }
    return Image.asset(
      candidates[index],
      width: w,
      height: h,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildFrontWithCandidates(context, w, h, candidates, index + 1);
      },
    );
  }

  List<String> _getCandidateAssetPaths() {
    String suitPrefix;
    String folderName;
    switch (card.suit) {
      case CardSuit.bastos:
        suitPrefix = 'B';
        folderName = 'BASTON';
        break;
      case CardSuit.oros:
        suitPrefix = 'O';
        folderName = 'OROS';
        break;
      case CardSuit.copas:
        suitPrefix = 'C';
        folderName = 'COPAS';
        break;
      case CardSuit.espadas:
        suitPrefix = 'E';
        folderName = 'ESPADAS';
        break;
    }

    String rankChar;
    switch (card.number) {
      case 10:
        rankChar = 'S';
        break;
      case 11:
        rankChar = 'C';
        break;
      case 12:
        rankChar = 'R';
        break;
      default:
        rankChar = '${card.number}';
    }

    return [
      // 1. Convención del usuario con carpeta: assets/cards/BASTON/B-1-CARD.png, B-S-CARD.png
      'assets/cards/$folderName/$suitPrefix-$rankChar-CARD.png',
      'assets/cards/$folderName/$suitPrefix-${card.number}-CARD.png',
      // 2. Variante directa en assets/cards/
      'assets/cards/$suitPrefix-$rankChar-CARD.png',
      'assets/cards/$suitPrefix-${card.number}-CARD.png',
      // 3. Convención estándar bastos_1.png
      'assets/cards/${card.suit.name.toLowerCase()}_${card.number}.png',
    ];
  }

  Widget _buildVectorFront(BuildContext context, double w, double h) {
    final suitDetails = _getSuitStyle(card.suit);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F0), // Tono marfil papel clásico
        border: Border.all(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF2C3E50),
          width: isSelected ? 2.2 : 1.4,
        ),
      ),
      child: Stack(
        children: [
          // Marco ornamental perimetral (característico de la baraja española)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(w * 0.05),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: suitDetails.color.withValues(alpha: 0.5), width: 1.0),
                  borderRadius: BorderRadius.circular(w * 0.04),
                ),
              ),
            ),
          ),

          // Esquina Superior Izquierda: Número e Ícono
          Positioned(
            top: h * 0.05,
            left: w * 0.07,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${card.number}',
                  style: TextStyle(
                    color: suitDetails.color,
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.20,
                    height: 0.9,
                  ),
                ),
                SizedBox(height: h * 0.008),
                _buildSuitIcon(card.suit, size: w * 0.15),
              ],
            ),
          ),

          // Centro: Ilustración del Palo / Figura
          Center(
            child: _buildCenterIllustration(w, h, suitDetails),
          ),

          // Esquina Inferior Derecha: Número e Ícono invertidos
          Positioned(
            bottom: h * 0.05,
            right: w * 0.07,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${card.number}',
                    style: TextStyle(
                      color: suitDetails.color,
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.20,
                      height: 0.9,
                    ),
                  ),
                  SizedBox(height: h * 0.008),
                  _buildSuitIcon(card.suit, size: w * 0.15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterIllustration(double w, double h, _SuitStyle style) {
    if (card.isFigure) {
      return Container(
        width: w * 0.54,
        height: h * 0.50,
        padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.02),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(w * 0.08),
          border: Border.all(color: style.color.withValues(alpha: 0.35), width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getFigureGlyph(card.number),
                style: TextStyle(fontSize: w * 0.32, height: 1.0),
              ),
              SizedBox(height: h * 0.012),
              _buildSuitIcon(card.suit, size: w * 0.18),
              SizedBox(height: h * 0.012),
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: 1.5),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: style.color.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  card.rankName.toUpperCase(),
                  style: TextStyle(
                    fontSize: w * 0.11,
                    fontWeight: FontWeight.w900,
                    color: style.color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Para cartas numéricas (1 a 7), mostramos el arreglo de símbolos centrales
    return Container(
      width: w * 0.52,
      height: h * 0.52,
      padding: EdgeInsets.all(w * 0.01),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: w * 0.50,
          height: h * 0.50,
          child: _buildNumberPips(card.number, card.suit, w),
        ),
      ),
    );
  }

  Widget _buildNumberPips(int number, CardSuit suit, double w) {
    if (number == 1) {
      // As tradicional: Gran blasón central
      return Center(child: _buildSuitIcon(suit, size: w * 0.38, isHero: true));
    }

    final iconSize = w * 0.18;
    // Disposición vertical o simétrica
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSuitIcon(suit, size: iconSize),
            if (number >= 2) _buildSuitIcon(suit, size: iconSize),
          ],
        ),
        if (number % 2 == 1 || number == 7)
          _buildSuitIcon(suit, size: iconSize),
        if (number >= 4)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSuitIcon(suit, size: iconSize),
              _buildSuitIcon(suit, size: iconSize),
            ],
          ),
      ],
    );
  }

  String _getFigureGlyph(int number) {
    switch (number) {
      case 10:
        return '💂'; // Sota
      case 11:
        return '🏇'; // Caballo
      case 12:
        return '👑'; // Rey
      default:
        return '👤';
    }
  }

  Widget _buildSuitIcon(CardSuit suit, {required double size, bool isHero = false}) {
    switch (suit) {
      case CardSuit.oros:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFFDE047), Color(0xFFCA8A04), Color(0xFF854D0E)],
              stops: [0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCA8A04).withValues(alpha: 0.5),
                blurRadius: isHero ? 6 : 2,
              ),
            ],
            border: Border.all(color: const Color(0xFF78350F), width: size * 0.08),
          ),
          child: Center(
            child: Icon(
              Icons.wb_sunny_rounded,
              size: size * 0.62,
              color: const Color(0xFF78350F),
            ),
          ),
        );

      case CardSuit.copas:
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              Icons.wine_bar_rounded,
              size: size * 1.0,
              color: const Color(0xFFDC2626),
            ),
          ),
        );

      case CardSuit.espadas:
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Icon(
                Icons.colorize_rounded, // Hoja afilada estilizada
                size: size * 0.95,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
        );

      case CardSuit.bastos:
        return Container(
          width: size * 0.45,
          height: size * 1.1,
          decoration: BoxDecoration(
            color: const Color(0xFF15803D),
            borderRadius: BorderRadius.circular(size * 0.2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF22C55E), Color(0xFF15803D), Color(0xFF14532D)],
            ),
            border: Border.all(color: const Color(0xFF052E16), width: 1),
          ),
          child: Center(
            child: Icon(
              Icons.eco_rounded,
              size: size * 0.4,
              color: const Color(0xFF86EFAC),
            ),
          ),
        );
    }
  }

  Widget _buildBack(double w, double h) {
    const backCandidates = [
      'assets/cards/REV-CARD.png',
      'assets/cards/rev-card.png',
      'assets/cards/reverso.png',
      'assets/cards/REVERSO.png',
      'assets/cards/back.png',
      'assets/cards/CARD-BACK.png',
      'assets/cards/reverso-card.png',
      'assets/cards/BASTON/reverso.png',
      'assets/cards/BASTON/REV-CARD.png',
    ];
    return _buildBackWithCandidates(w, h, backCandidates, 0);
  }

  Widget _buildBackWithCandidates(double w, double h, List<String> candidates, int index) {
    if (index >= candidates.length) {
      return _buildVectorBack(w, h);
    }
    return Image.asset(
      candidates[index],
      width: w,
      height: h,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildBackWithCandidates(w, h, candidates, index + 1),
    );
  }

  Widget _buildVectorBack(double w, double h) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B), // Azul real nocturno
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Stack(
        children: [
          // Patrón de grecas tradicional de reverso
          Positioned.fill(
            child: CustomPaint(
              painter: _CardBackPatternPainter(),
            ),
          ),
          Center(
            child: Container(
              width: w * 0.48,
              height: w * 0.48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF312E81),
                border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.shield_rounded,
                  size: w * 0.28,
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SuitStyle _getSuitStyle(CardSuit suit) {
    switch (suit) {
      case CardSuit.oros:
        return const _SuitStyle(color: Color(0xFFB45309));
      case CardSuit.copas:
        return const _SuitStyle(color: Color(0xFFB91C1C));
      case CardSuit.espadas:
        return const _SuitStyle(color: Color(0xFF1D4ED8));
      case CardSuit.bastos:
        return const _SuitStyle(color: Color(0xFF15803D));
    }
  }
}

class _SuitStyle {
  final Color color;
  const _SuitStyle({required this.color});
}

/// Pintor custom para el clásico tramado simétrico del reverso de los naipes.
class _CardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4338CA).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const step = 8.0;
    for (double i = -size.height; i < size.width + size.height; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
      canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
