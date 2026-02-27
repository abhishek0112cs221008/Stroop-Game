import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stroop_game/core/notifications/notification_service.dart';
import 'package:stroop_game/core/router/app_router.dart';
import 'package:stroop_game/core/constants/app_assets.dart';
import 'package:stroop_game/core/theme/app_colors.dart';
import 'package:stroop_game/data/repositories/stats_repository.dart';
import 'package:stroop_game/features/game/game_provider.dart';
import 'package:stroop_game/features/settings/settings_provider.dart';
import 'package:stroop_game/features/stats/stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final notifEnabled = ref.watch(notifEnabledProvider);
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: title + icons ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STROOP',
                          style: GoogleFonts.dancingScript(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0D1117),
                            letterSpacing: 3,
                          ),
                        ),
                        Text(
                          'Brain Training',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coin balance pill (tappable → wallet)
                  statsAsync.when(
                    data: (s) => GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRouter.wallet),
                      child: _CoinPill(coins: s.coinBalance, isDark: isDark),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: () => ref.read(themeProvider.notifier).toggle(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.bar_chart_rounded,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.stats),
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Streak banner ─────────────────────────────────────────────
              statsAsync.when(
                data: (s) =>
                    _StreakBanner(streak: s.streakCount, isDark: isDark),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 24),

              // ── Section label ──────────────────────────────────────────────
              _Label('GAME MODES', isDark),
              const SizedBox(height: 12),

              // ── Classic (always free) ──────────────────────────────────────
              _ModeCard(
                icon: '∞',
                title: 'Classic',
                subtitle: 'No timer, pure focus • Always FREE',
                gradient: AppColors.primaryGrad,
                coinCost: 0,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRouter.game, arguments: GameMode.classic),
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // ── 60 Seconds (costs 1 coin) ──────────────────────────────────
              statsAsync.when(
                data: (s) => _ModeCard(
                  icon: '60',
                  title: '60 Seconds',
                  subtitle: 'Race the clock • Earn 2 coins/correct + 20 bonus',
                  gradient: AppColors.coinGrad,
                  coinCost: 1,
                  onTap: () => _handlePaidMode(
                    context,
                    ref,
                    GameMode.timed,
                    s.coinBalance,
                    isDark,
                  ),
                  isDark: isDark,
                ),
                loading: () => _ModeCard(
                  icon: '60',
                  title: '60 Seconds',
                  subtitle: 'Race the clock',
                  gradient: AppColors.coinGrad,
                  coinCost: 1,
                  onTap: () {},
                  isDark: isDark,
                ),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 10),

              // ── Speed Run (costs 1 coin) ───────────────────────────────────
              statsAsync.when(
                data: (s) => _ModeCard(
                  icon: '⚡',
                  title: 'Speed Run',
                  subtitle:
                      'Gets faster every 5 correct • Earn 2 coins/correct + 20 bonus',
                  gradient: AppColors.greenGrad,
                  coinCost: 1,
                  onTap: () => _handlePaidMode(
                    context,
                    ref,
                    GameMode.speed,
                    s.coinBalance,
                    isDark,
                  ),
                  isDark: isDark,
                ),
                loading: () => _ModeCard(
                  icon: '⚡',
                  title: 'Speed Run',
                  subtitle: 'Gets faster every 5 correct',
                  gradient: AppColors.greenGrad,
                  coinCost: 1,
                  onTap: () {},
                  isDark: isDark,
                ),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 28),

              // ── How to play ────────────────────────────────────────────────
              _Label('HOW TO PLAY', isDark),
              const SizedBox(height: 12),
              _HowToPlay(isDark: isDark),

              const SizedBox(height: 24),

              // ── Daily reminder toggle ──────────────────────────────────────
              _NotifRow(
                isDark: isDark,
                enabled: notifEnabled,
                onChanged: (v) async {
                  if (v) {
                    final ok = await NotificationService.instance
                        .requestPermission();
                    if (ok) {
                      await NotificationService.instance.scheduleDailyReminder(
                        19,
                        0,
                      );
                      ref.read(notifEnabledProvider.notifier).setValue(true);
                    }
                  } else {
                    await NotificationService.instance.cancelDailyReminder();
                    ref.read(notifEnabledProvider.notifier).setValue(false);
                  }
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePaidMode(
    BuildContext context,
    WidgetRef ref,
    GameMode mode,
    int balance,
    bool isDark,
  ) {
    if (!StatsRepository.instance.canAffordGame(mode)) {
      _showNoCoinsDialog(context, isDark);
      return;
    }
    _showConfirmDialog(context, ref, mode, balance, isDark);
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    GameMode mode,
    int balance,
    bool isDark,
  ) {
    final label = mode == GameMode.timed ? '60 Seconds' : 'Speed Run';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        label: label,
        balance: balance,
        isDark: isDark,
        onConfirm: () async {
          Navigator.of(context).pop();
          await StatsRepository.instance.spendCoin(mode);
          ref.invalidate(statsProvider);
          if (context.mounted) {
            Navigator.of(context).pushNamed(AppRouter.game, arguments: mode);
          }
        },
      ),
    );
  }

  void _showNoCoinsDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => _NoCoinsDialog(isDark: isDark),
    );
  }
}

// ── Confirm Bottom Sheet ──────────────────────────────────────────────────────

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.label,
    required this.balance,
    required this.isDark,
    required this.onConfirm,
  });
  final String label;
  final int balance;
  final bool isDark;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Image.asset(AppAssets.coin, height: 60),
          const SizedBox(height: 10),
          Text(
            'Play $label?',
            style: GoogleFonts.dancingScript(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This mode costs 1 coin to enter.\nWin more coins based on your score!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.coin.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.coin.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your balance',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                Row(
                  children: [
                    Image.asset(AppAssets.coin, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$balance → ${balance - 1}',
                      style: GoogleFonts.dancingScript(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coin,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Spend 1 ',
                    style: GoogleFonts.dancingScript(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Image.asset(AppAssets.coin, height: 16, color: Colors.white),
                  Text(
                    ' & Play',
                    style: GoogleFonts.dancingScript(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No Coins Dialog ───────────────────────────────────────────────────────────

class _NoCoinsDialog extends StatelessWidget {
  const _NoCoinsDialog({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😅', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'Not enough coins!',
              style: GoogleFonts.dancingScript(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need at least 1 coin to play this mode.\n\nPlay Classic (free!) to earn coins — you get 5 coins per minute when your balance is 0!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it!',
                  style: GoogleFonts.dancingScript(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coin Pill ─────────────────────────────────────────────────────────────────

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins, required this.isDark});
  final int coins;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.coin.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.coin.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAssets.coin, height: 14),
          const SizedBox(width: 5),
          Text(
            '$coins',
            style: GoogleFonts.dancingScript(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.coin,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: AppColors.coin.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

// ── Icon Button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
        ),
      ),
    );
  }
}

// ── Streak Banner ─────────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak, required this.isDark});
  final int streak;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.greenGrad,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak-Day Streak',
                style: GoogleFonts.dancingScript(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                streak == 0
                    ? 'Play today to start your streak!'
                    : 'Keep it up! Don\'t miss a day.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mode Card ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.coinCost,
    required this.onTap,
    required this.isDark,
  });
  final String icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final int coinCost;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: GoogleFonts.dancingScript(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dancingScript(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0D1117),
                          ),
                        ),
                        if (coinCost > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.coin.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.coin.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(AppAssets.coin, height: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$coinCost',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.coin,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text, this.isDark);
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dancingScript(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.35),
        letterSpacing: 2,
      ),
    );
  }
}

// ── How To Play ───────────────────────────────────────────────────────────────

class _HowToPlay extends StatelessWidget {
  const _HowToPlay({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _Tip('👁️', 'A color word appears in a DIFFERENT ink color', isDark),
          _Tip('🎯', 'Tap the button that matches the INK color', isDark),
          _Tip(
            'Coin',
            '+2 coins per correct · Timed/Speed costs 1 coin to enter',
            isDark,
          ),
          _Tip('🔥', 'Maintain your daily streak for +10 bonus coins!', isDark),
          _Tip(
            '😅',
            'Broke? Classic earns 5 coins/min to get you back!',
            isDark,
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.emoji, this.text, this.isDark);
  final String emoji;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.65)
                    : Colors.black.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Row ──────────────────────────────────────────────────────────

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.isDark,
    required this.enabled,
    required this.onChanged,
  });
  final bool isDark;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reminder',
                  style: GoogleFonts.dancingScript(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                  ),
                ),
                Text(
                  '7:00 PM every day',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
