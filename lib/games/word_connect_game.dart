import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../core/util.dart';

class WordConnectGame extends MiniGame {
  @override
  String get name => 'Word Connect';

  @override
  String get instructions => 'Form words by tapping adjacent letters.';

  int n = 4;
  late List<String> words;
  final Random _rng = Random();
  late List<String> grid;
  late Set<String> found;
  List<int> path = [];

  @override
  void reset(Vector2 size) {
    switch (difficulty) {
      case GameDifficulty.easy:
        n = 4;
        words = ['CODE', 'GAME'];
        break;
      case GameDifficulty.medium:
        n = 4;
        words = ['CODE', 'GAME', 'PLAY'];
        break;
      case GameDifficulty.hard:
        n = 5;
        words = ['FLAME', 'LOGIC', 'PLAYS'];
        break;
    }
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    grid = List.filled(n * n, '');
    for (int i = 0; i < words.length && i < n; i++) {
      final word = words[i];
      for (int c = 0; c < word.length; c++) {
        grid[idx(i, c, n)] = word[c];
      }
    }
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].isEmpty) {
        grid[i] = letters[_rng.nextInt(letters.length)];
      }
    }
    found = <String>{};
    path = [];
  }

  @override
  bool get isSolved => found.length == words.length;

  String _currentWord() {
    return path.map((i) => grid[i]).join();
  }

  void _handleCell(int r, int c) {
    final i = idx(r, c, n);
    if (path.isEmpty) {
      path.add(i);
      return;
    }
    if (path.contains(i)) return;
    final last = path.last;
    final lr = last ~/ n;
    final lc = last % n;
    if ((lr - r).abs() + (lc - c).abs() != 1) {
      path = [i];
      return;
    }
    path.add(i);
    final word = _currentWord();
    if (words.contains(word)) {
      found.add(word);
      path = [];
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    final tile = Paint()..color = const Color(0xFF1B2430);
    final border = Paint()
      ..color = const Color(0xFF2A3442)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 20, color: Colors.white),
    );
    final selectPaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell,
          rect.top + r * cell,
          cell,
          cell,
        );
        canvas.drawRect(cellRect, tile);
        canvas.drawRect(cellRect, border);
        if (path.contains(i)) {
          canvas.drawRect(cellRect, selectPaint);
        }
        textPaint.render(
          canvas,
          grid[i],
          Vector2(cellRect.center.dx - 6, cellRect.center.dy - 10),
        );
      }
    }
    final text = 'Found: ${found.join(', ')}';
    TextPaint(
      style: const TextStyle(fontSize: 14, color: Colors.white70),
    ).render(canvas, text, Vector2(rect.left, rect.bottom + 8));
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    _handleCell(r, c);
  }

  @override
  void onLongPressDown(Vector2 position, Vector2 gameSize) {
    path = [];
  }

  @override
  void onPanStart(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    _handleCell(r, c);
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    _handleCell(r, c);
  }

  @override
  void onPanEnd(Vector2 velocity, Vector2 gameSize) {}
}
