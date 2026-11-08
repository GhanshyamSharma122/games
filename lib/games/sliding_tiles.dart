import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class SlidingTilesGame extends MiniGame {
  @override
  String get name => 'Sliding Tiles';

  @override
  String get instructions => 'Tap a tile next to empty to slide.';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 6;

  final Random _rng = Random();
  int n = 4;
  late List<int> tiles;
  late List<Offset> tilePositions; // Animated positions
  late List<double> tileScales; // Press animation
  int moveCount = 0;
  int lastMoved = -1;
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    n = 2 + level;
    n = n.clamp(3, 8);

    tiles = List.generate(n * n, (i) => i);
    tilePositions = List.generate(
      n * n,
      (i) => Offset((i % n).toDouble(), (i ~/ n).toDouble()),
    );
    tileScales = List.generate(n * n, (_) => 1.0);

    final shuffles = 100 + level * 50;
    for (int i = 0; i < shuffles; i++) {
      final empty = tiles.indexOf(0);
      final r = empty ~/ n;
      final c = empty % n;
      final moves = <int>[];
      if (r > 0) moves.add(idx(r - 1, c, n));
      if (r < n - 1) moves.add(idx(r + 1, c, n));
      if (c > 0) moves.add(idx(r, c - 1, n));
      if (c < n - 1) moves.add(idx(r, c + 1, n));
      final swap = moves[_rng.nextInt(moves.length)];
      final t = tiles[swap];
      tiles[swap] = 0;
      tiles[empty] = t;
    }

    // Update visual positions
    for (int i = 0; i < n * n; i++) {
      tilePositions[i] = Offset((i % n).toDouble(), (i ~/ n).toDouble());
    }

    moveCount = 0;
    lastMoved = -1;
    particles = [];
  }

  @override
  bool get isSolved {
    for (int i = 1; i < tiles.length; i++) {
      if (tiles[i] != i) return false;
    }
    return tiles[0] == 0;
  }

  @override
  void update(double dt) {
    // Animate tile positions
    for (int i = 0; i < n * n; i++) {
      // Find which tile is at position i
      for (int t = 0; t < n * n; t++) {
        if (tiles[t] != 0) {
          final gridX = (tiles.toList().indexOf(tiles[t]) % n).toDouble();
          final gridY = (tiles.toList().indexOf(tiles[t]) ~/ n).toDouble();

          // Smooth animation
          tilePositions[t] = Offset(
            tilePositions[t].dx + (gridX - tilePositions[t].dx) * dt * 12,
            tilePositions[t].dy + (gridY - tilePositions[t].dy) * dt * 12,
          );
        }
      }

      // Scale animation
      if (tileScales[i] < 1.0) {
        tileScales[i] += dt * 8;
        if (tileScales[i] > 1.0) tileScales[i] = 1.0;
      }
    }

    // Update position based on actual tile location
    for (int pos = 0; pos < n * n; pos++) {
      final tile = tiles[pos];
      if (tile != 0) {
        final targetX = (pos % n).toDouble();
        final targetY = (pos ~/ n).toDouble();
        tilePositions[tile] = Offset(
          tilePositions[tile].dx + (targetX - tilePositions[tile].dx) * dt * 15,
          tilePositions[tile].dy + (targetY - tilePositions[tile].dy) * dt * 15,
        );
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF11161D),
    );

    // Empty slot indicator
    final emptyIdx = tiles.indexOf(0);
    final emptyRect = Rect.fromLTWH(
      rect.left + (emptyIdx % n) * cell + 6,
      rect.top + (emptyIdx ~/ n) * cell + 6,
      cell - 12,
      cell - 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(emptyRect, const Radius.circular(10)),
      Paint()..color = const Color(0xFF1A2030),
    );

    // Draw tiles with animation
    for (int i = 1; i < n * n; i++) {
      final pos = tiles.indexOf(i);
      if (pos == -1) continue;

      final visualPos = tilePositions[i];
      final scale = tileScales[i];

      final cellRect = Rect.fromLTWH(
        rect.left + visualPos.dx * cell + 4,
        rect.top + visualPos.dy * cell + 4,
        cell - 8,
        cell - 8,
      );

      final scaledRect = Rect.fromCenter(
        center: cellRect.center,
        width: cellRect.width * scale,
        height: cellRect.height * scale,
      );

      // Shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          scaledRect.translate(2, 3),
          const Radius.circular(12),
        ),
        Paint()..color = Colors.black.withOpacity(0.3),
      );

      // Tile background with gradient effect
      final isCorrect = pos == i;
      final tileColor = isCorrect
          ? const Color(0xFF2A9D8F)
          : const Color(0xFF2B3646);

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(12)),
        Paint()..color = tileColor,
      );

      // Highlight
      final highlightRect = Rect.fromLTWH(
        scaledRect.left + 4,
        scaledRect.top + 4,
        scaledRect.width - 8,
        scaledRect.height * 0.3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
        Paint()..color = Colors.white.withOpacity(0.15),
      );

      // Number
      final fontSize = (cell * 0.4).clamp(16.0, 28.0);
      final textPaint = TextPaint(
        style: TextStyle(
          fontSize: fontSize * scale,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      final text = i.toString();
      final textWidth = textPaint.getLineMetrics(text).width;
      textPaint.render(
        canvas,
        text,
        Vector2(
          scaledRect.center.dx - textWidth / 2,
          scaledRect.center.dy - fontSize * scale / 2,
        ),
      );
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }

    // Move counter
    TextPaint(
      style: const TextStyle(fontSize: 14, color: Colors.white54),
    ).render(canvas, 'Moves: $moveCount', Vector2(rect.left, rect.bottom + 10));
  }

  void _spawnSlideParticles(Offset from, Offset to) {
    final center = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 30 + _rng.nextDouble() * 40;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: const Color(0xFF2A9D8F),
          size: 3,
          life: 0.4,
        ),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final cell = rect.width / n;
    if (!rect.contains(Offset(position.x, position.y))) return;
    final c = ((position.x - rect.left) / cell).floor();
    final r = ((position.y - rect.top) / cell).floor();
    final empty = tiles.indexOf(0);
    final er = empty ~/ n;
    final ec = empty % n;
    if ((r - er).abs() + (c - ec).abs() == 1) {
      final i = idx(r, c, n);
      final tile = tiles[i];

      // Spawn particles
      _spawnSlideParticles(
        Offset(rect.left + c * cell + cell / 2, rect.top + r * cell + cell / 2),
        Offset(
          rect.left + ec * cell + cell / 2,
          rect.top + er * cell + cell / 2,
        ),
      );

      tiles[empty] = tile;
      tiles[i] = 0;
      tileScales[tile] = 0.9;
      moveCount++;
      lastMoved = tile;
    }
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
  });

  void update(double dt) {
    position = position + velocity * dt;
    velocity = velocity * 0.92;
    life -= dt * 2;
  }
}
