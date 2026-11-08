import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class CoinCollectorGame extends MiniGame {
  @override
  String get name => 'Coin Collector';

  @override
  String get instructions => 'Drag the basket to catch falling coins!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final Random _rng = Random();
  List<_Coin> coins = [];
  List<_Particle> particles = [];
  double basketX = 200;
  double basketWidth = 80;
  int score = 0;
  int targetScore = 15;
  int missed = 0;
  int maxMissed = 5;
  double spawnTimer = 0;
  double spawnInterval = 1.0;

  @override
  void reset(Vector2 size) {
    final rect = boardRect(size);

    targetScore = 10 + level * 5;
    spawnInterval = 1.2 - level * 0.08;
    spawnInterval = spawnInterval.clamp(0.4, 1.2);
    basketWidth = 90 - level * 3;
    basketWidth = basketWidth.clamp(50, 90);

    basketX = rect.center.dx;
    coins = [];
    particles = [];
    score = 0;
    missed = 0;
    spawnTimer = 0;
  }

  void _spawnCoin(Rect rect) {
    final isGold = _rng.nextDouble() < 0.3;
    coins.add(
      _Coin(
        x: rect.left + 30 + _rng.nextDouble() * (rect.width - 60),
        y: rect.top - 20,
        speed: 120 + _rng.nextDouble() * 60 + level * 10,
        rotation: 0,
        rotationSpeed: 3 + _rng.nextDouble() * 4,
        isGold: isGold,
        scale: 0.0,
      ),
    );
  }

  void _spawnCollectParticles(double x, double y, bool isGold) {
    final color = isGold ? const Color(0xFFE9C46A) : const Color(0xFFC0C0C0);
    for (int i = 0; i < 10; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi;
      final speed = 60 + _rng.nextDouble() * 80;
      particles.add(
        _Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 3 + _rng.nextDouble() * 3,
          life: 0.5,
          color: color,
        ),
      );
    }
  }

  @override
  bool get isSolved => score >= targetScore;

  bool get isLost => missed >= maxMissed;

  @override
  void update(double dt) {
    if (isSolved || isLost) return;

    final rect = boardRect(Vector2(400, 600));

    // Spawn coins
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnCoin(rect);
    }

    // Update coins
    for (int i = coins.length - 1; i >= 0; i--) {
      final c = coins[i];

      // Scale in
      if (c.scale < 1.0) {
        c.scale += dt * 6;
        if (c.scale > 1.0) c.scale = 1.0;
      }

      c.y += c.speed * dt;
      c.rotation += c.rotationSpeed * dt;

      // Collect check
      final basketTop = rect.bottom - 60;
      if (c.y >= basketTop - 10 && c.y <= basketTop + 10) {
        if (c.x >= basketX - basketWidth / 2 &&
            c.x <= basketX + basketWidth / 2) {
          _spawnCollectParticles(c.x, c.y, c.isGold);
          score += c.isGold ? 3 : 1;
          coins.removeAt(i);
          continue;
        }
      }

      // Missed
      if (c.y > rect.bottom + 20) {
        coins.removeAt(i);
        missed++;
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 150 * dt;
      p.life -= dt * 2;
      if (p.life <= 0) particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Background
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    // Draw coins
    for (final c in coins) {
      final coinSize = 20 * c.scale;
      final color = c.isGold
          ? const Color(0xFFE9C46A)
          : const Color(0xFFC0C0C0);

      canvas.save();
      canvas.translate(c.x, c.y);
      canvas.rotate(c.rotation);

      // Coin glow
      canvas.drawCircle(
        Offset.zero,
        coinSize + 4,
        Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Coin body
      canvas.drawCircle(Offset.zero, coinSize, Paint()..color = color);

      // Coin shine
      canvas.drawCircle(
        Offset(-coinSize * 0.3, -coinSize * 0.3),
        coinSize * 0.3,
        Paint()..color = Colors.white.withOpacity(0.4),
      );

      // Coin symbol
      if (c.isGold) {
        canvas.drawCircle(
          Offset.zero,
          coinSize * 0.5,
          Paint()
            ..color = const Color(0xFFD4A84A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      canvas.restore();
    }

    // Draw basket
    final basketTop = rect.bottom - 60;
    final basketPath = Path()
      ..moveTo(basketX - basketWidth / 2, basketTop)
      ..lineTo(basketX - basketWidth / 2 + 10, basketTop + 40)
      ..lineTo(basketX + basketWidth / 2 - 10, basketTop + 40)
      ..lineTo(basketX + basketWidth / 2, basketTop)
      ..close();

    canvas.drawPath(basketPath, Paint()..color = const Color(0xFF8B4513));

    // Basket rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          basketX - basketWidth / 2 - 5,
          basketTop - 5,
          basketWidth + 10,
          10,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFA0522D),
    );

    // Basket weave pattern
    for (int i = 0; i < 3; i++) {
      final y = basketTop + 10 + i * 12;
      canvas.drawLine(
        Offset(basketX - basketWidth / 2 + 8, y),
        Offset(basketX + basketWidth / 2 - 8, y),
        Paint()
          ..color = const Color(0xFF6B3100)
          ..strokeWidth = 1.5,
      );
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }

    // Score
    final scoreText = '$score / $targetScore';
    TextPaint(
      style: const TextStyle(
        fontSize: 24,
        color: Color(0xFFE9C46A),
        fontWeight: FontWeight.bold,
      ),
    ).render(canvas, scoreText, Vector2(rect.center.dx - 30, rect.top + 15));

    // Lives
    for (int i = 0; i < maxMissed; i++) {
      final lost = i < missed;
      canvas.drawCircle(
        Offset(rect.left + 15 + i * 20, rect.top + 25),
        6,
        Paint()
          ..color = lost ? const Color(0xFFE63946) : const Color(0xFF2A9D8F),
      );
    }
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    basketX = (basketX + delta.x).clamp(
      rect.left + basketWidth / 2,
      rect.right - basketWidth / 2,
    );
  }
}

class _Coin {
  double x, y;
  double speed;
  double rotation;
  double rotationSpeed;
  bool isGold;
  double scale;

  _Coin({
    required this.x,
    required this.y,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.isGold,
    required this.scale,
  });
}

class _Particle {
  double x, y;
  double vx, vy;
  double size;
  double life;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  });
}
