import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/hive_helper.dart';
import '../models/transaction_item.dart';
import '../services/sms_service.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'dart:async';
// import 'package:share_plus/share_plus.dart'; // optional - user can add if needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmsService _smsService = SmsService();
  List<TransactionItem> _transactions = [];
  DateTime _shownMonth = DateTime.now();
  final StreamController<void> _refreshCtrl = StreamController.broadcast();
  StreamSubscription<TransactionItem>? _smsSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Start SMS service and subscribe to parsed transactions
    _smsService.startListening();
    _smsSub = _smsService.onTransaction.listen((t) {
      // insert into current list in-memory for immediate UI update
      setState(() {
        _transactions.insert(0, t);
      });
      _refreshCtrl.add(null);
    });
  }

  Future<void> _load() async {
    final all = await HiveHelper.getAllTransactions();
    setState(() {
      _transactions = all;
    });
    _refreshCtrl.add(null);
  }

  double get _monthTotal {
    final items = _transactions.where(
      (t) =>
          t.date.year == _shownMonth.year && t.date.month == _shownMonth.month,
    );
    return items.fold(0.0, (p, e) => p + (e.isDebit ? -e.amount : e.amount));
  }

  List<TransactionItem> get _shownTransactions {
    return _transactions
        .where(
          (t) =>
              t.date.year == _shownMonth.year &&
              t.date.month == _shownMonth.month,
        )
        .toList();
  }

  void _prevMonth() {
    setState(() {
      _shownMonth = DateTime(_shownMonth.year, _shownMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _shownMonth = DateTime(_shownMonth.year, _shownMonth.month + 1, 1);
    });
  }

  Future<void> _addManual() async {
    final sourceC = TextEditingController();
    final amountC = TextEditingController();
    final categoryC = TextEditingController();
    DateTime chosen = DateTime.now();

    final res = await showDialog<TransactionItem?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add transaction'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: sourceC,
                  decoration: const InputDecoration(labelText: 'Source'),
                ),
                TextField(
                  controller: amountC,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: categoryC,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final dt = await showDatePicker(
                      context: ctx,
                      initialDate: chosen,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (dt != null) chosen = dt;
                  },
                  child: const Text('Pick date'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final a = double.tryParse(amountC.text) ?? 0.0;
                final t = TransactionItem(
                  source: sourceC.text.isEmpty ? 'manual' : sourceC.text,
                  amount: a,
                  category: categoryC.text.isEmpty
                      ? 'Uncategorized'
                      : categoryC.text,
                  date: chosen,
                  rawMessage: 'manual',
                  isDebit: true, // Manual transactions default to debit
                );
                Navigator.of(ctx).pop(t);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (res != null) {
      await HiveHelper.insertTransaction(res);
      _load();
    }
  }

  @override
  void dispose() {
    _refreshCtrl.close();
    _smsSub?.cancel();
    _smsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM().format(_shownMonth);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Expense Tracker'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
            },
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    onClear: () async {
                      await HiveHelper.deleteAll();
                      await _load();
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Total: ₹ ${_monthTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _shownTransactions.isEmpty
                ? Center(child: Text('No transactions for $monthLabel'))
                : ListView.builder(
                    itemCount: _shownTransactions.length,
                    itemBuilder: (context, idx) {
                      final t = _shownTransactions[idx];
                      return ListTile(
                        leading: Icon(
                          t.isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: t.isDebit ? Colors.red : Colors.green,
                        ),
                        title: Text('${t.source} • ${t.category}'),
                        subtitle: Text(
                          '${DateFormat.yMMMd().add_jm().format(t.date)}\n${t.rawMessage}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '₹ ${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: t.isDebit ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          if (!mounted) return;
                          final categoryC = TextEditingController(
                            text: t.category,
                          );
                          final messenger = ScaffoldMessenger.of(context);
                          final newCategory = await showDialog<String?>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Edit transaction'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Source: ${t.source}'),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Amount: ₹ ${t.amount.toStringAsFixed(2)}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Date: ${DateFormat.yMMMd().add_jm().format(t.date)}',
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: categoryC,
                                        decoration: const InputDecoration(
                                          labelText: 'Category',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Message:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(t.rawMessage),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(null),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop(
                                        categoryC.text.isEmpty
                                            ? 'Uncategorized'
                                            : categoryC.text,
                                      );
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (newCategory != null) {
                            // Update DB outside of dialog context
                            final updated = TransactionItem(
                              id: t.id,
                              source: t.source,
                              amount: t.amount,
                              category: newCategory,
                              date: t.date,
                              rawMessage: t.rawMessage,
                              isDebit: t.isDebit,
                            );
                            await HiveHelper.updateTransaction(updated);
                            if (!mounted) return;
                            await _load();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Transaction updated'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scan inbox FAB (mini)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.small(
              heroTag: 'scan_sms',
              onPressed: () async {
                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                final added = await _smsService.scanInbox();
                if (added > 0) {
                  // reload from DB to ensure ordering
                  if (!mounted) return;
                  await _load();
                }
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Scan finished, $added new transactions added',
                    ),
                  ),
                );
              },
              tooltip: 'Scan SMS inbox',
              child: const Icon(Icons.refresh),
            ),
          ),
          FloatingActionButton(
            onPressed: _addManual,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
