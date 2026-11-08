import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class WordScrambleGame extends MiniGame {
  @override
  String get name => 'Word Scramble';

  @override
  String get instructions => 'Unscramble the word! Tap letters in order.';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final Random _rng = Random();
  final List<String> easyWords = ['CAT', 'DOG', 'SUN', 'HAT', 'PEN'];
  final List<String> mediumWords = [
    'APPLE',
    'HOUSE',
    'PHONE',
    'MUSIC',
    'WATER',
  ];
  final List<String> hardWords = [
    'BUTTERFLY',
    'COMPUTER',
    'ELEPHANT',
    'MOUNTAIN',
  ];

  late String targetWord;
  late List<String> scrambledLetters;
  List<int> usedIndices = [];
  String currentGuess = '';
  int wordsCompleted = 0;
  int targetWords = 3;

  // Animation
  List<_Particle> particles = [];
  double shake = 0;
  double pulse = 0;
  List<Offset> letterOffsets = []; // For flying letters

  @override
  void reset(Vector2 size) {
    targetWords = 2 + level;
    wordsCompleted = 0;
    particles = [];
    shake = 0;
    pulse = 0;
    _generateWord();
  }

  void _generateWord() {
    List<String> wordList;
    if (level <= 3) {
      wordList = easyWords;
    } else if (level <= 6) {
      wordList = mediumWords;
    } else {
      wordList = hardWords;
    }

    targetWord = wordList[_rng.nextInt(wordList.length)];
    scrambledLetters = targetWord.split('')..shuffle(_rng);

    // Make sure it's actually scrambled
    while (scrambledLetters.join() == targetWord) {
      scrambledLetters.shuffle(_rng);
    }

    usedIndices = [];
    currentGuess = '';
    letterOffsets = List.generate(scrambledLetters.length, (_) => Offset.zero);
  }

  @override
  bool get isSolved => wordsCompleted >= targetWords;

  void _spawnParticles(Offset pos, Color color) {
    for (int i = 0; i < 15; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 50 + _rng.nextDouble() * 100;
      particles.add(
        _Particle(
          pos: pos,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.5 + _rng.nextDouble() * 0.5,
          size: 3 + _rng.nextDouble() * 4,
          color: color,
        ),
      );
    }
  }

  void _selectLetter(int index) {
    if (usedIndices.contains(index)) return;

    usedIndices.add(index);
    currentGuess += scrambledLetters[index];

    // Add particle burst at letter location?
    // We don't have exact location here easily without recalculating
    // But we can add it in onTapDown

    if (currentGuess.length == targetWord.length) {
      if (currentGuess == targetWord) {
        wordsCompleted++;
        pulse = 1.0;
        _spawnParticles(Offset(200, 300), const Color(0xFF2A9D8F));

        if (!isSolved) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _generateWord();
          });
        }
      } else {
        // Wrong - reset
        shake = 0.5;
        usedIndices = [];
        currentGuess = '';
      }
    }
  }

  @override
  void update(double dt) {
    // Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      particles[i].vel += Offset(0, 100 * dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (shake > 0) {
      shake -= dt * 2;
      if (shake < 0) shake = 0;
    }

    if (pulse > 0) {
      pulse -= dt * 2;
      if (pulse < 0) pulse = 0;
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    if (shake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shake * 15,
        (_rng.nextDouble() - 0.5) * shake * 15,
      );
    }

    // Progress
    TextPaint(
      style: const TextStyle(fontSize: 16, color: Colors.white70),
    ).render(
      canvas,
      '$wordsCompleted / $targetWords',
      Vector2(rect.center.dx - 20, rect.top + 10),
    );

    // Current guess
    final startPulse = pulse > 0 ? (1.0 + sin(pulse * pi) * 0.2) : 1.0;
    final guessColor = pulse > 0
        ? const Color(0xFF2A9D8F)
        : const Color(0xFF2A9D8F);

    final guessPaint = TextPaint(
      style: TextStyle(
        fontSize: 36 * startPulse,
        color: guessColor,
        letterSpacing: 8,
      ),
    );
    final displayGuess = currentGuess
        .padRight(targetWord.length, '_')
        .split('')
        .join(' ');

    canvas.save();
    // Center logic approximate
    guessPaint.render(
      canvas,
      displayGuess,
      Vector2(rect.left + 20, rect.top + 60),
    );
    canvas.restore();

    // Scrambled letters
    final letterSize = 50.0;
    final startX =
        rect.left +
        (rect.width - scrambledLetters.length * (letterSize + 10)) / 2;

    for (int i = 0; i < scrambledLetters.length; i++) {
      final isUsed = usedIndices.contains(i);
      final letterRect = Rect.fromLTWH(
        startX + i * (letterSize + 10),
        rect.center.dy,
        letterSize,
        letterSize,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(letterRect, const Radius.circular(8)),
        Paint()
          ..color = isUsed ? const Color(0xFF3A4452) : const Color(0xFF2A3442),
      );

      if (!isUsed) {
        TextPaint(
          style: const TextStyle(fontSize: 28, color: Colors.white),
        ).render(
          canvas,
          scrambledLetters[i],
          Vector2(letterRect.center.dx - 8, letterRect.center.dy - 14),
        );
      }
    }

    // Reset button
    final resetRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom - 40),
      width: 100,
      height: 40,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(resetRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFFE76F51),
    );
    TextPaint(style: const TextStyle(fontSize: 16, color: Colors.white)).render(
      canvas,
      'RESET',
      Vector2(resetRect.center.dx - 25, resetRect.center.dy - 8),
    );

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
    if (isSolved) return;

    final rect = boardRect(gameSize);

    // Check reset button
    final resetRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom - 40),
      width: 100,
      height: 40,
    );
    if (resetRect.contains(Offset(position.x, position.y))) {
      usedIndices = [];
      currentGuess = '';
      return;
    }

    // Check letter buttons
    final letterSize = 50.0;
    final startX =
        rect.left +
        (rect.width - scrambledLetters.length * (letterSize + 10)) / 2;

    for (int i = 0; i < scrambledLetters.length; i++) {
      final letterRect = Rect.fromLTWH(
        startX + i * (letterSize + 10),
        rect.center.dy,
        letterSize,
        letterSize,
      );

      if (letterRect.contains(Offset(position.x, position.y))) {
        if (!usedIndices.contains(i)) {
          _spawnParticles(
            Offset(letterRect.center.dx, letterRect.center.dy),
            const Color(0xFFE9C46A),
          );
          _selectLetter(i);
        }
        break;
      }
    }
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
