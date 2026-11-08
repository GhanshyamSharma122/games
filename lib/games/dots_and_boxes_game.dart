import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class DotsAndBoxesGame extends MiniGame {
  @override
  String get name => 'Dots & Boxes';

  @override
  String get instructions => 'Draw lines to complete boxes!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 6;

  int n = 4; // n x n grid of dots
  late List<bool> horizontalLines; // (n-1) * n lines
  late List<bool> verticalLines; // n * (n-1) lines
  late List<int> boxes; // (n-1) * (n-1) boxes: 0 = empty, 1 = player, 2 = AI
  bool playerTurn = true;
  int playerScore = 0;
  int aiScore = 0;

  // Animation
  int? lastLineIndex;
  bool lastLineHorizontal = false;
  double lineProgress = 0;
  List<double> boxOpacities = [];

  @override
  void reset(Vector2 size) {
    n = 3 + level;
    n = n.clamp(3, 8);

    horizontalLines = List.generate((n - 1) * n, (_) => false);
    verticalLines = List.generate(n * (n - 1), (_) => false);
    boxes = List.generate((n - 1) * (n - 1), (_) => 0);
    boxOpacities = List.generate((n - 1) * (n - 1), (_) => 0.0);

    playerTurn = true;
    playerScore = 0;
    aiScore = 0;
    lastLineIndex = null;
    lineProgress = 1.0;
  }

  @override
  void update(double dt) {
    if (lineProgress < 1.0) {
      lineProgress += dt * 5;
      if (lineProgress > 1.0) lineProgress = 1.0;
    }

    for (int i = 0; i < boxes.length; i++) {
      if (boxes[i] != 0 && boxOpacities[i] < 1.0) {
        boxOpacities[i] += dt * 3;
        if (boxOpacities[i] > 1.0) boxOpacities[i] = 1.0;
      }
    }
  }

  @override
  bool get isSolved {
    if (boxes.contains(0)) return false;
    return playerScore > aiScore;
  }

  bool get isComplete => !boxes.contains(0);

  int _checkAndCompleteBoxes(int player) {
    int completed = 0;
    for (int r = 0; r < n - 1; r++) {
      for (int c = 0; c < n - 1; c++) {
        final boxIndex = r * (n - 1) + c;
        if (boxes[boxIndex] != 0) continue;

        final top = horizontalLines[r * (n - 1) + c];
        final bottom = horizontalLines[(r + 1) * (n - 1) + c];
        final left = verticalLines[r * n + c];
        final right = verticalLines[r * n + c + 1];

        if (top && bottom && left && right) {
          boxes[boxIndex] = player;
          boxOpacities[boxIndex] = 0.0; // Start fade in
          if (player == 1)
            playerScore++;
          else
            aiScore++;
          completed++;
        }
      }
    }
    return completed;
  }

  void _playMove(bool horizontal, int index) {
    if (horizontal) {
      horizontalLines[index] = true;
    } else {
      verticalLines[index] = true;
    }
    lastLineHorizontal = horizontal;
    lastLineIndex = index;
    lineProgress = 0.0;
  }

  int _countSides(int r, int c) {
    if (r < 0 || r >= n - 1 || c < 0 || c >= n - 1) return 0;
    int count = 0;
    // Top
    if (horizontalLines[r * (n - 1) + c]) count++;
    // Bottom
    if (horizontalLines[(r + 1) * (n - 1) + c]) count++;
    // Left
    if (verticalLines[r * n + c]) count++;
    // Right
    if (verticalLines[r * n + c + 1]) count++;
    return count;
  }

  void _aiMove() {
    if (!playerTurn || isComplete) return;

    List<int> horizontalOptions = [];
    for (int i = 0; i < horizontalLines.length; i++) {
      if (!horizontalLines[i]) horizontalOptions.add(i);
    }
    List<int> verticalOptions = [];
    for (int i = 0; i < verticalLines.length; i++) {
      if (!verticalLines[i]) verticalOptions.add(i);
    }

    if (horizontalOptions.isEmpty && verticalOptions.isEmpty) return;

    // 1. Check for moves that complete a box (take it!)
    for (final i in horizontalOptions) {
      if (_willCompleteBox(true, i)) {
        _playMove(true, i);
        if (_checkAndCompleteBoxes(2) > 0) {
          if (!isComplete) {
            Future.delayed(const Duration(milliseconds: 500), _aiMove);
          }
          return;
        }
      }
    }
    for (final i in verticalOptions) {
      if (_willCompleteBox(false, i)) {
        _playMove(false, i);
        if (_checkAndCompleteBoxes(2) > 0) {
          if (!isComplete) {
            Future.delayed(const Duration(milliseconds: 500), _aiMove);
          }
          return;
        }
      }
    }

    // 2. Avoid giving away a box (minimax-lite)
    // We want to pick a move that does NOT result in a box with 3 sides (which the opponent can take)
    // Filter options that are "safe"
    List<int> safeHorizontal = [];
    for (final i in horizontalOptions) {
      if (!_makesBoxVulnerable(true, i)) {
        safeHorizontal.add(i);
      }
    }
    List<int> safeVertical = [];
    for (final i in verticalOptions) {
      if (!_makesBoxVulnerable(false, i)) {
        safeVertical.add(i);
      }
    }

    // Pick random safe move
    if (safeHorizontal.isNotEmpty || safeVertical.isNotEmpty) {
      if (safeHorizontal.isNotEmpty &&
          (safeVertical.isEmpty || _rng.nextBool())) {
        _playMove(true, safeHorizontal[_rng.nextInt(safeHorizontal.length)]);
      } else {
        _playMove(false, safeVertical[_rng.nextInt(safeVertical.length)]);
      }
      _checkAndCompleteBoxes(2);
      playerTurn = true;
      return;
    }

    // 3. If no safe moves, we have to sacrifice. Pick random.
    if (horizontalOptions.isNotEmpty &&
        (verticalOptions.isEmpty || _rng.nextBool())) {
      _playMove(
        true,
        horizontalOptions[_rng.nextInt(horizontalOptions.length)],
      );
    } else {
      _playMove(false, verticalOptions[_rng.nextInt(verticalOptions.length)]);
    }
    _checkAndCompleteBoxes(2);
    playerTurn = true;
  }

  bool _willCompleteBox(bool horizontal, int index) {
    if (horizontal) {
      int r = index ~/ (n - 1);
      int c = index % (n - 1);
      // Check box above (row r-1, col c)
      if (r > 0) {
        if (_countSides(r - 1, c) == 3) return true;
      }
      // Check box below (row r, col c)
      if (r < n - 1) {
        if (_countSides(r, c) == 3) return true;
      }
    } else {
      int r = index ~/ n;
      int c = index % n;
      // Check box left (row r, col c-1)
      if (c > 0) {
        if (_countSides(r, c - 1) == 3) return true;
      }
      // Check box right (row r, col c)
      if (c < n - 1) {
        if (_countSides(r, c) == 3) return true;
      }
    }
    return false;
  }

  bool _makesBoxVulnerable(bool horizontal, int index) {
    // If we place this line, does it make any adjacent box have 3 sides (so the opponent can take it next)?
    // Note: _countSides counts CURRENT lines. After we add 1, if it becomes 3, that's bad?
    // Wait, if it becomes 4, we take it (good, handled in step 1).
    // If it becomes 3, opponent takes it (bad).
    // So we want to avoid creating a 3-sided box.

    if (horizontal) {
      int r = index ~/ (n - 1);
      int c = index % (n - 1);
      // Check box above
      if (r > 0) {
        if (_countSides(r - 1, c) == 2) return true; // Will become 3
      }
      // Check box below
      if (r < n - 1) {
        if (_countSides(r, c) == 2) return true; // Will become 3
      }
    } else {
      int r = index ~/ n;
      int c = index % n;
      // Check box left
      if (c > 0) {
        if (_countSides(r, c - 1) == 2) return true; // Will become 3
      }
      // Check box right
      if (c < n - 1) {
        if (_countSides(r, c) == 2) return true; // Will become 3
      }
    }
    return false;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final spacing = rect.width / n;

    final dotPaint = Paint()..color = Colors.white;
    final linePaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final emptyLinePaint = Paint()
      ..color = const Color(0xFF3A4452)
      ..strokeWidth = 2;
    // Box paints with opacity

    // Draw boxes
    for (int r = 0; r < n - 1; r++) {
      for (int c = 0; c < n - 1; c++) {
        final boxIndex = r * (n - 1) + c;
        if (boxes[boxIndex] != 0) {
          final paint = Paint()
            ..color =
                (boxes[boxIndex] == 1
                        ? const Color(0xFF2A9D8F)
                        : const Color(0xFFE76F51))
                    .withOpacity(0.3 * boxOpacities[boxIndex]);

          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + c * spacing,
              rect.top + r * spacing,
              spacing,
              spacing,
            ),
            paint,
          );
        }
      }
    }

    // Draw horizontal lines
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n - 1; c++) {
        final lineIndex = r * (n - 1) + c;
        final start = Offset(rect.left + c * spacing, rect.top + r * spacing);
        final end = Offset(
          rect.left + (c + 1) * spacing,
          rect.top + r * spacing,
        );

        if (horizontalLines[lineIndex]) {
          if (lastLineHorizontal && lastLineIndex == lineIndex) {
            final currentEnd = Offset.lerp(start, end, lineProgress)!;
            canvas.drawLine(start, currentEnd, linePaint);
          } else {
            canvas.drawLine(start, end, linePaint);
          }
        } else {
          canvas.drawLine(start, end, emptyLinePaint);
        }
      }
    }

    // Draw vertical lines
    for (int r = 0; r < n - 1; r++) {
      for (int c = 0; c < n; c++) {
        final lineIndex = r * n + c;
        final start = Offset(rect.left + c * spacing, rect.top + r * spacing);
        final end = Offset(
          rect.left + c * spacing,
          rect.top + (r + 1) * spacing,
        );

        if (verticalLines[lineIndex]) {
          if (!lastLineHorizontal && lastLineIndex == lineIndex) {
            final currentEnd = Offset.lerp(start, end, lineProgress)!;
            canvas.drawLine(start, currentEnd, linePaint);
          } else {
            canvas.drawLine(start, end, linePaint);
          }
        } else {
          canvas.drawLine(start, end, emptyLinePaint);
        }
      }
    }

    // Draw dots
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        canvas.drawCircle(
          Offset(rect.left + c * spacing, rect.top + r * spacing),
          5,
          dotPaint,
        );
      }
    }

    // Score
    TextPaint(style: const TextStyle(fontSize: 16, color: Colors.white)).render(
      canvas,
      'You: $playerScore  AI: $aiScore',
      Vector2(rect.left, rect.bottom + 10),
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (!playerTurn || isComplete) return;

    final rect = boardRect(gameSize);
    final spacing = rect.width / n;

    // Find nearest line
    double minDist = double.infinity;
    bool isHorizontal = true;
    int lineIndex = -1;

    // Check horizontal lines
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n - 1; c++) {
        final midX = rect.left + (c + 0.5) * spacing;
        final midY = rect.top + r * spacing;
        final dist = (position.x - midX).abs() + (position.y - midY).abs();
        if (dist < minDist && dist < spacing * 0.6) {
          minDist = dist;
          isHorizontal = true;
          lineIndex = r * (n - 1) + c;
        }
      }
    }

    // Check vertical lines
    for (int r = 0; r < n - 1; r++) {
      for (int c = 0; c < n; c++) {
        final midX = rect.left + c * spacing;
        final midY = rect.top + (r + 0.5) * spacing;
        final dist = (position.x - midX).abs() + (position.y - midY).abs();
        if (dist < minDist && dist < spacing * 0.6) {
          minDist = dist;
          isHorizontal = false;
          lineIndex = r * n + c;
        }
      }
    }

    if (lineIndex >= 0) {
      final lines = isHorizontal ? horizontalLines : verticalLines;
      if (!lines[lineIndex]) {
        _playMove(isHorizontal, lineIndex);

        final completed = _checkAndCompleteBoxes(1);
        if (completed == 0) {
          playerTurn = false;
          Future.delayed(const Duration(milliseconds: 500), () {
            _aiMove();
          });
        }
      }
    }
  }
}

final Random _rng = Random();
