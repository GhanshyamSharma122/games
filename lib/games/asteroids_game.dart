import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class AsteroidsGame extends MiniGame {
  @override
  String get name => 'Asteroids';

  @override
  String get instructions => 'Tap to shoot! Destroy all asteroids.';

  final Random _rng = Random();
  late Offset shipPos;
  double shipAngle = -pi / 2;
  List<Offset> bullets = [];
  List<Offset> bulletVels = [];
  List<Offset> asteroids = [];
  List<double> asteroidSizes = [];
  List<Offset> asteroidVels = [];
  double bulletSpeed = 400;
  int score = 0;
  int targetScore = 10;
  bool gameOver = false;

  // Animation
  List<_Particle> particles = [];
  double recoil = 0;
  double shake = 0;
  double thrustAnim = 0;

  @override
  void reset(Vector2 size) {
    final rect = boardRect(size);
    shipPos = rect.center;
    shipAngle = -pi / 2;
    bullets = [];
    bulletVels = [];
    asteroids = [];
    asteroidSizes = [];
    asteroidVels = [];
    score = 0;
    targetScore = 5 + level * 3;
    gameOver = false;
    particles = [];
    recoil = 0;
    shake = 0;
    thrustAnim = 0;

    for (int i = 0; i < 3 + level; i++) {
      _spawnAsteroid(rect, null);
    }
  }

  void _spawnAsteroid(Rect rect, Offset? pos) {
    Offset p;
    if (pos != null) {
      p = pos;
    } else {
      if (_rng.nextBool()) {
        p = Offset(
          _rng.nextBool() ? rect.left : rect.right,
          rect.top + _rng.nextDouble() * rect.height,
        );
      } else {
        p = Offset(
          rect.left + _rng.nextDouble() * rect.width,
          _rng.nextBool() ? rect.top : rect.bottom,
        );
      }
    }
    asteroids.add(p);
    asteroidSizes.add(25 + _rng.nextDouble() * 20);
    final angle = _rng.nextDouble() * 2 * pi;
    final speed = 40 + _rng.nextDouble() * 60;
    asteroidVels.add(Offset(cos(angle) * speed, sin(angle) * speed));
  }

  void _spawnExplosion(Offset pos, double size) {
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 20 + _rng.nextDouble() * 100;
      particles.add(
        _Particle(
          pos: pos,
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          life: 0.5 + _rng.nextDouble() * 0.4,
          size: 2 + _rng.nextDouble() * 3,
          color: const Color(0xFF5A6472),
        ),
      );
    }
  }

  void _spawnThrustParticles() {
    final angle = shipAngle + pi + (_rng.nextDouble() - 0.5) * 0.5;
    final speed = 50 + _rng.nextDouble() * 50;
    particles.add(
      _Particle(
        pos: shipPos - Offset(cos(shipAngle) * 10, sin(shipAngle) * 10),
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        life: 0.3,
        size: 2 + _rng.nextDouble() * 2,
        color: const Color(0xFFE9C46A),
      ),
    );
  }

  @override
  bool get isSolved => score >= targetScore;

  @override
  void update(double dt) {
    // Animation updates
    if (recoil > 0) recoil -= dt * 5;
    if (shake > 0) shake -= dt * 5;
    thrustAnim += dt * 10;

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].pos += particles[i].vel * dt;
      particles[i].life -= dt;
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (gameOver || isSolved) return;

    final rect = boardRect(Vector2(400, 600));

    // Move bullets
    for (int i = bullets.length - 1; i >= 0; i--) {
      bullets[i] = bullets[i] + bulletVels[i] * dt;
      if (!rect.contains(bullets[i])) {
        bullets.removeAt(i);
        bulletVels.removeAt(i);
      }
    }

    // Move asteroids
    for (int i = 0; i < asteroids.length; i++) {
      asteroids[i] = asteroids[i] + asteroidVels[i] * dt;
      if (asteroids[i].dx < rect.left)
        asteroids[i] = Offset(rect.right, asteroids[i].dy);
      if (asteroids[i].dx > rect.right)
        asteroids[i] = Offset(rect.left, asteroids[i].dy);
      if (asteroids[i].dy < rect.top)
        asteroids[i] = Offset(asteroids[i].dx, rect.bottom);
      if (asteroids[i].dy > rect.bottom)
        asteroids[i] = Offset(asteroids[i].dx, rect.top);
    }

    // Collision detection
    for (int b = bullets.length - 1; b >= 0; b--) {
      for (int a = asteroids.length - 1; a >= 0; a--) {
        if ((bullets[b] - asteroids[a]).distance < asteroidSizes[a]) {
          score++;
          shake = 0.2;
          _spawnExplosion(asteroids[a], asteroidSizes[a]);

          if (asteroidSizes[a] > 20) {
            _spawnAsteroid(rect, asteroids[a]);
          }
          asteroids.removeAt(a);
          asteroidSizes.removeAt(a);
          asteroidVels.removeAt(a);
          bullets.removeAt(b);
          bulletVels.removeAt(b);
          break;
        }
      }
    }

    // Check ship collision
    for (int a = 0; a < asteroids.length; a++) {
      if ((shipPos - asteroids[a]).distance < asteroidSizes[a] + 10) {
        gameOver = true;
        shake = 0.5;
        _spawnExplosion(shipPos, 30);
        return;
      }
    }

    if (asteroids.length < 2 + level && !isSolved) {
      _spawnAsteroid(rect, null);
    }
  }

  void _shoot() {
    bullets.add(shipPos + Offset(cos(shipAngle) * 20, sin(shipAngle) * 20));
    bulletVels.add(
      Offset(cos(shipAngle) * bulletSpeed, sin(shipAngle) * bulletSpeed),
    );
    recoil = 10.0;
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    if (shake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shake * 10,
        (_rng.nextDouble() - 0.5) * shake * 10,
      );
    }

    canvas.drawRect(rect, Paint()..color = const Color(0xFF0E1117));

    // Stars background
    _drawStars(canvas, rect);

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.pos,
        p.size * p.life,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }

    // Asteroids
    final asteroidStroke = Paint()
      ..color = const Color(0xFF8B9BB4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final asteroidFill = Paint()..color = const Color(0xFF2D3A4A);

    for (int i = 0; i < asteroids.length; i++) {
      // Draw irregular asteroid shape
      canvas.save();
      canvas.translate(asteroids[i].dx, asteroids[i].dy);

      canvas.drawCircle(Offset.zero, asteroidSizes[i], asteroidFill);
      canvas.drawCircle(Offset.zero, asteroidSizes[i], asteroidStroke);

      // Crater
      canvas.drawCircle(
        Offset(asteroidSizes[i] * 0.3, -asteroidSizes[i] * 0.3),
        asteroidSizes[i] * 0.2,
        Paint()..color = const Color(0xFF1B2430).withOpacity(0.5),
      );

      canvas.restore();
    }

    // Ship
    if (!gameOver) {
      canvas.save();
      canvas.translate(shipPos.dx, shipPos.dy);
      canvas.rotate(shipAngle + pi / 2);

      final shipOffset = recoil > 0 ? recoil : 0.0;
      canvas.translate(0, shipOffset);

      final shipPath = Path();
      shipPath.moveTo(0, -15);
      shipPath.lineTo(10, 15);
      shipPath.lineTo(0, 10);
      shipPath.lineTo(-10, 15);
      shipPath.close();

      canvas.drawPath(shipPath, Paint()..color = const Color(0xFF2A9D8F));

      // Thrust flame
      if (thrustAnim % 0.2 < 0.1) {
        final flamePath = Path();
        flamePath.moveTo(-6, 15);
        flamePath.lineTo(0, 25);
        flamePath.lineTo(6, 15);
        flamePath.close();
        canvas.drawPath(flamePath, Paint()..color = const Color(0xFFE9C46A));
      }

      canvas.restore();
    }

    // Bullets
    final bulletPaint = Paint()
      ..color = const Color(0xFFFF0055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final b in bullets) {
      canvas.drawLine(
        b,
        b - Offset(cos(shipAngle) * 8, sin(shipAngle) * 8), // Trail effect
        bulletPaint,
      );
    }

    // Score
    TextPaint(
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      '$score / $targetScore',
      Vector2(rect.left + 15, rect.top + 15),
    );

    if (gameOver) {
      canvas.drawRect(rect, Paint()..color = const Color(0xAA000000));
      TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color(0xFFE63946),
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        'DESTROYED',
        Vector2(rect.center.dx - 90, rect.center.dy),
      );
    }

    if (shake > 0) {
      canvas.restore();
    }
  }

  void _drawStars(Canvas canvas, Rect rect) {
    // Deterministic stars based on index
    final rng = Random(1337);
    for (int i = 0; i < 30; i++) {
      final x = rect.left + rng.nextDouble() * rect.width;
      final y = rect.top + rng.nextDouble() * rect.height;
      canvas.drawCircle(Offset(x, y), 1, Paint()..color = Colors.white24);
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (gameOver || isSolved) return;

    shipAngle = atan2(position.y - shipPos.dy, position.x - shipPos.dx);
    _shoot();
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    if (gameOver || isSolved) return;

    _spawnThrustParticles();

    final rect = boardRect(gameSize);
    shipPos = Offset(
      (shipPos.dx + delta.x).clamp(rect.left + 15, rect.right - 15),
      (shipPos.dy + delta.y).clamp(rect.top + 15, rect.bottom - 15),
    );
  }
}

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  double size;
  Color color;
  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
  });
}
