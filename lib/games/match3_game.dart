import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class Match3Game extends MiniGame {
  @override
  String get name => 'Match-3';

  @override
  String get instructions => 'Swap adjacent tiles to match 3.';

  int n = 6;
  int colors = 5;
  int matchesNeeded = 10;
  int matchesMade = 0;
  final Random _rng = Random();
  late List<int> grid;
  late List<double> tileScale; // Scale animation
  late List<double> tileShake; // Shake when selected
  late List<double> tileY; // Drop animation offset
  int? selected;
  double selectedPulse = 0;
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    colors = 3 + level;
    colors = colors.clamp(3, 7);

    n = 5 + ((level - 1) ~/ 2);
    n = n.clamp(5, 8);

    matchesNeeded = 5 + level * 3;
    matchesMade = 0;

    grid = List.generate(n * n, (_) => _rng.nextInt(colors));
    tileScale = List.generate(n * n, (_) => 1.0);
    tileShake = List.generate(n * n, (_) => 0.0);
    tileY = List.generate(n * n, (_) => 0.0);
    _resolveMatches();
    selected = null;
    selectedPulse = 0;
    particles = [];
  }

  @override
  bool get isSolved => matchesMade >= matchesNeeded;

  @override
  void update(double dt) {
    selectedPulse += dt * 6;

    // Animate tile scales
    for (int i = 0; i < n * n; i++) {
      if (tileScale[i] < 1.0) {
        tileScale[i] += dt * 4;
        if (tileScale[i] > 1.0) tileScale[i] = 1.0;
      }
      if (tileY[i] > 0) {
        tileY[i] -= dt * 300;
        if (tileY[i] < 0) tileY[i] = 0;
      }
      if (tileShake[i] != 0) {
        tileShake[i] *= 0.85;
        if (tileShake[i].abs() < 0.5) tileShake[i] = 0;
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }
  }

  void _spawnMatchParticles(Offset center, int color) {
    final colorsPaint = [
      const Color(0xFFE76F51),
      const Color(0xFFE9C46A),
      const Color(0xFF2A9D8F),
      const Color(0xFF264653),
      const Color(0xFFF4A261),
      const Color(0xFF6D597A),
      const Color(0xFFB56576),
    ];
    final particleColor = colorsPaint[color % colorsPaint.length];

    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 50 + _rng.nextDouble() * 60;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: particleColor,
          size: 4 + _rng.nextDouble() * 3,
          life: 0.5,
        ),
      );
    }
  }

  void _resolveMatches() {
    bool changed;
    do {
      changed = false;
      final toClear = List.generate(n * n, (_) => false);
      for (int r = 0; r < n; r++) {
        int run = 1;
        for (int c = 1; c < n; c++) {
          if (grid[idx(r, c, n)] == grid[idx(r, c - 1, n)]) {
            run++;
          } else {
            if (run >= 3) {
              for (int k = 0; k < run; k++) {
                toClear[idx(r, c - 1 - k, n)] = true;
              }
              matchesMade++;
            }
            run = 1;
          }
        }
        if (run >= 3) {
          for (int k = 0; k < run; k++) {
            toClear[idx(r, n - 1 - k, n)] = true;
          }
          matchesMade++;
        }
      }
      for (int c = 0; c < n; c++) {
        int run = 1;
        for (int r = 1; r < n; r++) {
          if (grid[idx(r, c, n)] == grid[idx(r - 1, c, n)]) {
            run++;
          } else {
            if (run >= 3) {
              for (int k = 0; k < run; k++) {
                toClear[idx(r - 1 - k, c, n)] = true;
              }
              matchesMade++;
            }
            run = 1;
          }
        }
        if (run >= 3) {
          for (int k = 0; k < run; k++) {
            toClear[idx(n - 1 - k, c, n)] = true;
          }
          matchesMade++;
        }
      }

      for (int c = 0; c < n; c++) {
        int write = n - 1;
        int dropHeight = 0;
        for (int r = n - 1; r >= 0; r--) {
          final i = idx(r, c, n);
          if (!toClear[i]) {
            grid[idx(write, c, n)] = grid[i];
            tileY[idx(write, c, n)] = dropHeight * 50.0;
            write--;
          } else {
            changed = true;
            dropHeight++;
          }
        }
        while (write >= 0) {
          grid[idx(write, c, n)] = _rng.nextInt(colors);
          tileScale[idx(write, c, n)] = 0.0;
          tileY[idx(write, c, n)] = (n - write) * 50.0;
          write--;
        }
      }
    } while (changed);
  }

  bool _isMatchAfterSwap(int a, int b) {
    final temp = grid[a];
    grid[a] = grid[b];
    grid[b] = temp;
    bool match = _hasMatchAt(a) || _hasMatchAt(b);
    grid[b] = grid[a];
    grid[a] = temp;
    return match;
  }

  bool _hasMatchAt(int i) {
    final r = i ~/ n;
    final c = i % n;
    final v = grid[i];
    int count = 1;
    for (int cc = c - 1; cc >= 0 && grid[idx(r, cc, n)] == v; cc--) {
      count++;
    }
    for (int cc = c + 1; cc < n && grid[idx(r, cc, n)] == v; cc++) {
      count++;
    }
    if (count >= 3) return true;
    count = 1;
    for (int rr = r - 1; rr >= 0 && grid[idx(rr, c, n)] == v; rr--) {
      count++;
    }
    for (int rr = r + 1; rr < n && grid[idx(rr, c, n)] == v; rr++) {
      count++;
    }
    return count >= 3;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    final colorsPaint = [
      const Color(0xFFE76F51),
      const Color(0xFFE9C46A),
      const Color(0xFF2A9D8F),
      const Color(0xFF264653),
      const Color(0xFFF4A261),
      const Color(0xFF6D597A),
      const Color(0xFFB56576),
    ];

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF1B2430),
    );

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final scale = tileScale[i];
        final shake = tileShake[i];
        final dropY = tileY[i];

        final baseRect = Rect.fromLTWH(
          rect.left + c * cell + 3 + shake,
          rect.top + r * cell + 3 - dropY,
          cell - 6,
          cell - 6,
        );
        final cellRect = Rect.fromCenter(
          center: baseRect.center,
          width: baseRect.width * scale,
          height: baseRect.height * scale,
        );

        // Shadow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            cellRect.translate(2, 2),
            const Radius.circular(8),
          ),
          Paint()..color = Colors.black.withOpacity(0.2),
        );

        final paint = Paint()
          ..color = colorsPaint[grid[i] % colorsPaint.length];
        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
          paint,
        );

        // Highlight
        final highlightRect = Rect.fromLTWH(
          cellRect.left + 3,
          cellRect.top + 3,
          cellRect.width - 6,
          cellRect.height * 0.3,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(4)),
          Paint()..color = Colors.white.withOpacity(0.2),
        );

        // Selection animation
        if (selected == i) {
          final pulse = sin(selectedPulse) * 0.1 + 1.0;
          final selectRect = Rect.fromCenter(
            center: cellRect.center,
            width: cellRect.width * pulse,
            height: cellRect.height * pulse,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(selectRect, const Radius.circular(10)),
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    final i = idx(r, c, n);

    tileScale[i] = 0.8;

    if (selected == null) {
      selected = i;
      return;
    }
    if (selected == i) {
      selected = null;
      return;
    }
    final sr = selected! ~/ n;
    final sc = selected! % n;
    if ((sr - r).abs() + (sc - c).abs() != 1) {
      selected = i;
      return;
    }
    if (_isMatchAfterSwap(selected!, i)) {
      // Swap animation
      final temp = grid[selected!];
      grid[selected!] = grid[i];
      grid[i] = temp;

      _spawnMatchParticles(
        Offset(rect.left + c * cell + cell / 2, rect.top + r * cell + cell / 2),
        grid[i],
      );

      _resolveMatches();
    } else {
      // Shake on invalid swap
      tileShake[selected!] = 8;
      tileShake[i] = 8;
    }
    selected = null;
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
    life -= dt * 2;
  }
}
