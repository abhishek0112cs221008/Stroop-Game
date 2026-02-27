import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Clean abstraction over flutter_local_notifications.
///
/// Usage:
///   await NotificationService.instance.initialize();
///   await NotificationService.instance.requestPermission();
///   await NotificationService.instance.scheduleDailyReminder(19, 0);
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyNotifId = 1;
  static const int _rewardNotifId = 2;
  static const String _channelId = 'stroop_daily';
  static const String _channelName = 'Daily Reminder';
  static const String _channelDesc = 'Daily brain training reminder';
  static const String _rewardChannelId = 'stroop_rewards';
  static const String _rewardChannelName = 'Game Rewards';
  static const String _rewardChannelDesc = 'Coin rewards after each game';

  // ──────────────────────────────────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create daily reminder channel
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    // Create game rewards channel
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _rewardChannelId,
            _rewardChannelName,
            description: _rewardChannelDesc,
            importance: Importance.defaultImportance,
          ),
        );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Permission (Android 13+)
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Scheduling
  // ──────────────────────────────────────────────────────────────────────────

  /// Schedule a daily notification at [hour]:[minute] local time.
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await _plugin.zonedSchedule(
      _dailyNotifId,
      '🧠 Time to train your brain!',
      'Play a quick Stroop round and keep your streak alive.',
      _nextInstance(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyNotifId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Game Reward Notification
  // ──────────────────────────────────────────────────────────────────────────

  /// Fire an immediate notification showing coins earned after a game.
  Future<void> showGameReward({
    required int coinsEarned,
    required int newBalance,
    required String modeName,
  }) async {
    if (!(await hasPermission())) return;
    final body = 'You now have $newBalance coins total. Keep going!';
    await _plugin.show(
      _rewardNotifId,
      '+$coinsEarned coins from $modeName!',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _rewardChannelId,
          _rewardChannelName,
          channelDescription: _rewardChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
