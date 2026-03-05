import 'package:flutter/foundation.dart';
import '../models/expense_prediction.dart';
import 'spending_analyzer.dart';

/// ExpensePredictor — statistical next-month expense forecast engine.
///
/// Uses weighted moving average across available months of history:
/// - Current month: 50% weight
/// - Last month: 30% weight
/// - Two months ago: 20% weight
/// Provides category-level breakdown predictions.
class ExpensePredictor {
  /// Generates a prediction for next month's expenses.
  ///
  /// [currentMonthTxns] — transactions from current month.
  /// [lastMonthTxns]    — transactions from last month.
  /// [twoMonthsAgoTxns] — transactions from 2 months ago (optional).
  static ExpensePrediction predict({
    required List<Map<String, dynamic>> currentMonthTxns,
    required List<Map<String, dynamic>> lastMonthTxns,
    List<Map<String, dynamic>> twoMonthsAgoTxns = const [],
  }) {
    try {
      final daysPassed = DateTime.now().day;
      final daysInMonth =
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

      // ── Step 1: Normalize current month to full-month equivalent ────
      final currentTotal = SpendingAnalyzer.totalDebit(currentMonthTxns);
      final normalizedCurrent = daysPassed > 3
          ? (currentTotal / daysPassed) * daysInMonth
          : currentTotal; // Don't extrapolate too early

      final lastTotal = SpendingAnalyzer.totalDebit(lastMonthTxns);
      final twoMonthsTotal = SpendingAnalyzer.totalDebit(twoMonthsAgoTxns);

      // ── Step 2: Weighted Average ────────────────────────────────────
      double predicted;
      double confidence;
      String methodology;

      if (twoMonthsTotal > 0 && lastTotal > 0) {
        // 3-month weighted average
        predicted =
            normalizedCurrent * 0.5 + lastTotal * 0.3 + twoMonthsTotal * 0.2;
        confidence = 0.85;
        methodology = 'Weighted 3-month average (50/30/20)';
      } else if (lastTotal > 0) {
        // 2-month weighted average
        predicted = normalizedCurrent * 0.6 + lastTotal * 0.4;
        confidence = 0.70;
        methodology = 'Weighted 2-month average (60/40)';
      } else if (currentTotal > 0 && daysPassed > 7) {
        // Single month extrapolation
        predicted = normalizedCurrent;
        confidence = 0.50;
        methodology = 'Single-month extrapolation';
      } else {
        return const ExpensePrediction(
          predictedTotal: 0,
          categoryBreakdown: {},
          confidence: 0,
          comparisonToCurrentMonth: 0,
          methodology:
              'Insufficient data — need at least 7 days of transactions.',
        );
      }

      // ── Step 3: Category Breakdown ──────────────────────────────────
      final currentCats = SpendingAnalyzer.groupByCategory(currentMonthTxns);
      final lastCats = SpendingAnalyzer.groupByCategory(lastMonthTxns);
      final twoMonthCats = SpendingAnalyzer.groupByCategory(twoMonthsAgoTxns);

      final allCategories = <String>{
        ...currentCats.keys,
        ...lastCats.keys,
        ...twoMonthCats.keys,
      };

      final Map<String, double> categoryPrediction = {};
      for (final cat in allCategories) {
        final currentCat = currentCats[cat] ?? 0;
        final normalizedCurrentCat = daysPassed > 3
            ? (currentCat / daysPassed) * daysInMonth
            : currentCat;
        final lastCat = lastCats[cat] ?? 0;
        final twoMonthCat = twoMonthCats[cat] ?? 0;

        if (twoMonthCat > 0 && lastCat > 0) {
          categoryPrediction[cat] =
              normalizedCurrentCat * 0.5 + lastCat * 0.3 + twoMonthCat * 0.2;
        } else if (lastCat > 0) {
          categoryPrediction[cat] = normalizedCurrentCat * 0.6 + lastCat * 0.4;
        } else {
          categoryPrediction[cat] = normalizedCurrentCat;
        }
      }

      // ── Step 4: Comparison ──────────────────────────────────────────
      final comparison = normalizedCurrent > 0
          ? ((predicted - normalizedCurrent) / normalizedCurrent) * 100
          : 0.0;

      return ExpensePrediction(
        predictedTotal: predicted,
        categoryBreakdown: categoryPrediction,
        confidence: confidence,
        comparisonToCurrentMonth: comparison,
        methodology: methodology,
      );
    } catch (e) {
      debugPrint('ExpensePredictor error: $e');
      return const ExpensePrediction(
        predictedTotal: 0,
        categoryBreakdown: {},
        confidence: 0,
        comparisonToCurrentMonth: 0,
        methodology: 'Prediction failed — calculation error.',
      );
    }
  }
}
