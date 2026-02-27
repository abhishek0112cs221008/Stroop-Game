import 'package:flutter/material.dart';
import 'package:stroop_game/features/game/game_provider.dart';
import 'package:stroop_game/features/game/game_screen.dart';
import 'package:stroop_game/features/home/main_shell.dart';

class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String game = '/game';
  static const String wallet = '/wallet';
  static const String stats = '/stats';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell());

      case game:
        final mode = settings.arguments as GameMode? ?? GameMode.classic;
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => GameScreen(mode: mode),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );

      default:
        return MaterialPageRoute(builder: (_) => const MainShell());
    }
  }
}
