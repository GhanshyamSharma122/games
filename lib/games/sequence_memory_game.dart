import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class SequenceMemoryGame extends MiniGame {
  @override
  String get name => 'Sequence Memory';

  @override
  String get instructions => 'Remember and repeat the number sequence!';

  final Random _rng = Random();
  List<int> sequence = [];
  int playerIndex = 0;
  bool showingSequence = true;
  int showIndex = 0;
  double timer = 0;
  int? highlightedButton;
  bool failed = false;
  int targetLength = 5;

  @override
  void reset(Vector2 size) {
    targetLength = 3 + level;
    sequence = List.generate(3, (_) => _rng.nextInt(9));
    playerIndex = 0;
    showingSequence = true;
    showIndex = 0;
    timer = 0;
    highlightedButton = null;
    failed = false;
  }

  @override
  bool get isSolved =>
      !failed &&
      sequence.length >= targetLength &&
      !showingSequence &&
      playerIndex >= sequence.length;

  @override
  void update(double dt) {
    if (failed || isSolved) return;

    if (showingSequence) {
      timer += dt;
      if (timer < 0.6) {
        highlightedButton = sequence[showIndex];
      } else if (timer < 0.8) {
        highlightedButton = null;
      } else {
        timer = 0;
        showIndex++;
        if (showIndex >= sequence.length) {
          showingSequence = false;
          showIndex = 0;
        }
      }
    }
  }

  void _handleTap(int button) {
    if (showingSequence || failed || isSolved) return;

    highlightedButton = button;
    Future.delayed(const Duration(milliseconds: 150), () {
      highlightedButton = null;
    });

    if (sequence[playerIndex] == button) {
      playerIndex++;
      if (playerIndex >= sequence.length) {
        if (sequence.length >= targetLength) {
          // Won!
        } else {
          // Add next to sequence
          sequence.add(_rng.nextInt(9));
          playerIndex = 0;
          showingSequence = true;
          showIndex = 0;
          timer = 0;
        }
      }
    } else {
      failed = true;
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cellSize = rect.width / 3 - 10;

    final normalPaint = Paint()..color = const Color(0xFF2A3442);
    final highlightPaint = Paint()..color = const Color(0xFF2A9D8F);
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 32, color: Colors.white),
    );

    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final buttonRect = Rect.fromLTWH(
        rect.left + col * (cellSize + 10),
        rect.top + row * (cellSize + 10),
        cellSize,
        cellSize,
      );

      final isHighlighted = highlightedButton == i;
      canvas.drawRRect(
        RRect.fromRectAndRadius(buttonRect, const Radius.circular(12)),
        isHighlighted ? highlightPaint : normalPaint,
      );

      textPaint.render(
        canvas,
        '${i + 1}',
        Vector2(buttonRect.center.dx - 10, buttonRect.center.dy - 16),
      );
    }

    // Status
    final statusPaint = TextPaint(
      style: const TextStyle(fontSize: 16, color: Colors.white70),
    );
    final status = showingSequence
        ? 'Watch...'
        : (failed
              ? 'Wrong!'
              : 'Your turn: ${playerIndex + 1}/${sequence.length}');
    statusPaint.render(canvas, status, Vector2(rect.left, rect.bottom + 10));

    if (failed) {
      final overlay = Paint()..color = const Color(0x88E63946);
      canvas.drawRect(rect, overlay);
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final cellSize = rect.width / 3 - 10;

    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final buttonRect = Rect.fromLTWH(
        rect.left + col * (cellSize + 10),
        rect.top + row * (cellSize + 10),
        cellSize,
        cellSize,
      );

      if (buttonRect.contains(Offset(position.x, position.y))) {
        _handleTap(i);
        break;
      }
    }
  }
}
