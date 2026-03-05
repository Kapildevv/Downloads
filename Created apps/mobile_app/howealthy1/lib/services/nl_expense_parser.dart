import 'package:flutter/foundation.dart';
import '../models/parsed_expense.dart';
import 'ml_classifier_service.dart';

/// NlExpenseParser — Natural language expense entry parser.
///
/// Dual-mode parser:
/// 1. Fast regex mode (offline) — handles common Indian expense patterns
/// 2. Gemini-enhanced mode (online) — for ambiguous inputs
///
/// Supports English and Hinglish (Hindi-English) patterns common in India.
class NlExpenseParser {
  // ─── Common patterns (case-insensitive) ──────────────────
  // "spent 500 on food", "paid 1200 for uber", "₹300 chai",
  // "biryani 250", "200 ka coffee", "rent 15000",
  // "zomato se 450 ka order", "300 rs auto"

  /// Amount extraction patterns.
  static final _amountPatterns = [
    // "₹500", "Rs 500", "INR 500", "Rs.500"
    RegExp(r'(?:₹|rs\.?|inr)\s?(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)',
        caseSensitive: false),
    // "500 rupees", "500 rs", "500 ka"
    RegExp(r'(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)\s*(?:rupees?|rs\.?|ka|ki|ke)',
        caseSensitive: false),
    // "spent/paid 500"
    RegExp(
        r'(?:spent|paid|kharcha?|kharch|diya|diye)\s+(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)',
        caseSensitive: false),
    // Standalone number with context (e.g., "biryani 250")
    RegExp(r'(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)$', caseSensitive: false),
    // Number at start (e.g., "250 for food")
    RegExp(r'^(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)\s+(?:for|on|at)',
        caseSensitive: false),
  ];

  /// Parses a natural language string into a structured expense.
  ///
  /// Returns null if unable to extract a valid amount.
  static ParsedExpense? parse(String input, {String source = 'text'}) {
    try {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return null;

      // Step 1: Extract amount
      final amount = _extractAmount(trimmed);
      if (amount == null || amount <= 0) return null;

      // Step 2: Extract description (remove amount-related tokens)
      final description = _extractDescription(trimmed);

      // Step 3: Classify category using MlClassifierService regex
      final category =
          MlClassifierService.classifyByRegex(trimmed.toLowerCase());

      // Step 4: Confidence based on how clearly the input matched
      final confidence = _calculateConfidence(trimmed, amount, category);

      return ParsedExpense(
        amount: amount,
        category: category,
        description: description,
        date: DateTime.now(),
        confidence: confidence,
        source: source,
      );
    } catch (e) {
      debugPrint('NlExpenseParser error: $e');
      return null;
    }
  }

  /// Extracts the monetary amount from input text.
  static double? _extractAmount(String input) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final rawAmount = match.group(1)!.replaceAll(',', '');
        return double.tryParse(rawAmount);
      }
    }

    // Last resort: find any number >= 5 and <= 10,00,000
    final anyNumber = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(input);
    if (anyNumber != null) {
      final val = double.tryParse(anyNumber.group(1)!);
      if (val != null && val >= 5 && val <= 1000000) {
        return val;
      }
    }

    return null;
  }

  /// Extracts a clean description from the input text.
  static String _extractDescription(String input) {
    // Remove amount-related tokens
    var description = input
        .replaceAll(RegExp(r'₹\s?\d+[\d,]*(?:\.\d+)?'), '')
        .replaceAll(
            RegExp(r'\d+[\d,]*(?:\.\d+)?\s*(?:rupees?|rs\.?|inr)',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'(?:spent|paid|kharcha?|kharch|diya|diye)\s+\d+',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'\b(?:on|for|at|ka|ki|ke|se|me|mein)\b',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (description.isEmpty) {
      description = input.replaceAll(RegExp(r'\d+[\d,]*(?:\.\d+)?'), '').trim();
    }

    return description.isEmpty ? 'Manual expense' : description;
  }

  /// Calculates parse confidence (0.0–1.0).
  static double _calculateConfidence(
      String input, double amount, String category) {
    double conf = 0.5; // Base confidence

    // Amount explicitly marked with currency symbol
    if (RegExp(r'[₹]|rs\.?|inr', caseSensitive: false).hasMatch(input)) {
      conf += 0.2;
    }

    // Category was successfully identified (not "Uncategorized")
    if (category != 'Uncategorized') {
      conf += 0.2;
    }

    // Input has action words (spent, paid, etc.)
    if (RegExp(r'spent|paid|bought|ordered|kharcha?', caseSensitive: false)
        .hasMatch(input)) {
      conf += 0.1;
    }

    return conf.clamp(0.0, 1.0);
  }
}
