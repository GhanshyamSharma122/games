import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../core/util.dart';

class MemoryFlipGame extends MiniGame {
  @override
  String get name => 'Memory Flip';

  @override
  String get instructions => 'Match all pairs.';

  int n = 4;
  final Random _rng = Random();
  late List<int> values;
  late List<bool> revealed;
  late List<bool> matched;
  late List<double> flipProgress; // 0 = face down, 1 = face up
  late List<double> matchScale; // Scale animation on match
  late List<double> shakeOffset; // Shake on mismatch
  int? first;
  int? second;
  double hideTimer = 0;
  bool showingMismatch = false;
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    // Progressive difficulty: increase grid size with level
    final baseN = switch (difficulty) {
      GameDifficulty.easy => 2,
      GameDifficulty.medium => 4,
      GameDifficulty.hard => 4,
    };

    // Add pairs as level increases (every 2 levels, increase grid)
    n = baseN + ((level - 1) ~/ 2) * 2;
    n = n.clamp(2, 8);

    // Grid must have even number of cells for pairs
    if ((n * n) % 2 != 0) n++;

    final list = <int>[];
    for (int i = 1; i <= (n * n) ~/ 2; i++) {
      list.add(i);
      list.add(i);
    }
    list.shuffle(_rng);
    values = list;
    revealed = List.generate(n * n, (_) => false);
    matched = List.generate(n * n, (_) => false);
    flipProgress = List.generate(n * n, (_) => 0.0);
    matchScale = List.generate(n * n, (_) => 1.0);
    shakeOffset = List.generate(n * n, (_) => 0.0);
    first = null;
    second = null;
    hideTimer = 0;
    showingMismatch = false;
    particles = [];
  }

  void _spawnMatchParticles(Offset center) {
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 80;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: const Color(0xFF2A9D8F),
          size: 4 + _rng.nextDouble() * 3,
          life: 0.6,
        ),
      );
    }
  }

  @override
  bool get isSolved => matched.every((v) => v);

  @override
  void update(double dt) {
    // Animate flip progress
    for (int i = 0; i < n * n; i++) {
      final target = (revealed[i] || matched[i]) ? 1.0 : 0.0;
      if (flipProgress[i] != target) {
        final delta = target > flipProgress[i] ? dt * 5 : -dt * 5;
        flipProgress[i] = (flipProgress[i] + delta).clamp(0.0, 1.0);
      }

      // Match scale bounce
      if (matchScale[i] > 1.0) {
        matchScale[i] -= dt * 3;
        if (matchScale[i] < 1.0) matchScale[i] = 1.0;
      }

      // Shake decay
      if (shakeOffset[i] != 0) {
        shakeOffset[i] *= 0.85;
        if (shakeOffset[i].abs() < 0.5) shakeOffset[i] = 0;
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }

    if (hideTimer > 0) {
      hideTimer -= dt;
      if (hideTimer <= 0 && first != null && second != null) {
        // Shake mismatched cards
        shakeOffset[first!] = 8 * (_rng.nextDouble() > 0.5 ? 1 : -1);
        shakeOffset[second!] = 8 * (_rng.nextDouble() > 0.5 ? 1 : -1);

        revealed[first!] = false;
        revealed[second!] = false;
        first = null;
        second = null;
        showingMismatch = false;
      }
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final flip = flipProgress[i];
        final scale = matchScale[i];
        final shake = shakeOffset[i];

        // Calculate visual flip (0 to 1, but show back from 0-0.5, front from 0.5-1)
        final flipAngle = flip * pi;
        final scaleX = cos(flipAngle).abs();

        final baseRect = Rect.fromLTWH(
          rect.left + c * cell + 4 + shake,
          rect.top + r * cell + 4,
          cell - 8,
          cell - 8,
        );

        final cellRect = Rect.fromCenter(
          center: baseRect.center,
          width: baseRect.width * scaleX * scale,
          height: baseRect.height * scale,
        );

        // Shadow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            cellRect.translate(2, 3),
            const Radius.circular(8),
          ),
          Paint()..color = Colors.black.withOpacity(0.2),
        );

        // Determine if showing front or back
        final showingFront = flip > 0.5;

        if (showingFront) {
          // Front face
          final frontColor = matched[i]
              ? const Color(0xFF2A9D8F)
              : const Color(0xFF3AB795);
          canvas.drawRRect(
            RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
            Paint()..color = frontColor,
          );

          // Card value
          if (scaleX > 0.3) {
            final textPaint = TextPaint(
              style: TextStyle(
                fontSize: (cell * 0.4).clamp(16, 28),
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
            textPaint.render(
              canvas,
              values[i].toString(),
              Vector2(
                cellRect.center.dx - (cell * 0.1),
                cellRect.center.dy - (cell * 0.15),
              ),
            );
          }
        } else {
          // Back face with pattern
          canvas.drawRRect(
            RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
            Paint()..color = const Color(0xFF2A3442),
          );

          // Pattern on back
          if (scaleX > 0.5) {
            final patternPaint = Paint()
              ..color = const Color(0xFF3A4452)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                cellRect.deflate(6),
                const Radius.circular(4),
              ),
              patternPaint,
            );

            // Question mark
            final qPaint = TextPaint(
              style: TextStyle(
                fontSize: (cell * 0.3).clamp(14, 24),
                color: const Color(0xFF4A5462),
                fontWeight: FontWeight.bold,
              ),
            );
            qPaint.render(
              canvas,
              '?',
              Vector2(
                cellRect.center.dx - (cell * 0.08),
                cellRect.center.dy - (cell * 0.12),
              ),
            );
          }
        }
      }
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life * 1.5,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (hideTimer > 0) return;
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    final i = idx(r, c, n);
    if (matched[i] || revealed[i]) return;
    revealed[i] = true;

    if (first == null) {
      first = i;
    } else if (second == null) {
      second = i;
      if (values[first!] == values[second!]) {
        matched[first!] = true;
        matched[second!] = true;
        matchScale[first!] = 1.3;
        matchScale[second!] = 1.3;

        // Spawn particles
        final cellSize = rect.width / n;
        _spawnMatchParticles(
          Offset(
            rect.left + (first! % n) * cellSize + cellSize / 2,
            rect.top + (first! ~/ n) * cellSize + cellSize / 2,
          ),
        );
        _spawnMatchParticles(
          Offset(
            rect.left + (second! % n) * cellSize + cellSize / 2,
            rect.top + (second! ~/ n) * cellSize + cellSize / 2,
          ),
        );

        first = null;
        second = null;
      } else {
        hideTimer = 1.0;
        showingMismatch = true;
      }
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
    velocity = velocity * 0.94;
    life -= dt * 1.5;
  }
}
