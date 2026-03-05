import 'package:flutter_test/flutter_test.dart';
import 'package:howealthy1/services/analytics_engine.dart';

/// Synthetic transaction factory for controlled test data.
Map<String, dynamic> _makeTxn({
  required double amount,
  required String type,
  String category = 'Food & Dining',
  DateTime? date,
}) {
  final d = date ?? DateTime.now();
  return {
    'amount': amount,
    'type': type,
    'category': category,
    'date': d.toIso8601String(),
    'fingerprint': '${amount}_${d.millisecondsSinceEpoch}',
  };
}

void main() {
  // -----------------------------------------------------------------------
  // 1. SPENDING HEATMAP
  // -----------------------------------------------------------------------
  group('computeSpendingHeatmap', () {
    test('returns empty grid for no transactions', () {
      final result = AnalyticsEngine.computeSpendingHeatmap([]);
      expect(result.grid, isEmpty);
      expect(result.maxCellValue, 0);
    });

    test('returns empty grid for credit-only transactions', () {
      final txns = [
        _makeTxn(amount: 5000, type: 'Credit'),
      ];
      final result = AnalyticsEngine.computeSpendingHeatmap(txns);
      expect(result.grid, isEmpty);
    });

    test('correctly buckets a debit into day-of-week and week-of-month', () {
      // Use a known date in the current month
      final now = DateTime.now();
      final testDate = DateTime(now.year, now.month, 10, 14, 30);
      final txns = [
        _makeTxn(amount: 500, type: 'Debit', date: testDate),
      ];

      final result = AnalyticsEngine.computeSpendingHeatmap(txns);

      final expectedWeek = ((testDate.day - 1) ~/ 7) + 1;
      final expectedDay = testDate.weekday;

      expect(result.grid[expectedWeek]?[expectedDay], 500);
      expect(result.maxCellValue, 500);
    });

    test('aggregates multiple debits on the same day', () {
      final now = DateTime.now();
      final testDate = DateTime(now.year, now.month, 5, 10, 0);
      final txns = [
        _makeTxn(amount: 200, type: 'Debit', date: testDate),
        _makeTxn(amount: 300, type: 'Debit', date: testDate),
      ];

      final result = AnalyticsEngine.computeSpendingHeatmap(txns);

      final week = ((testDate.day - 1) ~/ 7) + 1;
      final day = testDate.weekday;

      expect(result.grid[week]?[day], 500);
      expect(result.maxCellValue, 500);
    });

    test('ignores transactions from other months', () {
      final lastMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month - 1,
        15,
      );
      final txns = [
        _makeTxn(amount: 1000, type: 'Debit', date: lastMonth),
      ];
      final result = AnalyticsEngine.computeSpendingHeatmap(txns);
      expect(result.grid, isEmpty);
    });

    test('skips malformed transactions gracefully', () {
      final txns = <Map<String, dynamic>>[
        {'amount': 'not_a_number', 'type': 'Debit', 'date': 'invalid'},
        _makeTxn(amount: 100, type: 'Debit'),
      ];
      final result = AnalyticsEngine.computeSpendingHeatmap(txns);
      // Should have processed one valid txn
      expect(result.maxCellValue, 100);
    });
  });

  // -----------------------------------------------------------------------
  // 2. CATEGORY MONTHLY TRENDS
  // -----------------------------------------------------------------------
  group('computeCategoryTrends', () {
    test('returns empty map for no transactions', () {
      final result = AnalyticsEngine.computeCategoryTrends([]);
      expect(result, isEmpty);
    });

    test('groups debits by category and month', () {
      final now = DateTime.now();
      final txns = [
        _makeTxn(
          amount: 400,
          type: 'Debit',
          category: 'Food & Dining',
          date: DateTime(now.year, now.month, 5),
        ),
        _makeTxn(
          amount: 600,
          type: 'Debit',
          category: 'Food & Dining',
          date: DateTime(now.year, now.month, 15),
        ),
        _makeTxn(
          amount: 200,
          type: 'Debit',
          category: 'Transit & Auto',
          date: DateTime(now.year, now.month, 10),
        ),
      ];

      final result = AnalyticsEngine.computeCategoryTrends(txns);

      expect(result.containsKey('Food & Dining'), true);
      expect(result.containsKey('Transit & Auto'), true);

      // The current month's data point for Food should be 1000
      final foodSeries = result['Food & Dining']!;
      final currentMonthPoint = foodSeries.last;
      expect(currentMonthPoint.total, 1000);
    });

    test('returns 6 data points per category by default', () {
      final txns = [
        _makeTxn(amount: 100, type: 'Debit'),
      ];

      final result = AnalyticsEngine.computeCategoryTrends(txns);
      for (final series in result.values) {
        expect(series.length, 6);
      }
    });

    test('orders data points chronologically', () {
      final txns = [
        _makeTxn(amount: 100, type: 'Debit'),
      ];

      final result = AnalyticsEngine.computeCategoryTrends(txns);
      final series = result.values.first;

      for (int i = 1; i < series.length; i++) {
        final prev = DateTime(series[i - 1].year, series[i - 1].month);
        final curr = DateTime(series[i].year, series[i].month);
        expect(curr.isAfter(prev) || curr.isAtSameMomentAs(prev), true);
      }
    });

    test('ignores credit transactions', () {
      final txns = [
        _makeTxn(amount: 5000, type: 'Credit', category: 'Salary'),
      ];
      final result = AnalyticsEngine.computeCategoryTrends(txns);
      expect(result, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // 3. CASH FLOW WATERFALL
  // -----------------------------------------------------------------------
  group('computeCashFlowWaterfall', () {
    test('returns Opening + Income + Balance for no transactions', () {
      final result = AnalyticsEngine.computeCashFlowWaterfall([]);
      // Opening + Income(0) + Balance = 3 segments
      expect(result.length, 3);
      expect(result.first.label, 'Opening');
      expect(result[1].label, 'Income');
      expect(result.last.label, 'Balance');
      expect(result.last.runningTotal, 0);
    });

    test('net equals income minus total expenses', () {
      final now = DateTime.now();
      final txns = [
        _makeTxn(amount: 50000, type: 'Credit', date: now),
        _makeTxn(
          amount: 8000,
          type: 'Debit',
          category: 'Food & Dining',
          date: now,
        ),
        _makeTxn(
          amount: 3000,
          type: 'Debit',
          category: 'Transit & Auto',
          date: now,
        ),
      ];

      final result = AnalyticsEngine.computeCashFlowWaterfall(txns);

      // Opening(0) + Income(50000) + Food(8000) + Transit(3000) + Balance
      expect(result.length, 5);

      // Balance = 50000 - 8000 - 3000 = 39000
      final balance = result.last;
      expect(balance.label, 'Balance');
      expect(balance.runningTotal, 39000);
    });

    test('expense categories are sorted largest first', () {
      final now = DateTime.now();
      final txns = [
        _makeTxn(amount: 50000, type: 'Credit', date: now),
        _makeTxn(
          amount: 2000,
          type: 'Debit',
          category: 'Transit & Auto',
          date: now,
        ),
        _makeTxn(
          amount: 10000,
          type: 'Debit',
          category: 'Food & Dining',
          date: now,
        ),
      ];

      final result = AnalyticsEngine.computeCashFlowWaterfall(txns);

      // After Opening and Income, Food (10000) should come before Transit (2000)
      final expenseSegments =
          result.where((s) => s.segmentType == SegmentType.expense).toList();

      expect(expenseSegments[0].label, 'Food & Dining');
      expect(expenseSegments[1].label, 'Transit & Auto');
    });

    test('segment types are correctly assigned', () {
      final now = DateTime.now();
      final txns = [
        _makeTxn(amount: 30000, type: 'Credit', date: now),
        _makeTxn(amount: 5000, type: 'Debit', date: now),
      ];

      final result = AnalyticsEngine.computeCashFlowWaterfall(txns);

      expect(result[0].segmentType, SegmentType.balance); // Opening
      expect(result[1].segmentType, SegmentType.income); // Income
      expect(result[2].segmentType, SegmentType.expense); // Category
      expect(result[3].segmentType, SegmentType.balance); // Balance
    });
  });

  // -----------------------------------------------------------------------
  // 4. PEER COMPARISON
  // -----------------------------------------------------------------------
  group('computePeerComparison', () {
    test('returns results for all benchmark categories', () {
      final result = AnalyticsEngine.computePeerComparison([]);
      expect(
        result.length,
        AnalyticsEngine.defaultBenchmarks.length,
      );
    });

    test('zero spend yields Frugal verdict', () {
      final result = AnalyticsEngine.computePeerComparison([]);
      for (final r in result) {
        expect(r.userSpend, 0);
        expect(r.percentile, 0);
        expect(r.verdict, 'Frugal 🟢');
      }
    });

    test('percentile is clamped to 0-100 range', () {
      final now = DateTime.now();
      // Spend 10x the median to test clamping
      final txns = [
        _makeTxn(
          amount: 85000,
          type: 'Debit',
          category: 'Food & Dining',
          date: now,
        ),
      ];

      final result = AnalyticsEngine.computePeerComparison(txns);
      final food = result.firstWhere((r) => r.category == 'Food & Dining');

      expect(food.percentile, lessThanOrEqualTo(100));
      expect(food.percentile, greaterThanOrEqualTo(0));
    });

    test('spending exactly at median yields On Track verdict', () {
      final now = DateTime.now();
      // Food median is 8500, spend exactly 8500
      final txns = [
        _makeTxn(
          amount: 8500,
          type: 'Debit',
          category: 'Food & Dining',
          date: now,
        ),
      ];

      final result = AnalyticsEngine.computePeerComparison(txns);
      final food = result.firstWhere((r) => r.category == 'Food & Dining');

      // ratio = 8500/8500 = 1.0, percentile = 50
      expect(food.percentile, 50);
      expect(food.verdict, 'On Track 🟡');
    });

    test('high spending yields High Spender verdict', () {
      final now = DateTime.now();
      // Food median is 8500, spend 20000 → ratio ~2.35 → percentile ~100 (clamped)
      final txns = [
        _makeTxn(
          amount: 20000,
          type: 'Debit',
          category: 'Food & Dining',
          date: now,
        ),
      ];

      final result = AnalyticsEngine.computePeerComparison(txns);
      final food = result.firstWhere((r) => r.category == 'Food & Dining');

      expect(food.verdict, 'High Spender 🔴');
    });

    test('ignores transactions from other months', () {
      final lastMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month - 1,
        15,
      );
      final txns = [
        _makeTxn(
          amount: 50000,
          type: 'Debit',
          category: 'Food & Dining',
          date: lastMonth,
        ),
      ];

      final result = AnalyticsEngine.computePeerComparison(txns);
      final food = result.firstWhere((r) => r.category == 'Food & Dining');

      expect(food.userSpend, 0);
    });
  });
}
