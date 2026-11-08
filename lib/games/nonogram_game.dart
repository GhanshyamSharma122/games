import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class NonogramGame extends MiniGame {
  @override
  String get name => 'Nonogram';

  @override
  String get instructions => 'Fill cells to match row/col clues.';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 8;

  int n = 5;
  final Random _rng = Random();
  late List<bool> solution;
  late List<int> state; // 0 unknown, 1 filled, 2 empty

  // Animation
  List<double> cellOpacities = [];

  @override
  void reset(Vector2 size) {
    // Level determines grid size: 3x3 at level 1, up to 10x10 at level 8
    n = 2 + level;
    n = n.clamp(3, 10);

    solution = List.generate(n * n, (_) => _rng.nextBool());
    if (solution.every((v) => !v)) {
      solution[_rng.nextInt(n * n)] = true;
    }
    state = List.generate(n * n, (_) => 0);
    cellOpacities = List.generate(n * n, (_) => 0.0);
  }

  @override
  bool get isSolved {
    for (int i = 0; i < n * n; i++) {
      final shouldFill = solution[i];
      if (shouldFill && state[i] != 1) return false;
      if (!shouldFill && state[i] == 1) return false;
    }
    return true;
  }

  @override
  void update(double dt) {
    for (int i = 0; i < n * n; i++) {
      if (state[i] != 0 && cellOpacities[i] < 1.0) {
        cellOpacities[i] += dt * 5;
        if (cellOpacities[i] > 1.0) cellOpacities[i] = 1.0;
      } else if (state[i] == 0 && cellOpacities[i] > 0.0) {
        // Fade out if cleared (though 3-step cycle usually feels distinct, nice to have smooth transition)
        cellOpacities[i] -= dt * 5;
        if (cellOpacities[i] < 0.0) cellOpacities[i] = 0.0;
      }
    }
  }

  List<int> _clueRow(int r) {
    final clues = <int>[];
    int run = 0;
    for (int c = 0; c < n; c++) {
      final v = solution[idx(r, c, n)];
      if (v) {
        run++;
      } else if (run > 0) {
        clues.add(run);
        run = 0;
      }
    }
    if (run > 0) clues.add(run);
    if (clues.isEmpty) clues.add(0);
    return clues;
  }

  List<int> _clueCol(int c) {
    final clues = <int>[];
    int run = 0;
    for (int r = 0; r < n; r++) {
      final v = solution[idx(r, c, n)];
      if (v) {
        run++;
      } else if (run > 0) {
        clues.add(run);
        run = 0;
      }
    }
    if (run > 0) clues.add(run);
    if (clues.isEmpty) clues.add(0);
    return clues;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    // final fillPaint = Paint()..color = const Color(0xFF2A9D8F); // moved inside for opacity
    // final emptyPaint = Paint()..color = const Color(0xFF1B2430);
    final border = Paint()
      ..color = const Color(0xFF3A4452)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 12, color: Colors.white),
    );

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell,
          rect.top + r * cell,
          cell,
          cell,
        );
        final st = state[i];
        final opacity = cellOpacities[i];

        // Draw background first? default empty

        if (st == 1) {
          // Fill
          canvas.drawRect(
            cellRect,
            Paint()..color = const Color(0xFF2A9D8F).withOpacity(opacity),
          );
        } else if (st == 2) {
          // Mark X
          // For X, maybe fade in X stroke?
          // Using empty paint background logic from original:
          canvas.drawRect(cellRect, Paint()..color = const Color(0xFF1B2430));

          final xBorder = Paint()
            ..color = const Color(0xFFE76F51).withValues(alpha: opacity)
            ..strokeWidth = 2;

          canvas.drawLine(
            cellRect.topLeft + const Offset(4, 4),
            cellRect.bottomRight - const Offset(4, 4),
            xBorder,
          );
          canvas.drawLine(
            cellRect.bottomLeft + const Offset(4, -4),
            cellRect.topRight - const Offset(4, -4),
            xBorder,
          );
        }

        canvas.drawRect(cellRect, border);
      }
    }

    for (int r = 0; r < n; r++) {
      final clues = _clueRow(r).join(' ');
      textPaint.render(
        canvas,
        clues,
        Vector2(rect.left - 28, rect.top + r * cell + 8),
      );
    }
    for (int c = 0; c < n; c++) {
      final clues = _clueCol(c).join(' ');
      textPaint.render(
        canvas,
        clues,
        Vector2(rect.left + c * cell + 4, rect.top - 18),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved) return;

    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    final i = idx(r, c, n);

    state[i] = (state[i] + 1) % 3;
    cellOpacities[i] = 0.0; // Reset opacity to animate in new state
  }
}
