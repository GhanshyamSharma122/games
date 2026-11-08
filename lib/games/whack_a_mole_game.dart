import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class WhackAMoleGame extends MiniGame {
  @override
  String get name => 'Whack-a-Mole';

  @override
  String get instructions => 'Tap the moles before they hide!';

  final Random _rng = Random();
  late List<double> moleTimers; // Time until mole hides
  late List<bool> moleUp;
  late List<double> moleScale; // Animation scale 0-1
  late List<double> moleVelocity; // Pop velocity
  late List<double> hitEffects; // Hit flash timer
  int score = 0;
  int targetScore = 10;
  double spawnTimer = 0;
  double spawnInterval = 1.0;
  double moleShowTime = 1.5;

  // Particles for whack effect
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    // Progressive: faster spawns, shorter show time
    spawnInterval = 1.2 - (level - 1) * 0.1;
    spawnInterval = spawnInterval.clamp(0.4, 1.2);
    moleShowTime = 2.0 - (level - 1) * 0.15;
    moleShowTime = moleShowTime.clamp(0.8, 2.0);
    targetScore = 5 + level * 3;

    moleTimers = List.generate(9, (_) => 0);
    moleUp = List.generate(9, (_) => false);
    moleScale = List.generate(9, (_) => 0.0);
    moleVelocity = List.generate(9, (_) => 0.0);
    hitEffects = List.generate(9, (_) => 0.0);
    score = 0;
    spawnTimer = 0;
    particles = [];
  }

  @override
  bool get isSolved => score >= targetScore;

  @override
  void update(double dt) {
    if (isSolved) return;

    // Update mole timers and animations
    for (int i = 0; i < 9; i++) {
      if (moleUp[i]) {
        moleTimers[i] -= dt;

        // Pop-up animation
        if (moleScale[i] < 1.0) {
          moleScale[i] += dt * 8; // Fast pop-up
          moleVelocity[i] = 0.6;
        } else {
          moleScale[i] = 1.0;
          // Bouncy wobble
          moleVelocity[i] *= 0.9;
        }

        if (moleTimers[i] <= 0) {
          moleUp[i] = false;
        }
      } else {
        // Pop-down animation
        if (moleScale[i] > 0) {
          moleScale[i] -= dt * 6;
          if (moleScale[i] < 0) moleScale[i] = 0;
        }
      }

      // Hit flash decay
      if (hitEffects[i] > 0) {
        hitEffects[i] -= dt * 3;
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }

    // Spawn new moles
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnMole();
    }
  }

  void _spawnMole() {
    final available = <int>[];
    for (int i = 0; i < 9; i++) {
      if (!moleUp[i] && moleScale[i] < 0.1) available.add(i);
    }
    if (available.isNotEmpty) {
      final idx = available[_rng.nextInt(available.length)];
      moleUp[idx] = true;
      moleTimers[idx] = moleShowTime;
      moleScale[idx] = 0.0;
      moleVelocity[idx] = 0.0;
    }
  }

  void _spawnParticles(Offset center) {
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 50 + _rng.nextDouble() * 80;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: _rng.nextBool()
              ? const Color(0xFFE9C46A)
              : const Color(0xFFE76F51),
          size: 4 + _rng.nextDouble() * 4,
          life: 0.5,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / 3;
    final holePaint = Paint()..color = const Color(0xFF1B2430);
    final molePaint = Paint()..color = const Color(0xFF8B5A2B);
    final eyePaint = Paint()..color = Colors.white;

    for (int i = 0; i < 9; i++) {
      final r = i ~/ 3;
      final c = i % 3;
      final center = Offset(
        rect.left + c * cell + cell / 2,
        rect.top + r * cell + cell / 2,
      );

      // Hole shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, 3),
          width: cell * 0.72,
          height: cell * 0.42,
        ),
        Paint()..color = const Color(0xFF0A0F14),
      );

      // Hole
      canvas.drawOval(
        Rect.fromCenter(center: center, width: cell * 0.7, height: cell * 0.4),
        holePaint,
      );

      // Mole with animation
      if (moleScale[i] > 0.01) {
        final scale = moleScale[i];
        final bounce = sin(moleVelocity[i] * pi * 4) * 3 * moleVelocity[i];
        final moleY = center.dy - cell * 0.15 * scale + bounce;

        // Hit flash effect
        Color moleColor = molePaint.color;
        if (hitEffects[i] > 0) {
          moleColor = Color.lerp(moleColor, Colors.white, hitEffects[i])!;
        }

        // Mole body
        canvas.drawCircle(
          Offset(center.dx, moleY),
          cell * 0.25 * scale,
          Paint()..color = moleColor,
        );

        // Mole ears
        canvas.drawCircle(
          Offset(center.dx - cell * 0.15 * scale, moleY - cell * 0.1 * scale),
          cell * 0.08 * scale,
          Paint()..color = moleColor,
        );
        canvas.drawCircle(
          Offset(center.dx + cell * 0.15 * scale, moleY - cell * 0.1 * scale),
          cell * 0.08 * scale,
          Paint()..color = moleColor,
        );

        // Eyes
        if (scale > 0.5) {
          canvas.drawCircle(
            Offset(center.dx - 8 * scale, moleY - cell * 0.05),
            4 * scale,
            eyePaint,
          );
          canvas.drawCircle(
            Offset(center.dx + 8 * scale, moleY - cell * 0.05),
            4 * scale,
            eyePaint,
          );
          // Pupils
          canvas.drawCircle(
            Offset(center.dx - 7 * scale, moleY - cell * 0.04),
            2 * scale,
            Paint()..color = Colors.black,
          );
          canvas.drawCircle(
            Offset(center.dx + 9 * scale, moleY - cell * 0.04),
            2 * scale,
            Paint()..color = Colors.black,
          );

          // Nose
          canvas.drawCircle(
            Offset(center.dx, moleY + cell * 0.05),
            3 * scale,
            Paint()..color = const Color(0xFFE76F51),
          );
        }
      }
    }

    // Render particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * (p.life * 2),
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }

    // Score display with animation
    _drawScore(canvas, rect);
  }

  void _drawScore(Canvas canvas, Rect rect) {
    final scorePaint = Paint()..color = const Color(0xFF2A9D8F);
    final textBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.center.dx - 40, rect.bottom - 45, 80, 35),
      const Radius.circular(8),
    );
    canvas.drawRRect(textBg, scorePaint);
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved) return;

    final rect = boardRect(gameSize);
    final cell = rect.width / 3;

    if (!rect.contains(Offset(position.x, position.y))) return;

    final c = ((position.x - rect.left) / cell).floor();
    final r = ((position.y - rect.top) / cell).floor();
    final i = r * 3 + c;

    if (moleUp[i] && moleScale[i] > 0.3) {
      moleUp[i] = false;
      hitEffects[i] = 1.0;
      score++;

      // Spawn particles at mole position
      final center = Offset(
        rect.left + c * cell + cell / 2,
        rect.top + r * cell + cell / 2 - cell * 0.15,
      );
      _spawnParticles(center);
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
    velocity = Offset(
      velocity.dx * 0.95,
      velocity.dy * 0.95 + 150 * dt,
    ); // Gravity
    life -= dt * 2;
  }
}
