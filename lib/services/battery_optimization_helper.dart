import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationHelper {
  static Future<bool> requestDisableBatteryOptimization() async {
    // Only applicable on Android
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    // Only applicable for Android 6.0 (API 23) and above
    if (deviceInfo.version.sdkInt < 23) {
      return true;
    }

    // Request ignore battery optimizations
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) {
      return true;
    }

    try {
      final result = await Permission.ignoreBatteryOptimizations.request();
      return result.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isBatteryOptimizationDisabled() async {
    // Only applicable on Android
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    // Only applicable for Android 6.0 (API 23) and above
    if (deviceInfo.version.sdkInt < 23) {
      return true;
    }

    return await Permission.ignoreBatteryOptimizations.status.isGranted;
  }
}
