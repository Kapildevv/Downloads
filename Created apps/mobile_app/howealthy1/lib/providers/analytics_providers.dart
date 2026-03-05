import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_engine.dart';
import 'data_pipeline.dart';

// ---------------------------------------------------------------------------
// Derived analytics providers – reactively recompute when transactions change
// ---------------------------------------------------------------------------

/// Spending heatmap data for the current month.
final spendingHeatmapProvider = Provider<
    AsyncValue<({Map<int, Map<int, double>> grid, double maxCellValue})>>(
  (ref) {
    final txnAsync = ref.watch(transactionsStreamProvider);
    return txnAsync.whenData(
      (transactions) => AnalyticsEngine.computeSpendingHeatmap(transactions),
    );
  },
);

/// Category-wise monthly trend data for the last 6 months.
final categoryTrendsProvider =
    Provider<AsyncValue<Map<String, List<MonthlyDataPoint>>>>((ref) {
  final txnAsync = ref.watch(transactionsStreamProvider);
  return txnAsync.whenData(
    (transactions) => AnalyticsEngine.computeCategoryTrends(transactions),
  );
});

/// Cash flow waterfall segments for the current month.
final cashFlowWaterfallProvider =
    Provider<AsyncValue<List<WaterfallSegment>>>((ref) {
  final txnAsync = ref.watch(transactionsStreamProvider);
  return txnAsync.whenData(
    (transactions) => AnalyticsEngine.computeCashFlowWaterfall(transactions),
  );
});

/// Anonymized peer comparison results for the current month.
final peerComparisonProvider =
    Provider<AsyncValue<List<PeerComparisonResult>>>((ref) {
  final txnAsync = ref.watch(transactionsStreamProvider);
  return txnAsync.whenData(
    (transactions) => AnalyticsEngine.computePeerComparison(transactions),
  );
});
