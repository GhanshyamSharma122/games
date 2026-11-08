import 'dart:ui';

import 'package:flame/game.dart';

import 'difficulty.dart';

/// Abstract base class for mini-games.
/// Each game receives position data as simple Vector2 coordinates
/// to keep the interface clean and compatible with the hub.
abstract class MiniGame {
  String get name;
  String get instructions;
  bool get isSolved;
  GameDifficulty difficulty = GameDifficulty.medium;

  /// Current level (1-based). Games can override max level.
  int _level = 1;
  int get level => _level;
  int get maxLevel => 10; // Default max level, games can override

  /// Whether the game supports levels (vs progressive difficulty)
  bool get hasLevels => false;

  /// Advance to next level. Returns true if advanced, false if at max.
  bool nextLevel() {
    if (_level < maxLevel) {
      _level++;
      return true;
    }
    return false;
  }

  /// Reset to level 1
  void resetLevel() {
    _level = 1;
  }

  void setDifficulty(GameDifficulty d) {
    difficulty = d;
  }

  void reset(Vector2 size);
  void update(double dt) {}
  void render(Canvas canvas, Vector2 size);

  /// Called when user taps at the given position
  void onTapDown(Vector2 position, Vector2 gameSize) {}

  /// Called when user long-presses at the given position
  void onLongPressDown(Vector2 position, Vector2 gameSize) {}

  /// Called when user starts a pan/drag at the given position
  void onPanStart(Vector2 position, Vector2 gameSize) {}

  /// Called during pan/drag with current position and delta
  void onPanUpdate(Vector2 position, Vector2 delta, Vector2 gameSize) {}

  /// Called when pan/drag ends, with optional velocity
  void onPanEnd(Vector2 velocity, Vector2 gameSize) {}
}
