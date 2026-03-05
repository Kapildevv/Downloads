/// Data model for a parsed expense from natural language input.
class ParsedExpense {
  /// Extracted amount in INR.
  final double amount;

  /// Inferred category (e.g., "Food & Dining").
  final String category;

  /// User's original description or extracted merchant name.
  final String description;

  /// Date (defaults to now if not specified in input).
  final DateTime date;

  /// Confidence of the parse (0.0 to 1.0).
  final double confidence;

  /// Source of this entry: 'text', 'voice', or 'manual'.
  final String source;

  const ParsedExpense({
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.confidence,
    required this.source,
  });

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'amount': amount,
      'category': category,
      'type': 'Debit',
      'body': description,
      'date': date.toString(),
      'fingerprint':
          '${amount}_${date.millisecondsSinceEpoch ~/ (1000 * 60 * 5)}',
      'source': source,
    };
  }
}
