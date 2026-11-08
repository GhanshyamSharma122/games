import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class LightsOutGame extends MiniGame {
  @override
  String get name => 'Lights Toggle';

  @override
  String get instructions => 'Turn all lights off.';

  @override
  bool get hasLevels => true;

  @override
  int get maxLevel => 8;

  int n = 5;
  final Random _rng = Random();
  late List<bool> lights;
  late List<double> lightGlow; // Glow animation
  late List<double> lightScale; // Press animation
  late List<double> ripple; // Ripple effect
  int moveCount = 0;

  @override
  void reset(Vector2 size) {
    n = 2 + level;
    n = n.clamp(3, 10);

    lights = List.generate(n * n, (_) => false);
    lightGlow = List.generate(n * n, (_) => 0.0);
    lightScale = List.generate(n * n, (_) => 1.0);
    ripple = List.generate(n * n, (_) => 0.0);

    final toggles = 3 + level * 2;
    for (int t = 0; t < toggles; t++) {
      final r = _rng.nextInt(n);
      final c = _rng.nextInt(n);
      _toggleForSetup(r, c);
    }

    moveCount = 0;
  }

  void _toggleForSetup(int r, int c) {
    _toggleCell(r, c);
    _toggleCell(r - 1, c);
    _toggleCell(r + 1, c);
    _toggleCell(r, c - 1);
    _toggleCell(r, c + 1);
  }

  void _toggleCell(int r, int c) {
    if (r < 0 || r >= n || c < 0 || c >= n) return;
    final i = idx(r, c, n);
    lights[i] = !lights[i];
  }

  @override
  bool get isSolved => lights.every((v) => !v);

  void _toggle(int r, int c, bool animated) {
    if (r < 0 || r >= n || c < 0 || c >= n) return;
    final i = idx(r, c, n);
    lights[i] = !lights[i];
    if (animated) {
      lightGlow[i] = 1.0;
      lightScale[i] = 0.85;
    }
  }

  @override
  void update(double dt) {
    for (int i = 0; i < n * n; i++) {
      // Glow decay
      if (lightGlow[i] > 0) {
        lightGlow[i] -= dt * 3;
        if (lightGlow[i] < 0) lightGlow[i] = 0;
      }

      // Scale animation
      if (lightScale[i] < 1.0) {
        lightScale[i] += dt * 6;
        if (lightScale[i] > 1.0) lightScale[i] = 1.0;
      }

      // Ripple animation
      if (ripple[i] > 0) {
        ripple[i] -= dt * 4;
        if (ripple[i] < 0) ripple[i] = 0;
      }
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cell = rect.width / n;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF11161D),
    );

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final i = idx(r, c, n);
        final on = lights[i];
        final glow = lightGlow[i];
        final scale = lightScale[i];
        final rip = ripple[i];

        final baseRect = Rect.fromLTWH(
          rect.left + c * cell + 4,
          rect.top + r * cell + 4,
          cell - 8,
          cell - 8,
        );

        final cellRect = Rect.fromCenter(
          center: baseRect.center,
          width: baseRect.width * scale,
          height: baseRect.height * scale,
        );

        // Ripple effect
        if (rip > 0) {
          canvas.drawCircle(
            cellRect.center,
            cell * (1 - rip) * 1.5,
            Paint()
              ..color = (on ? const Color(0xFFE9C46A) : const Color(0xFF2A9D8F))
                  .withOpacity(rip * 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }

        // Glow effect for lit cells
        if (on && glow > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              cellRect.inflate(6),
              const Radius.circular(12),
            ),
            Paint()
              ..color = const Color(0xFFE9C46A).withOpacity(glow * 0.4)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
          );
        }

        // Cell shadow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            cellRect.translate(1, 2),
            const Radius.circular(8),
          ),
          Paint()..color = Colors.black.withOpacity(0.2),
        );

        // Cell
        final baseColor = on
            ? const Color(0xFFE9C46A)
            : const Color(0xFF273244);
        final displayColor = glow > 0
            ? Color.lerp(baseColor, Colors.white, glow * 0.3)!
            : baseColor;

        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
          Paint()..color = displayColor,
        );

        // Inner highlight
        if (on) {
          final highlightRect = Rect.fromLTWH(
            cellRect.left + 3,
            cellRect.top + 3,
            cellRect.width - 6,
            cellRect.height * 0.35,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(highlightRect, const Radius.circular(6)),
            Paint()..color = Colors.white.withOpacity(0.25),
          );
        }
      }
    }

    // Lights remaining counter
    canvas.drawCircle(
      Offset(rect.center.dx, rect.bottom + 25),
      18,
      Paint()..color = const Color(0xFF1B2430),
    );
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    final rect = boardRect(gameSize);
    final cell = rect.width / n;
    if (!rect.contains(Offset(position.x, position.y))) return;
    final c = ((position.x - rect.left) / cell).floor();
    final r = ((position.y - rect.top) / cell).floor();

    // Ripple from center
    ripple[idx(r, c, n)] = 1.0;

    _toggle(r, c, true);
    _toggle(r - 1, c, true);
    _toggle(r + 1, c, true);
    _toggle(r, c - 1, true);
    _toggle(r, c + 1, true);

    moveCount++;
  }
}
