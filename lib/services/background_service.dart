import 'dart:async';
import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import '../db/hive_helper.dart';
import 'sms_parser.dart';
import 'settings_manager.dart';
import 'notification_service.dart';

class BackgroundSmsService {
  static const _tag = "BackgroundSmsService";
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await HiveHelper.init();

    // Initialize settings
    await SettingsManager.init();
    if (!SettingsManager.isBackgroundServiceEnabled()) {
      debugPrint('$_tag: Background service disabled in settings');
      return;
    }

    final telephony = Telephony.instance;
    final granted = await telephony.requestSmsPermissions ?? false;
    if (!granted) {
      debugPrint('$_tag: SMS permissions not granted');
      return;
    }

    // Register background handler
    telephony.listenIncomingSms(
      onNewMessage: _handleNewSms,
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }

  static Future<void> _handleNewSms(SmsMessage message) async {
    if (message.body == null) return;

    final transaction = SmsParser.tryParse(
      message.address ?? 'unknown',
      message.body!,
      DateTime.now(),
    );

    if (transaction != null) {
      try {
        await HiveHelper.insertTransaction(transaction);
        await NotificationService.showTransactionNotification(transaction);
        debugPrint('$_tag: Successfully processed SMS and saved transaction');
      } catch (e) {
        debugPrint('$_tag: Error saving transaction: $e');
      }
    }
  }
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  // This handler runs in a background isolate
  await HiveHelper.init(); // Initialize Hive in this isolate

  if (message.body == null) return;

  final transaction = SmsParser.tryParse(
    message.address ?? 'unknown',
    message.body!,
    DateTime.now(),
  );

  if (transaction != null) {
    try {
      await HiveHelper.insertTransaction(transaction);
      debugPrint(
        'BackgroundMessageHandler: Successfully processed SMS and saved transaction',
      );
    } catch (e) {
      debugPrint('BackgroundMessageHandler: Error saving transaction: $e');
    }
  }
}
