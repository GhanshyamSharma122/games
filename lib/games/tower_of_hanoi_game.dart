import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class TowerOfHanoiGame extends MiniGame {
  @override
  String get name => 'Tower of Hanoi';

  @override
  String get instructions => 'Move all disks to the right peg!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 6;

  int numDisks = 3;
  late List<List<int>> pegs;
  int? selectedPeg;

  // Animation
  int? movingDisk;
  int? moveFrom;
  int? moveTo;
  double moveProgress = 0;

  @override
  void reset(Vector2 size) {
    numDisks = 2 + level;
    numDisks = numDisks.clamp(3, 8);

    pegs = [List.generate(numDisks, (i) => numDisks - i), [], []];
    selectedPeg = null;
    movingDisk = null;
    moveProgress = 0;
  }

  @override
  bool get isSolved => pegs[2].length == numDisks && movingDisk == null;

  @override
  void update(double dt) {
    if (movingDisk != null) {
      moveProgress += dt * 4; // Speed of animation
      if (moveProgress >= 1.0) {
        // Complete move
        pegs[moveTo!].add(movingDisk!);
        movingDisk = null;
        moveProgress = 0;
      }
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final pegWidth = rect.width / 3;
    final pegX = [
      rect.left + pegWidth * 0.5,
      rect.left + pegWidth * 1.5,
      rect.left + pegWidth * 2.5,
    ];

    final basePaint = Paint()..color = const Color(0xFF3A4452);
    final pegPaint = Paint()..color = const Color(0xFF5A6472);
    final selectPaint = Paint()
      ..color = const Color(0xFFE9C46A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final diskColors = [
      const Color(0xFFE76F51),
      const Color(0xFFF4A261),
      const Color(0xFFE9C46A),
      const Color(0xFF2A9D8F),
      const Color(0xFF264653),
      const Color(0xFF6D597A),
      const Color(0xFFB56576),
      const Color(0xFF355070),
    ];

    // Draw base and pegs
    for (int p = 0; p < 3; p++) {
      // Base
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(pegX[p], rect.bottom - 10),
          width: pegWidth * 0.8,
          height: 10,
        ),
        basePaint,
      );

      // Peg
      canvas.drawRect(
        Rect.fromLTWH(pegX[p] - 4, rect.top + 50, 8, rect.height - 60),
        pegPaint,
      );

      // Selection highlight
      if (selectedPeg == p) {
        canvas.drawRect(
          Rect.fromLTWH(
            pegX[p] - pegWidth * 0.4,
            rect.top + 40,
            pegWidth * 0.8,
            rect.height - 40,
          ),
          selectPaint,
        );
      }

      // Disks
      final diskHeight = 20.0;
      for (int d = 0; d < pegs[p].length; d++) {
        final diskSize = pegs[p][d];
        final diskWidth = 20.0 + diskSize * 15;
        final y = rect.bottom - 20 - d * (diskHeight + 2);

        _drawDisk(
          canvas,
          Offset(pegX[p], y),
          diskWidth,
          diskHeight,
          diskColors[diskSize - 1],
        );
      }
    }

    // Draw moving disk
    if (movingDisk != null) {
      final startX = pegX[moveFrom!];
      final endX = pegX[moveTo!];

      // Parabolic arc? Or simple Up-Over-Down
      // Let's do simple linear X, parabolic Y for jump effect
      final currentX = lerpDouble(startX, endX, moveProgress)!;

      // Height calculation
      final startY =
          rect.bottom - 20 - pegs[moveFrom!].length * 22.0; // was at top
      final endY = rect.bottom - 20 - pegs[moveTo!].length * 22.0;
      final peakY = rect.top + 60.0;

      double currentY;
      if (moveProgress < 0.5) {
        // Going up/over
        final t = moveProgress * 2;
        currentY = lerpDouble(startY, peakY, t)!;
      } else {
        // Going down
        final t = (moveProgress - 0.5) * 2;
        currentY = lerpDouble(peakY, endY, t)!;
      }

      final diskSize = movingDisk!;
      final diskWidth = 20.0 + diskSize * 15;

      _drawDisk(
        canvas,
        Offset(currentX, currentY),
        diskWidth,
        20.0,
        diskColors[diskSize - 1],
      );
    }

    // Peg labels
    final textPaint = TextPaint(
      style: const TextStyle(fontSize: 14, color: Colors.white70),
    );
    for (int p = 0; p < 3; p++) {
      textPaint.render(
        canvas,
        'Peg ${p + 1}',
        Vector2(pegX[p] - 20, rect.top + 20),
      );
    }
  }

  void _drawDisk(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Color color,
  ) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(2, 2), const Radius.circular(4)),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Main body
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = color,
    );

    // Highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + 2,
          rect.top + 2,
          rect.width - 4,
          rect.height * 0.4,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withOpacity(0.2),
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved || movingDisk != null) return;

    final rect = boardRect(gameSize);
    final pegWidth = rect.width / 3;

    int? tappedPeg;
    for (int p = 0; p < 3; p++) {
      final pegX = rect.left + pegWidth * (p + 0.5);
      if ((position.x - pegX).abs() < pegWidth * 0.4) {
        tappedPeg = p;
        break;
      }
    }

    if (tappedPeg == null) return;

    if (selectedPeg == null) {
      if (pegs[tappedPeg].isNotEmpty) {
        selectedPeg = tappedPeg;
      }
    } else {
      if (tappedPeg == selectedPeg) {
        selectedPeg = null;
      } else {
        final sourceTop = pegs[selectedPeg!].last;
        final destTop = pegs[tappedPeg].isEmpty ? 100 : pegs[tappedPeg].last;

        if (sourceTop < destTop) {
          // Start animation instead of immediate move
          movingDisk = pegs[selectedPeg!].removeLast();
          moveFrom = selectedPeg;
          moveTo = tappedPeg;
          moveProgress = 0;
        }
        selectedPeg = null;
      }
    }
  }
}
