import 'package:flutter/material.dart';
import 'package:stroop_game/core/theme/app_colors.dart';

/// All Stroop game word/color data lives here.
class GameConstants {
  GameConstants._();

  /// The words that appear in the center of the screen.
  static const List<String> words = [
    'RED',
    'BLUE',
    'GREEN',
    'YELLOW',
    'PURPLE',
    'ORANGE',
  ];

  /// Maps a word string to its actual color.
  static const Map<String, Color> wordColors = {
    'RED': AppColors.stroopRed,
    'BLUE': AppColors.stroopBlue,
    'GREEN': AppColors.stroopGreen,
    'YELLOW': AppColors.stroopYellow,
    'PURPLE': AppColors.stroopPurple,
    'ORANGE': AppColors.stroopOrange,
  };

  // ── Timing ──────────────────────────────────────────────────────────────

  /// Duration of the 60-second timed challenge (in seconds).
  static const int timedGameDuration = 60;

  /// Initial milliseconds per round in Speed mode.
  static const int speedModeInitialMs = 3000;

  /// How much to reduce per-round time in Speed mode (ms) every 5 correct.
  static const int speedModeReductionMs = 150;

  /// Minimum per-round time in Speed mode (ms).
  static const int speedModeMinMs = 800;

  // ── Scoring ──────────────────────────────────────────────────────────────

  static const int pointsCorrect = 10;
  static const int pointsIncorrect = -5; // negative to discourage guessing

  // ── Notification ────────────────────────────────────────────────────────

  static const int dailyNotificationHour = 19; // 7 PM
  static const int dailyNotificationMinute = 0;
}
