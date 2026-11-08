import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class BreakoutGame extends MiniGame {
  @override
  String get name => 'Breakout';

  @override
  String get instructions => 'Swipe to move paddle. Break all bricks!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 8;

  final Random _rng = Random();
  late List<_Brick> bricks;
  late Rect paddle;
  late Offset ball;
  late Offset ballVelocity;
  double ballSpeed = 300;
  double paddleX = 0;
  int brickRows = 4;
  int brickCols = 6;
  bool gameOver = false;

  // Animation effects
  List<_Particle> particles = [];
  List<Offset> ballTrail = [];
  double screenShake = 0;
  double comboTimer = 0;
  int combo = 0;

  @override
  void reset(Vector2 size) {
    brickRows = 3 + level ~/ 2;
    brickRows = brickRows.clamp(3, 7);
    brickCols = 5 + level ~/ 3;
    brickCols = brickCols.clamp(5, 9);
    ballSpeed = 220 + level * 25;

    final rect = boardRect(size);
    final brickWidth = rect.width / brickCols;
    final brickHeight = 20.0;

    bricks = [];
    for (int r = 0; r < brickRows; r++) {
      for (int c = 0; c < brickCols; c++) {
        bricks.add(
          _Brick(
            rect: Rect.fromLTWH(
              rect.left + c * brickWidth + 2,
              rect.top + r * (brickHeight + 4) + 20,
              brickWidth - 4,
              brickHeight,
            ),
            row: r,
          ),
        );
      }
    }

    paddleX = rect.center.dx;
    paddle = Rect.fromCenter(
      center: Offset(paddleX, rect.bottom - 30),
      width: (80.0 - (level - 1) * 4).clamp(40.0, 100.0),
      height: 12,
    );

    ball = Offset(rect.center.dx, rect.bottom - 100);
    final angle = -pi / 4 - _rng.nextDouble() * pi / 2;
    ballVelocity = Offset(cos(angle) * ballSpeed, sin(angle) * ballSpeed);
    if (ballVelocity.dy > 0)
      ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);

    gameOver = false;
    particles = [];
    ballTrail = [];
    screenShake = 0;
    combo = 0;
    comboTimer = 0;
  }

  @override
  bool get isSolved => bricks.isEmpty;

  void _spawnBrickParticles(Rect brick, int row) {
    final colors = [
      const Color(0xFFE76F51),
      const Color(0xFFF4A261),
      const Color(0xFFE9C46A),
      const Color(0xFF2A9D8F),
      const Color(0xFF264653),
      const Color(0xFF6D597A),
      const Color(0xFFB56576),
    ];
    final color = colors[row % colors.length];

    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 120;
      particles.add(
        _Particle(
          position: brick.center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: color,
          size: 3 + _rng.nextDouble() * 4,
          life: 0.6 + _rng.nextDouble() * 0.3,
          rotation: _rng.nextDouble() * pi * 2,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 10,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    if (isSolved || gameOver) return;

    // Update ball trail
    ballTrail.insert(0, ball);
    if (ballTrail.length > 8) ballTrail.removeLast();

    ball = ball + ballVelocity * dt;

    // Screen shake decay
    if (screenShake > 0) {
      screenShake -= dt * 10;
      if (screenShake < 0) screenShake = 0;
    }

    // Combo timer
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }

    // Update brick animations
    for (final brick in bricks) {
      brick.update(dt);
    }

    final rect = boardRect(Vector2(400, 600));

    // Wall collisions
    if (ball.dx <= rect.left || ball.dx >= rect.right) {
      ballVelocity = Offset(-ballVelocity.dx, ballVelocity.dy);
    }
    if (ball.dy <= rect.top) {
      ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
    }

    // Ball lost
    if (ball.dy >= rect.bottom) {
      gameOver = true;
      screenShake = 1.0;
      return;
    }

    // Paddle collision
    if (ball.dy >= paddle.top - 5 &&
        ball.dy <= paddle.bottom &&
        ball.dx >= paddle.left &&
        ball.dx <= paddle.right) {
      final hitPos = (ball.dx - paddle.center.dx) / (paddle.width / 2);
      final angle = -pi / 2 + hitPos * pi / 4;
      ballVelocity = Offset(cos(angle) * ballSpeed, sin(angle) * ballSpeed);
      if (ballVelocity.dy > 0)
        ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
    }

    // Brick collisions
    for (int i = bricks.length - 1; i >= 0; i--) {
      if (bricks[i].rect.contains(ball) && !bricks[i].breaking) {
        _spawnBrickParticles(bricks[i].rect, bricks[i].row);
        bricks[i].breaking = true;
        bricks[i].breakTimer = 0.15;
        ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
        screenShake = 0.3;
        combo++;
        comboTimer = 2.0;
        break;
      }
    }

    // Remove broken bricks
    bricks.removeWhere((b) => b.breaking && b.breakTimer <= 0);
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Apply screen shake
    if (screenShake > 0) {
      canvas.save();
      final shakeX = (_rng.nextDouble() - 0.5) * screenShake * 8;
      final shakeY = (_rng.nextDouble() - 0.5) * screenShake * 8;
      canvas.translate(shakeX, shakeY);
    }

    final bgPaint = Paint()..color = const Color(0xFF1B2430);
    canvas.drawRect(rect, bgPaint);

    // Brick colors
    final brickColors = [
      const Color(0xFFE76F51),
      const Color(0xFFF4A261),
      const Color(0xFFE9C46A),
      const Color(0xFF2A9D8F),
      const Color(0xFF264653),
      const Color(0xFF6D597A),
      const Color(0xFFB56576),
    ];

    // Draw bricks with animation
    for (final brick in bricks) {
      final color = brickColors[brick.row % brickColors.length];
      final scale = brick.breaking
          ? (1.0 + (0.15 - brick.breakTimer) * 2)
          : 1.0;
      final opacity = brick.breaking ? brick.breakTimer / 0.15 : 1.0;

      final scaledRect = Rect.fromCenter(
        center: brick.rect.center,
        width: brick.rect.width * scale,
        height: brick.rect.height * scale,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(4)),
        Paint()..color = color.withOpacity(opacity),
      );

      // Brick highlight
      if (!brick.breaking) {
        final highlightRect = Rect.fromLTWH(
          brick.rect.left + 2,
          brick.rect.top + 2,
          brick.rect.width - 4,
          brick.rect.height / 3,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(2)),
          Paint()..color = Colors.white.withOpacity(0.2),
        );
      }
    }

    // Draw ball trail
    for (int i = 0; i < ballTrail.length; i++) {
      final opacity = (1 - i / ballTrail.length) * 0.4;
      final trailSize = 8 - i * 0.8;
      canvas.drawCircle(
        ballTrail[i],
        trailSize,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // Paddle with glow
    final paddleGlow = Paint()
      ..color = const Color(0xFF2A9D8F).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddle.inflate(4), const Radius.circular(10)),
      paddleGlow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddle, const Radius.circular(6)),
      Paint()..color = const Color(0xFF2A9D8F),
    );

    // Paddle highlight
    final paddleHighlight = Rect.fromLTWH(
      paddle.left + 4,
      paddle.top + 2,
      paddle.width - 8,
      4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleHighlight, const Radius.circular(2)),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    // Ball with glow
    canvas.drawCircle(
      ball,
      14,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(ball, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      ball.translate(-2, -2),
      3,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    // Particles
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        Paint()..color = p.color.withOpacity((p.life * 1.5).clamp(0, 1)),
      );
      canvas.restore();
    }

    // Combo display
    if (combo > 1 && comboTimer > 0) {
      // Combo text would go here
    }

    if (gameOver) {
      canvas.drawRect(rect, Paint()..color = const Color(0x88E63946));
    }

    if (screenShake > 0) {
      canvas.restore();
    }
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    paddleX = (paddleX + delta.x).clamp(rect.left + 40, rect.right - 40);
    paddle = Rect.fromCenter(
      center: Offset(paddleX, rect.bottom - 30),
      width: 80,
      height: 12,
    );
  }
}

class _Brick {
  Rect rect;
  int row;
  bool breaking;
  double breakTimer;

  _Brick({required this.rect, required this.row})
    : breaking = false,
      breakTimer = 0;

  void update(double dt) {
    if (breaking) {
      breakTimer -= dt;
    }
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update(double dt) {
    position = position + velocity * dt;
    velocity = Offset(velocity.dx * 0.96, velocity.dy + 200 * dt);
    rotation += rotationSpeed * dt;
    life -= dt;
  }
}
