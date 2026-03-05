import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/fund_holding.dart';
import '../../repositories/mutual_fund_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/mf_holding_card.dart';
import '../widgets/glass_card.dart';

class MfDashboard extends ConsumerWidget {
  const MfDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assuming auth integration provides uid. Using a placeholder for now.
    const uid = 'current_user_id';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text('Mutual Funds',
            style: AppTypography.headlineMedium(isDark: isDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
      ),
      body: StreamBuilder<List<FundHolding>>(
        stream: ref.watch(mutualFundRepositoryProvider).getHoldingsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load portfolio.',
                style: AppTypography.bodyMedium(isDark: isDark)
                    .copyWith(color: AppColors.error),
              ),
            );
          }

          final holdings = snapshot.data ?? [];

          if (holdings.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return _buildPortfolioView(context, holdings, isDark);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement bottom sheet or navigation to add a fund manually
          // or navigate to CAMS/KFintech import flow
        },
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Fund', style: AppTypography.labelLarge(isDark: true)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline,
                size: 64,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary),
            const SizedBox(height: 16),
            Text(
              'No Mutual Funds Found',
              style: AppTypography.headlineMedium(isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Import your CAS statement or add funds manually to track your portfolio.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioView(
      BuildContext context, List<FundHolding> holdings, bool isDark) {
    double totalValue = 0;
    double totalInvested = 0;

    for (var h in holdings) {
      totalValue += h.currentValue;
      totalInvested += h.investedAmount;
    }

    double absoluteReturn = totalValue - totalInvested;
    double returnPct =
        totalInvested > 0 ? (absoluteReturn / totalInvested) * 100 : 0;
    bool isPositive = absoluteReturn >= 0;

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Hook up NavFetchService to refresh NAVs here.
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header / Summary Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Portfolio Value',
                    style: AppTypography.bodyMedium(isDark: isDark)),
                const SizedBox(height: 8),
                Text(
                  '₹${totalValue.toStringAsFixed(2)}',
                  style: AppTypography.displayLarge(isDark: isDark),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Invested',
                            style: AppTypography.bodySmall(isDark: isDark)),
                        const SizedBox(height: 4),
                        Text('₹${totalInvested.toStringAsFixed(2)}',
                            style: AppTypography.headlineSmall(isDark: isDark)),
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
                              '₹${absoluteReturn.abs().toStringAsFixed(2)} (${returnPct.toStringAsFixed(2)}%)',
                              style: AppTypography.amountMedium(
                                  isPositive: isPositive),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Your Holdings',
            style: AppTypography.headlineSmall(isDark: isDark),
          ),
          const SizedBox(height: 12),

          // List of Funds
          ...holdings.map((holding) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: MfHoldingCard(
                holding: holding,
                onTap: () {
                  // TODO: Navigate to the fund details page
                },
              ),
            );
          }),

          // FAB padding
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
