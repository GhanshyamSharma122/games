import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../core/difficulty.dart';
import '../core/mini_game.dart';
import '../games/games.dart';

class HubGame extends FlameGame
    with TapCallbacks, PanDetector, LongPressDetector {
  final List<_GameEntry> _entries = [];
  final TextPaint _titlePaint = TextPaint(
    style: const TextStyle(
      fontSize: 24,
      color: Color(0xFFE6E6E6),
      fontWeight: FontWeight.w700,
    ),
  );
  final TextPaint _smallPaint = TextPaint(
    style: const TextStyle(fontSize: 14, color: Color(0xFFB9C0C8)),
  );
  final TextPaint _tinyPaint = TextPaint(
    style: const TextStyle(fontSize: 11, color: Color(0xFF8B96A3)),
  );
  MiniGame? _current;
  String _banner = '';
  double _bannerTimer = 0;

  bool onBackPressed() {
    if (_current != null) {
      _goMenu();
      return true;
    }
    return false;
  }

  GameDifficulty _difficulty = GameDifficulty.medium;
  double _scrollOffset = 0;
  double _maxScroll = 0;

  HubGame() {
    _entries.addAll([
      _GameEntry(
        'Sliding Tiles',
        'Slide tiles into order.',
        () => SlidingTilesGame(),
      ),
      _GameEntry(
        'Lights Toggle',
        'Turn all lights off.',
        () => LightsOutGame(),
      ),
      _GameEntry(
        'Mines & Flags',
        'Reveal safe cells. Long-press to flag.',
        () => MinesGame(),
      ),
      _GameEntry(
        '2048 Merge',
        'Swipe to merge numbers.',
        () => Merge2048Game(),
      ),
      _GameEntry('Match-3', 'Swap to make 3 in a row.', () => Match3Game()),
      _GameEntry(
        'Memory Flip',
        'Find all matching pairs.',
        () => MemoryFlipGame(),
      ),
      _GameEntry(
        'Mini Sudoku',
        'Fill 1-4 without repeats.',
        () => MiniSudokuGame(),
      ),
      _GameEntry('Nonogram', 'Use clues to fill cells.', () => NonogramGame()),
      _GameEntry(
        'Pipe Connect',
        'Rotate to connect left-to-right.',
        () => PipeConnectGame(),
      ),
      _GameEntry(
        'Flow Connect',
        'Connect color pairs without crossing.',
        () => FlowConnectGame(),
      ),
      _GameEntry(
        'Path Fill',
        'Draw a path through all cells.',
        () => PathFillGame(),
      ),
      _GameEntry(
        'Rotate Match',
        'Rotate tiles so edges match.',
        () => RotateMatchGame(),
      ),
      _GameEntry(
        'Sokoban Push',
        'Push boxes onto targets.',
        () => SokobanGame(),
      ),
      _GameEntry(
        'Number Path',
        'Tap numbers in order.',
        () => NumberPathGame(),
      ),
      _GameEntry(
        'Word Connect',
        'Swipe to form hidden words.',
        () => WordConnectGame(),
      ),
      // New games
      _GameEntry('Snake', 'Eat food, grow longer!', () => SnakeGame()),
      _GameEntry(
        'Simon Says',
        'Repeat the color sequence.',
        () => SimonSaysGame(),
      ),
      _GameEntry('Tic-Tac-Toe', 'Beat the AI!', () => TicTacToeGame()),
      _GameEntry(
        'Whack-a-Mole',
        'Tap moles before they hide!',
        () => WhackAMoleGame(),
      ),
      _GameEntry('Connect Four', 'Get 4 in a row.', () => ConnectFourGame()),
      _GameEntry(
        'Mastermind',
        'Crack the secret code.',
        () => MastermindGame(),
      ),
      _GameEntry(
        'Reaction Test',
        'How fast can you tap?',
        () => ReactionTimerGame(),
      ),
      _GameEntry('Math Speed', 'Quick math problems.', () => MathSpeedGame()),
      _GameEntry('Hangman', 'Guess the word.', () => HangmanGame()),
      _GameEntry(
        'Tower of Hanoi',
        'Move disks to right peg.',
        () => TowerOfHanoiGame(),
      ),
      _GameEntry(
        'Sequence Memory',
        'Remember the numbers.',
        () => SequenceMemoryGame(),
      ),
      _GameEntry(
        'Color Match',
        'Does color match word?',
        () => ColorMatchGame(),
      ),
      _GameEntry('Breakout', 'Break all the bricks!', () => BreakoutGame()),
      _GameEntry('Pong', 'Classic paddle game.', () => PongGame()),
      _GameEntry(
        'Word Scramble',
        'Unscramble the letters.',
        () => WordScrambleGame(),
      ),
      _GameEntry(
        'Dots & Boxes',
        'Complete the most boxes.',
        () => DotsAndBoxesGame(),
      ),
      _GameEntry(
        'Battleship',
        'Find the hidden ships.',
        () => BattleshipGame(),
      ),
      // New games (batch 2)
      _GameEntry(
        'Flappy Bird',
        'Tap to fly through pipes!',
        () => FlappyBirdGame(),
      ),
      _GameEntry(
        'Block Drop',
        'Tetris-style falling blocks.',
        () => TetrisGame(),
      ),
      _GameEntry('Asteroids', 'Shoot the asteroids!', () => AsteroidsGame()),
      _GameEntry(
        'Checkers',
        'Jump to capture AI pieces.',
        () => CheckersGame(),
      ),
      _GameEntry('Reversi', 'Flip pieces to win!', () => ReversiGame()),
      _GameEntry('Blackjack', 'Get closer to 21!', () => BlackjackGame()),
      _GameEntry(
        'Higher/Lower',
        'Guess the next card!',
        () => HigherLowerGame(),
      ),
      _GameEntry('Tap Speed', 'How fast can you tap?', () => TapSpeedGame()),
      _GameEntry('Aim Trainer', 'Hit targets fast!', () => AimTrainerGame()),
      _GameEntry('Maze Runner', 'Navigate the maze!', () => MazeRunnerGame()),
      _GameEntry('Nim', 'Don\'t take the last stone!', () => NimGame()),
      _GameEntry('Pattern Copy', 'Copy the pattern!', () => PatternCopyGame()),
      _GameEntry('Quick Draw', 'Fastest draw wins!', () => QuickDrawGame()),
      // New games (batch 3 - with animations)
      _GameEntry(
        'Bubble Pop',
        'Pop bubbles before they escape!',
        () => BubblePopGame(),
      ),
      _GameEntry(
        'Coin Collector',
        'Catch falling coins!',
        () => CoinCollectorGame(),
      ),
      _GameEntry(
        'Color Switch',
        'Jump through matching colors!',
        () => ColorSwitchGame(),
      ),
      _GameEntry('Tap Rhythm', 'Tap notes on the beat!', () => TapRhythmGame()),
    ]);
  }

  @override
  Color backgroundColor() => const Color(0xFF0E1117);

  void _startGame(int index) {
    if (_hasDragged) return; // Prevent start if user was dragging
    _current = _entries[index].create();
    _current!.setDifficulty(_difficulty);
    _current!.reset(size);
    _banner = '';
    _bannerTimer = 0;
  }

  void _goMenu() {
    _current = null;
    _banner = '';
    _bannerTimer = 0;
  }

  void _resetCurrent() {
    if (_current == null) return;
    _current!.setDifficulty(_difficulty);
    _current!.reset(size);
    _banner = '';
    _bannerTimer = 0;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _current?.reset(size);
    _calculateScrollLimit();
  }

  void _calculateScrollLimit() {
    const double top = 90; // Increased top margin
    const double gap = 16;
    const double itemHeight = 72; // Slightly taller
    final int rows = _entries.length;
    final double totalHeight =
        top + rows * (itemHeight + gap) + gap + 60; // +60 for footer text
    _maxScroll = (totalHeight - size.y).clamp(0, double.infinity);
    _scrollOffset = _scrollOffset.clamp(0, _maxScroll);
  }

  double _scrollVelocity = 0;
  bool _hasDragged = false;
  Vector2? _dragStartPos;

  @override
  void update(double dt) {
    super.update(dt);
    if (_current != null) {
      _current!.update(dt);
      if (_current!.isSolved && _banner.isEmpty) {
        if (_current!.hasLevels) {
          // Level-based game: try to advance level
          if (_current!.nextLevel()) {
            _banner = 'Level ${_current!.level - 1} Complete!';
            _current!.reset(size);
          } else {
            _banner = 'All Levels Complete!';
          }
        } else {
          // Progressive game: advance and auto-reset
          _current!.nextLevel(); // Increase internal difficulty
          _banner = 'Solved! Level ${_current!.level}';
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (_current != null && _banner.isNotEmpty) {
              _current!.reset(size);
              _banner = '';
            }
          });
        }
        _bannerTimer = 2.0;
      }
    } else {
      // Menu momentum scrolling
      if (_maxScroll > 0) {
        if (!_hasDragged && _scrollVelocity.abs() > 0.1) {
          _scrollOffset -= _scrollVelocity * dt;
          _scrollVelocity *= 0.95; // Smoother glide
          // Clamp and stop if out of bounds (simple bounce stop)
          if (_scrollOffset < 0) {
            _scrollOffset = 0;
            _scrollVelocity = 0;
          } else if (_scrollOffset > _maxScroll) {
            _scrollOffset = _maxScroll;
            _scrollVelocity = 0;
          }
        }
      }
    }

    if (_bannerTimer > 0) {
      _bannerTimer -= dt;
      if (_bannerTimer <= 0) _banner = '';
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_current == null) {
      _renderMenu(canvas);
      return;
    }
    _renderHeader(canvas);
    _current!.render(canvas, size);
    _renderInstructions(canvas);
    if (_banner.isNotEmpty) {
      _drawBanner(canvas, _banner);
    }
  }

  double _measureTextWidth(TextPaint paint, String text) {
    final tp = paint.toTextPainter(text);
    tp.layout();
    return tp.width;
  }

  void _renderHeader(Canvas canvas) {
    // Two-row header: Row 1 = buttons, Row 2 = game title
    final headerRect = Rect.fromLTWH(0, 0, size.x, 90);
    final paint = Paint()..color = const Color(0xFF151A22);
    canvas.drawRect(headerRect, paint);

    // Row 1: Menu, Level indicator, Difficulty, Reset
    final backRect = Rect.fromLTWH(12, 8, 70, 32);
    final levelRect = Rect.fromLTWH(size.x / 2 - 50, 8, 100, 32);
    final diffRect = Rect.fromLTWH(size.x - 166, 8, 75, 32);
    final resetRect = Rect.fromLTWH(size.x - 82, 8, 70, 32);
    final btnPaint = Paint()..color = const Color(0xFF232B36);
    final accentPaint = Paint()..color = const Color(0xFF2A9D8F);

    canvas.drawRRect(
      RRect.fromRectAndRadius(backRect, const Radius.circular(8)),
      btnPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(levelRect, const Radius.circular(8)),
      accentPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(diffRect, const Radius.circular(8)),
      btnPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(resetRect, const Radius.circular(8)),
      btnPaint,
    );

    _tinyPaint.render(canvas, 'Menu', Vector2(backRect.left + 18, 16));

    // Level display
    final levelText = 'Lv ${_current!.level}';
    _smallPaint.render(
      canvas,
      levelText,
      Vector2(
        levelRect.center.dx - _measureTextWidth(_smallPaint, levelText) / 2,
        15,
      ),
    );

    _tinyPaint.render(
      canvas,
      _difficulty.label,
      Vector2(diffRect.left + 12, 16),
    );
    _tinyPaint.render(canvas, 'Reset', Vector2(resetRect.left + 14, 16));

    // Row 2: Game title (centered below buttons)
    _titlePaint.render(
      canvas,
      _current!.name,
      Vector2(
        (size.x - _measureTextWidth(_titlePaint, _current!.name)) / 2,
        52,
      ),
    );
  }

  void _renderMenu(Canvas canvas) {
    canvas.save();
    canvas.translate(0, -_scrollOffset);

    // Header gradient
    final headerRect = Rect.fromLTWH(0, 0, size.x, 80);
    final headerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F1217), Color(0xFF20262E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(headerRect);
    canvas.drawRect(headerRect, headerPaint);

    final title = '15 Mini Puzzle Games';
    _titlePaint.render(
      canvas,
      title,
      Vector2((size.x - _measureTextWidth(_titlePaint, title)) / 2, 28),
    );

    const double top = 90;
    const double gap = 16;
    final double columnWidth = size.x - 2 * gap; // Full width per item
    const double itemHeight = 72; // Slightly taller for single column

    // Main item background gradient
    const gradient = LinearGradient(
      colors: [Color(0xFF232B36), Color(0xFF1B222C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final border = Paint()
      ..color = const Color(0xFF354050)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);

    for (int i = 0; i < _entries.length; i++) {
      final double x = gap;
      final double y = top + i * (itemHeight + gap);

      // Cull off-screen items
      if (y - _scrollOffset > size.y || y + itemHeight - _scrollOffset < 0) {
        continue;
      }

      final rect = Rect.fromLTWH(x, y, columnWidth, itemHeight);

      // Shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(2, 4),
          const Radius.circular(16),
        ),
        shadowPaint,
      );

      // Card Background
      final cardPaint = Paint()..shader = gradient.createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        cardPaint,
      );

      // Border
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        border,
      );

      // Text
      _smallPaint.render(canvas, _entries[i].name, Vector2(x + 20, y + 16));
      _tinyPaint.render(
        canvas,
        _entries[i].instructions,
        Vector2(x + 20, y + 42),
      );

      // Play icon (chevron)
      final chevronX = rect.right - 30;
      final chevronY = rect.center.dy;
      final path = Path();
      path.moveTo(chevronX, chevronY - 6);
      path.lineTo(chevronX + 6, chevronY);
      path.lineTo(chevronX, chevronY + 6);

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF556070)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    final footerY = top + _entries.length * (itemHeight + gap) + 30;

    _smallPaint.render(
      canvas,
      'Difficulty: ${_difficulty.label}. Tap a game to start.',
      Vector2(16, footerY),
    );
    _smallPaint.render(
      canvas,
      'Long-press to flag or clear in some games.',
      Vector2(16, footerY + 24),
    );

    canvas.restore();

    // Scrollbar
    if (_maxScroll > 0) {
      final barHeight = (size.y / (size.y + _maxScroll)) * size.y;
      final barTop = (_scrollOffset / _maxScroll) * (size.y - barHeight);
      final barRect = Rect.fromLTWH(size.x - 6, barTop, 4, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        Paint()..color = Colors.white.withOpacity(0.2),
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    // Only handle tap if we haven't dragged significantly
    if (_hasDragged) return;

    final pos = event.localPosition;
    if (_current == null) {
      _handleMenuTap(pos);
      return;
    }
    if (_handleHeaderTap(pos)) return;
    // Current game handles taps internally usually via onTapDown,
    // but we can pass onTapUp if needed. For now staying with onTapDown for games
    // might be tricky if we consume it here.
    // Actually, games use onTapDown. We should propagate onTapDown if not menu.
    // But we need to distinguish menu tap vs scroll.
  }

  @override
  void onTapDown(TapDownEvent event) {
    // We don't act on menu tap down anymore, only game tap down
    final pos = event.localPosition;
    if (_current != null) {
      if (_handleHeaderTap(pos)) return;
      _current!.onTapDown(pos, size);
    }
    // For menu, we wait for Up to decide if it was a tap
    _hasDragged = false;
    _dragStartPos = pos.clone();
  }

  @override
  void onLongPressStart(LongPressStartInfo info) {
    if (_hasDragged) return;
    final pos = Vector2(
      info.eventPosition.global.x,
      info.eventPosition.global.y,
    );
    _current?.onLongPressDown(pos, size);
  }

  @override
  void onPanStart(DragStartInfo info) {
    _scrollVelocity = 0;
    _hasDragged = false;
    _dragStartPos = info.eventPosition.global.clone();

    final pos = Vector2(
      info.eventPosition.global.x,
      info.eventPosition.global.y,
    );
    _current?.onPanStart(pos, size);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final pos = Vector2(
      info.eventPosition.global.x,
      info.eventPosition.global.y,
    );

    // Check if we've moved enough to consider it a drag
    if (!_hasDragged && _dragStartPos != null) {
      final dist = (pos - _dragStartPos!).length;
      if (dist > 5) {
        // Threshold for drag
        _hasDragged = true;
      }
    }

    if (_current != null) {
      final delta = Vector2(info.delta.global.x, info.delta.global.y);
      _current?.onPanUpdate(pos, delta, size);
    } else {
      if (_maxScroll > 0) {
        _scrollOffset -= info.delta.global.y;
        _scrollOffset = _scrollOffset.clamp(0, _maxScroll);
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _dragStartPos = null;
    if (_current != null) {
      final velocity = Vector2(info.velocity.x, info.velocity.y);
      _current?.onPanEnd(velocity, size);
    } else {
      _scrollVelocity = info.velocity.y;
    }
    // _hasDragged remains true if it was set, until next TapDown resets it
  }

  bool _handleHeaderTap(Vector2 pos) {
    if (pos.y > 90) return false;
    // Row 1 buttons: y < 44
    if (pos.y < 44) {
      if (pos.x < 92) {
        _goMenu();
        return true;
      }
      if (pos.x > size.x - 166 && pos.x < size.x - 82) {
        _cycleDifficulty();
        return true;
      }
      if (pos.x > size.x - 82) {
        _resetCurrent();
        return true;
      }
    }
    return false;
  }

  void _handleMenuTap(Vector2 pos) {
    if (_hasDragged) return; // Ignore if it was a drag

    final localPos = Vector2(pos.x, pos.y + _scrollOffset);

    const double top = 70;
    const double gap = 12;
    final double columnWidth = size.x - 2 * gap;
    const double itemHeight = 72;

    if (localPos.y < top) return;

    final int index = ((localPos.y - top) / (itemHeight + gap)).floor();

    if (index < 0 || index >= _entries.length) return;

    final double y = top + index * (itemHeight + gap);
    // Be generous with hit target in single column
    if (localPos.y >= y && localPos.y <= y + itemHeight) {
      // Check within horizontal bounds too, though it's full width usually
      if (pos.x >= gap && pos.x <= gap + columnWidth) {
        _startGame(index);
      }
    }
  }

  void _drawBanner(Canvas canvas, String text) {
    final width = _measureTextWidth(_titlePaint, text) + 30;
    final rect = Rect.fromLTWH((size.x - width) / 2, 70, width, 40);
    final paint = Paint()..color = const Color(0xFF1D7A46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );
    _smallPaint.render(canvas, text, Vector2(rect.left + 15, rect.top + 12));
  }

  void _renderInstructions(Canvas canvas) {
    final text = _current!.instructions;
    final y = size.y - 24;
    _smallPaint.render(canvas, text, Vector2(12, y));
  }

  void _cycleDifficulty() {
    switch (_difficulty) {
      case GameDifficulty.easy:
        _difficulty = GameDifficulty.medium;
        break;
      case GameDifficulty.medium:
        _difficulty = GameDifficulty.hard;
        break;
      case GameDifficulty.hard:
        _difficulty = GameDifficulty.easy;
        break;
    }
    if (_current != null) {
      _current!.setDifficulty(_difficulty);
      _current!.reset(size);
    }
  }
}

class _GameEntry {
  final String name;
  final String instructions;
  final MiniGame Function() create;
  _GameEntry(this.name, this.instructions, this.create);
}
