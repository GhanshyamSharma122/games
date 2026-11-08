import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class AimTrainerGame extends MiniGame {
  @override
  String get name => 'Aim Trainer';

  @override
  String get instructions => 'Hit the targets as fast as you can!';

  final Random _rng = Random();
  Offset? target;
  double targetRadius = 30;
  int hits = 0;
  int targetHits = 15;
  double totalTime = 0;
  double bestAvg = 999;

  // Animation
  List<_Particle> particles = [];
  double targetScale = 0;

  @override
  void reset(Vector2 size) {
    targetHits = 10 + level * 3;
    targetRadius = 35 - level * 2;
    targetRadius = targetRadius.clamp(15, 35);

    hits = 0;
    totalTime = 0;
    particles = [];
    _spawnTarget(size);
  }

  void _spawnTarget(Vector2 size) {
    final rect = boardRect(size);
    target = Offset(
      rect.left +
          targetRadius +
          _rng.nextDouble() * (rect.width - targetRadius * 2),
      rect.top +
          targetRadius +
          _rng.nextDouble() * (rect.height - targetRadius * 2),
    );
    targetScale = 0.0; // Start small
  }

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
  bool get isSolved => hits >= targetHits;

  @override
  void update(double dt) {
    // Particle update
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      // particles[i].vel += Offset(0, 100 * dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    // Target appear animation
    if (targetScale < 1.0) {
      targetScale += dt * 5;
      if (targetScale > 1.0) targetScale = 1.0;
    }

    if (isSolved || target == null) return;
    totalTime += dt;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    if (target != null && !isSolved) {
      // Target
      canvas.save();
      canvas.translate(target!.dx, target!.dy);
      canvas.scale(targetScale);

      canvas.drawCircle(
        Offset.zero,
        targetRadius,
        Paint()..color = const Color(0xFFE76F51),
      );
      canvas.drawCircle(
        Offset.zero,
        targetRadius * 0.6,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset.zero,
        targetRadius * 0.3,
        Paint()..color = const Color(0xFFE76F51),
      );
      canvas.restore();
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.pos,
        p.size * p.life,
        Paint()..color = p.color.withValues(alpha: p.life),
      );
    }

    // Stats
    TextPaint(
      style: const TextStyle(fontSize: 16, color: Colors.white70),
    ).render(
      canvas,
      'Hits: $hits / $targetHits',
      Vector2(rect.left + 10, rect.top + 10),
    );

    if (hits > 0) {
      final avg = (totalTime / hits * 1000).round();
      TextPaint(
        style: const TextStyle(fontSize: 14, color: Colors.white54),
      ).render(canvas, 'Avg: ${avg}ms', Vector2(rect.left + 10, rect.top + 32));
    }

    if (isSolved) {
      final avg = (totalTime / hits * 1000).round();
      TextPaint(
        style: const TextStyle(fontSize: 28, color: Color(0xFF2A9D8F)),
      ).render(
        canvas,
        'Done! Avg: ${avg}ms',
        Vector2(rect.center.dx - 90, rect.center.dy - 14),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved || target == null) return;

    final dist = (Offset(position.x, position.y) - target!).distance;
    if (dist <= targetRadius) {
      _spawnParticles(target!, const Color(0xFFE76F51)); // Hit particles

      hits++;
      if (!isSolved) {
        _spawnTarget(gameSize);
      } else {
        target = null;
      }
    } else {
      // Miss particles?
      _spawnParticles(
        Offset(position.x, position.y),
        Colors.white.withOpacity(0.3),
      );
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
