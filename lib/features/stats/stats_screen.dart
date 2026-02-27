import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stroop_game/core/constants/app_assets.dart';
import 'package:stroop_game/core/theme/app_colors.dart';
import 'package:stroop_game/data/models/game_stats_model.dart';
import 'package:stroop_game/features/settings/settings_provider.dart';
import 'package:stroop_game/features/stats/stats_provider.dart';
import 'package:stroop_game/features/stats/streak_calendar.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Statistics',
                      style: GoogleFonts.dancingScript(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0D1117),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    onPressed: () => ref.invalidate(statsProvider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: statsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (s) => _StatsBody(stats: s, isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Body ────────────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats, required this.isDark});
  final GameStatsModel stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Coin balance card ─────────────────────────────────────────
          _CoinCard(coins: stats.coinBalance, isDark: isDark),
          const SizedBox(height: 14),

          // ── Best score + streak ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: '🏆',
                  label: 'Best Score',
                  value: '${stats.bestScore}',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  emoji: '🔥',
                  label: 'Streak',
                  value: '${stats.streakCount}d',
                  color: AppColors.incorrect,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: '🎯',
                  label: 'Accuracy',
                  value: '${(stats.averageAccuracy * 100).toStringAsFixed(1)}%',
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  emoji: '⚡',
                  label: 'Avg React',
                  value: stats.averageReactionMs > 0
                      ? '${stats.averageReactionMs.toStringAsFixed(0)}ms'
                      : '—',
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Games played – full width
          _WideStatCard(
            emoji: '🎮',
            label: 'Total Games Played',
            value: '${stats.totalGamesPlayed}',
            color: AppColors.coin,
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // ── Calendar ──────────────────────────────────────────────────
          _SectionLabel('ACTIVITY CALENDAR', isDark),
          const SizedBox(height: 10),
          StreakCalendar(playedDates: stats.playedDates, isDark: isDark),

          // ── Recent scores chart ───────────────────────────────────────
          if (stats.recentScores.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel('RECENT SCORES', isDark),
            const SizedBox(height: 10),
            _BarChart(scores: stats.recentScores, isDark: isDark),
          ],

          // ── Empty state ───────────────────────────────────────────────
          if (stats.totalGamesPlayed == 0) _EmptyState(isDark: isDark),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Coin Balance Card ─────────────────────────────────────────────────────────

class _CoinCard extends StatelessWidget {
  const _CoinCard({required this.coins, required this.isDark});
  final int coins;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.coinGrad,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.coin.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(AppAssets.coin, height: 44),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$coins',
                style: GoogleFonts.dancingScript(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Total Coins Earned',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+2',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'per correct',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Cards ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String emoji, label, value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dancingScript(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideStatCard extends StatelessWidget {
  const _WideStatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String emoji, label, value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.dancingScript(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.isDark);
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

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({required this.scores, required this.isDark});
  final List<int> scores;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(14),
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
      child: CustomPaint(
        painter: _BarPainter(
          scores: scores,
          barColor: AppColors.primary,
          labelColor: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.45),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.scores,
    required this.barColor,
    required this.labelColor,
  });
  final List<int> scores;
  final Color barColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;
    final max = scores.reduce((a, b) => a > b ? a : b);
    if (max == 0) return;

    final count = scores.length;
    final barW = (size.width / count) * 0.5;
    final gap = size.width / count;
    final chartH = size.height - 20;

    for (int i = 0; i < count; i++) {
      final x = i * gap + (gap - barW) / 2;
      final barH = (scores[i] / max) * chartH;
      final top = chartH - barH;

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [barColor, barColor.withValues(alpha: 0.4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, top, barW, barH));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barW, barH),
          const Radius.circular(5),
        ),
        paint,
      );

      // Score label
      final tp = TextPainter(
        text: TextSpan(
          text: '${scores[i]}',
          style: TextStyle(
            color: labelColor,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + barW / 2 - tp.width / 2, top - tp.height - 2),
      );

      // Index
      final idx = TextPainter(
        text: TextSpan(
          text: '#${i + 1}',
          style: TextStyle(color: labelColor, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      idx.paint(canvas, Offset(x + barW / 2 - idx.width / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.scores != scores;
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Text('🎮', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No games yet!',
              style: GoogleFonts.dancingScript(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Play your first game to see stats here.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
