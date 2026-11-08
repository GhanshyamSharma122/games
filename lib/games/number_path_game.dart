import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class NumberPathGame extends MiniGame {
  @override
  String get name => 'Number Path';

  @override
  String get instructions => 'Tap numbers in order (1..9).';

  int n = 3;
  late List<int> grid;
  int nextNumber = 1;
  final Random _rng = Random();

  @override
  void reset(Vector2 size) {
    // Progressive difficulty: increase grid size with level
    n = 2 + level;
    n = n.clamp(3, 7);

    grid = List.generate(n * n, (_) => 0);
    final path = _randomPath();
    for (int i = 0; i < path.length; i++) {
      grid[path[i]] = i + 1;
    }
    nextNumber = 1;
  }

  List<int> _randomPath() {
    final cells = List.generate(n * n, (i) => i);
    cells.shuffle(_rng);
    return cells;
  }

  @override
  bool get isSolved => nextNumber > n * n;

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    final paint = Paint()..color = const Color(0xFF1B2430);
    final border = Paint()
      ..color = const Color(0xFF2A3442)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 24, color: Colors.white),
    );
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell,
          rect.top + r * cell,
          cell,
          cell,
        );
        canvas.drawRect(cellRect, paint);
        canvas.drawRect(cellRect, border);
        final v = grid[idx(r, c, n)];
        textPaint.render(
          canvas,
          v.toString(),
          Vector2(cellRect.center.dx - 6, cellRect.center.dy - 12),
        );
      }
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
    if (grid[i] == nextNumber) {
      nextNumber++;
    } else {
      nextNumber = 1;
    }
  }
}
