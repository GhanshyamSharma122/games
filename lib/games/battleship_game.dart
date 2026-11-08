import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class BattleshipGame extends MiniGame {
  @override
  String get name => 'Battleship';

  @override
  String get instructions => 'Find and sink all enemy ships!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 8;

  final Random _rng = Random();
  int n = 8;
  late List<bool> ships; // Where ships are
  late List<int> revealed; // 0 = hidden, 1 = miss, 2 = hit
  int totalShips = 10;
  int shipsFound = 0;

  // Animation
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    n = 6 + level ~/ 2;
    n = n.clamp(6, 10);
    totalShips = 5 + level;
    totalShips = totalShips.clamp(5, 20);

    ships = List.generate(n * n, (_) => false);
    revealed = List.generate(n * n, (_) => 0);
    shipsFound = 0;
    particles = [];

    // Place ships randomly
    int placed = 0;
    while (placed < totalShips) {
      final i = _rng.nextInt(n * n);
      if (!ships[i]) {
        ships[i] = true;
        placed++;
      }
    }
  }

  void _spawnParticles(Offset pos, Color color, bool explosion) {
    int count = explosion ? 20 : 10;
    double speedBase = explosion ? 80 : 40;

    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = speedBase + _rng.nextDouble() * speedBase;
      particles.add(
        _Particle(
          pos: pos,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.5 + _rng.nextDouble() * 0.5,
          size: 3 + _rng.nextDouble() * 5,
          color: color,
        ),
      );
    }
  }

  @override
  bool get isSolved => shipsFound >= totalShips;

  @override
  void update(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      // particles[i].vel += Offset(0, 100 * dt); // Gravity? Maybe skip for splashes/explosions topdown
      if (particles[i].life <= 0) particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    final hiddenPaint = Paint()..color = const Color(0xFF264653);
    final missPaint = Paint()..color = const Color(0xFF3A4452);
    final hitPaint = Paint()..color = const Color(0xFFE76F51);
    final border = Paint()
      ..color = const Color(0xFF1B2430)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell + 2,
          rect.top + r * cell + 2,
          cell - 4,
          cell - 4,
        );

        Paint paint;
        if (revealed[i] == 0) {
          paint = hiddenPaint;
        } else if (revealed[i] == 1) {
          paint = missPaint;
        } else {
          paint = hitPaint;
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(4)),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(4)),
          border,
        );

        // Draw miss X
        if (revealed[i] == 1) {
          final xPaint = Paint()
            ..color = const Color(0xFF5A6472)
            ..strokeWidth = 2;
          canvas.drawLine(
            cellRect.topLeft + const Offset(8, 8),
            cellRect.bottomRight - const Offset(8, 8),
            xPaint,
          );
          canvas.drawLine(
            cellRect.topRight + const Offset(-8, 8),
            cellRect.bottomLeft + const Offset(8, -8),
            xPaint,
          );
        }
      }
    }

    // Progress indicator
    final progressRect = Rect.fromLTWH(
      rect.left,
      rect.bottom + 10,
      rect.width * (shipsFound / totalShips),
      8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(progressRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF2A9D8F),
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
    if (isSolved) return;

    final rect = boardRect(gameSize);
    final cell = rect.width / n;

    if (!rect.contains(Offset(position.x, position.y))) return;

    final c = ((position.x - rect.left) / cell).floor();
    final r = ((position.y - rect.top) / cell).floor();
    final i = idx(r, c, n);

    if (revealed[i] != 0) return;

    final center = Offset(
      rect.left + c * cell + cell / 2,
      rect.top + r * cell + cell / 2,
    );

    if (ships[i]) {
      revealed[i] = 2;
      shipsFound++;
      _spawnParticles(center, const Color(0xFFE63946), true); // Explosion
    } else {
      revealed[i] = 1;
      _spawnParticles(center, const Color(0xFF457B9D), false); // Splash
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
