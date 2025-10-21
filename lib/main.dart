// main.dart - entrypoint
import 'package:flutter/material.dart';
import 'package:arya/screens/home_screen.dart';
import 'package:arya/db/hive_helper.dart';
import 'package:arya/services/background_service.dart';
import 'package:arya/services/settings_manager.dart';
import 'package:arya/services/notification_service.dart';

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
