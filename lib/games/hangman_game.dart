import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class HangmanGame extends MiniGame {
  @override
  String get name => 'Hangman';

  @override
  String get instructions => 'Guess the word letter by letter!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final Random _rng = Random();
  final List<String> easyWords = [
    'CAT',
    'DOG',
    'SUN',
    'HAT',
    'BAT',
    'RAT',
    'PIG',
    'COW',
    'BEE',
    'ANT',
    'RED',
    'BLUE',
    'SKY',
    'SEA',
    'JOY',
    'FOX',
    'BOX',
    'TOY',
    'MAP',
    'CUP',
    'PEN',
    'KEY',
    'BUS',
    'CAR',
    'RUN',
    'SIT',
    'EAT',
    'FLY',
    'BED',
    'RUG',
    'JAM',
    'NUT',
    'EGG',
    'ICE',
    'INK',
    'OIL',
    'OWL',
    'YAK',
    'APE',
    'ELF',
  ];
  final List<String> mediumWords = [
    'APPLE',
    'HOUSE',
    'MOUSE',
    'PHONE',
    'WATER',
    'LIGHT',
    'MUSIC',
    'DANCE',
    'TIGER',
    'ZEBRA',
    'PIZZA',
    'BEACH',
    'CLOUD',
    'DREAM',
    'SMILE',
    'HAPPY',
    'LUNCH',
    'PARTY',
    'GHOST',
    'ROBOT',
    'TRAIN',
    'PLANE',
    'SPACE',
    'EARTH',
    'RIVER',
    'OCEAN',
    'LEMON',
    'GRAPE',
    'BREAD',
    'CHAIR',
    'TABLE',
    'PLANT',
    'STORE',
    'MONEY',
    'WATCH',
    'CLOCK',
    'HEART',
    'STORM',
    'SNOWY',
    'RAINY',
  ];
  final List<String> hardWords = [
    'ELEPHANT',
    'BUTTERFLY',
    'COMPUTER',
    'KEYBOARD',
    'MOUNTAIN',
    'CHALLENGE',
    'ADVENTURE',
    'ASTRONAUT',
    'CHOCOLATE',
    'DINOSAUR',
    'HELICOPTER',
    'KANGAROO',
    'MICROWAVE',
    'PINEAPPLE',
    'RAINBOW',
    'STRAWBERRY',
    'TELESCOPE',
    'UMBRELLA',
    'VOLCANO',
    'WATERFALL',
    'XYLOPHONE',
    'YESTERDAY',
    'ZEPPELIN',
    'BACKPACK',
    'BOOKSHELF',
    'CALCULATOR',
    'DANDELION',
    'ENVELOPE',
    'FIREWORKS',
    'GOLDFISH',
    'HAMBURGER',
    'JELLYFISH',
    'LIGHTHOUSE',
    'MUSHROOM',
    'NOTEBOOK',
    'OCTOPUS',
    'PARACHUTE',
    'QUESTION',
    'REFRIGERATOR',
    'SANDWICH',
    'TELEPHONE',
    'UNICORN',
    'VACATION',
    'WHISTLE',
    'ZUCCHINI',
    'ALGORITHM',
    'ENCRYPTION',
    'DASHBOARD',
  ];

  late String word;
  late Set<String> guessed;
  int wrongGuesses = 0;
  int maxWrong = 6;
  final List<String> alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  // Animation
  List<_Particle> particles = [];
  double shake = 0;
  List<double> letterScales = List.filled(26, 1.0);

  @override
  void reset(Vector2 size) {
    List<String> wordList;
    if (level <= 3) {
      wordList = easyWords;
    } else if (level <= 6) {
      wordList = mediumWords;
    } else {
      wordList = hardWords;
    }

    word = wordList[_rng.nextInt(wordList.length)];
    guessed = {};
    wrongGuesses = 0;
    particles = [];
    shake = 0;
    letterScales = List.filled(26, 1.0);
  }

  @override
  bool get isSolved => word.split('').every((c) => guessed.contains(c));

  bool get isLost => wrongGuesses >= maxWrong;

  String get displayWord =>
      word.split('').map((c) => guessed.contains(c) ? c : '_').join(' ');

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

  @override
  void update(double dt) {
    // Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      particles[i].vel += Offset(0, 150 * dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (shake > 0) {
      shake -= dt * 2;
      if (shake < 0) shake = 0;
    }

    // Letter scale animation (return to 1.0)
    for (int i = 0; i < 26; i++) {
      if (letterScales[i] > 1.0) {
        letterScales[i] -= dt * 5;
        if (letterScales[i] < 1.0) letterScales[i] = 1.0;
      }
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

    // Draw hangman
    final hangPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final baseX = rect.left + 50;
    final baseY = rect.top + 20;

    // Gallows
    canvas.drawLine(
      Offset(baseX, baseY + 120),
      Offset(baseX + 60, baseY + 120),
      hangPaint,
    );
    canvas.drawLine(
      Offset(baseX + 30, baseY + 120),
      Offset(baseX + 30, baseY),
      hangPaint,
    );
    canvas.drawLine(
      Offset(baseX + 30, baseY),
      Offset(baseX + 70, baseY),
      hangPaint,
    );
    canvas.drawLine(
      Offset(baseX + 70, baseY),
      Offset(baseX + 70, baseY + 20),
      hangPaint,
    );

    // Body parts with animation logic (could be improved with path drawing)
    if (wrongGuesses >= 1)
      canvas.drawCircle(Offset(baseX + 70, baseY + 35), 15, hangPaint);
    if (wrongGuesses >= 2)
      canvas.drawLine(
        Offset(baseX + 70, baseY + 50),
        Offset(baseX + 70, baseY + 80),
        hangPaint,
      );
    if (wrongGuesses >= 3)
      canvas.drawLine(
        Offset(baseX + 70, baseY + 55),
        Offset(baseX + 50, baseY + 70),
        hangPaint,
      );
    if (wrongGuesses >= 4)
      canvas.drawLine(
        Offset(baseX + 70, baseY + 55),
        Offset(baseX + 90, baseY + 70),
        hangPaint,
      );
    if (wrongGuesses >= 5)
      canvas.drawLine(
        Offset(baseX + 70, baseY + 80),
        Offset(baseX + 55, baseY + 100),
        hangPaint,
      );
    if (wrongGuesses >= 6)
      canvas.drawLine(
        Offset(baseX + 70, baseY + 80),
        Offset(baseX + 85, baseY + 100),
        hangPaint,
      );

    // Word display
    final wordPaint = TextPaint(
      style: const TextStyle(
        fontSize: 28,
        color: Colors.white,
        letterSpacing: 4,
      ),
    );
    wordPaint.render(
      canvas,
      displayWord,
      Vector2(rect.left + 140, rect.top + 60),
    );

    // Letter buttons
    final letterPaint = TextPaint(
      style: const TextStyle(fontSize: 16, color: Colors.white),
    );
    final usedPaint = TextPaint(
      style: const TextStyle(fontSize: 16, color: Colors.grey),
    );

    for (int i = 0; i < 26; i++) {
      final row = i ~/ 9;
      final col = i % 9;
      final x = rect.left + col * 32 + 10;
      final y = rect.top + 160 + row * 35;
      final scale = letterScales[i];

      final letter = alphabet[i];
      final isUsed = guessed.contains(letter);
      final paint = isUsed ? usedPaint : letterPaint;

      // Scale text slightly
      canvas.save();
      canvas.translate(x + 10, y + 10);
      canvas.scale(scale);
      canvas.translate(-(x + 10), -(y + 10));

      paint.render(canvas, letter, Vector2(x, y));
      canvas.restore();
    }

    if (isLost) {
      TextPaint(
        style: const TextStyle(fontSize: 20, color: Color(0xFFE63946)),
      ).render(
        canvas,
        'The word was: $word',
        Vector2(rect.left + 100, rect.top + 130),
      );
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
    if (isSolved || isLost) return;

    final rect = boardRect(gameSize);

    for (int i = 0; i < 26; i++) {
      final row = i ~/ 9;
      final col = i % 9;
      final x = rect.left + col * 32 + 10;
      final y = rect.top + 160 + row * 35;

      if (position.x >= x &&
          position.x <= x + 25 &&
          position.y >= y &&
          position.y <= y + 25) {
        letterScales[i] = 1.5; // Pop effect

        final letter = alphabet[i];
        if (!guessed.contains(letter)) {
          guessed.add(letter);
          if (!word.contains(letter)) {
            wrongGuesses++;
            shake = 0.5;
            _spawnParticles(Offset(x + 15, y + 15), const Color(0xFFE63946));
          } else {
            _spawnParticles(Offset(x + 15, y + 15), const Color(0xFF2A9D8F));
          }
        }
        return;
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
