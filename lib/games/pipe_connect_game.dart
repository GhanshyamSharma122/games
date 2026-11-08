import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../core/util.dart';

class PipeConnectGame extends MiniGame {
  @override
  String get name => 'Pipe Connect';

  @override
  String get instructions => 'Rotate tiles to connect start to end.';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 20;

  int n = 5;
  final Random _rng = Random();
  late List<int> baseMask; // bitmask 1=up 2=right 4=down 8=left
  late List<int> rotation; // 0-3
  late int startIdx;
  late int endIdx;
  bool isRegenerating = false;

  @override
  void reset(Vector2 size) {
    // Difficulty scaling
    if (difficulty == GameDifficulty.easy) {
      n = level < 5 ? 4 : 5;
    } else if (difficulty == GameDifficulty.medium) {
      n = level < 5 ? 5 : (level < 10 ? 6 : 7);
    } else {
      n = level < 5 ? 6 : (level < 10 ? 7 : 8);
    }
    n = n.clamp(4, 10);

    _generateLevel();
  }

  void _generateLevel() {
    isRegenerating = true;
    baseMask = List.filled(n * n, 0);
    rotation = List.filled(n * n, 0);

    // 1. Pick Start and End points
    startIdx = idx(_rng.nextInt(n), 0, n);
    endIdx = idx(_rng.nextInt(n), n - 1, n);

    // 2. Generate a main path from start to end
    final path = _generatePath(startIdx, endIdx);

    // 3. Populate matching pipes for the solution
    baseMask.fillRange(0, baseMask.length, 0);

    for (int i = 0; i < path.length; i++) {
      final cur = path[i];
      if (i > 0) {
        final prev = path[i - 1];
        _connect(cur, prev);
      }
      if (i < path.length - 1) {
        final next = path[i + 1];
        _connect(cur, next);
      }
    }

    // 4. Fill empty spots
    for (int i = 0; i < n * n; i++) {
      if (!path.contains(i) && _rng.nextDouble() < 0.4) {
        // Add a random valid pipe for decoration
        baseMask[i] = [3, 5, 6, 9, 10, 12][_rng.nextInt(6)];
      }
    }

    // 5. Scramble rotations
    for (int i = 0; i < n * n; i++) {
      if (baseMask[i] != 0) {
        rotation[i] = _rng.nextInt(4);
      }
    }

    // Ensure it's not solved by pure luck
    if (isSolved) {
      rotation[startIdx] = (rotation[startIdx] + 1) % 4;
    }

    isRegenerating = false;
  }

  void _connect(int a, int b) {
    final ra = a ~/ n;
    final ca = a % n;
    final rb = b ~/ n;
    final cb = b % n;

    if (ra == rb && ca == cb - 1) {
      // b is right of a
      baseMask[a] |= 2;
      baseMask[b] |= 8;
    } else if (ra == rb && ca == cb + 1) {
      // b is left of a
      baseMask[a] |= 8;
      baseMask[b] |= 2;
    } else if (ca == cb && ra == rb - 1) {
      // b is below a
      baseMask[a] |= 4;
      baseMask[b] |= 1;
    } else if (ca == cb && ra == rb + 1) {
      // b is above a
      baseMask[a] |= 1;
      baseMask[b] |= 4;
    }
  }

  // Simple randomized DFS
  List<int> _generatePath(int start, int end) {
    final stack = <int>[start];
    final cameFrom = <int, int>{};
    final visited = <int>{start};

    while (stack.isNotEmpty) {
      final current = stack.last;
      if (current == end) break;

      final neighbors = _nbs(current);
      neighbors.shuffle(_rng);

      bool found = false;
      for (final nb in neighbors) {
        if (!visited.contains(nb)) {
          visited.add(nb);
          cameFrom[nb] = current;
          stack.add(nb);
          found = true;
          break;
        }
      }
      if (!found) {
        stack.removeLast();
      }
    }

    // Reconstruct
    final path = <int>[];
    int? curr = end;
    while (curr != null) {
      path.add(curr);
      curr = cameFrom[curr];
    }
    return path.reversed.toList();
  }

  List<int> _nbs(int idx) {
    final r = idx ~/ n;
    final c = idx % n;
    final res = <int>[];
    if (r > 0) res.add(idx - n);
    if (r < n - 1) res.add(idx + n);
    if (c > 0) res.add(idx - 1);
    if (c < n - 1) res.add(idx + 1);
    return res;
  }

  int _rotMask(int mask, int rot) {
    int m = mask;
    for (int i = 0; i < rot; i++) {
      final up = (m & 1) != 0;
      final right = (m & 2) != 0;
      final down = (m & 4) != 0;
      final left = (m & 8) != 0;
      m = 0;
      if (left) m |= 1;
      if (up) m |= 2;
      if (right) m |= 4;
      if (down) m |= 8;
    }
    return m;
  }

  @override
  bool get isSolved {
    if (isRegenerating) return false;

    final visited = List<bool>.filled(n * n, false);
    final queue = <int>[startIdx];
    visited[startIdx] = true;

    // We check if startIdx is properly oriented to allow flow
    // But since startIdx is arbitrary, we just check connectivity

    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (cur == endIdx) return true;

      final r = cur ~/ n;
      final c = cur % n;
      final mask = _rotMask(baseMask[cur], rotation[cur]);

      void check(int nr, int nc, int bit, int opp) {
        if (nr < 0 || nr >= n || nc < 0 || nc >= n) return;
        if ((mask & bit) == 0) return;

        final nid = idx(nr, nc, n);
        final nMask = _rotMask(baseMask[nid], rotation[nid]);
        if ((nMask & opp) == 0) return;

        if (!visited[nid]) {
          visited[nid] = true;
          queue.add(nid);
        }
      }

      check(r - 1, c, 1, 4);
      check(r, c + 1, 2, 8);
      check(r + 1, c, 4, 1);
      check(r, c - 1, 8, 2);
    }
    return false;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;
    final tilePaint = Paint()
      ..color = const Color(0xFF1B2430)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..strokeWidth = cell * 0.2
      ..strokeCap = StrokeCap.round;

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

        if (baseMask[i] == 0) continue;

        final center = cellRect.center;
        final mask = _rotMask(baseMask[i], rotation[i]);

        if ((mask & 1) != 0)
          canvas.drawLine(center, Offset(center.dx, cellRect.top), linePaint);
        if ((mask & 2) != 0)
          canvas.drawLine(center, Offset(cellRect.right, center.dy), linePaint);
        if ((mask & 4) != 0)
          canvas.drawLine(
            center,
            Offset(center.dx, cellRect.bottom),
            linePaint,
          );
        if ((mask & 8) != 0)
          canvas.drawLine(center, Offset(cellRect.left, center.dy), linePaint);

        canvas.drawCircle(center, cell * 0.15, linePaint);
      }
    }

    // Markers
    final markPaint = Paint()..color = const Color(0xFFE9C46A);
    // Start
    canvas.drawCircle(
      Offset(
        rect.left + (startIdx % n) * cell + cell / 2,
        rect.top + (startIdx ~/ n) * cell + cell / 2,
      ),
      cell * 0.25,
      markPaint,
    );
    // End
    Paint endPaint = Paint()..color = const Color(0xFFE76F51);
    canvas.drawCircle(
      Offset(
        rect.left + (endIdx % n) * cell + cell / 2,
        rect.top + (endIdx ~/ n) * cell + cell / 2,
      ),
      cell * 0.25,
      endPaint,
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    if (!rect.contains(Offset(position.x, position.y))) return;

    final cell = rect.width / n;
    final c = ((position.x - rect.left) / cell).floor();
    final r = ((position.y - rect.top) / cell).floor();
    if (c < 0 || c >= n || r < 0 || r >= n) return;

    final i = idx(r, c, n);
    if (baseMask[i] != 0) {
      rotation[i] = (rotation[i] + 1) % 4;
    }
  }
}
