import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class PongGame extends MiniGame {
  @override
  String get name => 'Pong';

  @override
  String get instructions => 'Swipe to move paddle. Beat the AI!';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 10;

  late Rect playerPaddle;
  late Rect aiPaddle;
  late Offset ball;
  late Offset ballVelocity;
  double ballSpeed = 300;
  int playerScore = 0;
  int aiScore = 0;
  int targetScore = 5;
  double aiSpeed = 150;
  final Random _rng = Random();

  // Animation
  List<Offset> ballTrail = [];
  double screenShake = 0;
  double playerHit = 0;
  double aiHit = 0;
  double scoreFlash = 0;
  List<_Particle> particles = [];

  @override
  void reset(Vector2 size) {
    aiSpeed = 100 + level * 35;
    aiSpeed = aiSpeed.clamp(100, 450);
    ballSpeed = 260 + level * 20;

    final rect = boardRect(size);
    playerPaddle = Rect.fromCenter(
      center: Offset(rect.left + 30, rect.center.dy),
      width: 12,
      height: 60,
    );
    aiPaddle = Rect.fromCenter(
      center: Offset(rect.right - 30, rect.center.dy),
      width: 12,
      height: (60.0 - (level - 1) * 2).clamp(40.0, 60.0),
    );

    _resetBall(size);
    playerScore = 0;
    aiScore = 0;
    targetScore = 3 + level;
    ballTrail = [];
    screenShake = 0;
    playerHit = 0;
    aiHit = 0;
    scoreFlash = 0;
    particles = [];
  }

  void _resetBall(Vector2 size) {
    final rect = boardRect(size);
    ball = rect.center;
    final angle = _rng.nextBool() ? 0.0 : pi;
    ballVelocity = Offset(
      cos(angle) * ballSpeed,
      (_rng.nextDouble() - 0.5) * ballSpeed * 0.8,
    );
    ballTrail = [];
  }

  void _spawnHitParticles(Offset center, bool isPlayer) {
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * pi - pi / 2;
      final speed = 60 + _rng.nextDouble() * 80;
      final dir = isPlayer ? 1 : -1;
      particles.add(
        _Particle(
          position: center,
          velocity: Offset(cos(angle) * speed * dir, sin(angle) * speed),
          color: isPlayer ? const Color(0xFF2A9D8F) : const Color(0xFFE76F51),
          size: 3 + _rng.nextDouble() * 3,
          life: 0.4,
        ),
      );
    }
  }

  @override
  bool get isSolved => playerScore >= targetScore;

  bool get isLost => aiScore >= targetScore;

  @override
  void update(double dt) {
    // Animation updates
    if (screenShake > 0) screenShake -= dt * 8;
    if (playerHit > 0) playerHit -= dt * 4;
    if (aiHit > 0) aiHit -= dt * 4;
    if (scoreFlash > 0) scoreFlash -= dt * 3;

    // Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (isSolved || isLost) return;

    final rect = boardRect(Vector2(400, 600));

    // Ball trail
    ballTrail.insert(0, ball);
    if (ballTrail.length > 12) ballTrail.removeLast();

    // Move ball
    ball = ball + ballVelocity * dt;

    // Wall collisions (top/bottom)
    if (ball.dy <= rect.top + 5 || ball.dy >= rect.bottom - 5) {
      ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
      screenShake = 0.2;
    }

    // Paddle collisions
    if (ball.dx <= playerPaddle.right &&
        ball.dx >= playerPaddle.left &&
        ball.dy >= playerPaddle.top &&
        ball.dy <= playerPaddle.bottom) {
      ballVelocity = Offset(-ballVelocity.dx * 1.05, ballVelocity.dy);
      ball = Offset(playerPaddle.right + 5, ball.dy);
      playerHit = 1.0;
      screenShake = 0.3;
      _spawnHitParticles(ball, true);
    }

    if (ball.dx >= aiPaddle.left &&
        ball.dx <= aiPaddle.right &&
        ball.dy >= aiPaddle.top &&
        ball.dy <= aiPaddle.bottom) {
      ballVelocity = Offset(-ballVelocity.dx * 1.05, ballVelocity.dy);
      ball = Offset(aiPaddle.left - 5, ball.dy);
      aiHit = 1.0;
      screenShake = 0.3;
      _spawnHitParticles(ball, false);
    }

    // Scoring
    if (ball.dx <= rect.left) {
      aiScore++;
      scoreFlash = 1.0;
      _resetBall(Vector2(400, 600));
    }
    if (ball.dx >= rect.right) {
      playerScore++;
      scoreFlash = 1.0;
      _resetBall(Vector2(400, 600));
    }

    // AI movement
    final aiTarget = ball.dy;
    final aiCenter = aiPaddle.center.dy;
    final aiMove = (aiTarget - aiCenter).clamp(-aiSpeed * dt, aiSpeed * dt);
    aiPaddle = Rect.fromCenter(
      center: Offset(
        aiPaddle.center.dx,
        (aiCenter + aiMove).clamp(rect.top + 30, rect.bottom - 30),
      ),
      width: 12,
      height: 60,
    );
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);

    // Apply screen shake
    if (screenShake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * screenShake * 8,
        (_rng.nextDouble() - 0.5) * screenShake * 8,
      );
    }

    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    // Center line
    final dashPaint = Paint()..color = const Color(0xFF3A4452);
    for (double y = rect.top; y < rect.bottom; y += 20) {
      canvas.drawRect(Rect.fromLTWH(rect.center.dx - 2, y, 4, 10), dashPaint);
    }

    // Player paddle with glow on hit
    final playerScale = 1.0 + playerHit * 0.1;
    final playerRect = Rect.fromCenter(
      center: playerPaddle.center,
      width: playerPaddle.width * playerScale,
      height: playerPaddle.height * playerScale,
    );
    if (playerHit > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          playerRect.inflate(4),
          const Radius.circular(5),
        ),
        Paint()
          ..color = const Color(0xFF2A9D8F).withOpacity(playerHit * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(playerRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF2A9D8F),
    );

    // AI paddle with glow on hit
    final aiScale = 1.0 + aiHit * 0.1;
    final aiRect = Rect.fromCenter(
      center: aiPaddle.center,
      width: aiPaddle.width * aiScale,
      height: aiPaddle.height * aiScale,
    );
    if (aiHit > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(aiRect.inflate(4), const Radius.circular(5)),
        Paint()
          ..color = const Color(0xFFE76F51).withOpacity(aiHit * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(aiRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFE76F51),
    );

    // Ball trail
    for (int i = 0; i < ballTrail.length; i++) {
      final opacity = (1 - i / ballTrail.length) * 0.4;
      final trailSize = 8 - i * 0.5;
      canvas.drawCircle(
        ballTrail[i],
        trailSize,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // Ball with glow
    canvas.drawCircle(
      ball,
      14,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(ball, 8, Paint()..color = Colors.white);

    // Particles
    for (final p in particles) {
      canvas.drawCircle(
        p.position,
        p.size * p.life * 2,
        Paint()..color = p.color.withOpacity(p.life * 2),
      );
    }

    // Score with flash effect
    final scoreColor = scoreFlash > 0
        ? Color.lerp(Colors.white, const Color(0xFFE9C46A), scoreFlash)!
        : Colors.white;
    final scorePaint = TextPaint(
      style: TextStyle(
        fontSize: 32 + scoreFlash * 4,
        color: scoreColor,
        fontWeight: FontWeight.bold,
      ),
    );
    scorePaint.render(
      canvas,
      '$playerScore',
      Vector2(rect.center.dx - 50, rect.top + 20),
    );
    scorePaint.render(
      canvas,
      '$aiScore',
      Vector2(rect.center.dx + 30, rect.top + 20),
    );

    if (screenShake > 0) {
      canvas.restore();
    }
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final newY = (playerPaddle.center.dy + delta.y).clamp(
      rect.top + 30,
      rect.bottom - 30,
    );
    playerPaddle = Rect.fromCenter(
      center: Offset(playerPaddle.center.dx, newY),
      width: 12,
      height: 60,
    );
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
