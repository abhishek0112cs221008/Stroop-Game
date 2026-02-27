import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stroop_game/core/constants/app_assets.dart';
import 'package:stroop_game/core/notifications/notification_service.dart';
import 'package:stroop_game/core/router/app_router.dart';
import 'package:stroop_game/core/theme/app_colors.dart';
import 'package:stroop_game/data/repositories/stats_repository.dart';
import 'package:stroop_game/features/game/game_provider.dart';
import 'package:stroop_game/features/settings/settings_provider.dart';
import 'package:stroop_game/features/stats/stats_provider.dart';
import 'package:stroop_game/features/stats/stats_screen.dart';
import 'package:stroop_game/features/wallet/wallet_screen.dart';

// ── Shell provider (active tab) ───────────────────────────────────────────────
final _tabProvider = StateProvider<int>((ref) => 0);

// ── Main Shell ────────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final isDark = ref.watch(themeProvider);

    final pages = [
      const _HomeTab(),
      const _PlayTab(),
      const StatsScreen(),
      const WalletScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: false, // Better performance than true
        body: IndexedStack(index: tab, children: pages),
        bottomNavigationBar: RepaintBoundary(
          child: _AppleNavBar(
            currentIndex: tab,
            isDark: isDark,
            onTap: (i) => ref.read(_tabProvider.notifier).state = i,
          ),
        ),
      ),
    );
  }
}

// ── Frosted-glass Bottom Navigation Bar ───────────────────────────────────────

class _AppleNavBar extends StatelessWidget {
  const _AppleNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.sports_esports_rounded, label: 'Play'),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
      _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: active
                            ? const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              )
                            : EdgeInsets.zero,
                        decoration: active
                            ? BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        child: Icon(
                          items[i].icon,
                          size: 24,
                          color: active
                              ? AppColors.primary
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.4)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppColors.primary
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.4)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final statsAsync = ref.watch(statsProvider);
    final notifEnabled = ref.watch(notifEnabledProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ─────────────────────────────────────────────────
            _TopBar(isDark: isDark, ref: ref),
            const SizedBox(height: 28),

            // ── Hero greeting card ───────────────────────────────────────
            statsAsync.when(
              data: (s) => _HeroCard(
                streak: s.streakCount,
                coins: s.coinBalance,
                isDark: isDark,
              ),
              loading: () => const _HeroCardShimmer(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // ── Quick stats row ──────────────────────────────────────────
            statsAsync.when(
              data: (s) => _QuickStatsRow(stats: s, isDark: isDark),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 28),

            // ── Choose mode ──────────────────────────────────────────────
            _SectionHeader('GAME MODES', isDark),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (s) => _GameModeList(
                balance: s.coinBalance,
                isDark: isDark,
                context: context,
                ref: ref,
              ),
              loading: () => _GameModeList(
                balance: 0,
                isDark: isDark,
                context: context,
                ref: ref,
              ),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 28),

            // ── How to play ──────────────────────────────────────────────
            _SectionHeader('HOW TO PLAY', isDark),
            const SizedBox(height: 12),
            _HowToPlay(isDark: isDark),
            const SizedBox(height: 24),

            // ── Reminder toggle ──────────────────────────────────────────
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
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isDark, required this.ref});
  final bool isDark;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'STROOP',
            style: GoogleFonts.dancingScript(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
        ),
        // Theme toggle
        _CircleAction(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          isDark: isDark,
          onTap: () => ref.read(themeProvider.notifier).toggle(),
        ),
      ],
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.streak,
    required this.coins,
    required this.isDark,
  });
  final int streak;
  final int coins;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGrad,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration circles
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brain Training',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Train Daily,\nThink Faster.',
                style: GoogleFonts.dancingScript(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _HeroBadge(emoji: '🔥', value: '${streak}d', label: 'Streak'),
                  const SizedBox(width: 12),
                  _HeroBadge(emoji: '🪙', value: '$coins', label: 'Coins'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.emoji,
    required this.value,
    required this.label,
  });
  final String emoji, value, label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.dancingScript(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCardShimmer extends StatelessWidget {
  const _HeroCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

// ── Quick Stats Row ───────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.stats, required this.isDark});
  final dynamic stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accuracy = (stats.averageAccuracy * 100).toStringAsFixed(0);
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            value: '${stats.bestScore}',
            label: 'Best Score',
            icon: Icons.emoji_events_rounded,
            color: AppColors.coin,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            value: '$accuracy%',
            label: 'Avg Accuracy',
            icon: Icons.track_changes_rounded,
            color: AppColors.accent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            value: '${stats.totalGamesPlayed}',
            label: 'Games',
            icon: Icons.sports_esports_rounded,
            color: AppColors.secondary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String value, label;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dancingScript(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game Mode List (iOS card scroll) ─────────────────────────────────────────

class _GameModeList extends StatelessWidget {
  const _GameModeList({
    required this.balance,
    required this.isDark,
    required this.context,
    required this.ref,
  });
  final int balance;
  final bool isDark;
  final BuildContext context;
  final WidgetRef ref;

  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        _IosGameCard(
          icon: '∞',
          title: 'Classic',
          tagline: 'No timer • Always FREE',
          reward: '+2🪙 per correct',
          gradient: AppColors.primaryGrad,
          coinCost: 0,
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRouter.game, arguments: GameMode.classic),
        ),
        const SizedBox(height: 12),
        _IosGameCard(
          icon: '⏱',
          title: '60 Seconds',
          tagline: 'Race the clock',
          reward: '+20🪙 on finish',
          gradient: AppColors.coinGrad,
          coinCost: 1,
          onTap: () => _handlePaid(context, ref, GameMode.timed, balance),
        ),
        const SizedBox(height: 12),
        _IosGameCard(
          icon: '⚡',
          title: 'Speed Run',
          tagline: 'Gets faster every 5 correct',
          reward: 'High score → more coins',
          gradient: AppColors.greenGrad,
          coinCost: 1,
          onTap: () => _handlePaid(context, ref, GameMode.speed, balance),
        ),
      ],
    );
  }

  void _handlePaid(BuildContext ctx, WidgetRef r, GameMode mode, int bal) {
    if (!StatsRepository.instance.canAffordGame(mode)) {
      _showNoCoins(ctx);
      return;
    }
    _showConfirm(ctx, r, mode, bal);
  }

  void _showConfirm(BuildContext ctx, WidgetRef r, GameMode mode, int bal) {
    final label = mode == GameMode.timed ? '60 Seconds' : 'Speed Run';
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        label: label,
        balance: bal,
        isDark: isDark,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await StatsRepository.instance.spendCoin(mode);
          r.invalidate(statsProvider);
          if (ctx.mounted) {
            Navigator.of(ctx).pushNamed(AppRouter.game, arguments: mode);
          }
        },
      ),
    );
  }

  void _showNoCoins(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => _NoCoinsDialog(isDark: isDark),
    );
  }
}

// ── iOS App Store-style Game Card ───────────────────────────────────────────────

class _IosGameCard extends StatelessWidget {
  const _IosGameCard({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.reward,
    required this.gradient,
    required this.coinCost,
    required this.onTap,
  });
  final String icon, title, tagline, reward;
  final LinearGradient gradient;
  final int coinCost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -30,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: coinCost == 0
                              ? const Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(AppAssets.coin, height: 12),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '1 to play',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      Text(
                        icon,
                        style: GoogleFonts.dancingScript(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: GoogleFonts.dancingScript(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reward,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Play',
                              style: GoogleFonts.dancingScript(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: gradient.colors.first,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, this.isDark);
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dancingScript(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.35),
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
    final tips = [
      ('👁️', 'A color word appears in a DIFFERENT ink color'),
      ('🎯', 'Tap the button that matches the INK color'),
      ('🪙', '+2 coins per correct • Paid modes cost 1🪙'),
      ('🔥', 'Daily streak gives +10 bonus coins every 7 days'),
      ('😅', 'Broke? Classic earns recovery coins for you!'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: tips
            .map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.$2,
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
              ),
            )
            .toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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

// ── Circle Action Button ──────────────────────────────────────────────────────

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}

// ── Play Tab ──────────────────────────────────────────────────────────────────

class _PlayTab extends ConsumerWidget {
  const _PlayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final statsAsync = ref.watch(statsProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Choose Mode',
              style: GoogleFonts.dancingScript(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ),
            Text(
              'Pick your challenge',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),

            // Large cards
            statsAsync.when(
              data: (s) => _BigModeCard(
                icon: '∞',
                title: 'Classic',
                description:
                    'Unlimited rounds with no time pressure.\nPerfect for training your focus.',
                gradient: AppColors.primaryGrad,
                coinCost: 0,
                perks: ['Always FREE', '+2🪙 per correct', 'Recovery mode'],
                isDark: isDark,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRouter.game, arguments: GameMode.classic),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 14),
            statsAsync.when(
              data: (s) => _BigModeCard(
                icon: '⏱',
                title: '60 Seconds',
                description:
                    'Answer as many as possible in 60 seconds.\nRace against the clock!',
                gradient: AppColors.coinGrad,
                coinCost: 1,
                perks: ['Cost: 1🪙', '+2🪙 per correct', '+20🪙 on finish'],
                isDark: isDark,
                onTap: () {
                  if (!StatsRepository.instance.canAffordGame(GameMode.timed)) {
                    showDialog(
                      context: context,
                      builder: (_) => _NoCoinsDialog(isDark: isDark),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ConfirmSheet(
                      label: '60 Seconds',
                      balance: s.coinBalance,
                      isDark: isDark,
                      onConfirm: () async {
                        Navigator.of(context).pop();
                        await StatsRepository.instance.spendCoin(
                          GameMode.timed,
                        );
                        ref.invalidate(statsProvider);
                        if (context.mounted) {
                          Navigator.of(context).pushNamed(
                            AppRouter.game,
                            arguments: GameMode.timed,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 14),
            statsAsync.when(
              data: (s) => _BigModeCard(
                icon: '⚡',
                title: 'Speed Run',
                description:
                    'The game speeds up every 5 correct answers.\nHow long can you last?',
                gradient: AppColors.greenGrad,
                coinCost: 1,
                perks: ['Cost: 1🪙', 'Gets faster!', '+2🪙 per correct'],
                isDark: isDark,
                onTap: () {
                  if (!StatsRepository.instance.canAffordGame(GameMode.speed)) {
                    showDialog(
                      context: context,
                      builder: (_) => _NoCoinsDialog(isDark: isDark),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ConfirmSheet(
                      label: 'Speed Run',
                      balance: s.coinBalance,
                      isDark: isDark,
                      onConfirm: () async {
                        Navigator.of(context).pop();
                        await StatsRepository.instance.spendCoin(
                          GameMode.speed,
                        );
                        ref.invalidate(statsProvider);
                        if (context.mounted) {
                          Navigator.of(context).pushNamed(
                            AppRouter.game,
                            arguments: GameMode.speed,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Big Mode Card ──────────────────────────────────────────────────────────────

class _BigModeCard extends StatelessWidget {
  const _BigModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.coinCost,
    required this.perks,
    required this.isDark,
    required this.onTap,
  });
  final String icon, title, description;
  final LinearGradient gradient;
  final int coinCost;
  final List<String> perks;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: GoogleFonts.dancingScript(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dancingScript(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0D1117),
                          ),
                        ),
                        if (coinCost > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.coin.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.coin.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(AppAssets.coin, height: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.black.withValues(alpha: 0.45),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: perks
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm Sheet ─────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.1),
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
            'Costs 1 coin to enter.\nWin more based on your score!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.coin.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.coin.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance after entry',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppAssets.coin, height: 13),
                    const SizedBox(width: 4),
                    Text(
                      '$balance → ${balance - 1}',
                      style: GoogleFonts.dancingScript(
                        fontSize: 13,
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
                  borderRadius: BorderRadius.circular(16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😅', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'Not enough coins!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play Classic (free!) to earn coins.\nWith 0 balance you earn 5 coins per minute!',
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
                  style: GoogleFonts.outfit(
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
