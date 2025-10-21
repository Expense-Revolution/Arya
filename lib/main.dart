// main.dart - entrypoint
import 'package:flutter/material.dart';
import 'package:sms_expense_tracker/screens/home_screen.dart';
import 'package:sms_expense_tracker/db/hive_helper.dart';
import 'package:sms_expense_tracker/services/background_service.dart';
import 'package:sms_expense_tracker/services/settings_manager.dart';
import 'package:sms_expense_tracker/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage, settings and notifications
  await HiveHelper.init();
  await SettingsManager.init();
  await NotificationService.initialize();

  // Start background service if enabled
  if (SettingsManager.isBackgroundServiceEnabled()) {
    await BackgroundSmsService.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}
