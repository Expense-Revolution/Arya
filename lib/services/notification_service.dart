import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
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

    final amount = transaction.amount.toStringAsFixed(2);
    final title = transaction.isDebit
        ? 'New Expense Detected'
        : 'New Credit Detected';
    final body = '₹$amount - ${transaction.category} (${transaction.source})';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New transaction',
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
