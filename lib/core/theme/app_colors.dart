import 'package:flutter/material.dart';

/// Clean, professional dark-first palette
class AppColors {
  AppColors._();

  // ── Dark Mode Surfaces ───────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0D1117); // GitHub dark
  static const Color cardDark = Color(0xFF161B22);
  static const Color card2Dark = Color(0xFF21262D);

  // ── Light Mode Surfaces ──────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF6F8FA);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Brand ────────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F8EF7); // Electric blue
  static const Color secondary = Color(0xFF7B61FF); // Soft violet
  static const Color accent = Color(0xFF00C896); // Mint green

  // ── Coin / Reward ────────────────────────────────────────────────────────────
  static const Color coin = Color(0xFFFFB800); // Gold coin
  static const Color coinDim = Color(0xFF7A6000);

  // ── Feedback ────────────────────────────────────────────────────────────────
  static const Color correct = Color(0xFF00C896);
  static const Color incorrect = Color(0xFFFF4757);

  // ── Stroop Word Colors ───────────────────────────────────────────────────────
  static const Color stroopRed = Color(0xFFFF4757);
  static const Color stroopBlue = Color(0xFF4F8EF7);
  static const Color stroopGreen = Color(0xFF00C896);
  static const Color stroopYellow = Color(0xFFFFB800);
  static const Color stroopPurple = Color(0xFF7B61FF);
  static const Color stroopOrange = Color(0xFFFF6B35);

  // ── Calendar ────────────────────────────────────────────────────────────────
  static const Color calPlayed = Color(0xFF4F8EF7);
  static const Color calStreak = Color(0xFF00C896);
  static const Color calToday = Color(0xFFFFB800);

  // ── Gradient presets ────────────────────────────────────────────────────────
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF7B61FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient coinGrad = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGrad = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A3E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
