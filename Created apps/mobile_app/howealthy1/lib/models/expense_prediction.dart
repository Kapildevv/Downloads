/// Data model for expense predictions.
class ExpensePrediction {
  /// Total predicted expense for next month.
  final double predictedTotal;

  /// Per-category breakdown: {categoryName: predictedAmount}.
  final Map<String, double> categoryBreakdown;

  /// Confidence level (0.0 to 1.0).
  final double confidence;

  /// How this compares to current month actual (percentage change).
  final double comparisonToCurrentMonth;

  /// Human-readable methodology description.
  final String methodology;

  const ExpensePrediction({
    required this.predictedTotal,
    required this.categoryBreakdown,
    required this.confidence,
    required this.comparisonToCurrentMonth,
    required this.methodology,
  });
}
