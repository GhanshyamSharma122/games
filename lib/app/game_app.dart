import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'hub_game.dart';

import 'package:flutter/services.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  final HubGame _hubGame = HubGame();

  @override
  Widget build(BuildContext context) {
    Flame.device.fullScreen();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '15 Mini Puzzle Games',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1117),
      ),
      home: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          // Try to handle back in game (e.g. return to menu)
          if (!_hubGame.onBackPressed()) {
            // If game didn't handle it (we are in menu), exit app
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: SafeArea(child: GameWidget(game: _hubGame)),
        ),
      ),
    );
  }
}
