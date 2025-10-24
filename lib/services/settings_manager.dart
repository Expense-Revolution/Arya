import 'package:hive_ce_flutter/hive_flutter.dart';

class SettingsManager {
  static const String _settingsBoxName = 'app_settings';
  static const String _backgroundServiceKey = 'background_service_enabled';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_settingsBoxName);
    // Set default value if not set
    if (!_box!.containsKey(_backgroundServiceKey)) {
      await _box!.put(_backgroundServiceKey, true); // Enable by default
    }
  }

  static Future<void> setBackgroundServiceEnabled(bool enabled) async {
    await _box?.put(_backgroundServiceKey, enabled);
  }

  static bool isBackgroundServiceEnabled() {
    return _box?.get(_backgroundServiceKey, defaultValue: true) ?? true;
  }

  static Stream<BoxEvent> get settingsChanges =>
      _box?.watch() ?? Stream.empty();
}
