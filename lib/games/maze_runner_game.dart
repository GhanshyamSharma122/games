import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class MazeRunnerGame extends MiniGame {
  @override
  String get name => 'Maze Runner';

  @override
  String get instructions => 'Swipe to navigate through the maze!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 8;

  final Random _rng = Random();
  int n = 9;
  late List<bool> walls;
  late List<bool> rightWalls;
  late List<bool> bottomWalls;
  int playerPos = 0;
  int exitPos = 0;

  // Animation
  Offset playerRender = Offset.zero;
  List<Offset> trail = []; // Player trail
  List<_Particle> particles = [];
  double pulse = 0;
  double moveTimer = 0;

  @override
  void reset(Vector2 size) {
    n = 5 + level;
    n = n.clamp(5, 15);

    rightWalls = List.generate(n * n, (_) => true);
    bottomWalls = List.generate(n * n, (_) => true);
    trail = [];
    particles = [];
    pulse = 0;

    // Generate maze using recursive backtracker
    final visited = List.generate(n * n, (_) => false);
    final stack = <int>[];
    visited[0] = true;
    stack.add(0);

    while (stack.isNotEmpty) {
      final current = stack.last;
      final r = current ~/ n;
      final c = current % n;

      final neighbors = <int>[];
      if (r > 0 && !visited[idx(r - 1, c, n)]) neighbors.add(idx(r - 1, c, n));
      if (r < n - 1 && !visited[idx(r + 1, c, n)])
        neighbors.add(idx(r + 1, c, n));
      if (c > 0 && !visited[idx(r, c - 1, n)]) neighbors.add(idx(r, c - 1, n));
      if (c < n - 1 && !visited[idx(r, c + 1, n)])
        neighbors.add(idx(r, c + 1, n));

      if (neighbors.isEmpty) {
        stack.removeLast();
      } else {
        final next = neighbors[_rng.nextInt(neighbors.length)];
        final nr = next ~/ n;
        final nc = next % n;

        if (nr < r) bottomWalls[next] = false;
        if (nr > r) bottomWalls[current] = false;
        if (nc < c) rightWalls[next] = false;
        if (nc > c) rightWalls[current] = false;

        visited[next] = true;
        stack.add(next);
      }
    }

    playerPos = 0;
    exitPos = n * n - 1;
    playerRender = Offset(0, 0);
  }

  @override
  bool get isSolved => playerPos == exitPos;

  bool _canMove(int from, int to) {
    final fromR = from ~/ n;
    final fromC = from % n;
    final toR = to ~/ n;
    final toC = to % n;

    if (toR < 0 || toR >= n || toC < 0 || toC >= n) return false;

    if (toR < fromR) return !bottomWalls[to];
    if (toR > fromR) return !bottomWalls[from];
    if (toC < fromC) return !rightWalls[to];
    if (toC > fromC) return !rightWalls[from];

    return false;
  }

  @override
  void update(double dt) {
    moveTimer += dt;
    // Smooth move
    final target = Offset(
      (playerPos % n).toDouble(),
      (playerPos ~/ n).toDouble(),
    );
    playerRender += (target - playerRender) * dt * 10;

    // Trail
    if (trail.isEmpty || (trail.last - playerRender).distance > 0.1) {
      trail.add(playerRender);
      if (trail.length > 20) trail.removeAt(0);
    }

    pulse += dt * 5;

    // Solved particles
    if (isSolved && _rng.nextDouble() < 0.2) {
      particles.add(
        _Particle(
          pos: Offset(
            (exitPos % n).toDouble() + 0.5,
            (exitPos ~/ n).toDouble() + 0.5,
          ),
          vel: Offset((_rng.nextDouble() - 0.5) * 2, -_rng.nextDouble() * 3),
          life: 1.0,
          size: 0.2,
          color: const Color(0xFF2A9D8F),
        ),
      );
    }

    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      if (particles[i].life <= 0) particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cellSize = rect.width / n;

    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    final wallPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw walls
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final x = rect.left + c * cellSize;
        final y = rect.top + r * cellSize;
        final idxVal = idx(r, c, n);

        if (rightWalls[idxVal] && c < n - 1) {
          canvas.drawLine(
            Offset(x + cellSize, y),
            Offset(x + cellSize, y + cellSize),
            wallPaint,
          );
        }
        if (bottomWalls[idxVal] && r < n - 1) {
          canvas.drawLine(
            Offset(x, y + cellSize),
            Offset(x + cellSize, y + cellSize),
            wallPaint,
          );
        }
      }
    }

    // Border
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Exit
    final exitR = exitPos ~/ n;
    final exitC = exitPos % n;
    final exitCenter = Offset(
      rect.left + exitC * cellSize + cellSize / 2,
      rect.top + exitR * cellSize + cellSize / 2,
    );
    canvas.drawCircle(
      exitCenter,
      cellSize * 0.3 + sin(pulse) * 2,
      Paint()..color = const Color(0xFF2A9D8F),
    );

    // Trail
    for (final t in trail) {
      final tx = rect.left + t.dx * cellSize + cellSize / 2;
      final ty = rect.top + t.dy * cellSize + cellSize / 2;
      canvas.drawCircle(
        Offset(tx, ty),
        cellSize * 0.1,
        Paint()..color = const Color(0xFFE9C46A).withOpacity(0.3),
      );
    }

    // Player
    final px = rect.left + playerRender.dx * cellSize + cellSize / 2;
    final py = rect.top + playerRender.dy * cellSize + cellSize / 2;

    canvas.drawCircle(
      Offset(px, py),
      cellSize * 0.3,
      Paint()..color = const Color(0xFFE9C46A),
    );

    // Particles
    for (final p in particles) {
      final px = rect.left + p.pos.dx * cellSize;
      final py = rect.top + p.pos.dy * cellSize;
      canvas.drawCircle(
        Offset(px, py),
        p.size * cellSize,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    if (isSolved) return;
    if (moveTimer < 0.12) return; // Cooldown

    if (delta.length < 3) return;

    bool moved = false;
    final r = playerPos ~/ n;
    final c = playerPos % n;

    if (delta.x.abs() > delta.y.abs()) {
      // Horizontal
      final newC = c + (delta.x > 0 ? 1 : -1);
      final newPos = idx(r, newC, n);
      if (newC >= 0 && newC < n && _canMove(playerPos, newPos)) {
        playerPos = newPos;
        moved = true;
      }
    } else {
      // Vertical
      final newR = r + (delta.y > 0 ? 1 : -1);
      final newPos = idx(newR, c, n);
      if (newR >= 0 && newR < n && _canMove(playerPos, newPos)) {
        playerPos = newPos;
        moved = true;
      }
    }

    if (moved) moveTimer = 0;
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
