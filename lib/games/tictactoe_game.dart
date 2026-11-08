import 'dart:ui';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class TicTacToeGame extends MiniGame {
  @override
  String get name => 'Tic-Tac-Toe';

  @override
  String get instructions => 'Get 3 in a row to win!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 5;

  late List<int> board; // 0 = empty, 1 = X (player), 2 = O (AI)
  bool playerTurn = true;
  int? winner; // null = ongoing, 0 = draw, 1 = player, 2 = AI
  int aiDepth = 2;

  // Animation
  List<double> pieceScale = []; // Scale animation for each cell
  double winLineProgress = 0;
  List<int>? winningLine;
  double shakeAmount = 0;
  final Random _rng = Random();

  @override
  void reset(Vector2 size) {
    board = List.generate(9, (_) => 0);
    pieceScale = List.generate(9, (_) => 0.0);
    playerTurn = true;
    winner = null;
    winningLine = null;
    winLineProgress = 0;
    shakeAmount = 0;
    aiDepth = level + 1;
  }

  @override
  bool get isSolved => winner == 1;

  int? _checkWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (final line in lines) {
      if (board[line[0]] != 0 &&
          board[line[0]] == board[line[1]] &&
          board[line[1]] == board[line[2]]) {
        winningLine = line;
        return board[line[0]];
      }
    }

    if (!board.contains(0)) return 0; // Draw
    return null;
  }

  @override
  void update(double dt) {
    // Shake decay
    if (shakeAmount > 0) {
      shakeAmount -= dt * 5;
    }

    // Win line animation
    if (winner != null && winningLine != null) {
      if (winLineProgress < 1.0) {
        winLineProgress += dt * 3;
        if (winLineProgress > 1.0) winLineProgress = 1.0;
      }
    }

    // Piece scale animation
    for (int i = 0; i < 9; i++) {
      if (board[i] != 0 && pieceScale[i] < 1.0) {
        pieceScale[i] += dt * 8;
        if (pieceScale[i] > 1.0) pieceScale[i] = 1.0;
      }
    }
  }

  void _aiMove() {
    if (winner != null) return;

    int bestScore = -1000;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      if (board[i] == 0) {
        board[i] = 2;
        int score = _minimax(0, false, aiDepth);
        board[i] = 0;
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }

    if (bestMove >= 0) {
      board[bestMove] = 2;
      pieceScale[bestMove] = 0.0; // Start animation
      winner = _checkWinner();
      playerTurn = true;
    }
  }

  int _minimax(int depth, bool isMax, int maxDepth) {
    // ... same minimax logic ...
    // To handle winningLine correctly in recursion, we temporarily ignore side effects
    // But since _checkWinner sets winningLine, we should save/restore it
    // or use a pure version. For simplicity, we just use the logic here.

    // Duplicate check winner logic purely
    int? result;
    bool full = true;
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final line in lines) {
      if (board[line[0]] != 0 &&
          board[line[0]] == board[line[1]] &&
          board[line[1]] == board[line[2]]) {
        result = board[line[0]];
        break;
      }
    }
    if (result == null) {
      for (int i = 0; i < 9; i++)
        if (board[i] == 0) {
          full = false;
          break;
        }
      if (full) result = 0;
    }

    if (result == 2) return 10 - depth;
    if (result == 1) return depth - 10;
    if (result == 0 || depth >= maxDepth) return 0;

    if (isMax) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == 0) {
          board[i] = 2;
          best = max(best, _minimax(depth + 1, false, maxDepth));
          board[i] = 0;
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == 0) {
          board[i] = 1;
          best = min(best, _minimax(depth + 1, true, maxDepth));
          board[i] = 0;
        }
      }
      return best;
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / 3;

    // Shake effect
    if (shakeAmount > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shakeAmount * 10,
        (_rng.nextDouble() - 0.5) * shakeAmount * 10,
      );
    }

    final bgPaint = Paint()..color = const Color(0xFF1B2430);
    final linePaint = Paint()
      ..color = const Color(0xFF3A4452)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      bgPaint,
    );

    // Grid lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(rect.left + i * cell, rect.top + 10),
        Offset(rect.left + i * cell, rect.bottom - 10),
        linePaint,
      );
      canvas.drawLine(
        Offset(rect.left + 10, rect.top + i * cell),
        Offset(rect.right - 10, rect.top + i * cell),
        linePaint,
      );
    }

    // Pieces
    final xPaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final oPaint = Paint()
      ..color = const Color(0xFFE76F51)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 9; i++) {
      if (board[i] == 0) continue;

      final r = i ~/ 3;
      final c = i % 3;
      final center = Offset(
        rect.left + c * cell + cell / 2,
        rect.top + r * cell + cell / 2,
      );
      final scale = pieceScale[i];
      final size = cell * 0.25 * scale;

      if (board[i] == 1) {
        // Draw X
        canvas.drawLine(
          Offset(center.dx - size, center.dy - size),
          Offset(center.dx + size, center.dy + size),
          xPaint,
        );
        canvas.drawLine(
          Offset(center.dx + size, center.dy - size),
          Offset(center.dx - size, center.dy + size),
          xPaint,
        );
      } else if (board[i] == 2) {
        // Draw O
        canvas.drawCircle(center, size, oPaint);
      }
    }

    // Win line
    if (winningLine != null && winLineProgress > 0) {
      final startIdx = winningLine![0];
      final endIdx = winningLine![2];

      final startCenter = Offset(
        rect.left + (startIdx % 3) * cell + cell / 2,
        rect.top + (startIdx ~/ 3) * cell + cell / 2,
      );
      final endCenter = Offset(
        rect.left + (endIdx % 3) * cell + cell / 2,
        rect.top + (endIdx ~/ 3) * cell + cell / 2,
      );

      final currentEnd = Offset.lerp(startCenter, endCenter, winLineProgress)!;

      canvas.drawLine(
        startCenter,
        currentEnd,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    if (shakeAmount > 0) {
      canvas.restore();
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (!playerTurn || winner != null) return;

    final rect = boardRect(gameSize);
    final cell = rect.width / 3;

    if (!rect.contains(Offset(position.x, position.y))) return;

    final c = ((position.x - rect.left) / cell).floor();
    final r = ((position.y - rect.top) / cell).floor();
    final i = idx(r, c, 3);

    if (board[i] == 0) {
      board[i] = 1;
      pieceScale[i] = 0.0; // Start animation
      winner = _checkWinner();
      playerTurn = false;

      if (winner == null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          _aiMove();
        });
      }
    } else {
      shakeAmount = 0.5; // Shake on invalid move
    }
  }
}
