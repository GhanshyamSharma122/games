import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart'; // Ensure idx is valid

class ConnectFourGame extends MiniGame {
  @override
  String get name => 'Connect Four';

  @override
  String get instructions => 'Drop discs to get 4 in a row!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 5;

  late List<int> board;
  int? winner;
  bool playerTurn = true;
  int aiDepth = 3;
  static const int cols = 7;
  static const int rows = 6;

  // Animation
  List<double> dropY = []; // Visual Y offset for dropping animation
  List<int> winningCells = []; // Indices of winning cells for highlight
  double winFlash = 0;

  @override
  void reset(Vector2 size) {
    board = List.generate(rows * cols, (_) => 0);
    dropY = List.generate(rows * cols, (_) => 0.0);
    winner = null;
    playerTurn = true;
    winningCells = [];
    winFlash = 0;
    aiDepth = level + 2;
  }

  @override
  bool get isSolved => winner == 1;

  int? _dropPiece(int col, int player) {
    for (int r = rows - 1; r >= 0; r--) {
      final i = idx(r, col, cols);
      if (board[i] == 0) {
        board[i] = player;
        dropY[i] = -400.0; // Start drop from above
        return i;
      }
    }
    return null;
  }

  // Helper function to check 4
  bool _checkLine(int start, int step, {bool visualize = true}) {
    final p = board[start];
    if (p == 0) return false;
    if (board[start + step] == p &&
        board[start + 2 * step] == p &&
        board[start + 3 * step] == p) {
      if (visualize) {
        winningCells = [
          start,
          start + step,
          start + 2 * step,
          start + 3 * step,
        ];
      }
      return true;
    }
    return false;
  }

  int? _checkWinner({bool visualize = true}) {
    if (visualize) winningCells = [];
    // Horizontal
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        if (_checkLine(idx(r, c, cols), 1, visualize: visualize))
          return board[idx(r, c, cols)];
      }
    }
    // Vertical
    for (int r = 0; r <= rows - 4; r++) {
      for (int c = 0; c < cols; c++) {
        if (_checkLine(idx(r, c, cols), cols, visualize: visualize))
          return board[idx(r, c, cols)];
      }
    }
    // Diagonal down-right
    for (int r = 0; r <= rows - 4; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        if (_checkLine(idx(r, c, cols), cols + 1, visualize: visualize))
          return board[idx(r, c, cols)];
      }
    }
    // Diagonal up-right
    for (int r = 3; r < rows; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        if (_checkLine(idx(r, c, cols), -cols + 1, visualize: visualize))
          return board[idx(r, c, cols)];
      }
    }

    if (!board.contains(0)) return 0;
    return null;
  }

  void _aiMove() {
    // ... same AI logic ...
    if (winner != null) return;

    int bestCol = -1;
    int bestScore = -10000;

    for (int c = 0; c < cols; c++) {
      // simulate drop
      int? pos;
      // Manual drop simulation to avoid animation side effects in recursion
      for (int r = rows - 1; r >= 0; r--) {
        if (board[idx(r, c, cols)] == 0) {
          pos = idx(r, c, cols);
          break;
        }
      }

      if (pos != null) {
        board[pos] = 2; // AI move
        final score = _minimax(0, false, aiDepth, -10000, 10000);
        board[pos] = 0;
        if (score > bestScore) {
          bestScore = score;
          bestCol = c;
        }
      }
    }

    if (bestCol >= 0) {
      _dropPiece(bestCol, 2);
      final win = _checkWinner();
      if (win != null) {
        winner = win;
        if (winningCells.isNotEmpty) winFlash = 1.0;
      }
      playerTurn = true;
    }
  }

  int _minimax(int depth, bool isMax, int maxDepth, int alpha, int beta) {
    // Basic minimax, no animation logic
    // We need a pure check winner here that doesn't set winningCells
    // ... Copy of check winner logic without side effects for brevity ...
    // For now we rely on the side effect not being harmful as we reset winningCells at start of _checkWinner
    // But since _checkWinner modifies state, we should be careful.
    // Ideally we extract the logic.
    // Given the constraints, I will use a simplified heuristic if maxDepth is small

    // Quick check:
    // Quick check:
    final w = _checkWinner(
      visualize: false,
    ); // Changed to false to avoid side effects
    if (w == 2) return 100 - depth;
    if (w == 1) return depth - 100;
    if (w == 0 || depth >= maxDepth) return 0;

    if (isMax) {
      int best = -10000;
      for (int c = 0; c < cols; c++) {
        int? pos;
        for (int r = rows - 1; r >= 0; r--) {
          if (board[idx(r, c, cols)] == 0) {
            pos = idx(r, c, cols);
            break;
          }
        }

        if (pos != null) {
          board[pos] = 2;
          best = best > _minimax(depth + 1, false, maxDepth, alpha, beta)
              ? best
              : _minimax(depth + 1, false, maxDepth, alpha, beta);
          board[pos] = 0;
          alpha = alpha > best ? alpha : best;
          if (beta <= alpha) break;
        }
      }
      return best;
    } else {
      int best = 10000;
      for (int c = 0; c < cols; c++) {
        int? pos;
        for (int r = rows - 1; r >= 0; r--) {
          if (board[idx(r, c, cols)] == 0) {
            pos = idx(r, c, cols);
            break;
          }
        }
        if (pos != null) {
          board[pos] = 1;
          best = best < _minimax(depth + 1, true, maxDepth, alpha, beta)
              ? best
              : _minimax(depth + 1, true, maxDepth, alpha, beta);
          board[pos] = 0;
          beta = beta < best ? beta : best;
          if (beta <= alpha) break;
        }
      }
      return best;
    }
  }

  @override
  void update(double dt) {
    // Drop animation
    for (int i = 0; i < dropY.length; i++) {
      if (dropY[i] < 0) {
        dropY[i] += dt * 1000;
        if (dropY[i] > 0) {
          // Bounce effect
          dropY[i] = 0;
        }
      }
    }

    if (winFlash > 0) winFlash -= dt * 2;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cellW = rect.width / cols;
    final cellH = rect.height / rows;

    // Draw board background (blue part) - Draw this LAST to mask falling pieces?
    // Actually standard Connect 4 has pieces behind the board or inside it.
    // Let's draw chunks.

    final boardPaint = Paint()..color = const Color(0xFF264653);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      boardPaint,
    );

    // Draw pieces
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final i = idx(r, c, cols);
        final center = Offset(
          rect.left + c * cellW + cellW / 2,
          rect.top + r * cellH + cellH / 2,
        );
        final radius = (cellW < cellH ? cellW : cellH) * 0.4;

        // Draw hole background (dark)
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF1B2430),
        );

        final v = board[i];
        if (v != 0) {
          final dy = dropY[i];

          // Piece color
          final paint = Paint()
            ..color = v == 1
                ? const Color(0xFFE9C46A)
                : const Color(0xFFE76F51);

          // Draw piece
          canvas.drawCircle(Offset(center.dx, center.dy + dy), radius, paint);

          // Inner detail
          canvas.drawCircle(
            Offset(center.dx, center.dy + dy),
            radius * 0.7,
            Paint()
              ..color = Colors.black.withOpacity(0.1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );

          // Highlight
          canvas.drawCircle(
            Offset(center.dx - radius * 0.3, center.dy + dy - radius * 0.3),
            radius * 0.2,
            Paint()..color = Colors.white.withOpacity(0.3),
          );
        }
      }
    }

    // Draw win highlight
    if (winningCells.isNotEmpty) {
      final flashOpacity = (sin(winFlash * pi * 4).abs() + 0.5).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.5 * flashOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      for (final i in winningCells) {
        final r = i ~/ cols;
        final c = i % cols;
        final center = Offset(
          rect.left + c * cellW + cellW / 2,
          rect.top + r * cellH + cellH / 2,
        );
        final radius = (cellW < cellH ? cellW : cellH) * 0.4;
        canvas.drawCircle(center, radius + 4, paint);
      }
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (!playerTurn || winner != null) return;

    final rect = boardRect(gameSize);
    if (!rect.contains(Offset(position.x, position.y))) return;

    final cellW = rect.width / cols;
    final c = ((position.x - rect.left) / cellW).floor();

    // Check if any drop animation is playing to prevent spamming
    // if (dropY.any((y) => y < 0)) return;

    final pos = _dropPiece(c, 1);
    if (pos != null) {
      final win = _checkWinner();
      if (win != null) {
        winner = win;
        if (winningCells.isNotEmpty) winFlash = 1.0;
      }
      playerTurn = false;

      if (winner == null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _aiMove();
        });
      }
    }
  }
}
