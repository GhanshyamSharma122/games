import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class ColorMatchGame extends MiniGame {
  @override
  String get name => 'Color Match';

  @override
  String get instructions => 'Does the word match the color? Tap Yes/No!';

  final Random _rng = Random();
  final List<String> colorNames = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
  final List<Color> colors = [
    const Color(0xFFE76F51),
    const Color(0xFF264653),
    const Color(0xFF2A9D8F),
    const Color(0xFFE9C46A),
  ];

  late String displayedWord;
  late Color displayedColor;
  late bool isMatch;
  int score = 0;
  int targetScore = 10;
  double timeLimit = 3.0;
  double timer = 0;
  bool timedOut = false;

  // Animation
  double wordScale = 1.0;
  double wordShake = 0;
  double yesScale = 1.0;
  double noScale = 1.0;
  double flashIntensity = 0;
  Color flashColor = Colors.transparent;
  double pulseTimer = 0;
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    targetScore = 5 + level * 2;
    timeLimit = 4.0 - level * 0.3;
    timeLimit = timeLimit.clamp(1.5, 4.0);

    score = 0;
    particles = [];
    _generatePuzzle();
  }

  void _generatePuzzle() {
    final wordIndex = _rng.nextInt(4);
    displayedWord = colorNames[wordIndex];

    isMatch = _rng.nextBool();
    if (isMatch) {
      displayedColor = colors[wordIndex];
    } else {
      int colorIndex;
      do {
        colorIndex = _rng.nextInt(4);
      } while (colorIndex == wordIndex);
      displayedColor = colors[colorIndex];
    }

    timer = 0;
    timedOut = false;
    wordScale = 0.0;
    wordShake = 0;
  }

  @override
  bool get isSolved => score >= targetScore;

  @override
  void update(double dt) {
    pulseTimer += dt * 3;

    // Word pop-in animation
    if (wordScale < 1.0) {
      wordScale += dt * 6;
      if (wordScale > 1.0) wordScale = 1.0;
    }

    // Shake decay
    if (wordShake > 0) {
      wordShake -= dt * 10;
    }

    // Button scale animations
    if (yesScale < 1.0) {
      yesScale += dt * 8;
      if (yesScale > 1.0) yesScale = 1.0;
    }
    if (noScale < 1.0) {
      noScale += dt * 8;
      if (noScale > 1.0) noScale = 1.0;
    }

    // Flash decay
    if (flashIntensity > 0) {
      flashIntensity -= dt * 4;
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (isSolved || timedOut) return;

    timer += dt;
    if (timer >= timeLimit) {
      timedOut = true;
      score = 0;
      flashIntensity = 1.0;
      flashColor = const Color(0xFFE63946);
      wordShake = 1.0;
      Future.delayed(const Duration(milliseconds: 800), () {
        _generatePuzzle();
      });
    }
  }

  void _spawnCorrectParticles(Offset center) {
    for (int i = 0; i < 15; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 100;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: const Color(0xFF2A9D8F),
          size: 4 + _rng.nextDouble() * 3,
          life: 0.6,
        ),
      );
    }
  }

  void _answer(bool playerSaysMatch) {
    if (isSolved || timedOut) return;

    if (playerSaysMatch == isMatch) {
      score++;
      flashIntensity = 0.5;
      flashColor = const Color(0xFF2A9D8F);
      _spawnCorrectParticles(Offset(200, 300));
    } else {
      score = (score - 1).clamp(0, targetScore);
      flashIntensity = 0.5;
      flashColor = const Color(0xFFE63946);
      wordShake = 1.0;
    }

    if (!isSolved) {
      _generatePuzzle();
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Flash overlay
    if (flashIntensity > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = flashColor.withOpacity(flashIntensity * 0.3),
      );
    }

    // Timer bar with animation
    final timerProgress = 1.0 - timer / timeLimit;
    final timerWidth = timerProgress * rect.width;
    final timerColor = timerProgress > 0.3
        ? const Color(0xFF2A9D8F)
        : Color.lerp(
            const Color(0xFFE63946),
            const Color(0xFFE9C46A),
            timerProgress / 0.3,
          )!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, 10),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF1B2430),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, timerWidth, 10),
        const Radius.circular(5),
      ),
      Paint()..color = timerColor,
    );

    // Score with animation
    final scoreText = '$score / $targetScore';
    final scorePaint = TextPaint(
      style: const TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    final scoreWidth = scorePaint.getLineMetrics(scoreText).width;
    scorePaint.render(
      canvas,
      scoreText,
      Vector2(rect.center.dx - scoreWidth / 2, rect.top + 25),
    );

    // Word with animations
    final shake = sin(wordShake * pi * 8) * wordShake * 10;
    final wordPaint = TextPaint(
      style: TextStyle(
        fontSize: 56 * wordScale,
        color: displayedColor,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: displayedColor.withOpacity(0.3), blurRadius: 20),
        ],
      ),
    );
    final wordWidth = wordPaint.getLineMetrics(displayedWord).width;
    wordPaint.render(
      canvas,
      displayedWord,
      Vector2(rect.center.dx - wordWidth / 2 + shake, rect.center.dy - 80),
    );

    // Buttons with animations
    final buttonWidth = rect.width / 2 - 20;
    final buttonHeight = 70.0;

    final yesRect = Rect.fromCenter(
      center: Offset(rect.left + buttonWidth / 2 + 10, rect.bottom - 60),
      width: buttonWidth * yesScale,
      height: buttonHeight * yesScale,
    );
    final noRect = Rect.fromCenter(
      center: Offset(rect.right - buttonWidth / 2 - 10, rect.bottom - 60),
      width: buttonWidth * noScale,
      height: buttonHeight * noScale,
    );

    // Button shadows
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        yesRect.translate(2, 4),
        const Radius.circular(16),
      ),
      Paint()..color = Colors.black.withOpacity(0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        noRect.translate(2, 4),
        const Radius.circular(16),
      ),
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    // Buttons
    canvas.drawRRect(
      RRect.fromRectAndRadius(yesRect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF2A9D8F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(noRect, const Radius.circular(16)),
      Paint()..color = const Color(0xFFE76F51),
    );

    // Button highlights
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          yesRect.left + 4,
          yesRect.top + 4,
          yesRect.width - 8,
          yesRect.height * 0.3,
        ),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white.withOpacity(0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          noRect.left + 4,
          noRect.top + 4,
          noRect.width - 8,
          noRect.height * 0.3,
        ),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white.withOpacity(0.2),
    );

    final buttonText = TextPaint(
      style: const TextStyle(
        fontSize: 28,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    buttonText.render(
      canvas,
      'YES',
      Vector2(yesRect.center.dx - 28, yesRect.center.dy - 14),
    );
    buttonText.render(
      canvas,
      'NO',
      Vector2(noRect.center.dx - 18, noRect.center.dy - 14),
    );

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }

    if (timedOut) {
      TextPaint(
        style: const TextStyle(
          fontSize: 28,
          color: Color(0xFFE63946),
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        'Too slow!',
        Vector2(rect.center.dx - 60, rect.center.dy - 20),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final buttonWidth = rect.width / 2 - 20;
    final buttonHeight = 70.0;
    final yesRect = Rect.fromLTWH(
      rect.left + 10,
      rect.bottom - 95,
      buttonWidth,
      buttonHeight,
    );
    final noRect = Rect.fromLTWH(
      rect.right - buttonWidth - 10,
      rect.bottom - 95,
      buttonWidth,
      buttonHeight,
    );

    if (yesRect.contains(Offset(position.x, position.y))) {
      yesScale = 0.9;
      _answer(true);
    } else if (noRect.contains(Offset(position.x, position.y))) {
      noScale = 0.9;
      _answer(false);
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
    velocity = velocity * 0.94;
    life -= dt * 1.5;
  }
}
