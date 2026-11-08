import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../core/util.dart';

class RotateMatchGame extends MiniGame {
  @override
  String get name => 'Rotate Match';

  @override
  String get instructions => 'Rotate tiles so edges match.';

  int n = 4;
  final Random _rng = Random();
  late List<List<int>> edges; // [up,right,down,left]
  late List<int> rotation;

  @override
  void reset(Vector2 size) {
    n = switch (difficulty) {
      GameDifficulty.easy => 3,
      GameDifficulty.medium => 4,
      GameDifficulty.hard => 5,
    };
    edges = List.generate(n * n, (_) => [0, 0, 0, 0]);
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final up = r == 0 ? _rng.nextInt(3) : edges[idx(r - 1, c, n)][2];
        final left = c == 0 ? _rng.nextInt(3) : edges[idx(r, c - 1, n)][1];
        final right = _rng.nextInt(3);
        final down = _rng.nextInt(3);
        edges[i] = [up, right, down, left];
      }
    }
    rotation = List.generate(n * n, (_) => _rng.nextInt(4));
  }

  List<int> _rotEdges(int i) {
    final base = edges[i];
    int rot = rotation[i];
    var e = List<int>.from(base);
    for (int k = 0; k < rot; k++) {
      e = [e[3], e[0], e[1], e[2]];
    }
    return e;
  }

  @override
  bool get isSolved {
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final e = _rotEdges(i);
        if (r > 0) {
          final up = _rotEdges(idx(r - 1, c, n));
          if (e[0] != up[2]) return false;
        }
        if (c > 0) {
          final left = _rotEdges(idx(r, c - 1, n));
          if (e[3] != left[1]) return false;
        }
      }
    }
    return true;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    final tilePaint = Paint()..color = const Color(0xFF1B2430);
    final colors = [
      const Color(0xFFE76F51),
      const Color(0xFFE9C46A),
      const Color(0xFF2A9D8F),
    ];

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell + 4,
          rect.top + r * cell + 4,
          cell - 8,
          cell - 8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
          tilePaint,
        );
        final e = _rotEdges(i);
        final center = cellRect.center;
        final len = cell * 0.35;
        void drawEdge(int side, int colorIdx) {
          final paint = Paint()
            ..color = colors[colorIdx]
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round;
          Offset b = center;
          if (side == 0) b = Offset(center.dx, center.dy - len);
          if (side == 1) b = Offset(center.dx + len, center.dy);
          if (side == 2) b = Offset(center.dx, center.dy + len);
          if (side == 3) b = Offset(center.dx - len, center.dy);
          canvas.drawLine(center, b, paint);
        }

        for (int s = 0; s < 4; s++) {
          drawEdge(s, e[s]);
        }
      }
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
    rotation[i] = (rotation[i] + 1) % 4;
  }
}
