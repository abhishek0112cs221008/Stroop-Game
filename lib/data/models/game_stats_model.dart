import 'package:hive_flutter/hive_flutter.dart';

part 'game_stats_model.g.dart';

@HiveType(typeId: 0)
class GameStatsModel extends HiveObject {
  @HiveField(0)
  int bestScore;

  @HiveField(1)
  int totalGamesPlayed;

  @HiveField(2)
  double averageAccuracy;

  @HiveField(3)
  double averageReactionMs;

  @HiveField(4)
  int streakCount;

  @HiveField(5)
  String lastPlayedDate; // YYYY-MM-DD

  @HiveField(6)
  List<int> recentScores; // last 10

  /// Total coins earned (new in v2)
  @HiveField(7)
  int coinBalance;

  /// ISO date strings (YYYY-MM-DD) of every day the user played
  @HiveField(8)
  List<String> playedDates;

  GameStatsModel({
    this.bestScore = 0,
    this.totalGamesPlayed = 0,
    this.averageAccuracy = 0.0,
    this.averageReactionMs = 0.0,
    this.streakCount = 0,
    this.lastPlayedDate = '',
    List<int>? recentScores,
    this.coinBalance = 0,
    List<String>? playedDates,
  }) : recentScores = recentScores ?? [],
       playedDates = playedDates ?? [];
}
