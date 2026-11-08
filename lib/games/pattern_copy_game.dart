import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class PatternCopyGame extends MiniGame {
  @override
  String get name => 'Pattern Copy';

  @override
  String get instructions => 'Copy the pattern on the left!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 8;

  final Random _rng = Random();
  int n = 4;
  late List<bool> pattern;
  late List<bool> answer;
  int patternCount = 0;
  int targetPatterns = 3;

  @override
  void reset(Vector2 size) {
    n = 3 + level ~/ 2;
    n = n.clamp(3, 7);
    targetPatterns = 2 + level ~/ 3;
    patternCount = 0;
    _generatePattern();
  }

  void _generatePattern() {
    pattern = List.generate(n * n, (_) => _rng.nextBool());
    answer = List.generate(n * n, (_) => false);
  }

  @override
  bool get isSolved => patternCount >= targetPatterns;

  bool _checkMatch() {
    for (int i = 0; i < n * n; i++) {
      if (pattern[i] != answer[i]) return false;
    }
    return true;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final gridWidth = (rect.width - 30) / 2;
    final cellSize = gridWidth / n;

    // Pattern grid (left)
    final patternRect = Rect.fromLTWH(
      rect.left,
      rect.top + 40,
      gridWidth,
      gridWidth,
    );
    canvas.drawRect(patternRect, Paint()..color = const Color(0xFF2A3442));

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final cellRect = Rect.fromLTWH(
          patternRect.left + c * cellSize + 2,
          patternRect.top + r * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        );
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = pattern[idx(r, c, n)]
                ? const Color(0xFF2A9D8F)
                : const Color(0xFF1B2430),
        );
      }
    }

    // Answer grid (right)
    final answerRect = Rect.fromLTWH(
      rect.right - gridWidth,
      rect.top + 40,
      gridWidth,
      gridWidth,
    );
    canvas.drawRect(answerRect, Paint()..color = const Color(0xFF2A3442));

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final cellRect = Rect.fromLTWH(
          answerRect.left + c * cellSize + 2,
          answerRect.top + r * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        );
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = answer[idx(r, c, n)]
                ? const Color(0xFFE9C46A)
                : const Color(0xFF1B2430),
        );
      }
    }

    // Labels
    TextPaint(
      style: const TextStyle(fontSize: 14, color: Colors.white70),
    ).render(
      canvas,
      'Pattern',
      Vector2(patternRect.center.dx - 25, rect.top + 15),
    );
    TextPaint(
      style: const TextStyle(fontSize: 14, color: Colors.white70),
    ).render(
      canvas,
      'Your Copy',
      Vector2(answerRect.center.dx - 35, rect.top + 15),
    );

    // Progress
    TextPaint(style: const TextStyle(fontSize: 16, color: Colors.white)).render(
      canvas,
      '$patternCount / $targetPatterns',
      Vector2(rect.center.dx - 25, rect.bottom - 30),
    );

    // Check button
    final checkRect = Rect.fromCenter(
      center: Offset(rect.center.dx, answerRect.bottom + 40),
      width: 100,
      height: 40,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(checkRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF2A9D8F),
    );
    TextPaint(style: const TextStyle(fontSize: 16, color: Colors.white)).render(
      canvas,
      'CHECK',
      Vector2(checkRect.center.dx - 25, checkRect.center.dy - 8),
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved) return;

    final rect = boardRect(gameSize);
    final gridWidth = (rect.width - 30) / 2;
    final cellSize = gridWidth / n;

    // Check answer grid
    final answerRect = Rect.fromLTWH(
      rect.right - gridWidth,
      rect.top + 40,
      gridWidth,
      gridWidth,
    );
    if (answerRect.contains(Offset(position.x, position.y))) {
      final c = ((position.x - answerRect.left) / cellSize).floor();
      final r = ((position.y - answerRect.top) / cellSize).floor();
      if (r >= 0 && r < n && c >= 0 && c < n) {
        answer[idx(r, c, n)] = !answer[idx(r, c, n)];
      }
      return;
    }

    // Check button
    final checkRect = Rect.fromCenter(
      center: Offset(rect.center.dx, answerRect.bottom + 40),
      width: 100,
      height: 40,
    );
    if (checkRect.contains(Offset(position.x, position.y))) {
      if (_checkMatch()) {
        patternCount++;
        if (!isSolved) {
          _generatePattern();
        }
      } else {
        // Clear answer
        answer = List.generate(n * n, (_) => false);
      }
    }
  }
}
