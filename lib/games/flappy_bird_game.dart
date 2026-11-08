import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class FlappyBirdGame extends MiniGame {
  @override
  String get name => 'Flappy Bird';

  @override
  String get instructions => 'Tap to fly! Avoid the pipes.';

  final Random _rng = Random();
  double birdY = 0;
  double velocity = 0;
  double gravity = 800;
  double flapStrength = -280;
  List<double> pipeX = [];
  List<double> pipeGapY = [];
  double pipeWidth = 50;
  double gapHeight = 120;
  double pipeSpeed = 150;
  int score = 0;
  int targetScore = 5;
  bool gameOver = false;
  bool started = false;

  // Animation
  double wingAngle = 0;
  double birdRotation = 0;
  double deathY = 0;
  double deathVelocity = 0;
  bool dying = false;
  List<_Cloud> clouds = [];
  double groundOffset = 0;
  double screenShake = 0;
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    final rect = boardRect(size);
    birdY = rect.center.dy;
    velocity = 0;
    pipeX = [];
    pipeGapY = [];
    score = 0;
    targetScore = 3 + level * 2;
    pipeSpeed = 120 + level * 20;
    gapHeight = 140 - level * 5;
    gapHeight = gapHeight.clamp(80, 140);
    gameOver = false;
    started = false;
    wingAngle = 0;
    birdRotation = 0;
    dying = false;
    screenShake = 0;
    particles = [];

    // Initialize clouds
    clouds = [];
    for (int i = 0; i < 5; i++) {
      clouds.add(
        _Cloud(
          x: rect.left + _rng.nextDouble() * rect.width * 1.5,
          y: rect.top + 30 + _rng.nextDouble() * 100,
          size: 20 + _rng.nextDouble() * 30,
          speed: 20 + _rng.nextDouble() * 20,
        ),
      );
    }

    // Generate initial pipes
    for (int i = 0; i < 3; i++) {
      pipeX.add(rect.right + i * 180);
      pipeGapY.add(rect.top + 100 + _rng.nextDouble() * (rect.height - 200));
    }
  }

  @override
  bool get isSolved => score >= targetScore;

  @override
  void update(double dt) {
    final rect = boardRect(Vector2(400, 600));

    // Animate wing flapping
    wingAngle += dt * 15;

    // Animate clouds
    for (final cloud in clouds) {
      cloud.x -= cloud.speed * dt;
      if (cloud.x < rect.left - 50) {
        cloud.x = rect.right + 20;
        cloud.y = rect.top + 30 + _rng.nextDouble() * 100;
      }
    }

    // Ground animation
    groundOffset += pipeSpeed * dt * 0.5;
    if (groundOffset > 20) groundOffset = 0;

    // Screen shake decay
    if (screenShake > 0) {
      screenShake -= dt * 8;
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }

    if (dying) {
      deathVelocity += gravity * dt;
      deathY += deathVelocity * dt;
      birdRotation = (birdRotation + dt * 8).clamp(-0.5, 1.5);
      if (deathY > rect.bottom) {
        dying = false;
      }
      return;
    }

    if (gameOver || isSolved || !started) return;

    // Physics
    velocity += gravity * dt;
    birdY += velocity * dt;

    // Bird rotation based on velocity
    birdRotation = (velocity / 400).clamp(-0.5, 0.8);

    // Bounds check
    if (birdY < rect.top + 15 || birdY > rect.bottom - 15) {
      _die();
      return;
    }

    // Move pipes
    for (int i = 0; i < pipeX.length; i++) {
      pipeX[i] -= pipeSpeed * dt;
    }

    // Check scoring and collisions
    const birdX = 80.0;
    const birdRadius = 12.0;

    for (int i = 0; i < pipeX.length; i++) {
      // Passed pipe
      if (pipeX[i] < birdX - pipeWidth / 2 &&
          pipeX[i] > birdX - pipeWidth / 2 - pipeSpeed * dt) {
        score++;
        _spawnScoreParticles(Offset(birdX, birdY));
      }

      // Collision check
      if (pipeX[i] - pipeWidth / 2 < birdX + birdRadius &&
          pipeX[i] + pipeWidth / 2 > birdX - birdRadius) {
        if (birdY - birdRadius < pipeGapY[i] - gapHeight / 2 ||
            birdY + birdRadius > pipeGapY[i] + gapHeight / 2) {
          _die();
          return;
        }
      }
    }

    // Recycle pipes
    if (pipeX.isNotEmpty && pipeX[0] < rect.left - pipeWidth) {
      pipeX.removeAt(0);
      pipeGapY.removeAt(0);
      pipeX.add(pipeX.last + 180);
      pipeGapY.add(rect.top + 100 + _rng.nextDouble() * (rect.height - 200));
    }
  }

  void _die() {
    gameOver = true;
    dying = true;
    deathY = birdY;
    deathVelocity = -200;
    screenShake = 1.0;
  }

  void _spawnScoreParticles(Offset center) {
    for (int i = 0; i < 8; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5);
      final speed = 50 + _rng.nextDouble() * 50;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: const Color(0xFFE9C46A),
          size: 4,
          life: 0.5,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Apply screen shake
    if (screenShake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * screenShake * 10,
        (_rng.nextDouble() - 0.5) * screenShake * 10,
      );
    }

    // Sky gradient
    final skyGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF5BC0EB), const Color(0xFF87CEEB)],
      ).createShader(rect);
    canvas.drawRect(rect, skyGradient);

    // Clouds
    for (final cloud in clouds) {
      _drawCloud(canvas, cloud.x, cloud.y, cloud.size);
    }

    // Pipes with gradient and shadow
    for (int i = 0; i < pipeX.length; i++) {
      _drawPipe(canvas, rect, pipeX[i], pipeGapY[i]);
    }

    // Ground
    final groundRect = Rect.fromLTWH(
      rect.left,
      rect.bottom - 20,
      rect.width,
      20,
    );
    canvas.drawRect(groundRect, Paint()..color = const Color(0xFF8B6914));

    // Ground pattern
    final grassPaint = Paint()..color = const Color(0xFF4A8505);
    for (double x = rect.left - groundOffset; x < rect.right; x += 20) {
      canvas.drawRect(Rect.fromLTWH(x, rect.bottom - 20, 10, 5), grassPaint);
    }

    // Bird
    final birdDisplayY = dying ? deathY : birdY;
    _drawBird(canvas, 80, birdDisplayY);

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }

    // Score
    TextPaint(
      style: const TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black38, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
    ).render(canvas, '$score', Vector2(rect.center.dx - 10, rect.top + 15));

    if (!started && !gameOver) {
      TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ).render(
        canvas,
        'Tap to start',
        Vector2(rect.center.dx - 55, rect.center.dy + 50),
      );
    }

    if (gameOver && !dying) {
      canvas.drawRect(rect, Paint()..color = const Color(0x66E63946));
      TextPaint(
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        'Game Over!',
        Vector2(rect.center.dx - 70, rect.center.dy - 14),
      );
    }

    if (screenShake > 0) {
      canvas.restore();
    }
  }

  void _drawCloud(Canvas canvas, double x, double y, double size) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(x, y), size * 0.6, cloudPaint);
    canvas.drawCircle(
      Offset(x - size * 0.4, y + size * 0.2),
      size * 0.4,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(x + size * 0.5, y + size * 0.15),
      size * 0.45,
      cloudPaint,
    );
  }

  void _drawPipe(Canvas canvas, Rect rect, double x, double gapY) {
    final pipeColor = const Color(0xFF2A9D8F);
    final pipeHighlight = const Color(0xFF3AB795);
    final pipeShadow = const Color(0xFF1D7268);

    // Top pipe
    final topPipeRect = Rect.fromLTWH(
      x - pipeWidth / 2,
      rect.top,
      pipeWidth,
      gapY - gapHeight / 2 - rect.top,
    );
    final topCapRect = Rect.fromLTWH(
      x - pipeWidth / 2 - 4,
      gapY - gapHeight / 2 - 20,
      pipeWidth + 8,
      20,
    );

    canvas.drawRect(topPipeRect, Paint()..color = pipeColor);
    canvas.drawRect(
      Rect.fromLTWH(topPipeRect.left, topPipeRect.top, 6, topPipeRect.height),
      Paint()..color = pipeHighlight,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        topPipeRect.right - 6,
        topPipeRect.top,
        6,
        topPipeRect.height,
      ),
      Paint()..color = pipeShadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topCapRect, const Radius.circular(3)),
      Paint()..color = pipeColor,
    );

    // Bottom pipe
    final bottomPipeRect = Rect.fromLTWH(
      x - pipeWidth / 2,
      gapY + gapHeight / 2,
      pipeWidth,
      rect.bottom - gapY - gapHeight / 2,
    );
    final bottomCapRect = Rect.fromLTWH(
      x - pipeWidth / 2 - 4,
      gapY + gapHeight / 2,
      pipeWidth + 8,
      20,
    );

    canvas.drawRect(bottomPipeRect, Paint()..color = pipeColor);
    canvas.drawRect(
      Rect.fromLTWH(
        bottomPipeRect.left,
        bottomPipeRect.top,
        6,
        bottomPipeRect.height,
      ),
      Paint()..color = pipeHighlight,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        bottomPipeRect.right - 6,
        bottomPipeRect.top,
        6,
        bottomPipeRect.height,
      ),
      Paint()..color = pipeShadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bottomCapRect, const Radius.circular(3)),
      Paint()..color = pipeColor,
    );
  }

  void _drawBird(Canvas canvas, double x, double y) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(birdRotation);

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 28, height: 22),
      Paint()..color = const Color(0xFFE9C46A),
    );

    // Wing
    final wingFlap = sin(wingAngle) * 0.3;
    canvas.save();
    canvas.rotate(wingFlap);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 16, height: 8),
      Paint()..color = const Color(0xFFD4A84A),
    );
    canvas.restore();

    // Eye
    canvas.drawCircle(const Offset(8, -3), 6, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(9, -3), 3, Paint()..color = Colors.black);

    // Beak
    final beakPath = Path()
      ..moveTo(14, 0)
      ..lineTo(22, 2)
      ..lineTo(14, 5)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFE76F51));

    canvas.restore();
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (dying) return;
    if (gameOver) return;
    if (!started) {
      started = true;
    }
    velocity = flapStrength;
    wingAngle = 0; // Reset wing for flap animation
  }
}

class _Cloud {
  double x;
  double y;
  double size;
  double speed;

  _Cloud({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
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
    velocity = Offset(velocity.dx, velocity.dy - 100 * dt);
    life -= dt * 2;
  }
}
