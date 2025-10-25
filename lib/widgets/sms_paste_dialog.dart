import 'package:flutter/material.dart';
import '../services/sms_parser.dart';
import '../models/transaction_item.dart';

class SmsPasteDialog extends StatefulWidget {
  final Function(TransactionItem) onTransactionParsed;

  const SmsPasteDialog({
    super.key,
    required this.onTransactionParsed,
  });

  @override
  State<SmsPasteDialog> createState() => _SmsPasteDialogState();
}

class _SmsPasteDialogState extends State<SmsPasteDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isProcessing = false;

  void _parseSms() async {
    final smsText = _controller.text.trim();
    if (smsText.isEmpty) {
      setState(() {
        _errorText = 'Please paste an SMS message';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    try {
      // Parse the SMS using current date since it's a manual entry
      final transaction = SmsParser.tryParse('Manual Entry', smsText, DateTime.now());
      if (transaction != null) {
        widget.onTransactionParsed(transaction);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorText = 'Could not parse transaction from this SMS';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Error parsing SMS: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste SMS'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Paste your transaction SMS here',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _parseSms(),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _parseSms,
          child: const Text('Parse'),
        ),
      ],
    );
  }
}