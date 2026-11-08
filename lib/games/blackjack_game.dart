import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class BlackjackGame extends MiniGame {
  @override
  String get name => 'Blackjack';

  @override
  String get instructions => 'Get closer to 21 than the dealer!';

  final Random _rng = Random();

  List<int> playerHand = [];
  List<int> dealerHand = [];
  bool playerStand = false;
  bool gameOver = false;
  int wins = 0;
  int targetWins = 3;
  String result = '';

  // Animation
  List<_Particle> particles = [];
  double resultScale = 0;
  List<Offset> cardPos = []; // For moving cards
  List<double> cardScales = [];

  @override
  void reset(Vector2 size) {
    targetWins = 2 + level;
    wins = 0;
    particles = [];
    resultScale = 0;
    _startRound();
  }

  void _startRound() {
    playerHand = [_drawCard(), _drawCard()];
    dealerHand = [_drawCard(), _drawCard()];
    playerStand = false;
    gameOver = false;
    result = '';
    resultScale = 0;

    // Initialize animation states
    // In a real deal this would be sequential, for now we just animate them popping in
    cardScales = List.filled(4, 0.0);
    // Indices 0,1 are dealer, 2,3 are player initially.
    // We'll manage a list of scales for all cards in hands combined?
    // Simpler: Just map index in hand to a scale list or use time.

    // Check for blackjack
    if (_handValue(playerHand) == 21) {
      _endRound();
    }
  }

  void _spawnParticles(Offset pos, Color color) {
    for (int i = 0; i < 20; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 50 + _rng.nextDouble() * 100;
      particles.add(
        _Particle(
          pos: pos,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.5 + _rng.nextDouble() * 0.5,
          size: 3 + _rng.nextDouble() * 4,
          color: color,
        ),
      );
    }
  }

  int _drawCard() {
    return _rng.nextInt(13) + 1; // 1-13 (A-K)
  }

  int _cardValue(int card) {
    if (card == 1) return 11; // Ace
    if (card >= 10) return 10; // Face cards
    return card;
  }

  int _handValue(List<int> hand) {
    int value = 0;
    int aces = 0;

    for (final card in hand) {
      value += _cardValue(card);
      if (card == 1) aces++;
    }

    // Adjust aces
    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }

    return value;
  }

  String _cardName(int card) {
    if (card == 1) return 'A';
    if (card == 11) return 'J';
    if (card == 12) return 'Q';
    if (card == 13) return 'K';
    return card.toString();
  }

  void _hit() {
    if (playerStand || gameOver) return;

    playerHand.add(_drawCard());
    if (_handValue(playerHand) >= 21) {
      _endRound();
    }
  }

  void _stand() {
    if (gameOver) return;
    playerStand = true;

    // Dealer plays
    while (_handValue(dealerHand) < 17) {
      dealerHand.add(_drawCard());
    }

    _endRound();
  }

  void _endRound() {
    gameOver = true;
    final player = _handValue(playerHand);
    final dealer = _handValue(dealerHand);

    if (player > 21) {
      result = 'Bust!';
    } else if (dealer > 21) {
      result = 'Dealer Bust!';
      wins++;
      _spawnParticles(Offset(200, 300), const Color(0xFF2A9D8F));
    } else if (player > dealer) {
      result = 'You Win!';
      wins++;
      _spawnParticles(Offset(200, 300), const Color(0xFFE9C46A));
    } else if (dealer > player) {
      result = 'Dealer Wins';
    } else {
      result = 'Push';
    }
  }

  @override
  void update(double dt) {
    // Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      particles[i].vel += Offset(0, 100 * dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (gameOver && resultScale < 1.0) {
      resultScale += dt * 5;
      if (resultScale > 1.0) resultScale = 1.0;
    }
  }

  @override
  bool get isSolved => wins >= targetWins;

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B5E20));

    final cardWidth = 45.0;
    final cardHeight = 65.0;
    final cardPaint = Paint()..color = Colors.white;
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 18, color: Colors.black),
    );

    // Dealer hand
    for (int i = 0; i < dealerHand.length; i++) {
      final x = rect.left + 20 + i * 55;

      // Simple spawn animation check (could be refined)
      double scale = 1.0;

      canvas.save();
      canvas.translate(x + cardWidth / 2, rect.top + 30 + cardHeight / 2);
      canvas.scale(scale);
      canvas.translate(-(x + cardWidth / 2), -(rect.top + 30 + cardHeight / 2));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, rect.top + 30, cardWidth, cardHeight),
          const Radius.circular(4),
        ),
        cardPaint,
      );
      if (gameOver || i == 0) {
        textPaint.render(
          canvas,
          _cardName(dealerHand[i]),
          Vector2(x + 15, rect.top + 50),
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x + 5,
              rect.top + 35,
              cardWidth - 10,
              cardHeight - 10,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF264653),
        );
      }
      canvas.restore();
    }

    // Player hand
    for (int i = 0; i < playerHand.length; i++) {
      final x = rect.left + 20 + i * 55;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, rect.center.dy + 30, cardWidth, cardHeight),
          const Radius.circular(4),
        ),
        cardPaint,
      );
      textPaint.render(
        canvas,
        _cardName(playerHand[i]),
        Vector2(x + 15, rect.center.dy + 50),
      );
    }

    // Values
    TextPaint(style: const TextStyle(fontSize: 14, color: Colors.white)).render(
      canvas,
      'Dealer: ${gameOver ? _handValue(dealerHand) : "?"}',
      Vector2(rect.left + 20, rect.top + 10),
    );
    TextPaint(style: const TextStyle(fontSize: 14, color: Colors.white)).render(
      canvas,
      'You: ${_handValue(playerHand)}',
      Vector2(rect.left + 20, rect.center.dy + 10),
    );

    // Buttons
    if (!gameOver && !isSolved) {
      final hitRect = Rect.fromLTWH(rect.left + 20, rect.bottom - 50, 80, 35);
      final standRect = Rect.fromLTWH(
        rect.left + 120,
        rect.bottom - 50,
        80,
        35,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(hitRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFF2A9D8F),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(standRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFE76F51),
      );

      TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ).render(
        canvas,
        'HIT',
        Vector2(hitRect.center.dx - 15, hitRect.center.dy - 8),
      );
      TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ).render(
        canvas,
        'STAND',
        Vector2(standRect.center.dx - 25, standRect.center.dy - 8),
      );
    }

    // Result
    if (result.isNotEmpty) {
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy - 30);
      canvas.scale(resultScale);
      canvas.translate(-rect.center.dx, -(rect.center.dy - 30));

      TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Color(0xFFE9C46A),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
        ),
      ).render(
        canvas,
        result,
        Vector2(rect.center.dx, rect.center.dy - 30),
        anchor: Anchor.center,
      );
      canvas.restore();
    }

    // Score
    TextPaint(
      style: const TextStyle(fontSize: 14, color: Colors.white70),
    ).render(
      canvas,
      'Wins: $wins / $targetWins',
      Vector2(rect.right - 100, rect.top + 10),
    );

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.pos,
        p.size * p.life,
        Paint()..color = p.color.withValues(alpha: p.life),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);

    if (gameOver && !isSolved) {
      if (resultScale >= 1.0) _startRound();
      return;
    }

    if (!gameOver && !isSolved) {
      final hitRect = Rect.fromLTWH(rect.left + 20, rect.bottom - 50, 80, 35);
      final standRect = Rect.fromLTWH(
        rect.left + 120,
        rect.bottom - 50,
        80,
        35,
      );

      if (hitRect.contains(Offset(position.x, position.y))) {
        _hit();
      } else if (standRect.contains(Offset(position.x, position.y))) {
        _stand();
      }
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
