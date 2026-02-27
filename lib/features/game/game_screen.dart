import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stroop_game/core/constants/app_assets.dart';
import 'package:stroop_game/core/constants/game_constants.dart';
import 'package:stroop_game/core/theme/app_colors.dart';
import 'package:stroop_game/data/repositories/stats_repository.dart';
import 'package:stroop_game/features/game/game_provider.dart';
import 'package:stroop_game/features/settings/settings_provider.dart';
import 'package:stroop_game/features/stats/stats_provider.dart';
import 'package:stroop_game/features/wallet/wallet_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.mode});
  final GameMode mode;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _wordCtrl;
  late AnimationController _flashCtrl;
  late Animation<double> _wordScale;

  @override
  void initState() {
    super.initState();
    _wordCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wordScale = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _wordCtrl, curve: Curves.elasticOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).startGame(widget.mode);
    });
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final isDark = ref.watch(themeProvider);

    ref.listen(gameProvider, (prev, next) {
      if (next.lastResult != AnswerResult.none) {
        _wordCtrl.forward(from: 0);
        _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
      }
    });

    if (game.status == GameStatus.over) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOver(context, game);
      });
    }

    final flashColor = game.lastResult == AnswerResult.correct
        ? AppColors.correct.withValues(alpha: 0.14)
        : game.lastResult == AnswerResult.incorrect
        ? AppColors.incorrect.withValues(alpha: 0.14)
        : Colors.transparent;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: flashColor,
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _CircleBtn(
                      icon: Icons.close_rounded,
                      onTap: () {
                        ref.read(gameProvider.notifier).endGame();
                        Navigator.of(context).pop();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatsBar(game: game, isDark: isDark),
                    ),
                    if (widget.mode == GameMode.timed) ...[
                      const SizedBox(width: 12),
                      _TimerChip(seconds: game.timeLeftSeconds),
                    ],
                    // Live coin counter
                    const SizedBox(width: 8),
                    _LiveCoins(coins: game.coinsEarnedThisSession),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Mode label ─────────────────────────────────────────────
              _ModeChip(mode: widget.mode),
              const SizedBox(height: 24),

              // ── Word display ───────────────────────────────────────────
              ScaleTransition(
                scale: _wordScale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _WordPanel(
                    key: ValueKey(game.displayWord + game.inkColor.toString()),
                    word: game.displayWord,
                    color: game.inkColor,
                    isDark: isDark,
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'Tap the color of the text',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.35),
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 3),

              // ── Color grid ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: game.options.map((word) {
                    final c = GameConstants.wordColors[word] ?? Colors.grey;
                    return _ColorBtn(
                      word: word,
                      color: c,
                      onTap: () =>
                          ref.read(gameProvider.notifier).submitAnswer(word),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameOver(BuildContext ctx, GameState state) {
    if (!mounted) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _GameOverDialog(state: state),
    ).then((_) {
      ref.invalidate(statsProvider);
      ref.invalidate(transactionsProvider);
    });
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.game, required this.isDark});
  final GameState game;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final acc = game.total == 0 ? 0.0 : game.correct / game.total;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: 'Score', value: '${game.score}', isDark: isDark),
        _Divider(isDark: isDark),
        _Stat(
          label: 'Acc',
          value: '${(acc * 100).toStringAsFixed(0)}%',
          isDark: isDark,
        ),
        _Divider(isDark: isDark),
        _Stat(label: 'Rounds', value: '${game.total}', isDark: isDark),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.isDark});
  final String label, value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dancingScript(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
    );
  }
}

// ── Live Coin Counter ─────────────────────────────────────────────────────────

class _LiveCoins extends StatelessWidget {
  const _LiveCoins({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(coins),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.coin.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.coin.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.coin, height: 16),
            const SizedBox(width: 3),
            Text(
              '$coins',
              style: GoogleFonts.dancingScript(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.coin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timer Chip ────────────────────────────────────────────────────────────────

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final isLow = seconds <= 10;
    final color = isLow ? AppColors.incorrect : AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            '${seconds}s',
            style: GoogleFonts.dancingScript(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode Chip ─────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode});
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final (label, grad) = switch (mode) {
      GameMode.classic => ('∞  Classic', AppColors.primaryGrad),
      GameMode.timed => ('⏱  60 Seconds', AppColors.coinGrad),
      GameMode.speed => ('⚡  Speed Run', AppColors.greenGrad),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dancingScript(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Circle Button ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}

// ── Word Panel ────────────────────────────────────────────────────────────────

class _WordPanel extends StatelessWidget {
  const _WordPanel({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
  });
  final String word;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Text(
        word,
        style: GoogleFonts.dancingScript(
          fontSize: 72,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 4,
          shadows: [
            Shadow(color: color.withValues(alpha: 0.4), blurRadius: 14),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Color Button ──────────────────────────────────────────────────────────────

class _ColorBtn extends StatelessWidget {
  const _ColorBtn({
    required this.word,
    required this.color,
    required this.onTap,
  });
  final String word;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            word,
            style: GoogleFonts.dancingScript(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Game Over Dialog ──────────────────────────────────────────────────────────

class _GameOverDialog extends ConsumerWidget {
  const _GameOverDialog({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final acc = (state.accuracy * 100).toStringAsFixed(1);
    final coins = state.coinsEarnedThisSession;
    final canPlayAgain = StatsRepository.instance.canAffordGame(state.mode);

    // Breakdown lines
    final lines = <String>[];
    if (state.correct > 0)
      lines.add('+${state.correct * 2} (${state.correct} correct × 2🪙)');
    if (state.mode == GameMode.timed && state.timeLeftSeconds <= 0) {
      lines.add('+20 completion bonus 🎯');
    }
    if (state.startedWithZeroBalance && state.mode == GameMode.classic) {
      lines.add('+ recovery bonus (broke mode) 💪');
    }

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(
              'Game Over!',
              style: GoogleFonts.dancingScript(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ),
            const SizedBox(height: 6),

            // Coins earned badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.coin.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.coin.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppAssets.coin, height: 20),
                      const SizedBox(width: 6),
                      Text(
                        '+$coins coins earned!',
                        style: GoogleFonts.dancingScript(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.coin,
                        ),
                      ),
                    ],
                  ),
                  if (lines.isNotEmpty)
                    ...lines.map(
                      (l) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          l,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.coin.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Result tiles
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    'Score',
                    '${state.score}',
                    AppColors.primary,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile('Accuracy', '$acc%', AppColors.accent, isDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    'Correct',
                    '${state.correct}',
                    AppColors.coin,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    'Rounds',
                    '${state.total}',
                    AppColors.secondary,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Play Again
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canPlayAgain
                    ? () {
                        Navigator.of(context).pop();
                        if (state.mode != GameMode.classic) {
                          StatsRepository.instance.spendCoin(state.mode);
                        }
                        ref.read(gameProvider.notifier).startGame(state.mode);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  canPlayAgain
                      ? (state.mode == GameMode.classic
                            ? 'Play Again'
                            : 'Play Again (1 Coin)')
                      : 'Not enough coins',
                  style: GoogleFonts.dancingScript(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Home',
                      style: GoogleFonts.dancingScript(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    side: BorderSide(
                      color: AppColors.coin.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Image.asset(AppAssets.coin, height: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.color, this.isDark);
  final String label, value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dancingScript(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
