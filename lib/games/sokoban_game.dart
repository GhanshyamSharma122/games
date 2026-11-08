import 'dart:ui';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class SokobanGame extends MiniGame {
  @override
  String get name => 'Sokoban Push';

  @override
  String get instructions => 'Push box onto target. Swipe to move.';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final List<List<String>> allMaps = [
    ['#####', '#.P.#', '#.B.#', '#.T.#', '#####'],
    ['#####', '#P..#', '#.B.#', '#..T#', '#####'],
    ['######', '#P...#', '#.B..#', '#..T.#', '#....#', '######'],
    ['######', '#P.#.#', '#.B..#', '#..T.#', '#....#', '######'],
    [
      '#######',
      '#P....#',
      '#.B...#',
      '#..#..#',
      '#...T.#',
      '#.....#',
      '#######',
    ],
    [
      '#######',
      '#..P..#',
      '#.#B#.#',
      '#.....#',
      '#..T..#',
      '#.....#',
      '#######',
    ],
    [
      '########',
      '#P.....#',
      '#.B....#',
      '#..##..#',
      '#....T.#',
      '#......#',
      '########',
    ],
    [
      '########',
      '#P.#...#',
      '#.B.#..#',
      '#...#..#',
      '#..#T..#',
      '#......#',
      '########',
    ],
    [
      '########',
      '#P.....#',
      '#.#B#..#',
      '#.#.#..#',
      '#.#.T..#',
      '#......#',
      '########',
    ],
    [
      '#########',
      '#P......#',
      '#.##B##.#',
      '#.#...#.#',
      '#.#.T.#.#',
      '#.#...#.#',
      '#.......#',
      '#########',
    ],
  ];

  late int rows;
  late int cols;
  late List<List<String>> grid;
  late Offset player;
  late Offset box;
  late Offset target;

  // Animation
  Offset playerRender = Offset.zero;
  Offset boxRender = Offset.zero;
  List<_Particle> particles = [];
  double solvedAnim = 0;

  @override
  void reset(Vector2 size) {
    final mapIndex = (level - 1).clamp(0, allMaps.length - 1);
    final map = allMaps[mapIndex];
    rows = map.length;
    cols = map[0].length;
    grid = List.generate(rows, (r) => map[r].split(''));
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == 'P') {
          player = Offset(c.toDouble(), r.toDouble());
          grid[r][c] = '.';
        }
        if (grid[r][c] == 'B') {
          box = Offset(c.toDouble(), r.toDouble());
          grid[r][c] = '.';
        }
        if (grid[r][c] == 'T') {
          target = Offset(c.toDouble(), r.toDouble());
          grid[r][c] = '.';
        }
      }
    }
    playerRender = player;
    boxRender = box;
    solvedAnim = 0;
  }

  void _spawnDust(Offset pos) {
    final rng = Random();
    for (int i = 0; i < 5; i++) {
      particles.add(
        _Particle(
          pos:
              pos +
              Offset(rng.nextDouble() - 0.5, rng.nextDouble() - 0.5) * 0.5,
          vel: Offset((rng.nextDouble() - 0.5) * 2, -rng.nextDouble() * 2),
          life: 0.5,
          size: 0.1 + rng.nextDouble() * 0.1,
          color: Colors.white.withOpacity(0.5),
        ),
      );
    }
  }

  @override
  bool get isSolved => box == target;

  void _move(int dx, int dy) {
    final next = Offset(player.dx + dx, player.dy + dy);
    if (_isWall(next)) return;
    if (next == box) {
      final beyond = Offset(box.dx + dx, box.dy + dy);
      if (_isWall(beyond) || beyond == box) return;
      box = beyond;
      _spawnDust(box);
    }
    player = next;
    _spawnDust(player);
  }

  @override
  void update(double dt) {
    // Smooth movement
    playerRender += (player - playerRender) * dt * 15;
    boxRender += (box - boxRender) * dt * 10;

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (isSolved) solvedAnim += dt;
  }

  bool _isWall(Offset pos) {
    final r = pos.dy.toInt();
    final c = pos.dx.toInt();
    return grid[r][c] == '#';
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / cols;
    final wallPaint = Paint()..color = const Color(0xFF2A3442);
    final floorPaint = Paint()..color = const Color(0xFF1B2430);
    final playerPaint = Paint()..color = const Color(0xFF2A9D8F);
    final boxPaint = Paint()..color = const Color(0xFFE9C46A);
    final targetPaint = Paint()..color = const Color(0xFFE76F51);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell,
          rect.top + r * cell,
          cell,
          cell,
        );
        canvas.drawRect(cellRect, grid[r][c] == '#' ? wallPaint : floorPaint);
      }
    }
    final tRect = Rect.fromLTWH(
      rect.left + target.dx * cell + 8,
      rect.top + target.dy * cell + 8,
      cell - 16,
      cell - 16,
    );
    canvas.drawOval(tRect, targetPaint);

    // Draw box
    final bRect = Rect.fromLTWH(
      rect.left + boxRender.dx * cell + 6,
      rect.top + boxRender.dy * cell + 6,
      cell - 12,
      cell - 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bRect, const Radius.circular(6)),
      boxPaint,
    );
    // Box highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(bRect.deflate(4), const Radius.circular(4)),
      Paint()..color = Colors.white.withOpacity(0.2),
    );

    // Solved glow
    if (isSolved) {
      final glowSize = (sin(solvedAnim * 5) + 2) * 5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bRect.inflate(glowSize),
          const Radius.circular(10),
        ),
        Paint()
          ..color = const Color(0xFFE9C46A).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Draw Player
    final pRect = Rect.fromLTWH(
      rect.left + playerRender.dx * cell + 10,
      rect.top + playerRender.dy * cell + 10,
      cell - 20,
      cell - 20,
    );
    canvas.drawOval(pRect, playerPaint);
    // Player eyes
    canvas.drawCircle(
      pRect.center + const Offset(-6, -4),
      2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      pRect.center + const Offset(6, -4),
      2,
      Paint()..color = Colors.white,
    );

    // Particles
    for (final p in particles) {
      // Particles are in grid coords, map to screen
      final px = rect.left + p.pos.dx * cell + cell / 2;
      final py = rect.top + p.pos.dy * cell + cell / 2;
      canvas.drawCircle(
        Offset(px, py),
        p.size * cell * 0.5,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }
  }

  @override
  void onPanEnd(Vector2 velocity, Vector2 gameSize) {
    if (velocity.length < 100) return;
    if (velocity.x.abs() > velocity.y.abs()) {
      _move(velocity.x > 0 ? 1 : -1, 0);
    } else {
      _move(0, velocity.y > 0 ? 1 : -1);
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
