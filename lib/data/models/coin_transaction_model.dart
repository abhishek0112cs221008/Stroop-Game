import 'package:hive_flutter/hive_flutter.dart';

/// Represents a single coin credit or debit event.
@HiveType(typeId: 1)
class CoinTransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String timestamp; // ISO-8601

  @HiveField(2)
  String description;

  /// Positive = earned, negative = spent.
  @HiveField(3)
  int amount;

  /// Coin balance AFTER this transaction.
  @HiveField(4)
  int balance;

  CoinTransactionModel({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.amount,
    required this.balance,
  });
}

// ── Hand-written adapter (no build_runner needed) ─────────────────────────────

class CoinTransactionModelAdapter extends TypeAdapter<CoinTransactionModel> {
  @override
  final int typeId = 1;

  @override
  CoinTransactionModel read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return CoinTransactionModel(
      id: fields[0] as String,
      timestamp: fields[1] as String,
      description: fields[2] as String,
      amount: fields[3] as int,
      balance: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CoinTransactionModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.balance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoinTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
