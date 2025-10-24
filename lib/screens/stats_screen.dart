import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:intl/intl.dart';
import '../db/hive_helper.dart';
// import '../models/transaction_item.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, double> _byCategory = {};
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await HiveHelper.getAllTransactions();
    final map = <String, double>{};
    double tot = 0;
    for (final t in all) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
      tot += t.amount;
    }
    setState(() {
      _byCategory = map;
      _total = tot;
    });
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    // Store context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all transaction data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    await HiveHelper.deleteAll();
    await _load(); // Reload the data
    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('All transaction data has been deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _byCategory.entries.map((e) {
      return PieChartSectionData(title: e.key, value: e.value, radius: 60);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export & share CSV',
            onPressed: () async {
              final scaffold = ScaffoldMessenger.of(context);
              scaffold.showSnackBar(
                const SnackBar(content: Text('Preparing export...')),
              );
              final path = await HiveHelper.exportTransactionsCsv();
              if (path == null) {
                scaffold.showSnackBar(
                  const SnackBar(content: Text('Failed to create export')),
                );
                return;
              }
              try {
                // shareXFiles is deprecated in newer versions; keep a short ignore to preserve behavior
                // ignore: deprecated_member_use
                await Share.shareXFiles([
                  XFile(path),
                ], text: 'Transactions export');
              } catch (e) {
                scaffold.showSnackBar(
                  const SnackBar(content: Text('Share failed')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Total: ₹ ${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (sections.isEmpty)
              const Text('No data to show')
            else
              SizedBox(
                height: 240,
                child: PieChart(PieChartData(sections: sections)),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: _byCategory.entries
                    .map(
                      (e) => ListTile(
                        title: Text(e.key),
                        trailing: Text('₹ ${e.value.toStringAsFixed(2)}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
