import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/transaction_item.dart';
import '../models/transaction_item_adapter.dart';

class HiveHelper {
  static const _boxName = 'transactions_box';
  static const _encryptionKeyStorageKey = 'hive_master_key';
  static final _secureStorage = const FlutterSecureStorage();

  static Future<void> init({bool enableEncryption = true}) async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionItemHiveAdapter());
    }

    final key = enableEncryption ? await _getOrCreateKey() : null;

    // Check if unencrypted box exists
    final boxExists = await Hive.boxExists(_boxName);

    if (enableEncryption && boxExists) {
      // Try opening with encryption first
      try {
        await Hive.openBox<TransactionItemHive>(
          _boxName,
          encryptionCipher: HiveAesCipher(key!),
        );
        return; // success
      } catch (_) {
        // Migration needed: box exists unencrypted
        final unencryptedBox = await Hive.openBox<TransactionItemHive>(
          _boxName,
        );
        final items = unencryptedBox.values.toList();
        await unencryptedBox.close();
        await Hive.deleteBoxFromDisk(_boxName);

        final encryptedBox = await Hive.openBox<TransactionItemHive>(
          _boxName,
          encryptionCipher: HiveAesCipher(key!),
        );

        // Re-insert old items
        for (var item in items) {
          await encryptedBox.add(item);
        }
        await encryptedBox.close();
        print("✅ Migrated unencrypted data to encrypted box.");
      }
    }

    // Normal open
    await Hive.openBox<TransactionItemHive>(
      _boxName,
      encryptionCipher: enableEncryption && key != null
          ? HiveAesCipher(key)
          : null,
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

  /// Export all transactions as CSV and return the file path.
  /// Columns: id,source,amount,category,date_iso,rawMessage,isDebit
  static Future<String?> exportTransactionsCsv() async {
    try {
      final items = await getAllTransactions();
      final buffer = StringBuffer();
      buffer.writeln('id,source,amount,category,date,rawMessage,isDebit');
      for (final t in items) {
        // Escape double quotes and wrap fields that may contain commas or quotes
        String esc(String s) => '"${s.replaceAll('"', '""')}"';
        final id = t.id?.toString() ?? '';
        final source = esc(t.source);
        final amount = t.amount.toStringAsFixed(2);
        final category = esc(t.category);
        final date = esc(t.date.toIso8601String());
        final raw = esc(t.rawMessage);
        final isDebit = t.isDebit ? '1' : '0';
        buffer.writeln('$id,$source,$amount,$category,$date,$raw,$isDebit');
      }

      final tmp = await getTemporaryDirectory();
      final filename =
          'transactions_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
      final filePath = p.join(tmp.path, filename);
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      return filePath;
    } catch (e) {
      return null;
    }
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
    try {
      final existing = await _secureStorage.read(key: _encryptionKeyStorageKey);
      if (existing != null && existing.isNotEmpty) {
        final bytes = base64Url.decode(existing);
        if (bytes.length == 32) {
          return bytes; // valid key
        } else {
          // print("⚠️ Hive key length invalid, regenerating...");
        }
      } else {
        // print("⚠️ No existing Hive key found, creating new...");
      }
    } catch (e) {
      // print("⚠️ Failed to read Hive key: $e, regenerating...");
    }

    // Generate a new secure key
    final newKey = Hive.generateSecureKey(); // always 32 bytes
    await _secureStorage.write(
      key: _encryptionKeyStorageKey,
      value: base64Url.encode(newKey),
    );
    return newKey;
  }
}
