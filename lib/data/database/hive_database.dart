import 'package:hive_flutter/hive_flutter.dart';
import 'package:stroop_game/data/models/coin_transaction_model.dart';
import 'package:stroop_game/data/models/game_stats_model.dart';

/// Handles Hive initialization and provides typed box access.
class HiveDatabase {
  HiveDatabase._();

  static const String _statsBox = 'stats_box';
  static const String _txBox = 'transactions_box';

  /// Call once from main() before runApp.
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(GameStatsModelAdapter());
    Hive.registerAdapter(CoinTransactionModelAdapter());
    await Hive.openBox<GameStatsModel>(_statsBox);
    await Hive.openBox<CoinTransactionModel>(_txBox);
  }

  static Box<GameStatsModel> get statsBox =>
      Hive.box<GameStatsModel>(_statsBox);

  static Box<CoinTransactionModel> get transactionsBox =>
      Hive.box<CoinTransactionModel>(_txBox);
}
