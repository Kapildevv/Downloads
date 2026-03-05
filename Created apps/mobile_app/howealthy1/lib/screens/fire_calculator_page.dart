import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'widgets/glass_card.dart';
import 'widgets/animated_goal_ring.dart';

class FireCalculatorPage extends StatefulWidget {
  const FireCalculatorPage({super.key});

  @override
  State<FireCalculatorPage> createState() => _FireCalculatorPageState();
}

class _FireCalculatorPageState extends State<FireCalculatorPage> {
  final int _currentAge = 30;
  int _retirementAge = 50;
  double _monthlyInvestment = 20000; // INR
  double _expectedReturn = 12.0; // %
  final double _currentCorpus = 500000; // INR

  int? _touchedIndex;

  List<FlSpot> _calculateProjection() {
    List<FlSpot> spots = [];
    double corpus = _currentCorpus;
    int yearsToRetire = _retirementAge - _currentAge;

    // Monthly rate
    double monthlyRate = (_expectedReturn / 100) / 12;

    for (int i = 0; i <= yearsToRetire; i++) {
      spots.add(FlSpot(_currentAge + i.toDouble(), corpus));

      // Calculate next year's corpus
      for (int m = 0; m < 12; m++) {
        corpus += _monthlyInvestment;
        corpus += corpus * monthlyRate;
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _calculateProjection();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt =
        NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    double finalAmount = spots.isNotEmpty ? spots.last.y : 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text('FIRE Calculator',
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
                  progress: 0.9, // 90% towards FIRE goal
                  size: 280,
                  primaryColor: AppColors.primaryGold,
                  secondaryColor: AppColors.primaryTealAccent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Projected Corpus\nat Age $_retirementAge',
                        style: AppTypography.bodyLarge(isDark: isDark)
                            .copyWith(color: AppColors.darkTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFmt.format(finalAmount),
                        style: AppTypography.displayLarge(isDark: isDark)
                            .copyWith(color: AppColors.primaryGold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Chart Section with Haptic Scrubbing
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 300,
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
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  NumberFormat.compact().format(value),
                                  style: AppTypography.bodySmall(isDark: isDark)
                                      .copyWith(
                                          fontSize: 10,
                                          color: AppColors.darkTextSecondary),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value % 5 != 0 &&
                                  value != _currentAge &&
                                  value != _retirementAge) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Age ${value.toInt()}',
                                  style: AppTypography.bodySmall(isDark: isDark)
                                      .copyWith(
                                          fontSize: 10,
                                          color: AppColors.darkTextSecondary),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: spots.first.x,
                      maxX: spots.last.x,
                      minY: 0,
                      maxY: finalAmount * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppColors.primaryTealAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              if (index == _touchedIndex) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: AppColors.primaryGold,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.background,
                                );
                              }
                              return FlDotCirclePainter(
                                  radius: 0, color: Colors.transparent);
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryTealAccent
                                    .withValues(alpha: 0.4),
                                AppColors.primaryTealAccent
                                    .withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      // Floating Tooltip & Haptic Feedback Logic
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
                          tooltipBgColor: AppColors.surface,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                'Age ${touchedSpot.x.toInt()}\n',
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

                          // Trigger Haptic Scrubbing when changing indices!
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

              // Controls
              Text('Adjust Parameters',
                  style: AppTypography.headlineSmall(isDark: isDark)),
              const SizedBox(height: 16),

              _buildSlider(
                label: 'Monthly Investment',
                value: _monthlyInvestment,
                min: 0,
                max: 200000,
                divisions: 200,
                formatValue: (v) => currencyFmt.format(v),
                onChanged: (val) {
                  setState(() {
                    _monthlyInvestment = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildSlider(
                label: 'Expected Return',
                value: _expectedReturn,
                min: 5,
                max: 20,
                divisions: 30,
                formatValue: (v) => '${v.toStringAsFixed(1)}%',
                onChanged: (val) {
                  setState(() {
                    _expectedReturn = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildSlider(
                label: 'Retirement Age',
                value: _retirementAge.toDouble(),
                min: _currentAge.toDouble() + 5,
                max: 80,
                divisions: (80 - (_currentAge + 5)),
                formatValue: (v) => '${v.toInt()} yrs',
                onChanged: (val) {
                  setState(() {
                    _retirementAge = val.toInt();
                  });
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) formatValue,
    required ValueChanged<double> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.bodyMedium(isDark: isDark)),
              Text(formatValue(value),
                  style: AppTypography.headlineSmall(isDark: isDark)
                      .copyWith(color: AppColors.income)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primaryTealAccent,
            inactiveColor: AppColors.darkDivider,
            onChanged: onChanged,
            onChangeEnd: (_) => HapticFeedback
                .lightImpact(), // Feedback when finishing adjustment
          ),
        ],
      ),
    );
  }
}
