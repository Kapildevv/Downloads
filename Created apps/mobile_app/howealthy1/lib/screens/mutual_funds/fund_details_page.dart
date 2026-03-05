import 'package:flutter/material.dart';
import '../../models/fund_holding.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class FundDetailsPage extends StatelessWidget {
  final FundHolding holding;

  const FundDetailsPage({super.key, required this.holding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = holding.absoluteReturn >= 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text('Fund Details',
            style: AppTypography.headlineMedium(isDark: isDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.fundName,
                    style: AppTypography.headlineLarge(isDark: isDark),
                  ),
                  const SizedBox(height: 8),
                  if (holding.folioNumber != null) ...[
                    Text(
                      'Folio: ${holding.folioNumber}',
                      style: AppTypography.bodySmall(isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Value',
                              style: AppTypography.bodySmall(isDark: isDark)),
                          const SizedBox(height: 4),
                          Text('₹${holding.currentValue.toStringAsFixed(2)}',
                              style:
                                  AppTypography.displayMedium(isDark: isDark)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invested Amount',
                              style: AppTypography.bodySmall(isDark: isDark)),
                          const SizedBox(height: 4),
                          Text('₹${holding.investedAmount.toStringAsFixed(2)}',
                              style:
                                  AppTypography.headlineSmall(isDark: isDark)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Absolute Returns',
                              style: AppTypography.bodySmall(isDark: isDark)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isPositive
                                    ? AppColors.income
                                    : AppColors.expense,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '₹${holding.absoluteReturn.abs().toStringAsFixed(2)} (${holding.returnPercentage.toStringAsFixed(2)}%)',
                                style: AppTypography.amountMedium(
                                    isPositive: isPositive),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                      height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Total Units',
                          holding.units.toStringAsFixed(3), isDark),
                      _buildStatColumn('Current NAV',
                          '₹${holding.currentNav.toStringAsFixed(4)}', isDark),
                      _buildStatColumn('Avg. NAV',
                          '₹${holding.averageNav.toStringAsFixed(4)}', isDark,
                          isRightAligned: true),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SIP Details Card
            if (holding.isSipActive) ...[
              Text(
                'SIP Information',
                style: AppTypography.headlineSmall(isDark: isDark),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly SIP Amount',
                            style: AppTypography.bodySmall(isDark: isDark)),
                        const SizedBox(height: 4),
                        Text(
                            '₹${holding.sipAmount?.toStringAsFixed(2) ?? '0.00'}',
                            style: AppTypography.headlineSmall(isDark: isDark)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Next SIP Date',
                            style: AppTypography.bodySmall(isDark: isDark)),
                        const SizedBox(height: 4),
                        Text(
                            holding.sipDate != null
                                ? '${holding.sipDate} of every month'
                                : 'Not set',
                            style: AppTypography.bodyMedium(isDark: isDark)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Transaction History Placeholder
            Text(
              'Recent Transactions',
              style: AppTypography.headlineSmall(isDark: isDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                        size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: AppTypography.bodyMedium(isDark: isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isDark,
      {bool isRightAligned = false}) {
    return Column(
      crossAxisAlignment:
          isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall(isDark: isDark),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.labelLarge(isDark: isDark),
        ),
      ],
    );
  }
}
