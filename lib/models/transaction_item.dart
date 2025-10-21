class TransactionItem {
  final int? id;
  final String source;
  final double amount;
  final String category;
  final DateTime date;
  final String rawMessage;
  final bool isDebit;

  TransactionItem({
    this.id,
    required this.source,
    required this.amount,
    required this.category,
    required this.date,
    required this.rawMessage,
    required this.isDebit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'rawMessage': rawMessage,
      'isDebit': isDebit ? 1 : 0,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> m) {
    return TransactionItem(
      id: m['id'] as int?,
      source: m['source'] as String,
      amount: (m['amount'] as num).toDouble(),
      category: m['category'] as String,
      date: DateTime.parse(m['date'] as String),
      rawMessage: m['rawMessage'] as String,
      isDebit:
          (m['isDebit'] as int? ?? 1) == 1, // default to debit for old records
    );
  }
}
