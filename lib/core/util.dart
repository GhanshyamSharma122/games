import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

Rect boardRect(Vector2 size) {
  const double top = 70;
  const double pad = 14;
  final double boardSize = min(size.x - pad * 2, size.y - top - pad * 2);
  final double left = (size.x - boardSize) / 2;
  final double topY = top + (size.y - top - boardSize) / 2;
  return Rect.fromLTWH(left, topY, boardSize, boardSize);
}

int idx(int r, int c, int n) => r * n + c;
