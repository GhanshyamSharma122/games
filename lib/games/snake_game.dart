import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class SnakeGame extends MiniGame {
  @override
  String get name => 'Snake';

  @override
  String get instructions =>
      'Swipe to move. Eat food! It gets faster as you grow.';

  int n = 12;
  final Random _rng = Random();
  late List<Offset> snake;
  late List<Offset> displaySnake; // Smooth visual positions
  late Offset food;
  Offset direction = const Offset(1, 0);
  Offset nextDirection = const Offset(1, 0);
  double moveTimer = 0;
  double moveInterval = 0.2;
  bool gameOver = false;

  // Animation
  double foodPulse = 0;
  double eatScale = 1.0;
  List<_Particle> particles = [];
  double deathShake = 0;

  @override
  void reset(Vector2 size) {
    // Continuous mode: Start slow-ish, speed up with length
    moveInterval = 0.22;
    // targetLength is effectively infinite now

    n = 12;
    snake = [Offset((n ~/ 2).toDouble(), (n ~/ 2).toDouble())];
    displaySnake = List.from(snake);
    direction = const Offset(1, 0);
    nextDirection = const Offset(1, 0);
    _spawnFood();
    moveTimer = 0;
    gameOver = false;
    foodPulse = 0;
    eatScale = 1.0;
    particles = [];
    deathShake = 0;
  }

  void _spawnFood() {
    final free = <Offset>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final pos = Offset(c.toDouble(), r.toDouble());
        if (!snake.contains(pos)) free.add(pos);
      }
    }
    if (free.isNotEmpty) {
      food = free[_rng.nextInt(free.length)];
    }
  }

  void _spawnEatParticles(Offset center) {
    for (int i = 0; i < 10; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 40 + _rng.nextDouble() * 60;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: const Color(0xFFE76F51),
          size: 3 + _rng.nextDouble() * 3,
          life: 0.5,
        ),
      );
    }
  }

  @override
  bool get isSolved => false; // Continuous play

  @override
  void update(double dt) {
    // Animate food pulse
    foodPulse += dt * 4;

    // Animate eat scale
    if (eatScale > 1.0) {
      eatScale -= dt * 4;
      if (eatScale < 1.0) eatScale = 1.0;
    }

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }

    // Death shake
    if (deathShake > 0) {
      deathShake -= dt * 5;
    }

    // Smooth snake animation
    for (int i = 0; i < displaySnake.length && i < snake.length; i++) {
      final target = snake[i];
      final current = displaySnake[i];
      displaySnake[i] = Offset(
        _lerpWrap(current.dx, target.dx, n.toDouble(), dt * 15),
        _lerpWrap(current.dy, target.dy, n.toDouble(), dt * 15),
      );
    }
    while (displaySnake.length < snake.length) {
      displaySnake.add(snake[displaySnake.length]);
    }
    while (displaySnake.length > snake.length) {
      displaySnake.removeLast();
    }

    if (gameOver) return;
    moveTimer += dt;
    if (moveTimer >= moveInterval) {
      moveTimer = 0;
      direction = nextDirection;
      _move();
    }
  }

  double _lerpWrap(double a, double b, double max, double t) {
    // Handle wrapping for smooth movement at edges
    var diff = b - a;
    if (diff.abs() > max / 2) {
      if (diff > 0)
        diff -= max;
      else
        diff += max;
    }
    return a + diff * t.clamp(0, 1);
  }

  void _move() {
    final head = snake.first;
    final next = Offset(head.dx + direction.dx, head.dy + direction.dy);

    // Check wall collision
    if (next.dx < 0 || next.dx >= n || next.dy < 0 || next.dy >= n) {
      gameOver = true;
      deathShake = 1.0;
      return;
    }

    // Check self collision
    if (snake.contains(next)) {
      gameOver = true;
      deathShake = 1.0;
      return;
    }

    snake.insert(0, next);

    if (next == food) {
      eatScale = 1.4;
      _spawnEatParticles(_getScreenPos(food));
      _spawnFood();
      // Speed up slightly
      moveInterval = (0.22 * pow(0.98, snake.length)).clamp(0.08, 0.25);
    } else {
      snake.removeLast();
    }
  }

  Offset _getScreenPos(Offset gridPos) {
    final rect = boardRect(Vector2(400, 600));
    final cell = rect.width / n;
    return Offset(
      rect.left + gridPos.dx * cell + cell / 2,
      rect.top + gridPos.dy * cell + cell / 2,
    );
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Apply shake
    if (deathShake > 0) {
      canvas.save();
      final shakeX = (_rng.nextDouble() - 0.5) * deathShake * 8;
      final shakeY = (_rng.nextDouble() - 0.5) * deathShake * 8;
      canvas.translate(shakeX, shakeY);
    }

    final cell = rect.width / n;
    final bgPaint = Paint()..color = const Color(0xFF1B2430);
    canvas.drawRect(rect, bgPaint);

    // Grid pattern
    final gridPaint = Paint()..color = const Color(0xFF232D3B);
    for (int r = 0; r <= n; r++) {
      canvas.drawLine(
        Offset(rect.left, rect.top + r * cell),
        Offset(rect.right, rect.top + r * cell),
        gridPaint,
      );
    }
    for (int c = 0; c <= n; c++) {
      canvas.drawLine(
        Offset(rect.left + c * cell, rect.top),
        Offset(rect.left + c * cell, rect.bottom),
        gridPaint,
      );
    }

    // Draw snake with gradient
    for (int i = displaySnake.length - 1; i >= 0; i--) {
      final pos = displaySnake[i];
      final t = i / displaySnake.length;
      final cellRect = Rect.fromLTWH(
        rect.left + pos.dx * cell + 1,
        rect.top + pos.dy * cell + 1,
        cell - 2,
        cell - 2,
      );

      final color = Color.lerp(
        const Color(0xFF3AB795),
        const Color(0xFF264653),
        t,
      )!;

      // Shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          cellRect.translate(2, 2),
          const Radius.circular(6),
        ),
        Paint()..color = Colors.black.withOpacity(0.2),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(6)),
        Paint()..color = color,
      );

      // Highlight on head
      if (i == 0) {
        final eyeOffset = direction.dx != 0
            ? Offset(direction.dx * cell * 0.2, 0)
            : Offset(0, direction.dy * cell * 0.2);

        // Eyes
        canvas.drawCircle(
          cellRect.center + eyeOffset + Offset(-cell * 0.15, -cell * 0.1),
          cell * 0.12,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          cellRect.center + eyeOffset + Offset(cell * 0.15, -cell * 0.1),
          cell * 0.12,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          cellRect.center + eyeOffset + Offset(-cell * 0.15, -cell * 0.1),
          cell * 0.06,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          cellRect.center + eyeOffset + Offset(cell * 0.15, -cell * 0.1),
          cell * 0.06,
          Paint()..color = Colors.black,
        );
      }
    }

    // Draw food with pulse
    final pulse = sin(foodPulse) * 0.15 + 1.0;
    final foodSize = (cell - 4) * pulse * eatScale;
    final foodRect = Rect.fromCenter(
      center: Offset(
        rect.left + food.dx * cell + cell / 2,
        rect.top + food.dy * cell + cell / 2,
      ),
      width: foodSize,
      height: foodSize,
    );

    // Food glow
    canvas.drawOval(
      foodRect.inflate(4),
      Paint()
        ..color = const Color(0xFFE76F51).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawOval(foodRect, Paint()..color = const Color(0xFFE76F51));

    // Food highlight
    canvas.drawCircle(
      foodRect.center.translate(-foodSize * 0.15, -foodSize * 0.15),
      foodSize * 0.2,
      Paint()..color = Colors.white.withOpacity(0.4),
    );

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }

    if (gameOver) {
      final overlay = Paint()..color = const Color(0x88000000);
      canvas.drawRect(rect, overlay);
    }

    if (deathShake > 0) {
      canvas.restore();
    }
  }

  @override
  void onPanEnd(Vector2 velocity, Vector2 gameSize) {
    if (velocity.length < 50) return;
    if (velocity.x.abs() > velocity.y.abs()) {
      final newDir = velocity.x > 0 ? const Offset(1, 0) : const Offset(-1, 0);
      if (direction.dx == 0) nextDirection = newDir;
    } else {
      final newDir = velocity.y > 0 ? const Offset(0, 1) : const Offset(0, -1);
      if (direction.dy == 0) nextDirection = newDir;
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
    velocity = velocity * 0.95;
    life -= dt * 2;
  }
}
