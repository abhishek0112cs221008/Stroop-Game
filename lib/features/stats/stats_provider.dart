import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stroop_game/data/models/game_stats_model.dart';
import 'package:stroop_game/data/repositories/stats_repository.dart';

/// Exposes the current GameStatsModel to the UI.
/// Invalidated whenever a game ends and stats are updated.
final statsProvider = FutureProvider<GameStatsModel>((ref) async {
  return StatsRepository.instance.getStats();
});

/// Call this after a game ends to force a refresh.
void refreshStats(WidgetRef ref) {
  ref.invalidate(statsProvider);
}
