import 'package:flutter/material.dart';
import '../services/settings_manager.dart';
import '../services/background_service.dart';
import '../services/battery_optimization_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onClear;
  const SettingsScreen({super.key, required this.onClear});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backgroundServiceEnabled = true;
  bool _isBatteryOptDisabled = false;

  @override
  void initState() {
    super.initState();
    _backgroundServiceEnabled = SettingsManager.isBackgroundServiceEnabled();
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    final isDisabled =
        await BatteryOptimizationHelper.isBatteryOptimizationDisabled();
    if (mounted) {
      setState(() {
        _isBatteryOptDisabled = isDisabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_backgroundServiceEnabled)
              ListTile(
                title: const Text('Battery Optimization'),
                subtitle: Text(
                  _isBatteryOptDisabled
                      ? 'Optimization disabled - background service will work reliably'
                      : 'Enable to ensure reliable background service',
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    // Store context before async gap
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final disabled =
                        await BatteryOptimizationHelper.requestDisableBatteryOptimization();
                    if (!mounted) return;

                    setState(() {
                      _isBatteryOptDisabled = disabled;
                    });
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          disabled
                              ? 'Battery optimization disabled'
                              : 'Battery optimization still enabled',
                        ),
                      ),
                    );
                  },
                  child: const Text('Disable'),
                ),
              ),
            SwitchListTile(
              title: const Text('Background SMS Processing'),
              subtitle: const Text(
                'Automatically process SMS messages even when app is closed',
              ),
              value: _backgroundServiceEnabled,
              onChanged: (value) async {
                // Store context before async gap
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                await SettingsManager.setBackgroundServiceEnabled(value);
                if (!mounted) return;

                setState(() {
                  _backgroundServiceEnabled = value;
                });
                if (value) {
                  await BackgroundSmsService.initialize();
                }
                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Background service enabled'
                          : 'Background service disabled',
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ElevatedButton.icon(
              onPressed: () async {
                // Store context before async gap
                final navigator = Navigator.of(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all data?'),
                    content: const Text(
                      'This will permanently delete all local transactions.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (!mounted) return;

                if (ok == true) {
                  widget.onClear();
                  navigator.pop();
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('Clear local data'),
            ),
            const SizedBox(height: 12),
            const Text('Privacy: Data stored locally only.'),
          ],
        ),
      ),
    );
  }
}
