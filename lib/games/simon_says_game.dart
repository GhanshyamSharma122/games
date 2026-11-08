import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class SimonSaysGame extends MiniGame {
  @override
  String get name => 'Simon Says';

  @override
  String get instructions => 'Watch the pattern, then repeat it!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final Random _rng = Random();
  List<int> sequence = [];
  int inputIndex = 0;
  bool showingSequence = true;
  int showIndex = 0;
  double showTimer = 0;
  double showDuration = 0.6;
  int targetLength = 4;
  bool gameOver = false;

  // Animation
  late List<double> buttonGlow; // Glow intensity 0-1
  late List<double> buttonScale; // Scale for bounce
  double successPulse = 0;
  bool showingSuccess = false;
  List<_Particle> particles = [];

  static const buttonColors = [
    Color(0xFFE76F51), // Red
    Color(0xFF2A9D8F), // Green
    Color(0xFF264653), // Blue
    Color(0xFFE9C46A), // Yellow
  ];

  @override
  void reset(Vector2 size) {
    targetLength = 3 + level;
    showDuration = 0.7 - level * 0.03;
    showDuration = showDuration.clamp(0.3, 0.7);

    sequence = [_rng.nextInt(4)];
    inputIndex = 0;
    showingSequence = true;
    showIndex = 0;
    showTimer = 0;
    gameOver = false;
    buttonGlow = List.generate(4, (_) => 0.0);
    buttonScale = List.generate(4, (_) => 1.0);
    successPulse = 0;
    showingSuccess = false;
    particles = [];
  }

  @override
  bool get isSolved =>
      sequence.length > targetLength && !showingSequence && !gameOver;

  void _addToSequence() {
    sequence.add(_rng.nextInt(4));
    showIndex = 0;
    showTimer = 0;
    showingSequence = true;
  }

  void _spawnSuccessParticles(Offset center) {
    for (int i = 0; i < 20; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 100;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: buttonColors[_rng.nextInt(4)],
          size: 4 + _rng.nextDouble() * 4,
          life: 0.8,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    // Update button glow decay
    for (int i = 0; i < 4; i++) {
      if (buttonGlow[i] > 0) {
        buttonGlow[i] -= dt * 3;
        if (buttonGlow[i] < 0) buttonGlow[i] = 0;
      }
      // Bounce back scale
      if (buttonScale[i] != 1.0) {
        buttonScale[i] += (1.0 - buttonScale[i]) * dt * 10;
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }

    // Success animation
    if (showingSuccess) {
      successPulse -= dt * 2;
      if (successPulse <= 0) {
        showingSuccess = false;
        _addToSequence();
      }
    }

    if (!showingSequence || gameOver || showingSuccess) return;

    showTimer += dt;

    // Light up current button
    if (showIndex < sequence.length) {
      buttonGlow[sequence[showIndex]] = 1.0;
    }

    if (showTimer >= showDuration) {
      showTimer = 0;
      showIndex++;
      if (showIndex >= sequence.length) {
        showingSequence = false;
        inputIndex = 0;
      }
    }
  }

  Rect _buttonRect(int index, Rect bounds) {
    final size = bounds.width / 2 - 15;
    final x = index % 2 == 0
        ? bounds.left + 5
        : bounds.left + bounds.width / 2 + 5;
    final y = index < 2 ? bounds.top + 5 : bounds.top + bounds.height / 2 + 5;
    return Rect.fromLTWH(x, y, size, size);
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final bgPaint = Paint()..color = const Color(0xFF1B2430);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      bgPaint,
    );

    // Draw buttons
    for (int i = 0; i < 4; i++) {
      final btnRect = _buttonRect(i, rect);
      final scale = buttonScale[i];
      final scaledRect = Rect.fromCenter(
        center: btnRect.center,
        width: btnRect.width * scale,
        height: btnRect.height * scale,
      );

      final baseColor = buttonColors[i];
      final glowAmount = buttonGlow[i];

      // Glow effect
      if (glowAmount > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            scaledRect.inflate(8),
            const Radius.circular(24),
          ),
          Paint()
            ..color = baseColor.withOpacity(glowAmount * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
        );
      }

      // Button shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          scaledRect.translate(3, 3),
          const Radius.circular(18),
        ),
        Paint()..color = Colors.black.withOpacity(0.3),
      );

      // Button base
      final buttonColor = Color.lerp(
        baseColor,
        Colors.white,
        glowAmount * 0.4,
      )!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(18)),
        Paint()..color = buttonColor,
      );

      // Button highlight
      final highlightRect = Rect.fromLTWH(
        scaledRect.left + scaledRect.width * 0.1,
        scaledRect.top + scaledRect.height * 0.1,
        scaledRect.width * 0.8,
        scaledRect.height * 0.3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(12)),
        Paint()..color = Colors.white.withOpacity(0.2 + glowAmount * 0.2),
      );
    }

    // Center indicator
    final centerSize = 60.0;
    final centerRect = Rect.fromCenter(
      center: rect.center,
      width: centerSize,
      height: centerSize,
    );
    canvas.drawOval(centerRect, Paint()..color = const Color(0xFF0E1117));

    // Progress dots
    final dotCount = sequence.length.clamp(0, 10);
    for (int i = 0; i < dotCount; i++) {
      final angle = -pi / 2 + (i / 10) * 2 * pi;
      final dotPos = Offset(
        rect.center.dx + cos(angle) * 22,
        rect.center.dy + sin(angle) * 22,
      );
      canvas.drawCircle(
        dotPos,
        4,
        Paint()
          ..color = i < inputIndex
              ? const Color(0xFF2A9D8F)
              : const Color(0xFF3A4452),
      );
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }

    if (gameOver) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(20)),
        Paint()..color = const Color(0x88E63946),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (showingSequence || gameOver || isSolved || showingSuccess) return;

    final rect = boardRect(gameSize);

    for (int i = 0; i < 4; i++) {
      final btnRect = _buttonRect(i, rect);
      if (btnRect.contains(Offset(position.x, position.y))) {
        buttonGlow[i] = 1.0;
        buttonScale[i] = 0.9;

        if (i == sequence[inputIndex]) {
          inputIndex++;
          if (inputIndex >= sequence.length) {
            // Completed sequence!
            showingSuccess = true;
            successPulse = 0.8;
            _spawnSuccessParticles(rect.center);
          }
        } else {
          gameOver = true;
        }
        break;
      }
    }
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
  });

  void update(double dt) {
    position = position + velocity * dt;
    velocity = velocity * 0.95;
    life -= dt * 1.5;
  }
}
