import 'dart:math';
import 'package:stroop_game/data/database/hive_database.dart';
import 'package:stroop_game/data/models/coin_transaction_model.dart';
import 'package:stroop_game/data/models/game_stats_model.dart';
import 'package:stroop_game/features/game/game_provider.dart';

// ── Coin configuration ────────────────────────────────────────────────────────

class CoinConfig {
  static const int welcomeBonus = 50;
  static const int perCorrect = 2; // classic & paid modes
  static const int paidEntryFee = 1; // cost per Timed / Speed game
  static const int timedCompletionBonus = 20; // for completing 60-sec fully
  static const int streakMilestone = 7; // every N-day streak
  static const int streakBonusCoins = 10;

  // Classic zero-balance recovery: 5 coins × minutes played × accuracy factor
  static const int zeroBalancePerMinute = 5;
}

// ── Repository ────────────────────────────────────────────────────────────────

class StatsRepository {
  StatsRepository._();
  static final StatsRepository instance = StatsRepository._();

  static const int _statsKey = 0;

  // ── Read ───────────────────────────────────────────────────────────────────

  GameStatsModel getStats() =>
      HiveDatabase.statsBox.get(_statsKey) ?? GameStatsModel();

  /// Returns transactions sorted newest-first (up to [limit]).
  List<CoinTransactionModel> getTransactions({int limit = 100}) {
    final box = HiveDatabase.transactionsBox;
    final all = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }

  // ── Welcome coins ──────────────────────────────────────────────────────────

  /// Award 50 welcome coins on first install (no games played, balance = 0).
  Future<void> ensureWelcomeCoins() async {
    final stats = getStats();
    if (stats.totalGamesPlayed == 0 && stats.coinBalance == 0) {
      stats.coinBalance = CoinConfig.welcomeBonus;
      await _save(stats);
      await _logTx(
        description: '🎉 Welcome Bonus',
        amount: CoinConfig.welcomeBonus,
        balance: stats.coinBalance,
      );
    }
  }

  // ── Economy helpers ────────────────────────────────────────────────────────

  /// Whether the user can start a game in [mode].
  /// Classic is always free; other modes require ≥ 1 coin.
  bool canAffordGame(GameMode mode) {
    if (mode == GameMode.classic) return true;
    return getStats().coinBalance >= CoinConfig.paidEntryFee;
  }

  /// Deduct the entry fee for a paid game mode. Returns the new balance.
  Future<int> spendCoin(GameMode mode) async {
    assert(mode != GameMode.classic, 'Classic is always free');
    final stats = getStats();
    stats.coinBalance = (stats.coinBalance - CoinConfig.paidEntryFee).clamp(
      0,
      999999,
    );
    await _save(stats);
    final label = switch (mode) {
      GameMode.timed => '60-Second Game',
      GameMode.speed => 'Speed Run',
      GameMode.classic => '',
    };
    await _logTx(
      description: '🎮 Played: $label',
      amount: -CoinConfig.paidEntryFee,
      balance: stats.coinBalance,
    );
    return stats.coinBalance;
  }

  // ── Award coins after a game ───────────────────────────────────────────────

  /// Compute and persist coins earned at game end.
  /// Returns the net coins earned (positive number).
  Future<int> awardCoins({
    required GameMode mode,
    required int score,
    required int correctCount,
    required double accuracy,
    required int durationSeconds,
    required bool isTimedComplete,
    required bool startedWithZeroBalance,
  }) async {
    final stats = getStats();
    int earned = 0;
    final breakdown = <String>[];

    // Base: 2 coins per correct answer (all modes)
    final perCorrectCoins = correctCount * CoinConfig.perCorrect;
    if (perCorrectCoins > 0) {
      earned += perCorrectCoins;
      breakdown.add('+$perCorrectCoins ($correctCount correct × 2)');
    }

    // Timed game completion bonus
    if (isTimedComplete) {
      earned += CoinConfig.timedCompletionBonus;
      breakdown.add('+${CoinConfig.timedCompletionBonus} completion bonus');
    }

    // Classic zero-balance recovery: 5 coins/min × score multiplier
    if (mode == GameMode.classic && startedWithZeroBalance) {
      final minutes = max(1, (durationSeconds / 60).ceil());
      final accFactor = accuracy.clamp(0.5, 1.5);
      final recovery = (minutes * CoinConfig.zeroBalancePerMinute * accFactor)
          .round()
          .clamp(3, 999);
      earned += recovery;
      breakdown.add('+$recovery recovery bonus (${minutes}min play)');
    }

    // Streak bonus every 7-day milestone
    final now = DateTime.now();
    final last = DateTime.tryParse(stats.lastPlayedDate);
    int newStreak = stats.streakCount;
    if (last == null) {
      newStreak = 1;
    } else {
      final diff = _daysBetween(last, now);
      if (diff == 0) {
        // same day
      } else if (diff == 1) {
        newStreak += 1;
      } else {
        newStreak = 1;
      }
    }
    if (newStreak > 0 &&
        newStreak % CoinConfig.streakMilestone == 0 &&
        newStreak != stats.streakCount) {
      earned += CoinConfig.streakBonusCoins;
      breakdown.add('+${CoinConfig.streakBonusCoins} streak bonus 🔥');
    }

    // Update stats
    final today = _dateStr(now);
    if (score > stats.bestScore) stats.bestScore = score;
    final prev = stats.totalGamesPlayed;
    stats.totalGamesPlayed = prev + 1;
    stats.averageAccuracy =
        ((stats.averageAccuracy * prev) + accuracy) / stats.totalGamesPlayed;
    stats.streakCount = newStreak;
    stats.lastPlayedDate = today;

    final dates = List<String>.from(stats.playedDates);
    if (!dates.contains(today)) dates.add(today);
    stats.playedDates = dates;

    final recent = List<int>.from(stats.recentScores)..add(score);
    if (recent.length > 10) recent.removeAt(0);
    stats.recentScores = recent;

    stats.coinBalance = (stats.coinBalance + earned).clamp(0, 999999);
    await _save(stats);

    if (earned > 0) {
      final desc = breakdown.join(', ');
      await _logTx(
        description: '🏆 Game reward: $desc',
        amount: earned,
        balance: stats.coinBalance,
      );
    }

    return earned;
  }

  // ── Stats reset ────────────────────────────────────────────────────────────

  Future<void> resetStats() async {
    await HiveDatabase.statsBox.delete(_statsKey);
    await HiveDatabase.transactionsBox.clear();
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _save(GameStatsModel model) =>
      HiveDatabase.statsBox.put(_statsKey, model);

  Future<void> _logTx({
    required String description,
    required int amount,
    required int balance,
  }) async {
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final tx = CoinTransactionModel(
      id: id,
      timestamp: DateTime.now().toIso8601String(),
      description: description,
      amount: amount,
      balance: balance,
    );
    await HiveDatabase.transactionsBox.put(id, tx);
  }

  String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  int _daysBetween(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return bDate.difference(aDate).inDays;
  }
}
