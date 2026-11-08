import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class BubblePopGame extends MiniGame {
  @override
  String get name => 'Bubble Pop';

  @override
  String get instructions => 'Pop all the bubbles before they escape!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final Random _rng = Random();
  List<_Bubble> bubbles = [];
  List<_Particle> particles = [];
  int score = 0;
  int targetScore = 10;
  int escaped = 0;
  int maxEscaped = 3;
  double spawnTimer = 0;
  double spawnInterval = 1.5;

  @override
  void reset(Vector2 size) {
    targetScore = 8 + level * 4;
    spawnInterval = 1.8 - level * 0.12;
    spawnInterval = spawnInterval.clamp(0.5, 1.8);
    maxEscaped = 5 - level ~/ 3;
    maxEscaped = maxEscaped.clamp(2, 5);

    bubbles = [];
    particles = [];
    score = 0;
    escaped = 0;
    spawnTimer = 0;

    // Spawn initial bubbles
    final rect = boardRect(size);
    for (int i = 0; i < 3; i++) {
      _spawnBubble(rect);
    }
  }

  void _spawnBubble(Rect rect) {
    final size = 30 + _rng.nextDouble() * 30;
    bubbles.add(
      _Bubble(
        x: rect.left + size + _rng.nextDouble() * (rect.width - size * 2),
        y: rect.bottom + size,
        size: size,
        speed: 40 + _rng.nextDouble() * 40 + level * 5,
        wobblePhase: _rng.nextDouble() * pi * 2,
        wobbleSpeed: 2 + _rng.nextDouble() * 2,
        hue: _rng.nextDouble() * 360,
        scale: 0.0,
      ),
    );
  }

  void _spawnPopParticles(double x, double y, double hue) {
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 100;
      particles.add(
        _Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 4 + _rng.nextDouble() * 4,
          life: 0.5 + _rng.nextDouble() * 0.3,
          hue: hue,
        ),
      );
    }
  }

  @override
  bool get isSolved => score >= targetScore;

  bool get isLost => escaped >= maxEscaped;

  @override
  void update(double dt) {
    if (isSolved || isLost) return;

    final rect = boardRect(Vector2(400, 600));

    // Spawn new bubbles
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      _spawnBubble(rect);
    }

    // Update bubbles
    for (int i = bubbles.length - 1; i >= 0; i--) {
      final b = bubbles[i];

      // Scale in animation
      if (b.scale < 1.0) {
        b.scale += dt * 4;
        if (b.scale > 1.0) b.scale = 1.0;
      }

      // Float up with wobble
      b.y -= b.speed * dt;
      b.wobblePhase += b.wobbleSpeed * dt;
      b.x += sin(b.wobblePhase) * 0.5;

      // Escaped
      if (b.y < rect.top - b.size) {
        bubbles.removeAt(i);
        escaped++;
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 200 * dt; // Gravity
      p.life -= dt * 2;
      if (p.life <= 0) particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Background gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1B2430), const Color(0xFF2D3A4A)],
        ).createShader(rect),
    );

    // Draw bubbles
    for (final b in bubbles) {
      final displaySize = b.size * b.scale;
      final color = HSVColor.fromAHSV(1, b.hue, 0.6, 0.9).toColor();

      // Bubble glow
      canvas.drawCircle(
        Offset(b.x, b.y),
        displaySize + 8,
        Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Bubble body
      canvas.drawCircle(
        Offset(b.x, b.y),
        displaySize,
        Paint()..color = color.withOpacity(0.7),
      );

      // Bubble highlight
      canvas.drawCircle(
        Offset(b.x - displaySize * 0.3, b.y - displaySize * 0.3),
        displaySize * 0.25,
        Paint()..color = Colors.white.withOpacity(0.5),
      );

      // Bubble rim
      canvas.drawCircle(
        Offset(b.x, b.y),
        displaySize,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw particles
    for (final p in particles) {
      final color = HSVColor.fromAHSV(p.life * 2, p.hue, 0.8, 1).toColor();
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life,
        Paint()..color = color,
      );
    }

    // Score display
    _drawScoreBar(canvas, rect);

    // Lives display
    for (int i = 0; i < maxEscaped; i++) {
      final lost = i < escaped;
      canvas.drawCircle(
        Offset(rect.left + 15 + i * 25, rect.top + 15),
        8,
        Paint()
          ..color = lost ? const Color(0xFFE63946) : const Color(0xFF2A9D8F),
      );
    }
  }

  void _drawScoreBar(Canvas canvas, Rect rect) {
    final progress = score / targetScore;
    final barWidth = rect.width - 80;
    final barRect = Rect.fromLTWH(
      rect.right - barWidth - 10,
      rect.top + 8,
      barWidth,
      14,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(7)),
      Paint()..color = const Color(0xFF1B2430),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * progress,
          barRect.height,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF2A9D8F),
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (isSolved || isLost) return;

    for (int i = bubbles.length - 1; i >= 0; i--) {
      final b = bubbles[i];
      final dist = sqrt(pow(position.x - b.x, 2) + pow(position.y - b.y, 2));
      if (dist <= b.size * b.scale) {
        _spawnPopParticles(b.x, b.y, b.hue);
        bubbles.removeAt(i);
        score++;
        break;
      }
    }
  }
}

class _Bubble {
  double x, y;
  double size;
  double speed;
  double wobblePhase;
  double wobbleSpeed;
  double hue;
  double scale;

  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobblePhase,
    required this.wobbleSpeed,
    required this.hue,
    required this.scale,
  });
}

class _Particle {
  double x, y;
  double vx, vy;
  double size;
  double life;
  double hue;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.hue,
  });
}
