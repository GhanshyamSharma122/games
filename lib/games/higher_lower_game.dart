import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class HigherLowerGame extends MiniGame {
  @override
  String get name => 'Higher or Lower';

  @override
  String get instructions => 'Guess if the next card is Higher or Lower.';

  final Random _rng = Random();

  int targetStreak = 5;
  int streak = 0;
  // Cards are 0-51. Rank = card % 13 (0=2, 8=10, 9=J, 10=Q, 11=K, 12=A)
  // Wait, let's stick to standard: 0=A, 1=2... 9=10, 10=J, 11=Q, 12=K ?
  // Or 2-A sorting? Usually A is high or low. Let's say A=1 (low) for simplicity or standard Casino?
  // User didn't specify. Let's use A=1 (low) to K=13 (high) as per previous code, independent of suit.
  // Actually, in previous code A=1, K=13.
  // Let's use:
  // 0-12: Spades (A-K)
  // 13-25: Hearts (A-K)
  // 26-38: Diamonds (A-K)
  // 39-51: Clubs (A-K)
  int currentCard = 0;
  int nextCard = 0;
  bool revealed = false;
  bool correct = false;

  // Animation
  List<_Particle> particles = [];
  double flipScale = 1.0; // 1 to 0 to 1
  bool flipping = false;
  double shake = 0;
  Vector2 _gameSize = Vector2.zero();

  @override
  void reset(Vector2 size) {
    _gameSize = size;
    targetStreak = 5 + level * 2;
    streak = 0;
    currentCard = _rng.nextInt(52);
    nextCard = _rng.nextInt(52);
    // Ensure not same rank
    while (_rank(nextCard) == _rank(currentCard)) {
      nextCard = _rng.nextInt(52);
    }

    revealed = false;
    particles = [];
    flipScale = 1.0;
    flipping = false;
    shake = 0;
  }

  int _rank(int card) => (card % 13) + 1; // 1=A ... 13=K
  int _suit(int card) => card ~/ 13; // 0=Spade, 1=Heart, 2=Diamond, 3=Club

  void _newRound() {
    currentCard = nextCard;
    nextCard = _rng.nextInt(52);
    while (_rank(nextCard) == _rank(currentCard)) {
      nextCard = _rng.nextInt(52);
    }
    revealed = false;
  }

  void _spawnParticles(Offset pos, Color color) {
    for (int i = 0; i < 30; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 100 + _rng.nextDouble() * 150;
      particles.add(
        _Particle(
          pos: pos,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.8 + _rng.nextDouble() * 0.6,
          size: 4 + _rng.nextDouble() * 6,
          color: color,
        ),
      );
    }
  }

  void _guess(bool higher) {
    if (revealed || isSolved || flipping) return;

    flipping = true;
    revealed = true;

    final curR = _rank(currentCard);
    final nextR = _rank(nextCard);

    // strictly higher/lower for challenge? Or equal wins?
    // Let's say equal is loss or re-draw? I forced not-equal in generation.
    // A=1, K=13.
    if (higher) {
      correct = nextR > curR;
    } else {
      correct = nextR < curR;
    }
  }

  @override
  void update(double dt) {
    // Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      particles[i].vel += Offset(0, 300 * dt); // Gravity
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (shake > 0) {
      shake -= dt * 3;
      if (shake < 0) shake = 0;
    }

    if (flipping) {
      flipScale -= dt * 3;
      if (flipScale < -1.0) {
        flipScale = 1.0;
        flipping = false;

        if (correct) {
          streak++;
          _spawnParticles(
            Offset(_gameSize.x / 2, _gameSize.y / 2),
            const Color(0xFFFFD700),
          );
          if (!isSolved) {
            Future.delayed(const Duration(milliseconds: 800), _newRound);
          }
        } else {
          streak = 0;
          shake = 1.0;
          _spawnParticles(
            Offset(_gameSize.x / 2, _gameSize.y / 2),
            const Color(0xFFEF476F),
          );
          Future.delayed(const Duration(milliseconds: 1000), _newRound);
        }
      }
    }
  }

  @override
  bool get isSolved => streak >= targetStreak;

  String _rankStr(int r) {
    if (r == 1) return 'A';
    if (r == 11) return 'J';
    if (r == 12) return 'Q';
    if (r == 13) return 'K';
    return r.toString();
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // 1. Premium Background
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1B2631), const Color(0xFF0E1117)],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    if (shake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shake * 20,
        (_rng.nextDouble() - 0.5) * shake * 20,
      );
    }

    // Centered layout
    final center = rect.center;
    final cardW = 100.0;
    final cardH = 150.0;
    final gap = 40.0;

    // Current Card
    _drawCard(
      canvas,
      currentCard,
      Offset(center.dx - cardW / 2 - gap / 2 - cardW / 2, center.dy - 20),
      cardW,
      cardH,
      1.0,
    );

    // Next Card
    final nextScale = flipping ? flipScale.abs() : 1.0;
    final showBack = (revealed && flipping && flipScale > 0) || (!revealed);
    _drawCard(
      canvas,
      nextCard,
      Offset(center.dx + gap / 2 + cardW / 2, center.dy - 20),
      cardW,
      cardH,
      nextScale,
      showBack: showBack,
    );

    // UI Overlay
    // Buttons
    if (!flipping && !revealed && !isSolved) {
      _drawButton(
        canvas,
        'HIGHER',
        const Color(0xFF2A9D8F),
        Rect.fromLTWH(center.dx - 120, center.dy + 100, 100, 50),
      );
      _drawButton(
        canvas,
        'LOWER',
        const Color(0xFFE76F51),
        Rect.fromLTWH(center.dx + 20, center.dy + 100, 100, 50),
      );
    }

    // Streak / Header
    _drawHUD(canvas, rect);

    // Result Text
    if (revealed && !flipping) {
      _drawResult(canvas, center);
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.pos,
        p.size * p.life,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }

    if (shake > 0) canvas.restore();
  }

  void _drawCard(
    Canvas canvas,
    int card,
    Offset center,
    double w,
    double h,
    double scale, {
    bool showBack = false,
  }) {
    final rect = Rect.fromCenter(center: center, width: w * scale, height: h);
    if (scale < 0.1) return;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Shadow
    canvas.drawPath(
      Path()..addRRect(rrect.shift(const Offset(4, 4))),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    if (showBack) {
      // Card Back
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE9C46A));
      final inner = rect.deflate(8 * scale);
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(6)),
        Paint()..color = const Color(0xFF264653),
      );
      // Pattern
      final pPaint = Paint()
        ..color = const Color(0xFF2A9D8F).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale;
      canvas.drawLine(inner.topLeft, inner.bottomRight, pPaint);
      canvas.drawLine(inner.topRight, inner.bottomLeft, pPaint);

      // Center Logo
      if (scale > 0.5) {
        TextPaint(
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE9C46A),
          ),
        ).render(canvas, '?', Vector2(center.dx - 7, center.dy - 15));
      }
    } else {
      // Card Front
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF1FAEE));

      if (scale > 0.4) {
        final rank = _rank(card);
        final suit = _suit(card);
        final isRed = suit == 1 || suit == 2;
        final color = isRed ? const Color(0xFFE63946) : const Color(0xFF1D3557);

        final rankTxt = _rankStr(rank);

        // Top Left
        _drawCardCorner(canvas, rect, rankTxt, suit, color, true);
        // Bottom Right
        _drawCardCorner(canvas, rect, rankTxt, suit, color, false);

        // Center Suit
        _drawSuitIcon(canvas, suit, center, 40 * scale, color);
      }
    }
  }

  void _drawCardCorner(
    Canvas canvas,
    Rect rect,
    String text,
    int suit,
    Color color,
    bool topLeft,
  ) {
    if (rect.width < 30) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final x = topLeft ? rect.left + 8 : rect.right - 8 - tp.width;
    final y = topLeft ? rect.top + 8 : rect.bottom - 8 - tp.height;

    tp.paint(canvas, Offset(x, y));

    // Mini suit below/above
    final suitCY = topLeft ? y + tp.height + 8 : y - 8;
    _drawSuitIcon(canvas, suit, Offset(x + tp.width / 2, suitCY), 10, color);
  }

  void _drawSuitIcon(
    Canvas canvas,
    int suit,
    Offset center,
    double size,
    Color color,
  ) {
    // 0=Spade, 1=Heart, 2=Diamond, 3=Club
    // Simple shape drawing
    final paint = Paint()..color = color;
    final path = Path();

    if (suit == 0) {
      // Spade
      path.moveTo(center.dx, center.dy - size * 0.5);
      path.cubicTo(
        center.dx + size * 0.5,
        center.dy,
        center.dx + size * 0.5,
        center.dy + size * 0.5,
        center.dx,
        center.dy + size * 0.2,
      );
      path.cubicTo(
        center.dx - size * 0.5,
        center.dy + size * 0.5,
        center.dx - size * 0.5,
        center.dy,
        center.dx,
        center.dy - size * 0.5,
      );
      // Stem
      path.moveTo(center.dx, center.dy + size * 0.2);
      path.lineTo(center.dx - size * 0.1, center.dy + size * 0.6);
      path.lineTo(center.dx + size * 0.1, center.dy + size * 0.6);
      path.close();
    } else if (suit == 1) {
      // Heart
      path.moveTo(center.dx, center.dy + size * 0.4);
      path.cubicTo(
        center.dx - size * 0.7,
        center.dy - size * 0.2,
        center.dx - size * 0.3,
        center.dy - size * 0.6,
        center.dx,
        center.dy - size * 0.2,
      );
      path.cubicTo(
        center.dx + size * 0.3,
        center.dy - size * 0.6,
        center.dx + size * 0.7,
        center.dy - size * 0.2,
        center.dx,
        center.dy + size * 0.4,
      );
      path.close();
    } else if (suit == 2) {
      // Diamond
      path.moveTo(center.dx, center.dy - size * 0.5);
      path.lineTo(center.dx + size * 0.4, center.dy);
      path.lineTo(center.dx, center.dy + size * 0.5);
      path.lineTo(center.dx - size * 0.4, center.dy);
      path.close();
    } else {
      // Club
      final r = size * 0.2;
      canvas.drawCircle(Offset(center.dx, center.dy - r), r, paint);
      canvas.drawCircle(Offset(center.dx - r, center.dy + r * 0.5), r, paint);
      canvas.drawCircle(Offset(center.dx + r, center.dy + r * 0.5), r, paint);
      path.moveTo(center.dx, center.dy);
      path.lineTo(center.dx - size * 0.1, center.dy + size * 0.6);
      path.lineTo(center.dx + size * 0.1, center.dy + size * 0.6);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  void _drawButton(Canvas canvas, String text, Color color, Rect rect) {
    // Glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(25)),
      Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Body
    final thumbPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.8), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(25)),
      thumbPaint,
    );

    // Shine
    canvas.drawPath(
      Path()..addOval(
        Rect.fromLTWH(
          rect.left + 5,
          rect.top + 2,
          rect.width - 10,
          rect.height / 2,
        ),
      ),
      Paint()..color = Colors.white.withOpacity(0.2),
    );

    // Text
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
    );
  }

  void _drawHUD(Canvas canvas, Rect rect) {
    final paint = Paint()..color = const Color(0xFF151A22).withOpacity(0.8);
    final hudRect = Rect.fromLTWH(
      rect.left + 10,
      rect.top + 10,
      rect.width - 20,
      50,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hudRect, const Radius.circular(12)),
      paint,
    );

    TextPaint(
      style: const TextStyle(
        fontSize: 20,
        color: Color(0xFFE9C46A),
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      'Streak: $streak / $targetStreak',
      Vector2(hudRect.center.dx - 60, hudRect.center.dy - 12),
    );
  }

  void _drawResult(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy + 20);
    // Rotating or scaling effect could be added here
    final color = correct ? const Color(0xFF2A9D8F) : const Color(0xFFE76F51);
    final text = correct ? 'CORRECT' : 'WRONG';

    // Shadow
    TextPaint(
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: Colors.black.withOpacity(0.5),
      ),
    ).render(canvas, text, Vector2(-62, -42));
    // Main
    TextPaint(
      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color),
    ).render(canvas, text, Vector2(-60, -40));

    canvas.restore();
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (revealed || isSolved || flipping) return;

    final rect = boardRect(gameSize);
    final center = rect.center;
    final higherRect = Rect.fromLTWH(center.dx - 120, center.dy + 100, 100, 50);
    final lowerRect = Rect.fromLTWH(center.dx + 20, center.dy + 100, 100, 50);

    if (higherRect.contains(Offset(position.x, position.y))) {
      _guess(true);
    } else if (lowerRect.contains(Offset(position.x, position.y))) {
      _guess(false);
    }
  }
}

class _Particle {
  Offset pos, vel;
  double life, size;
  Color color;
  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
  });
}
