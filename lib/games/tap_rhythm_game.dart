import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class TapRhythmGame extends MiniGame {
  @override
  String get name => 'Tap Rhythm';

  @override
  String get instructions => 'Tap the circles when they reach the target!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final Random _rng = Random();
  static const laneColors = [
    Color(0xFFE76F51),
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFF6D597A),
  ];

  List<_Note> notes = [];
  List<_Particle> particles = [];
  List<_RippleEffect> ripples = [];
  double targetY = 0;
  int score = 0;
  int targetScore = 20;
  int combo = 0;
  int maxCombo = 0;
  double spawnTimer = 0;
  double spawnInterval = 0.8;
  double noteSpeed = 200;

  @override
  void reset(Vector2 size) {
    final rect = boardRect(size);

    targetScore = 15 + level * 5;
    spawnInterval = 0.9 - level * 0.05;
    spawnInterval = spawnInterval.clamp(0.3, 0.9);
    noteSpeed = 180 + level * 15;

    targetY = rect.bottom - 80;
    notes = [];
    particles = [];
    ripples = [];
    score = 0;
    combo = 0;
    maxCombo = 0;
    spawnTimer = 0;
  }

  void _spawnNote(Rect rect) {
    final lane = _rng.nextInt(4);
    final laneWidth = rect.width / 4;
    notes.add(
      _Note(
        x: rect.left + laneWidth * lane + laneWidth / 2,
        y: rect.top - 30,
        lane: lane,
        scale: 0.0,
      ),
    );
  }

  void _spawnHitParticles(double x, double y, int lane) {
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 80;
      particles.add(
        _Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 50,
          size: 5,
          life: 0.4,
          color: laneColors[lane],
        ),
      );
    }
    ripples.add(
      _RippleEffect(
        x: x,
        y: y,
        color: laneColors[lane],
        radius: 0,
        maxRadius: 60,
        life: 1.0,
      ),
    );
  }

  @override
  bool get isSolved => score >= targetScore;

  @override
  void update(double dt) {
    if (isSolved) return;

    final rect = boardRect(Vector2(400, 600));

    // Spawn notes
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnNote(rect);
    }

    // Update notes
    for (int i = notes.length - 1; i >= 0; i--) {
      final n = notes[i];

      // Scale in
      if (n.scale < 1.0) {
        n.scale += dt * 8;
        if (n.scale > 1.0) n.scale = 1.0;
      }

      n.y += noteSpeed * dt;

      // Missed
      if (n.y > targetY + 50) {
        notes.removeAt(i);
        combo = 0;
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 200 * dt;
      p.life -= dt * 2.5;
      if (p.life <= 0) particles.removeAt(i);
    }

    // Update ripples
    for (int i = ripples.length - 1; i >= 0; i--) {
      final r = ripples[i];
      r.radius += 150 * dt;
      r.life -= dt * 3;
      if (r.life <= 0) ripples.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Background
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    final laneWidth = rect.width / 4;

    // Lane separators
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(rect.left + laneWidth * i, rect.top),
        Offset(rect.left + laneWidth * i, rect.bottom),
        Paint()..color = const Color(0xFF2A3442),
      );
    }

    // Target line with glow
    canvas.drawLine(
      Offset(rect.left, targetY),
      Offset(rect.right, targetY),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawLine(
      Offset(rect.left, targetY),
      Offset(rect.right, targetY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // Target circles
    for (int i = 0; i < 4; i++) {
      final x = rect.left + laneWidth * i + laneWidth / 2;
      canvas.drawCircle(
        Offset(x, targetY),
        25,
        Paint()
          ..color = laneColors[i].withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Ripple effects
    for (final r in ripples) {
      canvas.drawCircle(
        Offset(r.x, r.y),
        r.radius,
        Paint()
          ..color = r.color.withOpacity(r.life * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Notes
    for (final n in notes) {
      final noteSize = 22 * n.scale;

      // Note glow
      canvas.drawCircle(
        Offset(n.x, n.y),
        noteSize + 6,
        Paint()
          ..color = laneColors[n.lane].withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Note body
      canvas.drawCircle(
        Offset(n.x, n.y),
        noteSize,
        Paint()..color = laneColors[n.lane],
      );

      // Note highlight
      canvas.drawCircle(
        Offset(n.x - noteSize * 0.3, n.y - noteSize * 0.3),
        noteSize * 0.3,
        Paint()..color = Colors.white.withOpacity(0.4),
      );
    }

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }

    // Score and combo
    TextPaint(
      style: const TextStyle(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ).render(canvas, '$score', Vector2(rect.center.dx - 15, rect.top + 15));

    if (combo > 1) {
      TextPaint(
        style: TextStyle(
          fontSize: 18,
          color: const Color(0xFFE9C46A).withOpacity(0.8),
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        '${combo}x',
        Vector2(rect.center.dx - 15, rect.top + 45),
      );
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved) return;

    final rect = boardRect(gameSize);
    final laneWidth = rect.width / 4;
    final tappedLane = ((position.x - rect.left) / laneWidth).floor().clamp(
      0,
      3,
    );

    // Find closest note in lane
    _Note? closest;
    double closestDist = double.infinity;

    for (final n in notes) {
      if (n.lane == tappedLane) {
        final dist = (n.y - targetY).abs();
        if (dist < closestDist && dist < 40) {
          closest = n;
          closestDist = dist;
        }
      }
    }

    if (closest != null) {
      _spawnHitParticles(closest.x, targetY, closest.lane);
      notes.remove(closest);
      score++;
      combo++;
      if (combo > maxCombo) maxCombo = combo;
    } else {
      combo = 0;
    }
  }
}

class _Note {
  double x, y;
  int lane;
  double scale;

  _Note({
    required this.x,
    required this.y,
    required this.lane,
    required this.scale,
  });
}

class _Particle {
  double x, y;
  double vx, vy;
  double size;
  double life;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  });
}

class _RippleEffect {
  double x, y;
  Color color;
  double radius;
  double maxRadius;
  double life;

  _RippleEffect({
    required this.x,
    required this.y,
    required this.color,
    required this.radius,
    required this.maxRadius,
    required this.life,
  });
}
