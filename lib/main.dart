import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stroop_game/core/notifications/notification_service.dart';
import 'package:stroop_game/core/router/app_router.dart';
import 'package:stroop_game/core/theme/app_theme.dart';
import 'package:stroop_game/data/database/hive_database.dart';
import 'package:stroop_game/data/repositories/stats_repository.dart';
import 'package:stroop_game/features/settings/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize local database (Hive)
  await HiveDatabase.init();

  // Award welcome coins to brand-new users
  await StatsRepository.instance.ensureWelcomeCoins();

  // Initialize notifications
  await NotificationService.instance.initialize();

  // Load SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: buildProviderOverrides(prefs),
      child: const StroopApp(),
    ),
  );
}

class StroopApp extends ConsumerWidget {
  const StroopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Stroop Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
