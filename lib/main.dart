// main.dart - entrypoint
import 'package:flutter/material.dart';
import 'package:koshik/screens/home_screen.dart';
import 'package:koshik/db/hive_helper.dart';
import 'package:koshik/services/background_service.dart';
import 'package:koshik/services/settings_manager.dart';
import 'package:koshik/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage, settings and notifications
  await HiveHelper.init(enableEncryption: true);
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
      title: 'Koshik: Smart Hisāb',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}
