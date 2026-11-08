import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class NimGame extends MiniGame {
  @override
  String get name => 'Nim';

  @override
  String get instructions => 'Take 1-3 stones. Don\'t take the last one!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 6;

  int stones = 15;
  bool playerTurn = true;
  int? lastTake;
  bool gameOver = false;
  bool playerWon = false;

  @override
  void reset(Vector2 size) {
    stones = 10 + level * 3;
    playerTurn = true;
    lastTake = null;
    gameOver = false;
    playerWon = false;
  }

  @override
  bool get isSolved => gameOver && playerWon;

  void _playerTake(int amount) {
    if (!playerTurn || gameOver || amount > stones) return;

    stones -= amount;
    lastTake = amount;

    if (stones <= 0) {
      gameOver = true;
      playerWon = false; // Player took the last stone
      return;
    }

    playerTurn = false;
    Future.delayed(const Duration(milliseconds: 500), () {
      _aiTake();
    });
  }

  void _aiTake() {
    if (playerTurn || gameOver) return;

    // Optimal strategy: leave a multiple of 4
    int take = stones % 4;
    if (take == 0) take = 1; // If already optimal, take 1
    take = take.clamp(1, 3);
    if (take > stones) take = stones;

    stones -= take;
    lastTake = take;

    if (stones <= 0) {
      gameOver = true;
      playerWon = true; // AI took the last stone
      return;
    }

    playerTurn = true;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    // Draw stones
    final stoneRadius = 12.0;
    final stonesPerRow = 8;

    for (int i = 0; i < stones; i++) {
      final row = i ~/ stonesPerRow;
      final col = i % stonesPerRow;
      final x = rect.left + 30 + col * 35;
      final y = rect.top + 80 + row * 35;

      canvas.drawCircle(
        Offset(x, y),
        stoneRadius,
        Paint()..color = const Color(0xFF5A6472),
      );
    }

    // Stone count
    TextPaint(style: const TextStyle(fontSize: 20, color: Colors.white)).render(
      canvas,
      'Stones: $stones',
      Vector2(rect.center.dx - 50, rect.top + 20),
    );

    // Turn indicator
    final turnText = playerTurn ? 'Your turn' : 'AI thinking...';
    TextPaint(
      style: const TextStyle(fontSize: 14, color: Colors.white70),
    ).render(canvas, turnText, Vector2(rect.center.dx - 40, rect.top + 50));

    // Buttons
    if (playerTurn && !gameOver) {
      for (int i = 1; i <= 3; i++) {
        if (i > stones) continue;
        final buttonRect = Rect.fromLTWH(
          rect.left + 30 + (i - 1) * 90,
          rect.bottom - 60,
          70,
          45,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(buttonRect, const Radius.circular(8)),
          Paint()..color = const Color(0xFF2A9D8F),
        );

        TextPaint(
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ).render(
          canvas,
          'Take $i',
          Vector2(buttonRect.center.dx - 25, buttonRect.center.dy - 9),
        );
      }
    }

    // Game over
    if (gameOver) {
      final resultText = playerWon ? 'You Win!' : 'AI Wins!';
      final resultColor = playerWon
          ? const Color(0xFF2A9D8F)
          : const Color(0xFFE76F51);
      TextPaint(style: TextStyle(fontSize: 28, color: resultColor)).render(
        canvas,
        resultText,
        Vector2(rect.center.dx - 60, rect.center.dy + 40),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (!playerTurn || gameOver) return;

    final rect = boardRect(gameSize);

    for (int i = 1; i <= 3; i++) {
      if (i > stones) continue;
      final buttonRect = Rect.fromLTWH(
        rect.left + 30 + (i - 1) * 90,
        rect.bottom - 60,
        70,
        45,
      );

      if (buttonRect.contains(Offset(position.x, position.y))) {
        _playerTake(i);
        return;
      }
    }
  }
}
