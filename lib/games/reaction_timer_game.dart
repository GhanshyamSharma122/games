import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';

class ReactionTimerGame extends MiniGame {
  @override
  String get name => 'Reaction Timer';

  @override
  String get instructions => 'Tap when the screen turns green!';

  final Random _rng = Random();
  double waitTime = 0;
  double elapsedTime = 0;
  bool waiting = true;
  bool canTap = false;
  bool tooEarly = false;
  int? reactionTime;
  int roundsCompleted = 0;
  int targetRounds = 5;
  List<int> times = [];
  int targetAvg = 400;

  // Animation
  double pulseTimer = 0;
  double flashIntensity = 0;
  double shakeAmount = 0;
  double resultScale = 0;
  Color bgColor = const Color(0xFF1B2430);
  Color targetBgColor = const Color(0xFF1B2430);

  @override
  void reset(Vector2 size) {
    targetRounds = 3 + level;
    targetAvg = 500 - level * 30;
    targetAvg = targetAvg.clamp(200, 500);

    _startRound();
    roundsCompleted = 0;
    times = [];
    resultScale = 0;
  }

  void _startRound() {
    waitTime = 1.5 + _rng.nextDouble() * 3;
    elapsedTime = 0;
    waiting = true;
    canTap = false;
    tooEarly = false;
    reactionTime = null;
    targetBgColor = const Color(0xFFE76F51);
    flashIntensity = 0;
    resultScale = 0;
  }

  @override
  bool get isSolved {
    if (times.length < targetRounds) return false;
    final avg = times.reduce((a, b) => a + b) / times.length;
    return avg <= targetAvg;
  }

  @override
  void update(double dt) {
    pulseTimer += dt * 4;

    // Smooth color transition
    bgColor = Color.lerp(bgColor, targetBgColor, dt * 8)!;

    // Flash decay
    if (flashIntensity > 0) {
      flashIntensity -= dt * 4;
    }

    // Shake decay
    if (shakeAmount > 0) {
      shakeAmount -= dt * 10;
    }

    // Result scale animation
    if (reactionTime != null && resultScale < 1.0) {
      resultScale += dt * 5;
      if (resultScale > 1.0) resultScale = 1.0;
    }

    if (tooEarly || reactionTime != null) return;

    elapsedTime += dt;

    if (waiting && elapsedTime >= waitTime) {
      waiting = false;
      canTap = true;
      elapsedTime = 0;
      targetBgColor = const Color(0xFF2A9D8F);
      flashIntensity = 1.0;
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Apply shake
    if (shakeAmount > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shakeAmount * 10,
        (_rng.nextDouble() - 0.5) * shakeAmount * 10,
      );
    }

    // Background with flash
    var displayColor = bgColor;
    if (flashIntensity > 0) {
      displayColor = Color.lerp(bgColor, Colors.white, flashIntensity * 0.3)!;
    }
    canvas.drawRect(rect, Paint()..color = displayColor);

    // Animated circles in background
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    for (int i = 3; i >= 0; i--) {
      final pulse = sin(pulseTimer + i * 0.5) * 20;
      final radius = 100 + i * 60 + pulse;
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.03 + i * 0.01)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    String text;
    double fontSize = 32;

    if (tooEarly) {
      text = 'Too early!';
      fontSize = 36;
    } else if (waiting) {
      text = 'Wait...';
      final dots = ((elapsedTime * 2) % 4).floor();
      text = 'Wait${'.' * dots}';
    } else if (canTap && reactionTime == null) {
      text = 'TAP NOW!';
      fontSize = 48;
    } else if (reactionTime != null) {
      text = '${reactionTime}ms';
      fontSize = 48 * resultScale;
    } else {
      text = 'Tap to start';
    }

    final textPaint = TextPaint(
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
    );

    final textWidth = textPaint.getLineMetrics(text).width;
    textPaint.render(
      canvas,
      text,
      Vector2(centerX - textWidth / 2, centerY - fontSize / 2),
    );

    // Round indicator
    if (roundsCompleted > 0 || reactionTime != null || times.isNotEmpty) {
      final roundText =
          'Round ${roundsCompleted + (reactionTime != null ? 0 : 1)}/$targetRounds';
      final roundPaint = TextPaint(
        style: const TextStyle(fontSize: 18, color: Colors.white70),
      );
      final roundWidth = roundPaint.getLineMetrics(roundText).width;
      roundPaint.render(
        canvas,
        roundText,
        Vector2(centerX - roundWidth / 2, centerY + 60),
      );
    }

    // Progress dots
    for (int i = 0; i < targetRounds; i++) {
      final dotX = centerX - (targetRounds - 1) * 12 / 2 + i * 12;
      final dotY = centerY + 100;
      final completed = i < times.length;
      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()..color = completed ? Colors.white : Colors.white24,
      );
    }

    if (times.isNotEmpty && isSolved) {
      final avg = times.reduce((a, b) => a + b) ~/ times.length;
      final avgPaint = TextPaint(
        style: const TextStyle(
          fontSize: 22,
          color: Color(0xFFE9C46A),
          fontWeight: FontWeight.bold,
        ),
      );
      final avgText = 'Average: ${avg}ms';
      final avgWidth = avgPaint.getLineMetrics(avgText).width;
      avgPaint.render(
        canvas,
        avgText,
        Vector2(centerX - avgWidth / 2, centerY + 130),
      );
    }

    // Tap hint
    if (tooEarly) {
      final hintPaint = TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.white60),
      );
      hintPaint.render(
        canvas,
        'Tap to retry',
        Vector2(centerX - 40, centerY + 40),
      );
    }

    if (shakeAmount > 0) {
      canvas.restore();
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (tooEarly) {
      _startRound();
      return;
    }

    if (waiting) {
      tooEarly = true;
      targetBgColor = const Color(0xFFE63946);
      shakeAmount = 1.0;
      return;
    }

    if (canTap && reactionTime == null) {
      reactionTime = (elapsedTime * 1000).round();
      times.add(reactionTime!);
      roundsCompleted++;
      canTap = false;
      targetBgColor = const Color(0xFF264653);
      flashIntensity = 0.5;

      if (roundsCompleted < targetRounds) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          _startRound();
        });
      }
      return;
    }
  }
}
