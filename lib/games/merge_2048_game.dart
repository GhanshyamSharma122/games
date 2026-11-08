import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../core/util.dart';

double _measureTextWidth(TextPaint paint, String text) {
  final tp = paint.toTextPainter(text);
  tp.layout();
  return tp.width;
}

class Merge2048Game extends MiniGame {
  @override
  String get name => '2048 Merge';

  @override
  String get instructions => 'Swipe to merge tiles.';

  int n = 4;
  int target = 2048;
  final Random _rng = Random();
  late List<int> grid;
  late List<double> tileScale; // Pop animation on new tiles
  late List<double> tileMergeScale; // Merge pop effect
  late List<Offset> tileOffset; // Slide animation offset

  @override
  void reset(Vector2 size) {
    final baseTarget = switch (difficulty) {
      GameDifficulty.easy => 512,
      GameDifficulty.medium => 1024,
      GameDifficulty.hard => 2048,
    };

    target = baseTarget * (1 << (level - 1));
    target = target.clamp(512, 16384);
    n = level >= 5 ? 5 : 4;

    grid = List.generate(n * n, (_) => 0);
    tileScale = List.generate(n * n, (_) => 1.0);
    tileMergeScale = List.generate(n * n, (_) => 1.0);
    tileOffset = List.generate(n * n, (_) => Offset.zero);
    _addTile();
    _addTile();
  }

  @override
  bool get isSolved => grid.any((v) => v >= target);

  @override
  void update(double dt) {
    // Animate tile scales and positions
    for (int i = 0; i < n * n; i++) {
      // Scale animation
      if (tileScale[i] < 1.0) {
        tileScale[i] += dt * 8;
        if (tileScale[i] > 1.0) tileScale[i] = 1.0;
      }

      // Merge pop animation
      if (tileMergeScale[i] > 1.0) {
        tileMergeScale[i] -= dt * 4;
        if (tileMergeScale[i] < 1.0) tileMergeScale[i] = 1.0;
      }

      // Slide animation
      if (tileOffset[i] != Offset.zero) {
        tileOffset[i] = Offset(tileOffset[i].dx * 0.8, tileOffset[i].dy * 0.8);
        if (tileOffset[i].distance < 1) {
          tileOffset[i] = Offset.zero;
        }
      }
    }
  }

  void _addTile() {
    final empty = <int>[];
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] == 0) empty.add(i);
    }
    if (empty.isEmpty) return;
    final i = empty[_rng.nextInt(empty.length)];
    grid[i] = _rng.nextDouble() < 0.9 ? 2 : 4;
    tileScale[i] = 0.0; // Start small for pop animation
  }

  bool _move(List<int> lines, List<int> indices) {
    final merged = <int>[];
    final mergedIndices = <int>[];
    int i = 0;
    while (i < lines.length) {
      if (i < lines.length - 1 && lines[i] == lines[i + 1]) {
        merged.add(lines[i] * 2);
        mergedIndices.add(indices[i]);
        tileMergeScale[indices[i]] = 1.3; // Pop effect on merge
        i += 2;
      } else {
        merged.add(lines[i]);
        mergedIndices.add(indices[i]);
        i++;
      }
    }
    while (merged.length < n) {
      merged.add(0);
      mergedIndices.add(-1);
    }
    bool changed = false;
    for (int j = 0; j < n; j++) {
      if (merged[j] != lines[j]) changed = true;
      lines[j] = merged[j];
    }
    return changed;
  }

  bool _slide(int dir) {
    bool moved = false;
    if (dir == 0) {
      // Left
      for (int r = 0; r < n; r++) {
        final line = <int>[];
        final indices = <int>[];
        for (int c = 0; c < n; c++) {
          final v = grid[idx(r, c, n)];
          if (v != 0) {
            line.add(v);
            indices.add(idx(r, c, n));
          }
        }
        while (line.length < n) {
          line.add(0);
          indices.add(-1);
        }
        final changed = _move(line, indices);
        for (int c = 0; c < n; c++) {
          grid[idx(r, c, n)] = line[c];
        }
        moved = moved || changed;
      }
    } else if (dir == 1) {
      // Right
      for (int r = 0; r < n; r++) {
        final line = <int>[];
        final indices = <int>[];
        for (int c = n - 1; c >= 0; c--) {
          final v = grid[idx(r, c, n)];
          if (v != 0) {
            line.add(v);
            indices.add(idx(r, c, n));
          }
        }
        while (line.length < n) {
          line.add(0);
          indices.add(-1);
        }
        final changed = _move(line, indices);
        for (int c = n - 1, i = 0; c >= 0; c--, i++) {
          grid[idx(r, c, n)] = line[i];
        }
        moved = moved || changed;
      }
    } else if (dir == 2) {
      // Up
      for (int c = 0; c < n; c++) {
        final line = <int>[];
        final indices = <int>[];
        for (int r = 0; r < n; r++) {
          final v = grid[idx(r, c, n)];
          if (v != 0) {
            line.add(v);
            indices.add(idx(r, c, n));
          }
        }
        while (line.length < n) {
          line.add(0);
          indices.add(-1);
        }
        final changed = _move(line, indices);
        for (int r = 0; r < n; r++) {
          grid[idx(r, c, n)] = line[r];
        }
        moved = moved || changed;
      }
    } else {
      // Down
      for (int c = 0; c < n; c++) {
        final line = <int>[];
        final indices = <int>[];
        for (int r = n - 1; r >= 0; r--) {
          final v = grid[idx(r, c, n)];
          if (v != 0) {
            line.add(v);
            indices.add(idx(r, c, n));
          }
        }
        while (line.length < n) {
          line.add(0);
          indices.add(-1);
        }
        final changed = _move(line, indices);
        for (int r = n - 1, i = 0; r >= 0; r--, i++) {
          grid[idx(r, c, n)] = line[i];
        }
        moved = moved || changed;
      }
    }
    if (moved) _addTile();
    return moved;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;

    // Background with rounded corners
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF1D2633),
    );

    // Grid lines
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final emptyRect = Rect.fromLTWH(
          rect.left + c * cell + 4,
          rect.top + r * cell + 4,
          cell - 8,
          cell - 8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(emptyRect, const Radius.circular(8)),
          Paint()..color = const Color(0xFF2C3442),
        );
      }
    }

    final colors = <int, Color>{
      2: const Color(0xFFE9C46A),
      4: const Color(0xFFF4A261),
      8: const Color(0xFFE76F51),
      16: const Color(0xFFB56576),
      32: const Color(0xFF6D597A),
      64: const Color(0xFF355070),
      128: const Color(0xFF2A9D8F),
      256: const Color(0xFF264653),
      512: const Color(0xFF5F0F40),
      1024: const Color(0xFF9A031E),
      2048: const Color(0xFF0F4C5C),
      4096: const Color(0xFF1D3557),
      8192: const Color(0xFF457B9D),
      16384: const Color(0xFFA8DADC),
    };

    // Draw tiles
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final v = grid[i];
        if (v == 0) continue;

        final scale = tileScale[i] * tileMergeScale[i];
        final offset = tileOffset[i];

        final baseRect = Rect.fromLTWH(
          rect.left + c * cell + 4 + offset.dx,
          rect.top + r * cell + 4 + offset.dy,
          cell - 8,
          cell - 8,
        );
        final cellRect = Rect.fromCenter(
          center: baseRect.center,
          width: baseRect.width * scale,
          height: baseRect.height * scale,
        );

        // Shadow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            cellRect.translate(2, 3),
            const Radius.circular(10),
          ),
          Paint()..color = Colors.black.withOpacity(0.25),
        );

        final paint = Paint()..color = colors[v] ?? const Color(0xFF3D5A80);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(10)),
          paint,
        );

        // Highlight
        final highlightRect = Rect.fromLTWH(
          cellRect.left + 4,
          cellRect.top + 4,
          cellRect.width - 8,
          cellRect.height * 0.25,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(6)),
          Paint()..color = Colors.white.withOpacity(0.15),
        );

        // Text
        final fontSize = v >= 1000 ? 14.0 : (v >= 100 ? 16.0 : 18.0);
        final textPaint = TextPaint(
          style: TextStyle(
            fontSize: fontSize * scale,
            color: v <= 4 ? const Color(0xFF776E65) : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
        final text = v.toString();
        textPaint.render(
          canvas,
          text,
          Vector2(
            cellRect.center.dx - _measureTextWidth(textPaint, text) / 2,
            cellRect.center.dy - fontSize * scale / 2,
          ),
        );
      }
    }
  }

  @override
  void onPanEnd(Vector2 velocity, Vector2 gameSize) {
    // Use velocity for more responsive swipe
    // If velocity is too low, ignore
    if (velocity.length < 100) return;

    if (velocity.x.abs() > velocity.y.abs()) {
      _slide(velocity.x > 0 ? 1 : 0);
    } else {
      _slide(velocity.y > 0 ? 3 : 2);
    }
  }
}
