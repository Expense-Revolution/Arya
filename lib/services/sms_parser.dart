import '../models/transaction_item.dart';

class SmsParser {
  static TransactionItem? tryParse(String from, String body, DateTime date) {
    // Skip reminders, alerts and payment requests
    if (_isNonTransactionMessage(body)) {
      return null;
    }

    final amt = _extractAmount(body);
    if (amt == null) {
      return null;
    }
    final cat = _guessCategory(body);
    final isDebit = _isDebitTransaction(body.toLowerCase());
    return TransactionItem(
      source: from,
      amount: amt,
      category: cat,
      date: date,
      rawMessage: body,
      isDebit: isDebit,
    );
  }

  /// Identifies messages that aren't actual transactions (reminders, alerts, requests).
  static bool _isNonTransactionMessage(String text) {
    final s = text.toLowerCase();

    // Due date and reminder patterns
    if (s.contains(' due on ') ||
        s.contains(' is due ') ||
        s.contains(' will be due ') ||
        s.contains('reminder') ||
        s.contains('has requested money') ||
        s.contains('requested money from you')) {
      return true;
    }

    // Alert patterns (plan expiry, usage alerts etc)
    if (s.contains('alert!') ||
        s.contains('data exhausted') ||
        s.contains('data usage') ||
        s.contains('speed will') ||
        s.contains('recharge with')) {
      return true;
    }

    // Payment links and requests
    if (s.contains('click here to ') ||
        s.contains('click to ') ||
        s.contains('tap to ') ||
        s.contains('click : http')) {
      return true;
    }

    return false;
  }

  static double? _extractAmount(String text) {
    final cleaned = text.replaceAll('\u00A0', ' ');
    final patterns = [
      RegExp(
        r'(?:rs\.?|inr|₹|rs)\s?([0-9]+(?:[.,][0-9]{2,})?)',
        caseSensitive: false,
      ),
      RegExp(r'([0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]{1,2})?)'),
      RegExp(r'([0-9]+\.[0-9]{2})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(cleaned);
      if (m != null) {
        var s = m.group(1) ?? m.group(0)!;
        s = s.replaceAll(',', '');
        s = s.replaceAll('₹', '');
        s = s.replaceAll('Rs', '');
        s = s.replaceAll('INR', '');
        try {
          final val = double.parse(s);
          if (val > 0 && val < 100000000) return val;
        } catch (_) {}
      }
    }
    return null;
  }

  static String _guessCategory(String t) {
    final s = t.toLowerCase();
    if (s.contains('fuel') || s.contains('petrol') || s.contains('diesel')) {
      return 'Fuel';
    }
    if (s.contains('uber') ||
        s.contains('ola') ||
        s.contains('taxi') ||
        s.contains('ride')) {
      return 'Transport';
    }
    if (s.contains('amazon') ||
        s.contains('flipkart') ||
        s.contains('order') ||
        s.contains('txn')) {
      return 'Shopping';
    }
    if (s.contains('atm') || s.contains('withdraw')) {
      return 'Cash Withdrawal';
    }
    if (s.contains('grocery') ||
        s.contains('bigbasket') ||
        s.contains('dmart')) {
      return 'Groceries';
    }
    if (s.contains('upi') ||
        s.contains('google pay') ||
        s.contains('gpay') ||
        s.contains('phonepe') ||
        s.contains('paytm')) {
      return 'UPI';
    }
    return 'Uncategorized';
  }

  static bool _isDebitTransaction(String text) {
    final s = text.toLowerCase();

    // Credit card spends are debits
    if (s.contains('spent on your') && s.contains('credit card')) {
      return true;
    }

    // Clear credit indicators (money coming in)
    if (s.contains('credited to') ||
        s.contains('received in') ||
        s.contains('credit received') ||
        s.contains('salary credit') ||
        s.contains('refund credit') ||
        s.contains('cashback credited')) {
      return false;
    }

    // Clear debit indicators (money going out)
    if (s.contains('debited') ||
        s.contains('debited from') ||
        s.contains('debit from') ||
        s.contains('spent') ||
        s.contains('paid for') ||
        s.contains('payment made') ||
        s.contains('withdrawn') ||
        s.contains('purchase at')) {
      return true;
    }

    // Default to debit for ambiguous cases
    return true;
  }
}
