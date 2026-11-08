import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/mini_game.dart';
import '../core/util.dart';

class TetrisGame extends MiniGame {
  @override
  String get name => 'Block Drop';

  @override
  String get instructions => 'Swipe to move. Tap to rotate. Complete lines!';

  final Random _rng = Random();
  int cols = 10;
  int rows = 16;
  late List<int> board;
  late List<List<int>> currentPiece;
  late int pieceType;
  int pieceX = 0;
  int pieceY = 0;
  double dropTimer = 0;
  double dropSpeed = 0.8;
  int score = 0;
  int targetLines = 5;
  int linesCleared = 0;
  bool gameOver = false;

  // Animation
  List<_Particle> particles = [];
  double shakeAmount = 0;
  double flashIntensity = 0;
  List<double> rowFlash = []; // Flash timer per row for clear animation

  static const List<List<List<int>>> pieces = [
    [
      [1, 1, 1, 1],
    ], // I
    [
      [1, 1],
      [1, 1],
    ], // O
    [
      [0, 1, 0],
      [1, 1, 1],
    ], // T
    [
      [1, 0, 0],
      [1, 1, 1],
    ], // L
    [
      [0, 0, 1],
      [1, 1, 1],
    ], // J
    [
      [0, 1, 1],
      [1, 1, 0],
    ], // S
    [
      [1, 1, 0],
      [0, 1, 1],
    ], // Z
  ];

  static const List<Color> pieceColors = [
    Color(0xFF00FFFF),
    Color(0xFFFFFF00),
    Color(0xFFAA00FF),
    Color(0xFFFF8800),
    Color(0xFF0000FF),
    Color(0xFF00FF00),
    Color(0xFFFF0000),
  ];

  @override
  void reset(Vector2 size) {
    targetLines = 3 + level * 2;
    dropSpeed = 1.0 - level * 0.08;
    dropSpeed = dropSpeed.clamp(0.2, 1.0);

    board = List.generate(rows * cols, (_) => 0);
    linesCleared = 0;
    score = 0;
    gameOver = false;
    particles = [];
    shakeAmount = 0;
    flashIntensity = 0;
    rowFlash = List.generate(rows, (_) => 0.0);

    _spawnPiece();
  }

  void _spawnPiece() {
    pieceType = _rng.nextInt(7);
    currentPiece = pieces[pieceType].map((row) => List<int>.from(row)).toList();
    pieceX = cols ~/ 2 - currentPiece[0].length ~/ 2;
    pieceY = 0;

    if (!_canPlace(pieceX, pieceY)) {
      gameOver = true;
      shakeAmount = 1.0;
    }
  }

  void _spawnLandParticles(int x, int y, int width, int colorIdx) {
    final color = pieceColors[colorIdx];
    for (int i = 0; i < width * 3; i++) {
      final px = x + _rng.nextDouble() * width;
      final py = y.toDouble();
      particles.add(
        _Particle(
          x: px,
          y: py,
          vx: (_rng.nextDouble() - 0.5) * 50,
          vy: -20 - _rng.nextDouble() * 30,
          size: 3,
          life: 0.5,
          color: color,
        ),
      );
    }
  }

  void _spawnClearParticles(int row) {
    for (int c = 0; c < cols; c++) {
      final colorIdx = board[idx(row, c, cols)] - 1;
      if (colorIdx < 0) continue;
      final color = pieceColors[colorIdx];

      for (int i = 0; i < 5; i++) {
        particles.add(
          _Particle(
            x: c.toDouble() + 0.5,
            y: row.toDouble() + 0.5,
            vx: (_rng.nextDouble() - 0.5) * 100,
            vy: (_rng.nextDouble() - 0.5) * 100,
            size: 4,
            life: 0.8,
            color: color,
          ),
        );
      }
    }
  }

  bool _canPlace(int x, int y) {
    for (int r = 0; r < currentPiece.length; r++) {
      for (int c = 0; c < currentPiece[r].length; c++) {
        if (currentPiece[r][c] != 0) {
          final nx = x + c;
          final ny = y + r;
          if (nx < 0 || nx >= cols || ny >= rows) return false;
          if (ny >= 0 && board[idx(ny, nx, cols)] != 0) return false;
        }
      }
    }
    return true;
  }

  void _placePiece() {
    for (int r = 0; r < currentPiece.length; r++) {
      for (int c = 0; c < currentPiece[r].length; c++) {
        if (currentPiece[r][c] != 0) {
          final nx = pieceX + c;
          final ny = pieceY + r;
          if (ny >= 0 && ny < rows && nx >= 0 && nx < cols) {
            board[idx(ny, nx, cols)] = pieceType + 1;
          }
        }
      }
    }

    // Landing effect
    _spawnLandParticles(
      pieceX,
      pieceY + currentPiece.length,
      currentPiece[0].length,
      pieceType,
    );
    shakeAmount = 0.2;

    _clearLines();
    _spawnPiece();
  }

  void _clearLines() {
    List<int> linesToClear = [];
    for (int r = rows - 1; r >= 0; r--) {
      bool full = true;
      for (int c = 0; c < cols; c++) {
        if (board[idx(r, c, cols)] == 0) {
          full = false;
          break;
        }
      }
      if (full) linesToClear.add(r);
    }

    if (linesToClear.isNotEmpty) {
      shakeAmount = 0.5 * linesToClear.length;
      flashIntensity = 0.5;

      for (final r in linesToClear) {
        rowFlash[r] = 1.0;
        _spawnClearParticles(r);

        // Remove line and shift down
        for (int y = r; y > 0; y--) {
          for (int c = 0; c < cols; c++) {
            board[idx(y, c, cols)] = board[idx(y - 1, c, cols)];
          }
        }
        for (int c = 0; c < cols; c++) {
          board[idx(0, c, cols)] = 0;
        }
        linesCleared++;
        score += 100 * linesToClear.length; // Bonus for multi-line
      }
    }
  }

  void _rotate() {
    final rotated = <List<int>>[];
    for (int c = 0; c < currentPiece[0].length; c++) {
      final newRow = <int>[];
      for (int r = currentPiece.length - 1; r >= 0; r--) {
        newRow.add(currentPiece[r][c]);
      }
      rotated.add(newRow);
    }

    final oldPiece = currentPiece;
    currentPiece = rotated;
    if (!_canPlace(pieceX, pieceY)) {
      currentPiece = oldPiece;
    }
  }

  @override
  bool get isSolved => linesCleared >= targetLines;

  @override
  void update(double dt) {
    // Animation updates
    if (shakeAmount > 0) shakeAmount -= dt * 4;
    if (flashIntensity > 0) flashIntensity -= dt * 2;
    for (int i = 0; i < rows; i++) {
      if (rowFlash[i] > 0) rowFlash[i] -= dt * 5;
    }

    // Particle updates
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].x += particles[i].vx * dt;
      particles[i].y += particles[i].vy * dt;
      particles[i].vy += 10 * dt; // Gravity
      particles[i].life -= dt * 2;
      if (particles[i].life <= 0) particles.removeAt(i);
    }

    if (gameOver || isSolved) return;

    dropTimer += dt;
    if (dropTimer >= dropSpeed) {
      dropTimer = 0;
      if (_canPlace(pieceX, pieceY + 1)) {
        pieceY++;
      } else {
        _placePiece();
      }
    }
  }

  @override
  void render(Canvas canvas, Vector2 size) {
    final rect = boardRect(size);
    final cellW = rect.width / cols;
    final cellH = rect.height / rows;

    // Apply shake
    if (shakeAmount > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shakeAmount * 10,
        (_rng.nextDouble() - 0.5) * shakeAmount * 10,
      );
    }

    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B2430));

    // Draw board
    for (int r = 0; r < rows; r++) {
      // Row flash
      if (rowFlash[r] > 0) {
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top + r * cellH, rect.width, cellH),
          Paint()..color = Colors.white.withOpacity(rowFlash[r] * 0.5),
        );
      }

      for (int c = 0; c < cols; c++) {
        final v = board[idx(r, c, cols)];
        if (v != 0) {
          final cellRect = Rect.fromLTWH(
            rect.left + c * cellW + 1,
            rect.top + r * cellH + 1,
            cellW - 2,
            cellH - 2,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(cellRect, const Radius.circular(4)),
            Paint()..color = pieceColors[v - 1],
          );

          // Highlight
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                cellRect.left + 2,
                cellRect.top + 2,
                cellRect.width - 4,
                cellRect.height * 0.4,
              ),
              const Radius.circular(2),
            ),
            Paint()..color = Colors.white.withOpacity(0.3),
          );
        }
      }
    }

    // Draw current piece
    for (int r = 0; r < currentPiece.length; r++) {
      for (int c = 0; c < currentPiece[r].length; c++) {
        if (currentPiece[r][c] != 0) {
          final x = pieceX + c;
          final y = pieceY + r;
          if (y >= 0) {
            final cellRect = Rect.fromLTWH(
              rect.left + x * cellW + 1,
              rect.top + y * cellH + 1,
              cellW - 2,
              cellH - 2,
            );

            // Ghost piece effect
            canvas.drawRRect(
              RRect.fromRectAndRadius(cellRect, const Radius.circular(4)),
              Paint()..color = pieceColors[pieceType].withOpacity(0.8),
            );
            // Highlight
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  cellRect.left + 2,
                  cellRect.top + 2,
                  cellRect.width - 4,
                  cellRect.height * 0.4,
                ),
                const Radius.circular(2),
              ),
              Paint()..color = Colors.white.withOpacity(0.3),
            );
          }
        }
      }
    }

    // Particles (mapped to screen coords)
    for (final p in particles) {
      canvas.drawCircle(
        Offset(rect.left + p.x * cellW, rect.top + p.y * cellH),
        p.size * p.life,
        Paint()..color = p.color.withOpacity(p.life),
      );
    }

    // Flash overlay
    if (flashIntensity > 0) {
      canvas.drawRect(
        rect,
        Paint()..color = Colors.white.withOpacity(flashIntensity * 0.2),
      );
    }

    if (gameOver) {
      canvas.drawRect(rect, Paint()..color = const Color(0x88E63946));
      TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ).render(
        canvas,
        'GAME OVER',
        Vector2(rect.center.dx - 80, rect.center.dy),
      );
    }

    if (shakeAmount > 0) {
      canvas.restore();
    }
  }

  @override
  void onTapDown(Vector2 position, Vector2 gameSize) {
    if (gameOver || isSolved) return;
    _rotate();
  }

  @override
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {
    if (gameOver || isSolved) return;

    if (delta.x.abs() > 10) {
      final dir = delta.x > 0 ? 1 : -1;
      if (_canPlace(pieceX + dir, pieceY)) {
        pieceX += dir;
      }
    }
    if (delta.y > 15) {
      while (_canPlace(pieceX, pieceY + 1)) {
        pieceY++;
      }
    }
  }
}

class _Particle {
  double x, y, vx, vy, size, life;
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
