import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/transaction_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'sms_transactions';
  static const String _channelName = 'SMS Transactions';
  static const String _channelDescription =
      'Notifications for new SMS transactions';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Skip initialization on Windows platform
    if (Platform.isWindows) {
      _initialized = true;
      return;
    }

    // Ensure we're on a supported platform
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS && !Platform.isLinux) {
      _initialized = true;
      return;
    }

    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      macOS: const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      linux: const LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      ),
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the notification channel for Android
    await _createNotificationChannel();

    _initialized = true;
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showTransactionNotification(
    TransactionItem transaction,
  ) async {
    if (!_initialized) await initialize();

    // Skip showing notifications on Windows
    if (Platform.isWindows) {
      return;
    }

    final amount = transaction.amount.toStringAsFixed(2);
    final title = transaction.isDebit
        ? 'New Expense Detected'
        : 'New Credit Detected';
    final body = '₹$amount - ${transaction.category} (${transaction.source})';

    NotificationDetails? details;
    
    if (Platform.isAndroid) {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'New transaction',
      );
      details = NotificationDetails(android: androidDetails);
    } else if (Platform.isIOS) {
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      details = const NotificationDetails(iOS: iosDetails);
    } else if (Platform.isMacOS) {
      const macOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      details = const NotificationDetails(macOS: macOSDetails);
    } else if (Platform.isLinux) {
      const linuxDetails = LinuxNotificationDetails(
        actions: [
          LinuxNotificationAction(
            key: 'view',
            label: 'View Transaction',
          ),
        ],
        urgency: LinuxNotificationUrgency.normal,
      );
      details = const NotificationDetails(linux: linuxDetails);
    }

    // If we couldn't create platform-specific details, return
    if (details == null) return;

    await _notifications.show(
      transaction.hashCode, // Use hash as notification ID
      title,
      body,
      details,
      payload:
          '{"id":${transaction.id},"date":"${transaction.date.toIso8601String()}}',
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // This will be handled by the app to navigate to the transaction
    debugPrint('Notification tapped: ${response.payload}');
  }
}
