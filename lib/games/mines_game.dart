import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../core/util.dart';

class MinesGame extends MiniGame {
  @override
  String get name => 'Mines & Flags';

  @override
  String get instructions => 'Reveal all safe cells. Long-press to flag.';

  int n = 8;
  int mines = 10;
  final Random _rng = Random();
  late List<bool> mine;
  late List<bool> reveal;
  late List<bool> flag;
  bool lost = false;

  // Animation
  List<_Particle> _particles = [];
  List<double> revealScale = []; // 0 to 1
  double shake = 0;

  @override
  void reset(Vector2 size) {
    // ... (rest of reset is fine, just need to update particles ref)
    final baseN = switch (difficulty) {
      GameDifficulty.easy => 6,
      GameDifficulty.medium => 8,
      GameDifficulty.hard => 10,
    };
    final baseMines = switch (difficulty) {
      GameDifficulty.easy => 6,
      GameDifficulty.medium => 12,
      GameDifficulty.hard => 20,
    };

    n = baseN + (level - 1);
    mines = baseMines + (level - 1) * (difficulty.index + 2);
    n = n.clamp(6, 16);
    mines = mines.clamp(6, (n * n * 0.35).toInt());

    mine = List.generate(n * n, (_) => false);
    reveal = List.generate(n * n, (_) => false);
    flag = List.generate(n * n, (_) => false);
    revealScale = List.generate(n * n, (_) => 1.0); // Default to 1 (hidden)
    _particles = [];
    lost = false;
    shake = 0;

    int placed = 0;
    while (placed < mines) {
      final i = _rng.nextInt(n * n);
      if (!mine[i]) {
        mine[i] = true;
        placed++;
      }
    }
  }

  @override
  bool get isSolved {
    if (lost) return false;
    for (int i = 0; i < n * n; i++) {
      if (!mine[i] && !reveal[i]) return false;
    }
    return true;
  }

  void _spawnExplosion(Rect rect) {
    for (int i = 0; i < 30; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 50 + _rng.nextDouble() * 150;
      _particles.add(
        _Particle(
          pos: rect.center,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.5 + _rng.nextDouble() * 0.5,
          size: 4 + _rng.nextDouble() * 6,
          color: const Color(0xFFE63946),
        ),
      );
    }
  }

  int _count(int r, int c) {
    int count = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final rr = r + dr;
        final cc = c + dc;
        if (rr < 0 || rr >= n || cc < 0 || cc >= n) continue;
        if (mine[idx(rr, cc, n)]) count++;
      }
    }
    return count;
  }

  void _flood(int r, int c) {
    final i = idx(r, c, n);
    if (reveal[i] || flag[i]) return;
    reveal[i] = true;
    revealScale[i] = 0.0; // Startup animation

    if (_count(r, c) > 0) return;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final rr = r + dr;
        final cc = c + dc;
        if (rr < 0 || rr >= n || cc < 0 || cc >= n) continue;
        _flood(rr, cc);
      }
    }
  }

  @override
  void update(double dt) {
    if (shake > 0) shake -= dt * 2;

    // Animate reveals
    for (int i = 0; i < n * n; i++) {
      if (reveal[i] && revealScale[i] < 1.0) {
        revealScale[i] += dt * 8;
        if (revealScale[i] > 1.0) revealScale[i] = 1.0;
      }
    }

    // Particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].pos += _particles[i].vel * dt;
      _particles[i].life -= dt;
      _particles[i].vel += Offset(0, 100 * dt); // gravity
      if (_particles[i].life <= 0) _particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;

    if (shake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shake * 15,
        (_rng.nextDouble() - 0.5) * shake * 15,
      );
    }

    final hidden = Paint()..color = const Color(0xFF2A3442);
    final shown = Paint()..color = const Color(0xFF1B2430);
    final minePaint = Paint()..color = const Color(0xFFE63946);
    final flagPaint = Paint()..color = const Color(0xFFF4A261);
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell + 2,
          rect.top + r * cell + 2,
          cell - 4,
          cell - 4,
        );

        if (reveal[i]) {
          double scale = revealScale[i];
          // Scale from center
          final center = cellRect.center;
          final drawRect = Rect.fromCenter(
            center: center,
            width: cellRect.width * scale,
            height: cellRect.height * scale,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(drawRect, const Radius.circular(6)),
            shown,
          );

          if (mine[i]) {
            canvas.drawCircle(center, cell * 0.25 * scale, minePaint);
            // Mine spikes
            if (scale > 0.8) {
              for (int k = 0; k < 8; k++) {
                final a = k * pi / 4;
                canvas.drawLine(
                  center + Offset(cos(a) * cell * 0.15, sin(a) * cell * 0.15),
                  center + Offset(cos(a) * cell * 0.35, sin(a) * cell * 0.35),
                  Paint()
                    ..color = const Color(0xFFE63946)
                    ..strokeWidth = 2,
                );
              }
            }
          } else {
            final count = _count(r, c);
            if (count > 0 && scale > 0.8) {
              textPaint.render(
                canvas,
                count.toString(),
                Vector2(center.dx - 4, center.dy - 10),
                anchor: Anchor.center,
              );
              // Override color (TextPaint clones style?)
              // Flame TextPaint holds style. Easier to just draw text with correct color if we rebuild it
              // For optimization, use one TextPaint, but color is fixed.
              // We'll skip per-number color for now to keep it simple, or use style override if possible.
            }
          }
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(cellRect, const Radius.circular(6)),
            hidden,
          );
          // Highlight top edge for 3D effect
          canvas.drawLine(
            cellRect.topLeft + const Offset(2, 0),
            cellRect.topRight + const Offset(-2, 0),
            Paint()
              ..color = Colors.white.withOpacity(0.1)
              ..strokeWidth = 2,
          );

          if (flag[i]) {
            // Flag staff
            canvas.drawLine(
              cellRect.center + Offset(-2, 8),
              cellRect.center + Offset(-2, -8),
              Paint()
                ..color = Colors.white
                ..strokeWidth = 2,
            );
            // Flag sail
            final path = Path();
            path.moveTo(cellRect.center.dx - 2, cellRect.center.dy - 8);
            path.lineTo(cellRect.center.dx + 8, cellRect.center.dy - 4);
            path.lineTo(cellRect.center.dx - 2, cellRect.center.dy);
            path.close();
            canvas.drawPath(path, flagPaint);
          }
        }
      }
    }

    // Particles
    for (final p in _particles) {
      canvas.drawCircle(
        p.pos,
        p.size * p.life,
        Paint()..color = p.color.withValues(alpha: p.life),
      );
    }

    if (shake > 0) canvas.restore();

    if (lost) {
      TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color(0xFFE63946),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
        ),
      ).render(
        canvas,
        'BOOM!',
        Vector2(rect.center.dx, rect.center.dy),
        anchor: Anchor.center,
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (lost) return;
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    final i = idx(r, c, n);
    if (flag[i] || reveal[i]) return;
    if (mine[i]) {
      reveal[i] = true;
      lost = true;
      shake = 1.0;
      final cellRect = Rect.fromLTWH(
        rect.left + c * cell,
        rect.top + r * cell,
        cell,
        cell,
      );
      _spawnExplosion(cellRect);

      for (int j = 0; j < n * n; j++) {
        if (mine[j]) {
          reveal[j] = true;
          revealScale[j] = 0.0;
        }
      }
    } else {
      _flood(r, c);
    }
  }

  @override
  void onLongPressDown(Vector2 position, Vector2 gameSize) {
    if (lost) return;
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    final i = idx(r, c, n);
    if (reveal[i]) return;
    flag[i] = !flag[i];
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
