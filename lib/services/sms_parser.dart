import '../models/transaction_item.dart';

class SmsParser {
  static TransactionItem? tryParse(String from, String body, DateTime date) {
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
    // Credit indicators
    if (s.contains('credited') ||
        s.contains('received') ||
        s.contains('credit') ||
        s.contains('salary') ||
        s.contains('refund') ||
        s.contains('cashback')) {
      return false;
    }
    // Debit indicators
    if (s.contains('debited') ||
        s.contains('debit') ||
        s.contains('spent') ||
        s.contains('paid') ||
        s.contains('withdrawn') ||
        s.contains('payment')) {
      return true;
    }
    // Default to debit for ambiguous cases
    return true;
  }
}
