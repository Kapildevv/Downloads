import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'widgets/glass_card.dart';
import 'widgets/animated_goal_ring.dart';

class NetWorthDashboardPage extends StatefulWidget {
  const NetWorthDashboardPage({super.key});

  @override
  State<NetWorthDashboardPage> createState() => _NetWorthDashboardPageState();
}

class _NetWorthDashboardPageState extends State<NetWorthDashboardPage> {
  int? _touchedIndex;

  // Mock data for the past 6 months
  final List<FlSpot> _netWorthSpots = const [
    FlSpot(1, 500000),
    FlSpot(2, 520000),
    FlSpot(3, 505000),
    FlSpot(4, 530000),
    FlSpot(5, 590000),
    FlSpot(6, 610000),
  ];

  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt =
        NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    double currentNetWorth = _netWorthSpots.last.y;
    double netWorthChange = _netWorthSpots.last.y - _netWorthSpots.first.y;
    double changePercent = (netWorthChange / _netWorthSpots.first.y) * 100;
    bool isPositive = netWorthChange >= 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text('Net Worth',
            style: AppTypography.headlineMedium(isDark: isDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              Center(
                child: AnimatedGoalRing(
                  progress: 0.85, // 85% towards dynamic Net Worth goal
                  size: 280,
                  primaryColor: AppColors.primaryTealAccent,
                  secondaryColor: AppColors.primaryGold,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Net Worth',
                        style: AppTypography.bodyLarge(isDark: isDark)
                            .copyWith(color: AppColors.darkTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          // Show the touched spot's Y value if scrubbing, else current max
                          _touchedIndex != null
                              ? currencyFmt
                                  .format(_netWorthSpots[_touchedIndex!].y)
                              : currencyFmt.format(currentNetWorth),
                          key: ValueKey<int>(_touchedIndex ?? -1),
                          style: AppTypography.displayLarge(isDark: isDark)
                              .copyWith(color: AppColors.income),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color:
                                isPositive ? AppColors.income : AppColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${currencyFmt.format(netWorthChange.abs())} (${changePercent.toStringAsFixed(2)}%)',
                            style: AppTypography.amountMedium(
                                isPositive: isPositive),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Interactive Haptic Chart
              GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: AppColors.darkDivider,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                                showTitles:
                                    false)), // Hide Y axis for cleaner look
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt() - 1;
                              if (index < 0 || index >= _months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _months[index],
                                  style: AppTypography.bodySmall(isDark: isDark)
                                      .copyWith(
                                    fontSize: 12,
                                    color: _touchedIndex == index
                                        ? AppColors.primaryGold
                                        : AppColors.darkTextSecondary,
                                    fontWeight: _touchedIndex == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 1,
                      maxX: 6,
                      minY: 450000,
                      maxY: 650000,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _netWorthSpots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppColors.primaryTealAccent,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              if (index == _touchedIndex) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: AppColors.primaryGold,
                                  strokeWidth: 3,
                                  strokeColor: AppColors.background,
                                );
                              }
                              // Optionally show dots for all points, but smaller
                              return FlDotCirclePainter(
                                  radius: 3,
                                  color: AppColors.primaryTealAccent,
                                  strokeWidth: 0);
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryTealAccent
                                    .withValues(alpha: 0.5),
                                AppColors.primaryTealAccent
                                    .withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        getTouchedSpotIndicator:
                            (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((index) {
                            return const TouchedSpotIndicatorData(
                              FlLine(
                                  color: AppColors.primaryGold,
                                  strokeWidth: 2,
                                  dashArray: [4, 4]),
                              FlDotData(show: false),
                            );
                          }).toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor:
                              AppColors.surface.withValues(alpha: 0.9),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              final index = touchedSpot.x.toInt() - 1;
                              return LineTooltipItem(
                                '${_months[index]}\n',
                                AppTypography.bodySmall(isDark: isDark)
                                    .copyWith(
                                        color: AppColors.darkTextSecondary),
                                children: [
                                  TextSpan(
                                    text: currencyFmt.format(touchedSpot.y),
                                    style: AppTypography.headlineSmall(
                                            isDark: isDark)
                                        .copyWith(
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                        touchCallback: (FlTouchEvent event,
                            LineTouchResponse? touchResponse) {
                          if (!event.isInterestedForInteractions ||
                              touchResponse == null ||
                              touchResponse.lineBarSpots == null ||
                              touchResponse.lineBarSpots!.isEmpty) {
                            if (_touchedIndex != null) {
                              setState(() {
                                _touchedIndex = null;
                              });
                            }
                            return;
                          }

                          final newIndex =
                              touchResponse.lineBarSpots!.first.spotIndex;
                          if (newIndex != _touchedIndex) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _touchedIndex = newIndex;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Breakdown List
              Text('Asset Breakdown',
                  style: AppTypography.headlineSmall(isDark: isDark)),
              const SizedBox(height: 16),
              _buildAssetBreakdownTile(
                  context, 'Cash & Bank', 200000, AppColors.income),
              _buildAssetBreakdownTile(
                  context, 'Mutual Funds', 350000, AppColors.primaryTealAccent),
              _buildAssetBreakdownTile(
                  context, 'Stocks', 60000, AppColors.primaryGold),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetBreakdownTile(
      BuildContext context, String title, double amount, Color color) {
    final currencyFmt =
        NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child:
                  Text(title, style: AppTypography.bodyLarge(isDark: isDark)),
            ),
            Text(
              currencyFmt.format(amount),
              style: AppTypography.headlineSmall(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}
