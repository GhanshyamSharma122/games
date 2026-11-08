import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class MathSpeedGame extends MiniGame {
  @override
  String get name => 'Math Speed';

  @override
  String get instructions => 'Solve math problems quickly!';

  final Random _rng = Random();
  int num1 = 0;
  int num2 = 0;
  String op = '+';
  int correctAnswer = 0;
  List<int> options = [];
  int score = 0;
  int targetScore = 10;
  int maxNum = 10;
  bool includeMultiply = false;
  bool includeDivide = false;

  @override
  void reset(Vector2 size) {
    targetScore = 5 + level * 2;
    maxNum = 10 + level * 5;
    includeMultiply = level >= 3;
    includeDivide = level >= 5;

    score = 0;
    _generateProblem();
  }

  void _generateProblem() {
    final ops = ['+', '-'];
    if (includeMultiply) ops.add('×');
    if (includeDivide) ops.add('÷');

    op = ops[_rng.nextInt(ops.length)];

    if (op == '÷') {
      // Ensure clean division
      num2 = 1 + _rng.nextInt(10);
      correctAnswer = 1 + _rng.nextInt(10);
      num1 = num2 * correctAnswer;
    } else if (op == '×') {
      num1 = 1 + _rng.nextInt(12);
      num2 = 1 + _rng.nextInt(12);
      correctAnswer = num1 * num2;
    } else if (op == '-') {
      num1 = _rng.nextInt(maxNum) + 5;
      num2 = _rng.nextInt(num1);
      correctAnswer = num1 - num2;
    } else {
      num1 = _rng.nextInt(maxNum);
      num2 = _rng.nextInt(maxNum);
      correctAnswer = num1 + num2;
    }

    // Generate wrong options
    options = [correctAnswer];
    while (options.length < 4) {
      final wrong = correctAnswer + _rng.nextInt(11) - 5;
      if (wrong != correctAnswer && wrong >= 0 && !options.contains(wrong)) {
        options.add(wrong);
      }
    }
    options.shuffle(_rng);
  }

  @override
  bool get isSolved => score >= targetScore;

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final bgPaint = Paint()..color = const Color(0xFF1B2430);
    canvas.drawRect(rect, bgPaint);

    // Problem
    final problemPaint = TextPaint(
      style: const TextStyle(fontSize: 36, color: Colors.white),
    );
    final problem = '$num1 $op $num2 = ?';
    problemPaint.render(
      canvas,
      problem,
      Vector2(rect.center.dx - 80, rect.top + 40),
    );

    // Score
    TextPaint(
      style: const TextStyle(fontSize: 18, color: Colors.white70),
    ).render(
      canvas,
      '$score / $targetScore',
      Vector2(rect.center.dx - 30, rect.top + 10),
    );

    // Options
    final buttonWidth = rect.width / 2 - 20;
    final buttonHeight = 60.0;
    final optionPaint = Paint()..color = const Color(0xFF2A9D8F);
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 28, color: Colors.white),
    );

    for (int i = 0; i < 4; i++) {
      final row = i ~/ 2;
      final col = i % 2;
      final buttonRect = Rect.fromLTWH(
        rect.left + col * (buttonWidth + 20) + 10,
        rect.top + 120 + row * (buttonHeight + 20),
        buttonWidth,
        buttonHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(buttonRect, const Radius.circular(12)),
        optionPaint,
      );

      textPaint.render(
        canvas,
        options[i].toString(),
        Vector2(buttonRect.center.dx - 15, buttonRect.center.dy - 14),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved) return;

    final rect = boardRect(gameSize);
    final buttonWidth = rect.width / 2 - 20;
    final buttonHeight = 60.0;

    for (int i = 0; i < 4; i++) {
      final row = i ~/ 2;
      final col = i % 2;
      final buttonRect = Rect.fromLTWH(
        rect.left + col * (buttonWidth + 20) + 10,
        rect.top + 120 + row * (buttonHeight + 20),
        buttonWidth,
        buttonHeight,
      );

      if (buttonRect.contains(Offset(position.x, position.y))) {
        if (options[i] == correctAnswer) {
          score++;
          _generateProblem();
        } else {
          // Wrong answer - could add penalty
          _generateProblem();
        }
        return;
      }
    }
  }
}
