import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class PathFillGame extends MiniGame {
  @override
  String get name => 'Path Fill';

  @override
  String get instructions => 'Create a path visiting all cells.';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 6;

  int n = 5;
  late List<Offset> path;

  @override
  void reset(Vector2 size) {
    // Level determines grid size: 3x3 at level 1, up to 8x8 at level 6
    n = 2 + level;
    n = n.clamp(3, 8);
    path = [const Offset(0, 0)];
  }

  @override
  bool get isSolved =>
      path.length == n * n &&
      path.last == Offset((n - 1).toDouble(), (n - 1).toDouble());

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    final border = Paint()
      ..color = const Color(0xFF2A3442)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final cellRect = Rect.fromLTWH(
          rect.left + c * cell,
          rect.top + r * cell,
          cell,
          cell,
        );
        canvas.drawRect(cellRect, border);
      }
    }
    final pathPaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final aPos = Offset(
        rect.left + (a.dx + 0.5) * cell,
        rect.top + (a.dy + 0.5) * cell,
      );
      final bPos = Offset(
        rect.left + (b.dx + 0.5) * cell,
        rect.top + (b.dy + 0.5) * cell,
      );
      canvas.drawLine(aPos, bPos, pathPaint);
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
    final cellPos = Offset(c.toDouble(), r.toDouble());
    if (path.isNotEmpty && path.last == cellPos) return;
    if (path.length >= 2 && path[path.length - 2] == cellPos) {
      path.removeLast();
      return;
    }
    if (path.contains(cellPos)) return;
    final last = path.last;
    final dist = (last.dx - cellPos.dx).abs() + (last.dy - cellPos.dy).abs();
    if (dist != 1) return;
    path.add(cellPos);
  }
}
