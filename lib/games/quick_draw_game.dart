import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class QuickDrawGame extends MiniGame {
  @override
  String get name => 'Quick Draw';

  @override
  String get instructions => 'Tap when you see GO! Don\'t jump the gun!';

  final Random _rng = Random();
  double waitTime = 0;
  double elapsedTime = 0;
  int phase =
      0; // 0 = waiting to start, 1 = wait for signal, 2 = GO!, 3 = result
  int? reactionTime;
  bool tooEarly = false;
  int wins = 0;
  int targetWins = 5;
  int aiReaction = 0;
  bool playerWon = false;

  @override
  void reset(Vector2 size) {
    targetWins = 3 + level;
    wins = 0;
    _startRound();
  }

  void _startRound() {
    waitTime = 1.5 + _rng.nextDouble() * 3;
    elapsedTime = 0;
    phase = 1;
    reactionTime = null;
    tooEarly = false;
    aiReaction = 150 + _rng.nextInt(350 - level * 30);
    aiReaction = aiReaction.clamp(100, 400);
    playerWon = false;
  }

  @override
  bool get isSolved => wins >= targetWins;

  @override
  void update(double dt) {
    if (phase == 1) {
      elapsedTime += dt;
      if (elapsedTime >= waitTime) {
        phase = 2;
        elapsedTime = 0;
      }
    } else if (phase == 2) {
      elapsedTime += dt;
      // AI shoots after its reaction time
      if (reactionTime == null && elapsedTime * 1000 >= aiReaction) {
        // AI shot first!
        reactionTime = aiReaction;
        playerWon = false;
        phase = 3;
      }
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    Color bgColor;
    String text;

    if (phase == 0) {
      bgColor = const Color(0xFF264653);
      text = 'Tap to ready up';
    } else if (phase == 1) {
      bgColor = const Color(0xFFE76F51);
      text = 'WAIT...';
    } else if (phase == 2) {
      bgColor = const Color(0xFF2A9D8F);
      text = 'DRAW!';
    } else if (tooEarly) {
      bgColor = const Color(0xFFE63946);
      text = 'Too early! Tap to retry';
    } else {
      bgColor = const Color(0xFF264653);
      text = playerWon
          ? 'You win! ${reactionTime}ms'
          : 'AI wins! (${aiReaction}ms)';
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()..color = bgColor,
    );

    TextPaint(
      style: const TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ).render(canvas, text, Vector2(rect.center.dx - 100, rect.center.dy - 16));

    // Score
    TextPaint(
      style: const TextStyle(fontSize: 16, color: Colors.white70),
    ).render(
      canvas,
      'Wins: $wins / $targetWins',
      Vector2(rect.center.dx - 50, rect.top + 20),
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (phase == 0) {
      _startRound();
    } else if (phase == 1) {
      tooEarly = true;
      phase = 3;
    } else if (phase == 2) {
      reactionTime = (elapsedTime * 1000).round();
      playerWon = reactionTime! < aiReaction;
      if (playerWon) wins++;
      phase = 3;
    } else if (phase == 3) {
      if (!isSolved) {
        phase = 0;
      }
    }
  }
}
