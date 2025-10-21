import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../db/hive_helper.dart';
import '../models/transaction_item.dart';
import 'sms_parser.dart';

// Best-effort SMS service for handling incoming messages
class SmsService {
  final Telephony telephony = Telephony.instance;
  StreamController<TransactionItem>? _ctrl;
  bool _listening = false;

  Stream<TransactionItem> get onTransaction =>
      (_ctrl ??= StreamController<TransactionItem>.broadcast()).stream;

  Future<bool> requestPermissions() async {
    final smsStatus = await Permission.sms.request();
    return smsStatus.isGranted;
  }

  /// Start listening to incoming SMS and emit parsed TransactionItem on [onTransaction].
  /// Also reads the inbox once (best-effort) to pick up historical messages.
  Future<void> startListening() async {
    if (_listening) return;
    final granted = await requestPermissions();
    if (!granted) return;
    _listening = true;

    // Listen incoming
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage msg) async {
        if (msg.body != null) {
          final parsed = SmsParser.tryParse(
            msg.address ?? 'unknown',
            msg.body!,
            DateTime.now(),
          );
          if (parsed != null) {
            await HiveHelper.insertTransaction(parsed);
            _ctrl?.add(parsed);
          }
        }
      },
      onBackgroundMessage: null,
    );

    // Read inbox once (may throw on some devices)
    try {
      final inbox = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );
      for (final sms in inbox) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          sms.date ?? DateTime.now().millisecondsSinceEpoch,
        );
        if (sms.body != null) {
          final parsed = SmsParser.tryParse(
            sms.address ?? 'unknown',
            sms.body!,
            date,
          );
          if (parsed != null) {
            await HiveHelper.insertTransaction(parsed);
            _ctrl?.add(parsed);
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  /// Scans the entire SMS inbox once, inserts parsed transactions and emits them.
  /// Returns the number of newly added transactions.
  Future<int> scanInbox() async {
    final granted = await requestPermissions();
    if (!granted) return 0;
    int added = 0;
    try {
      final inbox = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );

      // Load existing transactions for a simple dedupe check
      final existing = await HiveHelper.getAllTransactions();

      for (final sms in inbox) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          sms.date ?? DateTime.now().millisecondsSinceEpoch,
        );
        if (sms.body != null) {
          final parsed = SmsParser.tryParse(
            sms.address ?? 'unknown',
            sms.body!,
            date,
          );
          if (parsed != null) {
            final isDup = existing.any(
              (e) =>
                  e.rawMessage == parsed.rawMessage &&
                  e.date == parsed.date &&
                  e.amount == parsed.amount &&
                  e.source == parsed.source,
            );
            if (!isDup) {
              await HiveHelper.insertTransaction(parsed);
              _ctrl?.add(parsed);
              existing.add(parsed);
              added++;
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }
    return added;
  }

  /// Stop listening and close stream controller
  Future<void> stop() async {
    _listening = false;
    await _ctrl?.close();
    _ctrl = null;
  }
}
