import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_providers.dart';
import '../../services/analytics_engine.dart';
import '../../theme/app_colors.dart';

/// Cash flow waterfall chart: Income → per-category expenses → closing balance.
class CashFlowWaterfallView extends ConsumerWidget {
  const CashFlowWaterfallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterfallAsync = ref.watch(cashFlowWaterfallProvider);

    return waterfallAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load cash flow: $error',
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (segments) {
        if (segments.length <= 2) {
          // Only Opening + Balance = no real data
          return const Center(
            child: Text(
              'No transactions this month for cash flow analysis.',
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16),
            ),
          );
        }

        final fmt = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        );

        // Compute chart bounds
        double maxRunning = 0;
        for (final seg in segments) {
          if (seg.runningTotal.abs() > maxRunning) {
            maxRunning = seg.runningTotal.abs();
          }
          if (seg.value.abs() > maxRunning) {
            maxRunning = seg.value.abs();
          }
        }
        maxRunning *= 1.15;
        if (maxRunning == 0) maxRunning = 1000;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cash Flow Waterfall',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: maxRunning,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxRunning / 4,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Colors.white10,
                        strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) => Text(
                            '₹${NumberFormat.compact(locale: "en_IN").format(value)}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= segments.length) {
                              return const SizedBox();
                            }
                            // Truncate long labels
                            String label = segments[idx].label;
                            if (label.length > 6) {
                              label = '${label.substring(0, 5)}…';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: AppColors.darkTextTertiary,
                                  fontSize: 9,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(segments),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final seg = segments[groupIndex];
                          return BarTooltipItem(
                            '${seg.label}\n${fmt.format(seg.value)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 500),
                ),
              ),

              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(Colors.tealAccent, 'Income'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.error, 'Expenses'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.darkTextSecondary, 'Balance'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<WaterfallSegment> segments) {
    return segments.asMap().entries.map((entry) {
      final idx = entry.key;
      final seg = entry.value;

      Color barColor;
      switch (seg.segmentType) {
        case SegmentType.income:
          barColor = Colors.tealAccent;
          break;
        case SegmentType.expense:
          barColor = AppColors.error;
          break;
        case SegmentType.balance:
          barColor = seg.runningTotal >= 0 ? AppColors.darkTextSecondary : AppColors.warning;
          break;
      }

      // For waterfall effect:
      // - Income/Balance bars: fromY = 0, toY = runningTotal
      // - Expense bars: fromY = runningTotal, toY = runningTotal + value
      double fromY;
      double toY;

      if (seg.segmentType == SegmentType.expense) {
        fromY = seg.runningTotal;
        toY = seg.runningTotal + seg.value;
      } else {
        fromY = 0;
        toY = seg.runningTotal;
      }

      if (fromY < 0) fromY = 0;
      if (toY < 0) toY = 0;

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            fromY: fromY,
            toY: toY,
            color: barColor,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 11),
        ),
      ],
    );
  }
}
