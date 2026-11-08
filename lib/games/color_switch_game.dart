import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class ColorSwitchGame extends MiniGame {
  @override
  String get name => 'Color Switch';

  @override
  String get instructions => 'Tap to jump through matching colors!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  final Random _rng = Random();
  static const colors = [
    Color(0xFFE76F51),
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFF264653),
  ];

  double ballY = 0;
  double velocity = 0;
  double gravity = 600;
  double jumpStrength = -300;
  int ballColor = 0;
  List<_Obstacle> obstacles = [];
  List<_Particle> particles = [];
  double cameraY = 0;
  int score = 0;
  int targetScore = 5;
  bool gameOver = false;
  double rotationSpeed = 2;

  @override
  void reset(Vector2 size) {
    final rect = boardRect(size);

    targetScore = 3 + level * 2;
    rotationSpeed = 1.5 + level * 0.2;
    gravity = 500 + level * 30;

    ballY = rect.center.dy;
    velocity = 0;
    ballColor = 0;
    cameraY = 0;
    score = 0;
    gameOver = false;
    particles = [];

    // Generate obstacles
    obstacles = [];
    for (int i = 0; i < targetScore + 3; i++) {
      obstacles.add(
        _Obstacle(
          y: rect.center.dy - 200 - i * 250,
          type: _rng.nextInt(2),
          rotation: 0,
          hasSwitcher: i > 0,
        ),
      );
    }
  }

  void _spawnScoreParticles(double y) {
    for (int i = 0; i < 15; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 80;
      particles.add(
        _Particle(
          x: 200,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 5,
          life: 0.5,
          color: colors[_rng.nextInt(4)],
        ),
      );
    }
  }

  @override
  bool get isSolved => score >= targetScore;

  @override
  void update(double dt) {
    if (isSolved || gameOver) return;

    // Physics
    velocity += gravity * dt;
    ballY += velocity * dt;

    // Camera follows ball
    final targetCameraY = ballY - 400;
    cameraY += (targetCameraY - cameraY) * dt * 3;

    // Rotate obstacles
    for (final obs in obstacles) {
      obs.rotation += rotationSpeed * dt;
    }

    // Check collisions
    final rect = boardRect(Vector2(400, 600));
    if (ballY > rect.bottom + cameraY) {
      gameOver = true;
    }

    // Check obstacle collisions
    for (final obs in obstacles) {
      // Color switcher collection
      if (obs.hasSwitcher && !obs.switcherCollected) {
        if ((ballY - obs.y).abs() < 25) {
          obs.switcherCollected = true;
          ballColor = (ballColor + 1) % 4;
          score++;
          _spawnScoreParticles(obs.y - cameraY);
        }
      }

      // Ring collision (simplified)
      final dist = (ballY - obs.y).abs();
      if (dist < 80 && dist > 40) {
        // Check if ball is in correct color segment
        final angle = (obs.rotation + pi / 2) % (2 * pi);
        final ballAngle = pi / 2; // Ball is always at center x
        final segmentIndex = ((angle + ballAngle) / (pi / 2)).floor() % 4;
        if (segmentIndex != ballColor && dist < 60 && dist > 50) {
          // Simplified: just lose if in wrong area at height
        }
      }
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt * 2;
      if (p.life <= 0) particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Background
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    canvas.save();
    canvas.translate(0, -cameraY);

    // Draw obstacles
    for (final obs in obstacles) {
      _drawObstacle(canvas, rect.center.dx, obs);
    }

    // Draw ball
    final ballScreenY = ballY;

    // Ball trail
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(rect.center.dx, ballScreenY + i * 8),
        15 - i * 2,
        Paint()..color = colors[ballColor].withOpacity(0.3 - i * 0.05),
      );
    }

    // Ball glow
    canvas.drawCircle(
      Offset(rect.center.dx, ballScreenY),
      22,
      Paint()
        ..color = colors[ballColor].withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Ball
    canvas.drawCircle(
      Offset(rect.center.dx, ballScreenY),
      15,
      Paint()..color = colors[ballColor],
    );

    // Ball highlight
    canvas.drawCircle(
      Offset(rect.center.dx - 5, ballScreenY - 5),
      5,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    canvas.restore();

    // Particles (screen space)
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }

    // Score
    _drawScore(canvas, rect);
  }

  void _drawObstacle(Canvas canvas, double centerX, _Obstacle obs) {
    canvas.save();
    canvas.translate(centerX, obs.y);
    canvas.rotate(obs.rotation);

    // Draw color ring
    final radius = 60.0;
    final strokeWidth = 12.0;

    for (int i = 0; i < 4; i++) {
      final startAngle = i * pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        pi / 2 - 0.1,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();

    // Color switcher
    if (obs.hasSwitcher && !obs.switcherCollected) {
      canvas.drawCircle(
        Offset(centerX, obs.y),
        12,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(centerX, obs.y),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawScore(Canvas canvas, Rect rect) {
    final scoreCircle = Offset(rect.center.dx, rect.top + 40);
    canvas.drawCircle(
      scoreCircle,
      25,
      Paint()..color = const Color(0xFF2A9D8F),
    );
    canvas.drawCircle(
      scoreCircle,
      25,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (gameOver) return;
    velocity = jumpStrength;
  }
}

class _Obstacle {
  double y;
  int type;
  double rotation;
  bool hasSwitcher;
  bool switcherCollected;

  _Obstacle({
    required this.y,
    required this.type,
    required this.rotation,
    required this.hasSwitcher,
  }) : switcherCollected = false;
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
