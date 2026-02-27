import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stroop_game/core/constants/app_assets.dart';
import 'package:stroop_game/core/theme/app_colors.dart';
import 'package:stroop_game/data/models/coin_transaction_model.dart';
import 'package:stroop_game/data/repositories/stats_repository.dart';
import 'package:stroop_game/features/settings/settings_provider.dart';
import 'package:stroop_game/features/stats/stats_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final transactionsProvider = FutureProvider<List<CoinTransactionModel>>((
  ref,
) async {
  return StatsRepository.instance.getTransactions();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final statsAsync = ref.watch(statsProvider);
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Coin Wallet',
                      style: GoogleFonts.dancingScript(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0D1117),
                      ),
                    ),
                  ),
                  // Balance pill
                  statsAsync.when(
                    data: (s) => _BalancePill(coins: s.coinBalance),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),

            // ── Earn guide card ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EarnGuideCard(isDark: isDark),
            ),
            const SizedBox(height: 20),

            // ── Transaction label ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'TRANSACTION HISTORY',
                style: GoogleFonts.dancingScript(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.35),
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Transaction list ─────────────────────────────────────────────
            Expanded(
              child: txAsync.when(
                data: (txs) => txs.isEmpty
                    ? _EmptyState(isDark: isDark)
                    : _TransactionList(txs: txs, isDark: isDark),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balance Pill ──────────────────────────────────────────────────────────────

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.coinGrad,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAssets.coin, height: 18),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: GoogleFonts.dancingScript(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Earn Guide Card ───────────────────────────────────────────────────────────

class _EarnGuideCard extends StatelessWidget {
  const _EarnGuideCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coin.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.coin.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'How to earn',
                style: GoogleFonts.dancingScript(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coin,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(AppAssets.coin, height: 14),
            ],
          ),
          const SizedBox(height: 8),
          _GuideRow('Classic (free)', '+2 per correct answer', isDark),
          _GuideRow('Classic (0 balance)', '+5 per minute played', isDark),
          _GuideRow(
            '60-Sec / Speed',
            'Cost 1🪙 → +2 per correct, +20 finish',
            isDark,
          ),
          _GuideRow('7-Day Streak', '+10 bonus coins', isDark),
          _GuideRow('Welcome', '+50 on first launch 🎉', isDark),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow(this.label, this.value, this.isDark);
  final String label, value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction List ──────────────────────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.txs, required this.isDark});
  final List<CoinTransactionModel> txs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: txs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TxTile(tx: txs[i], isDark: isDark),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx, required this.isDark});
  final CoinTransactionModel tx;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.amount >= 0;
    final color = isEarned ? AppColors.accent : AppColors.incorrect;
    final dt = DateTime.tryParse(tx.timestamp) ?? DateTime.now();
    final timeLabel = _relativeTime(dt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isEarned ? Icons.add_rounded : Icons.remove_rounded,
                color: color,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarned ? '+' : ''}${tx.amount}',
                style: GoogleFonts.dancingScript(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.coin, height: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${tx.balance}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAssets.coin, height: 60),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: GoogleFonts.dancingScript(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Play a game to earn your first coins!',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
