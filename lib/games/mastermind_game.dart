import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class MastermindGame extends MiniGame {
  @override
  String get name => 'Mastermind';

  @override
  String get instructions => 'Guess the secret code!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 8;

  final List<Color> colorOptions = [
    const Color(0xFFE76F51),
    const Color(0xFF2A9D8F),
    const Color(0xFFE9C46A),
    const Color(0xFF264653),
    const Color(0xFFF4A261),
    const Color(0xFF6D597A),
  ];

  final Random _rng = Random();
  late List<int> secret;
  late List<List<int>> guesses;
  late List<List<int>>
  feedback; // 2 = correct pos, 1 = wrong pos, 0 = not in code
  int currentGuess = 0;
  int codeLength = 4;
  int numColors = 4;
  int maxGuesses = 10;
  List<int> currentInput = [];

  // Animation
  List<_Particle> particles = [];
  List<double> pegScales = []; // For current input
  double feedbackTimer = 0;
  List<int> feedbackReveal = []; // How many feedback pegs to show
  double shake = 0;

  @override
  void reset(Vector2 size) {
    codeLength = level >= 5 ? 5 : 4;
    numColors = 3 + level;
    numColors = numColors.clamp(4, 6);
    maxGuesses = 12 - level;
    maxGuesses = maxGuesses.clamp(6, 12);

    secret = List.generate(codeLength, (_) => _rng.nextInt(numColors));
    guesses = [];
    feedback = [];
    currentGuess = 0;
    currentInput = [];

    particles = [];
    pegScales = [];
    feedbackTimer = 0;
    feedbackReveal = [];
    shake = 0;
  }

  @override
  bool get isSolved {
    if (guesses.isEmpty) return false;
    final last = guesses.last;
    for (int i = 0; i < codeLength; i++) {
      if (last[i] != secret[i]) return false;
    }
    return true;
  }

  List<int> _getFeedback(List<int> guess) {
    final result = <int>[];
    final secretCopy = List<int>.from(secret);
    final guessCopy = List<int>.from(guess);

    // Check exact matches first
    for (int i = 0; i < codeLength; i++) {
      if (guessCopy[i] == secretCopy[i]) {
        result.add(2);
        secretCopy[i] = -1;
        guessCopy[i] = -2;
      }
    }

    // Check color matches
    for (int i = 0; i < codeLength; i++) {
      if (guessCopy[i] >= 0) {
        final idx = secretCopy.indexOf(guessCopy[i]);
        if (idx >= 0) {
          result.add(1);
          secretCopy[idx] = -1;
        }
      }
    }

    while (result.length < codeLength) {
      result.add(0);
    }

    result.sort((a, b) => b - a);
    return result;
  }

  void _spawnParticles(Offset pos, Color color) {
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 30 + _rng.nextDouble() * 50;
      particles.add(
        _Particle(
          pos: pos,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.5 + _rng.nextDouble() * 0.4,
          size: 3 + _rng.nextDouble() * 3,
          color: color,
        ),
      );
    }
  }

  void _submitGuess() {
    if (currentInput.length != codeLength) return;
    if (currentGuess >= maxGuesses) return;

    final feedbackResult = _getFeedback(currentInput);
    guesses.add(List<int>.from(currentInput));
    feedback.add(feedbackResult);
    feedbackReveal.add(0); // Start with 0 revealed
    feedbackTimer = 0.5; // Start reveal timer

    // Check win
    bool win = true;
    for (int i = 0; i < codeLength; i++) {
      if (currentInput[i] != secret[i]) win = false;
    }

    if (win) {
      _spawnParticles(Offset(200, 300), Colors.white); // Center burst
    } else {
      shake = 0.5;
    }

    currentGuess++;
    currentInput = [];
    pegScales = [];
  }

  @override
  void update(double dt) {
    // Particle update
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      particles[i].vel += Offset(0, 100 * dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    // Shake decay
    if (shake > 0) {
      shake -= dt * 2;
      if (shake < 0) shake = 0;
    }

    // Peg scales
    for (int i = 0; i < pegScales.length; i++) {
      if (pegScales[i] < 1.0) {
        pegScales[i] += dt * 5;
        if (pegScales[i] > 1.0) pegScales[i] = 1.0;
      }
    }

    // Feedback reveal
    if (feedbackReveal.isNotEmpty && feedback.isNotEmpty) {
      final lastIdx = feedback.length - 1;
      if (feedbackReveal[lastIdx] < feedback[lastIdx].length) {
        feedbackTimer -= dt;
        if (feedbackTimer <= 0) {
          feedbackReveal[lastIdx]++;
          feedbackTimer = 0.15; // Next peg delay
        }
      }
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cellSize = rect.width / (codeLength + 2);

    if (shake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shake * 10,
        (_rng.nextDouble() - 0.5) * shake * 10,
      );
    }

    // Draw color picker at bottom
    final pickerY = rect.bottom - cellSize - 10;
    for (int i = 0; i < numColors; i++) {
      final x = rect.left + i * (cellSize + 5);
      final paint = Paint()..color = colorOptions[i];
      canvas.drawCircle(
        Offset(x + cellSize / 2, pickerY + cellSize / 2),
        cellSize * 0.4,
        paint,
      );
    }

    // Draw current input
    final inputY = pickerY - cellSize - 20;
    for (int i = 0; i < codeLength; i++) {
      final x = rect.left + i * (cellSize + 5);
      final cellRect = Rect.fromLTWH(x, inputY, cellSize, cellSize);

      if (i < currentInput.length) {
        double scale = 1.0;
        if (i < pegScales.length) scale = pegScales[i];

        canvas.drawCircle(
          cellRect.center,
          cellSize * 0.4 * scale,
          Paint()..color = colorOptions[currentInput[i]],
        );
      } else {
        canvas.drawCircle(
          cellRect.center,
          cellSize * 0.4,
          Paint()
            ..color = const Color(0xFF3A4452)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Draw previous guesses
    for (int g = 0; g < guesses.length && g < 6; g++) {
      final y = rect.top + g * (cellSize + 5);
      for (int i = 0; i < codeLength; i++) {
        final x = rect.left + i * (cellSize + 5);
        canvas.drawCircle(
          Offset(x + cellSize / 2, y + cellSize / 2),
          cellSize * 0.35,
          Paint()..color = colorOptions[guesses[g][i]],
        );
      }

      // Feedback pegs
      if (g < feedback.length && g < feedbackReveal.length) {
        final fbX = rect.left + codeLength * (cellSize + 5) + 10;
        final count = feedbackReveal[g];

        for (int i = 0; i < count; i++) {
          final pegColor = feedback[g][i] == 2
              ? const Color(0xFF2A9D8F)
              : (feedback[g][i] == 1 ? Colors.white : const Color(0xFF3A4452));
          canvas.drawCircle(
            Offset(fbX + (i % 2) * 15, y + (i ~/ 2) * 15 + 10),
            5,
            Paint()..color = pegColor,
          );
        }
      }
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.pos,
        p.size * p.life,
        Paint()..color = p.color.withValues(alpha: p.life),
      );
    }

    if (shake > 0) canvas.restore();
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved || currentGuess >= maxGuesses) return;

    final rect = boardRect(gameSize);
    final cellSize = rect.width / (codeLength + 2);
    final pickerY = rect.bottom - cellSize - 10;

    // Check color picker tap
    for (int i = 0; i < numColors; i++) {
      final x = rect.left + i * (cellSize + 5);
      final center = Offset(x + cellSize / 2, pickerY + cellSize / 2);
      if ((position.x - center.dx).abs() < cellSize / 2 &&
          (position.y - center.dy).abs() < cellSize / 2) {
        if (currentInput.length < codeLength) {
          currentInput.add(i);
          pegScales.add(0.0); // Animate in
          _spawnParticles(center, colorOptions[i].withValues(alpha: 0.5));

          if (currentInput.length == codeLength) {
            Future.delayed(const Duration(milliseconds: 300), () {
              _submitGuess();
            });
          }
        }
        return;
      }
    }
  }

  @override
  void onLongPressDown(Vector2 position, Vector2 gameSize) {
    // Clear current input
    currentInput = [];
    pegScales = [];
  }
}

class _Particle {
  Offset pos, vel;
  double life, size;
  Color color;
  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
  });
}
