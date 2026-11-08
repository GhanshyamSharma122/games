import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class TapSpeedGame extends MiniGame {
  @override
  String get name => 'Tap Speed';

  final Random _rng = Random();

  @override
  String get instructions => 'Tap as fast as you can in 10 seconds!';

  int taps = 0;
  double timer = 0;
  double duration = 10;
  bool running = false;
  bool finished = false;
  int targetTaps = 50;

  // Animation
  double countScale = 1.0;
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    targetTaps = 30 + level * 10;
    taps = 0;
    timer = 0;
    running = false;
    finished = false;
    particles = [];
    countScale = 1.0;
  }

  void _spawnParticles(Offset pos, Color color) {
    for (int i = 0; i < 10; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 50 + _rng.nextDouble() * 100;
      particles.add(
        _Particle(
          pos: pos,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.3 + _rng.nextDouble() * 0.4,
          size: 2 + _rng.nextDouble() * 4,
          color: color,
        ),
      );
    }
  }

  @override
  bool get isSolved => finished && taps >= targetTaps;

  @override
  void update(double dt) {
    if (countScale > 1.0) {
      countScale -= dt * 3;
      if (countScale < 1.0) countScale = 1.0;
    }

    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      particles[i].vel += Offset(0, 100 * dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (!running || finished) return;

    timer += dt;
    if (timer >= duration) {
      finished = true;
      running = false;
      if (taps >= targetTaps) {
        _spawnParticles(
          Offset(200, 300),
          const Color(0xFFE9C46A),
        ); // Success burst
      }
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    final bgColor = running
        ? const Color(0xFF2A9D8F)
        : (finished ? const Color(0xFF264653) : const Color(0xFF3A4452));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()..color = bgColor,
    );

    if (!running && !finished) {
      TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.white),
      ).render(
        canvas,
        'TAP TO START',
        Vector2(rect.center.dx - 80, rect.center.dy - 12),
      );
    } else {
      // Tap count
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy - 60);
      canvas.scale(countScale);

      TextPaint(
        style: const TextStyle(
          fontSize: 72,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        '$taps',
        Vector2(-20, -40), // Approximate centering adjustment
      );
      canvas.restore();

      // Timer
      final remaining = (duration - timer).clamp(0, duration);
      TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.white70),
      ).render(
        canvas,
        '${remaining.toStringAsFixed(1)}s',
        Vector2(rect.center.dx - 25, rect.center.dy + 30),
      );

      // Target
      TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.white54),
      ).render(
        canvas,
        'Target: $targetTaps',
        Vector2(rect.center.dx - 40, rect.top + 20),
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

    if (finished) {
      final resultText = taps >= targetTaps ? 'You did it!' : 'Not enough!';
      final resultColor = taps >= targetTaps
          ? const Color(0xFFE9C46A)
          : const Color(0xFFE76F51);
      TextPaint(style: TextStyle(fontSize: 20, color: resultColor)).render(
        canvas,
        resultText,
        Vector2(rect.center.dx - 50, rect.center.dy + 70),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    if (!rect.contains(Offset(position.x, position.y))) return;

    _spawnParticles(
      Offset(position.x, position.y),
      Colors.white.withOpacity(0.5),
    );

    if (!running && !finished) {
      running = true;
      taps = 0;
      timer = 0;
      countScale = 1.2;
    } else if (running) {
      taps++;
      countScale = 1.1; // Small pulse on tap
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
