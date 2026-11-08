import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../core/util.dart';

class MiniSudokuGame extends MiniGame {
  @override
  String get name => 'Mini Sudoku';

  @override
  String get instructions => 'Fill 1-4. Long-press to clear.';

  final Random _rng = Random();
  late List<int> puzzle;
  late List<int> solution;
  late List<bool> fixed;

  final List<List<int>> _puzzlesEasy = [
    [0, 0, 3, 4, 3, 4, 0, 0, 0, 0, 4, 3, 4, 3, 0, 0],
    [1, 0, 0, 4, 0, 0, 1, 0, 0, 4, 0, 0, 2, 0, 0, 3],
    [0, 2, 0, 0, 0, 0, 4, 3, 4, 3, 0, 0, 0, 0, 2, 0],
  ];
  final List<List<int>> _puzzlesMedium = [
    [0, 0, 0, 4, 3, 4, 0, 0, 0, 0, 4, 0, 4, 0, 0, 0],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 4, 0, 0, 2, 0, 0, 0],
    [0, 2, 0, 0, 0, 0, 4, 0, 4, 0, 0, 0, 0, 0, 2, 0],
  ];
  final List<List<int>> _puzzlesHard = [
    [0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 3],
    [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0],
  ];
  final List<List<int>> _solutions = [
    [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
    [1, 2, 3, 4, 3, 4, 1, 2, 2, 4, 3, 1, 2, 1, 4, 3],
    [1, 2, 3, 4, 3, 4, 4, 3, 4, 3, 1, 2, 2, 1, 2, 1],
  ];

  @override
  void reset(Vector2 size) {
    final List<List<int>> pool = switch (difficulty) {
      GameDifficulty.easy => _puzzlesEasy,
      GameDifficulty.medium => _puzzlesMedium,
      GameDifficulty.hard => _puzzlesHard,
    };
    final i = _rng.nextInt(pool.length);
    puzzle = List.from(pool[i]);
    solution = List.from(_solutions[i]);
    fixed = puzzle.map((v) => v != 0).toList();
  }

  @override
  bool get isSolved => puzzle.join(',') == solution.join(',');

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / 4;
    final border = Paint()
      ..color = const Color(0xFF8892A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fixedPaint = Paint()..color = const Color(0xFF1D2633);
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 20, color: Colors.white),
    );

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final i = idx(r, c, 4);
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell,
          rect.top + r * cell,
          cell,
          cell,
        );
        if (fixed[i]) {
          canvas.drawRect(cellRect, fixedPaint);
        }
        canvas.drawRect(cellRect, border);
        final v = puzzle[i];
        if (v != 0) {
          textPaint.render(
            canvas,
            v.toString(),
            Vector2(cellRect.center.dx - 6, cellRect.center.dy - 10),
          );
        }
      }
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / 4;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    final i = idx(r, c, 4);
    if (fixed[i]) return;
    puzzle[i] = puzzle[i] % 4 + 1;
  }

  @override
  void onLongPressDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / 4;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    final i = idx(r, c, 4);
    if (fixed[i]) return;
    puzzle[i] = 0;
  }
}
