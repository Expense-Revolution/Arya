import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_item.dart';
import '../models/transaction_item_adapter.dart';

class HiveHelper {
  static const _boxName = 'transactions_box';
  static const _encryptionKeyStorageKey = 'hive_master_key';
  static final _secureStorage = const FlutterSecureStorage();

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionItemHiveAdapter());
    }
    // ensure encryption key exists
    final key = await _getOrCreateKey();
    await Hive.openBox<TransactionItemHive>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }

  static Future<List<TransactionItem>> getAllTransactions() async {
    final box = Hive.box<TransactionItemHive>(_boxName);
    final items = box.values.map((h) => h.toModel()).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static Future<int> insertTransaction(TransactionItem t) async {
    final box = Hive.box<TransactionItemHive>(_boxName);
    final hive = TransactionItemHive.fromModel(t);
    final key = await box.add(hive);
    // Hive auto-assigns numeric keys; use key as id
    final updated = TransactionItem(
      id: key,
      source: t.source,
      amount: t.amount,
      category: t.category,
      date: t.date,
      rawMessage: t.rawMessage,
      isDebit: t.isDebit,
    );
    await box.put(key, TransactionItemHive.fromModel(updated));
    return key;
  }

  static Future<void> deleteAll() async {
    final box = Hive.box<TransactionItemHive>(_boxName);
    await box.clear();
  }

  static Future<int> updateTransaction(TransactionItem t) async {
    if (t.id == null) return 0;
    final box = Hive.box<TransactionItemHive>(_boxName);
    if (!box.containsKey(t.id)) return 0;
    await box.put(t.id, TransactionItemHive.fromModel(t));
    return 1;
  }

  static Future<List<TransactionItem>> queryByCategory(String category) async {
    final all = await getAllTransactions();
    return all.where((t) => t.category == category).toList();
  }

  static Future<List<int>> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _encryptionKeyStorageKey);
    if (existing != null) {
      final bytes = base64Url.decode(existing);
      return bytes;
    }
    final newKey = Hive.generateSecureKey();
    await _secureStorage.write(
      key: _encryptionKeyStorageKey,
      value: base64Url.encode(newKey),
    );
    return newKey;
  }
}
