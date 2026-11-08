import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:games/core/util.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';

class FlowConnectGame extends MiniGame {
  @override
  String get name => 'Flow Connect';

  @override
  String get instructions => 'Connect same-color pairs without crossing.';

  int n = 5;
  final List<Color> colors = [
    const Color(0xFFE76F51),
    const Color(0xFFE9C46A),
    const Color(0xFF2A9D8F),
    const Color(0xFF264653),
  ];
  late List<Offset> starts;
  late List<Offset> ends;
  late List<List<Offset>> paths;
  int? active;

  @override
  void reset(Vector2 size) {
    switch (difficulty) {
      case GameDifficulty.easy:
        n = 4;
        starts = [const Offset(0, 0), const Offset(3, 0)];
        ends = [const Offset(3, 3), const Offset(0, 3)];
        break;
      case GameDifficulty.medium:
        n = 5;
        starts = [const Offset(0, 0), const Offset(4, 0), const Offset(1, 4)];
        ends = [const Offset(4, 4), const Offset(0, 4), const Offset(3, 2)];
        break;
      case GameDifficulty.hard:
        n = 6;
        starts = [
          const Offset(0, 0),
          const Offset(5, 0),
          const Offset(0, 5),
          const Offset(2, 2),
        ];
        ends = [
          const Offset(5, 5),
          const Offset(0, 5),
          const Offset(5, 2),
          const Offset(3, 4),
        ];
        break;
    }
    paths = List.generate(starts.length, (_) => []);
    active = null;
  }

  @override
  bool get isSolved {
    for (int i = 0; i < starts.length; i++) {
      if (paths[i].isEmpty) return false;
      if (paths[i].first != starts[i] || paths[i].last != ends[i]) return false;
    }
    return true;
  }

  bool _isOccupied(Offset cell, {int? ignore}) {
    for (int i = 0; i < paths.length; i++) {
      if (ignore != null && i == ignore) continue;
      if (paths[i].contains(cell)) return true;
    }
    return false;
  }

  void _handleCell(Offset cellPos) {
    for (int i = 0; i < starts.length; i++) {
      if (cellPos == starts[i] || cellPos == ends[i]) {
        active = i;
        paths[i] = [cellPos];
        return;
      }
    }
    if (active == null) return;
    final path = paths[active!];
    if (path.isNotEmpty && path.last == cellPos) return;
    if (path.isNotEmpty) {
      final last = path.last;
      final dist = (last.dx - cellPos.dx).abs() + (last.dy - cellPos.dy).abs();
      if (dist != 1) return;
      if (_isOccupied(cellPos, ignore: active)) return;
    }
    path.add(cellPos);
  }

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

    for (int i = 0; i < paths.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      final path = paths[i];
      for (int j = 0; j < path.length - 1; j++) {
        final a = path[j];
        final b = path[j + 1];
        final aPos = Offset(
          rect.left + (a.dx + 0.5) * cell,
          rect.top + (a.dy + 0.5) * cell,
        );
        final bPos = Offset(
          rect.left + (b.dx + 0.5) * cell,
          rect.top + (b.dy + 0.5) * cell,
        );
        canvas.drawLine(aPos, bPos, paint);
      }
    }

    for (int i = 0; i < starts.length; i++) {
      final paint = Paint()..color = colors[i];
      final s = starts[i];
      final e = ends[i];
      final sRect = Rect.fromCircle(
        center: Offset(
          rect.left + (s.dx + 0.5) * cell,
          rect.top + (s.dy + 0.5) * cell,
        ),
        radius: cell * 0.18,
      );
      final eRect = Rect.fromCircle(
        center: Offset(
          rect.left + (e.dx + 0.5) * cell,
          rect.top + (e.dy + 0.5) * cell,
        ),
        radius: cell * 0.18,
      );
      canvas.drawOval(sRect, paint);
      canvas.drawOval(eRect, paint);
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
    _handleCell(Offset(c.toDouble(), r.toDouble()));
  }

  @override
  void onPanStart(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    _handleCell(Offset(c.toDouble(), r.toDouble()));
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final pos = position;
    final cell = rect.width / n;
    if (!rect.contains(Offset(pos.x, pos.y))) return;
    final c = ((pos.x - rect.left) / cell).floor();
    final r = ((pos.y - rect.top) / cell).floor();
    _handleCell(Offset(c.toDouble(), r.toDouble()));
  }

  @override
  void onPanEnd(Vector2 velocity, Vector2 gameSize) {
    active = null;
  }
}
