/// AnalyticsEngine — Pure-Dart algorithms for consumer-facing financial visualizations.
///
/// All methods are static, stateless, and side-effect-free. They transform
/// raw Firestore transaction maps into structured data models that UI widgets
/// can render directly.
library;

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

/// A single data point representing one category's total spend in a given month.
class MonthlyDataPoint {
  final int year;
  final int month;
  final double total;

  const MonthlyDataPoint({
    required this.year,
    required this.month,
    required this.total,
  });

  /// Label used on the x-axis, e.g. "Jan", "Feb".
  String get label => _monthNames[month - 1];
  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

/// Type of segment in the cash flow waterfall chart.
enum SegmentType { income, expense, balance }

/// One bar in the waterfall chart.
class WaterfallSegment {
  final String label;
  final double value;
  final double runningTotal;
  final SegmentType segmentType;

  const WaterfallSegment({
    required this.label,
    required this.value,
    required this.runningTotal,
    required this.segmentType,
  });
}

/// Anonymized benchmark data for a spending category.
class PeerBenchmark {
  final String category;

  /// Median monthly spend (₹) for urban India, age 25-35.
  final double median;

  const PeerBenchmark({required this.category, required this.median});
}

/// Result of comparing a user's spend against peer benchmarks.
class PeerComparisonResult {
  final String category;
  final double userSpend;
  final double peerMedian;
  final double percentile;
  final String verdict;

  const PeerComparisonResult({
    required this.category,
    required this.userSpend,
    required this.peerMedian,
    required this.percentile,
    required this.verdict,
  });
}

// ---------------------------------------------------------------------------
// ANALYTICS ENGINE
// ---------------------------------------------------------------------------

class AnalyticsEngine {
  // -------------------------------------------------------------------------
  // 1. SPENDING HEATMAP
  // -------------------------------------------------------------------------

  /// Computes a spending heatmap for the current month.
  ///
  /// Returns a map of `{weekOfMonth (1-5): {dayOfWeek (1=Mon..7=Sun): totalSpend}}`.
  /// A parallel `maxCellValue` is returned for normalizing color intensities.
  static ({Map<int, Map<int, double>> grid, double maxCellValue})
      computeSpendingHeatmap(List<Map<String, dynamic>> transactions) {
    final Map<int, Map<int, double>> grid = {};
    double maxCell = 0;

    final now = DateTime.now();

    for (final txn in transactions) {
      try {
        if (txn['type'] != 'Debit') continue;

        final date = DateTime.parse(txn['date'] as String);
        // Only include current month
        if (date.year != now.year || date.month != now.month) continue;

        final amount = (txn['amount'] as num).toDouble();
        final dayOfWeek = date.weekday; // 1 = Monday .. 7 = Sunday
        final weekOfMonth = ((date.day - 1) ~/ 7) + 1; // 1-5

        grid.putIfAbsent(weekOfMonth, () => {});
        grid[weekOfMonth]![dayOfWeek] =
            (grid[weekOfMonth]![dayOfWeek] ?? 0) + amount;

        final cellVal = grid[weekOfMonth]![dayOfWeek]!;
        if (cellVal > maxCell) maxCell = cellVal;
      } catch (_) {
        // Skip malformed transactions silently
        continue;
      }
    }

    return (grid: grid, maxCellValue: maxCell);
  }

  // -------------------------------------------------------------------------
  // 2. CATEGORY-WISE MONTHLY TRENDS
  // -------------------------------------------------------------------------

  /// Groups debit transactions by category and month for the last [monthsBack] months.
  ///
  /// Returns `{category: [MonthlyDataPoint]}` sorted chronologically.
  static Map<String, List<MonthlyDataPoint>> computeCategoryTrends(
    List<Map<String, dynamic>> transactions, {
    int monthsBack = 6,
  }) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month - monthsBack + 1, 1);
    final Map<String, Map<String, double>> categoryMonthMap = {};
    // key = "category", inner key = "year-month"

    for (final txn in transactions) {
      try {
        if (txn['type'] != 'Debit') continue;

        final date = DateTime.parse(txn['date'] as String);
        if (date.isBefore(cutoff)) continue;

        final category = txn['category'] as String? ?? 'Other';
        final amount = (txn['amount'] as num).toDouble();
        final monthKey = '${date.year}-${date.month}';

        categoryMonthMap.putIfAbsent(category, () => {});
        categoryMonthMap[category]![monthKey] =
            (categoryMonthMap[category]![monthKey] ?? 0) + amount;
      } catch (_) {
        continue;
      }
    }

    // Build sorted time series per category
    final Map<String, List<MonthlyDataPoint>> result = {};

    for (final entry in categoryMonthMap.entries) {
      final points = <MonthlyDataPoint>[];

      // Walk through each month in the range
      for (int i = 0; i < monthsBack; i++) {
        final m = DateTime(now.year, now.month - monthsBack + 1 + i, 1);
        final key = '${m.year}-${m.month}';
        points.add(MonthlyDataPoint(
          year: m.year,
          month: m.month,
          total: entry.value[key] ?? 0,
        ));
      }

      result[entry.key] = points;
    }

    return result;
  }

  // -------------------------------------------------------------------------
  // 3. CASH FLOW WATERFALL
  // -------------------------------------------------------------------------

  /// Builds a waterfall chart data model for the current month's transactions.
  ///
  /// Segment order: Opening (₹0) → Income → per-category expenses → Closing Balance.
  static List<WaterfallSegment> computeCashFlowWaterfall(
    List<Map<String, dynamic>> transactions,
  ) {
    final now = DateTime.now();
    double totalIncome = 0;
    final Map<String, double> expenseByCategory = {};

    for (final txn in transactions) {
      try {
        final date = DateTime.parse(txn['date'] as String);
        if (date.year != now.year || date.month != now.month) continue;

        final amount = (txn['amount'] as num).toDouble();

        if (txn['type'] == 'Credit') {
          totalIncome += amount;
        } else if (txn['type'] == 'Debit') {
          final cat = txn['category'] as String? ?? 'Other';
          expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + amount;
        }
      } catch (_) {
        continue;
      }
    }

    // Sort expenses largest first
    final sortedExpenses = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final segments = <WaterfallSegment>[];
    double running = 0;

    // 1. Opening balance
    segments.add(const WaterfallSegment(
      label: 'Opening',
      value: 0,
      runningTotal: 0,
      segmentType: SegmentType.balance,
    ));

    // 2. Income
    running += totalIncome;
    segments.add(WaterfallSegment(
      label: 'Income',
      value: totalIncome,
      runningTotal: running,
      segmentType: SegmentType.income,
    ));

    // 3. Per-category expenses
    for (final e in sortedExpenses) {
      running -= e.value;
      segments.add(WaterfallSegment(
        label: e.key,
        value: e.value,
        runningTotal: running,
        segmentType: SegmentType.expense,
      ));
    }

    // 4. Closing balance
    segments.add(WaterfallSegment(
      label: 'Balance',
      value: running,
      runningTotal: running,
      segmentType: SegmentType.balance,
    ));

    return segments;
  }

  // -------------------------------------------------------------------------
  // 4. ANONYMIZED PEER COMPARISON
  // -------------------------------------------------------------------------

  /// Default benchmarks: median monthly spend for urban India, age 25-35.
  /// Sources: RBI Household Finance Committee report, NSSO 68th round
  /// consumer expenditure survey, adjusted to 2025-26 inflation.
  static const List<PeerBenchmark> defaultBenchmarks = [
    PeerBenchmark(category: 'Food & Dining', median: 8500),
    PeerBenchmark(category: 'Transit & Auto', median: 3200),
    PeerBenchmark(category: 'Utilities & Bills', median: 4500),
    PeerBenchmark(category: 'Shopping & Groceries', median: 6000),
    PeerBenchmark(category: 'Investments', median: 10000),
    PeerBenchmark(category: 'Uncategorized Matter', median: 5000),
  ];

  /// Compares user's per-category monthly spend against peer benchmarks.
  static List<PeerComparisonResult> computePeerComparison(
    List<Map<String, dynamic>> transactions, {
    List<PeerBenchmark>? benchmarks,
  }) {
    final activeBenchmarks = benchmarks ?? defaultBenchmarks;
    final now = DateTime.now();

    // Compute user's current-month spend per category
    final Map<String, double> userSpendByCategory = {};
    for (final txn in transactions) {
      try {
        if (txn['type'] != 'Debit') continue;
        final date = DateTime.parse(txn['date'] as String);
        if (date.year != now.year || date.month != now.month) continue;

        final cat = txn['category'] as String? ?? 'Other';
        final amount = (txn['amount'] as num).toDouble();
        userSpendByCategory[cat] = (userSpendByCategory[cat] ?? 0) + amount;
      } catch (_) {
        continue;
      }
    }

    final results = <PeerComparisonResult>[];

    for (final benchmark in activeBenchmarks) {
      final userSpend = userSpendByCategory[benchmark.category] ?? 0;
      final ratio = benchmark.median > 0 ? userSpend / benchmark.median : 0.0;
      final percentile = (ratio * 50).clamp(0, 100).toDouble();

      String verdict;
      if (percentile <= 25) {
        verdict = 'Frugal 🟢';
      } else if (percentile <= 50) {
        verdict = 'On Track 🟡';
      } else if (percentile <= 75) {
        verdict = 'Above Peers 🟠';
      } else {
        verdict = 'High Spender 🔴';
      }

      results.add(PeerComparisonResult(
        category: benchmark.category,
        userSpend: userSpend,
        peerMedian: benchmark.median,
        percentile: percentile,
        verdict: verdict,
      ));
    }

    return results;
  }
}
