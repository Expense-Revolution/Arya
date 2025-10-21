import 'package:hive/hive.dart';
import 'transaction_item.dart';

class TransactionItemHive {
  final int? id;
  final String source;
  final double amount;
  final String category;
  final DateTime date;
  final String rawMessage;
  final bool isDebit;

  TransactionItemHive({
    this.id,
    required this.source,
    required this.amount,
    required this.category,
    required this.date,
    required this.rawMessage,
    required this.isDebit,
  });

  factory TransactionItemHive.fromModel(TransactionItem m) =>
      TransactionItemHive(
        id: m.id,
        source: m.source,
        amount: m.amount,
        category: m.category,
        date: m.date,
        rawMessage: m.rawMessage,
        isDebit: m.isDebit,
      );

  TransactionItem toModel() => TransactionItem(
    id: id,
    source: source,
    amount: amount,
    category: category,
    date: date,
    rawMessage: rawMessage,
    isDebit: isDebit,
  );
}

class TransactionItemHiveAdapter extends TypeAdapter<TransactionItemHive> {
  @override
  final int typeId = 0;

  @override
  TransactionItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return TransactionItemHive(
      id: fields[0] as int?,
      source: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      date: fields[4] as DateTime,
      rawMessage: fields[5] as String,
      isDebit: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionItemHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.source)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.rawMessage)
      ..writeByte(6)
      ..write(obj.isDebit);
  }
}
