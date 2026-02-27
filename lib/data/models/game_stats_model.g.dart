// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_stats_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameStatsModelAdapter extends TypeAdapter<GameStatsModel> {
  @override
  final int typeId = 0;

  @override
  GameStatsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameStatsModel(
      bestScore: (fields[0] as int?) ?? 0,
      totalGamesPlayed: (fields[1] as int?) ?? 0,
      averageAccuracy: (fields[2] as double?) ?? 0.0,
      averageReactionMs: (fields[3] as double?) ?? 0.0,
      streakCount: (fields[4] as int?) ?? 0,
      lastPlayedDate: (fields[5] as String?) ?? '',
      recentScores: (fields[6] as List?)?.cast<int>(),
      coinBalance: (fields[7] as int?) ?? 0,
      playedDates: (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, GameStatsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.bestScore)
      ..writeByte(1)
      ..write(obj.totalGamesPlayed)
      ..writeByte(2)
      ..write(obj.averageAccuracy)
      ..writeByte(3)
      ..write(obj.averageReactionMs)
      ..writeByte(4)
      ..write(obj.streakCount)
      ..writeByte(5)
      ..write(obj.lastPlayedDate)
      ..writeByte(6)
      ..write(obj.recentScores)
      ..writeByte(7)
      ..write(obj.coinBalance)
      ..writeByte(8)
      ..write(obj.playedDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStatsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
