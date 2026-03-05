import '../models/insight.dart';
import 'spending_analyzer.dart';

/// ClairvoyanceEngine 2.0 — Oracle's intelligent financial insight generator.
///
/// Upgraded from 3 basic rules to 33 sophisticated insights across 8 categories:
/// Spending Anomalies, Budget & Burn Rate, Savings Intelligence, Income & Cash Flow,
/// Lifestyle & Behavioral, Trend Analysis, and Positive Reinforcement.
class ClairvoyanceEngine {
  /// Generates a prioritized list of financial insights from transaction data.
  ///
  /// [currentMonthTxns] — all transactions for the current month.
  /// [lastMonthTxns]    — all transactions for the previous month.
  static List<Insight> generateInsights(
    List<Map<String, dynamic>> currentMonthTxns,
    List<Map<String, dynamic>> lastMonthTxns,
  ) {
    final List<Insight> insights = [];

    final currentCategories =
        SpendingAnalyzer.groupByCategory(currentMonthTxns);
    final lastCategories = SpendingAnalyzer.groupByCategory(lastMonthTxns);
    final currentTotal = SpendingAnalyzer.totalDebit(currentMonthTxns);
    final lastTotal = SpendingAnalyzer.totalDebit(lastMonthTxns);
    final currentIncome = SpendingAnalyzer.totalCredit(currentMonthTxns);
    final daysPassed = DateTime.now().day;
    final daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

    // ═══════════════════════════════════════════════════════════
    // CATEGORY 1: SPENDING ANOMALIES (8 rules)
    // ═══════════════════════════════════════════════════════════

    // 1. Food Spike Detection
    final currentFood = currentCategories['Food & Dining'] ?? 0;
    final pastFood = lastCategories['Food & Dining'] ?? 0;
    if (currentFood > (pastFood * 1.5) && pastFood > 0) {
      final pct = (((currentFood - pastFood) / pastFood) * 100).toInt();
      insights.add(Insight(
        emoji: '🍕',
        title: 'Food Spending Spike',
        description:
            '$pct% increase in Food & Dining vs last month (₹${currentFood.toInt()} vs ₹${pastFood.toInt()}).',
        severity: InsightSeverity.warning,
        category: InsightCategory.spending,
        actionTip:
            'Try cooking at home 3 days a week — could save ₹${((currentFood - pastFood) * 0.6).toInt()}/month.',
      ));
    }

    // 2. Shopping Splurge Detection
    final currentShopping = currentCategories['Shopping & Groceries'] ?? 0;
    final pastShopping = lastCategories['Shopping & Groceries'] ?? 0;
    if (currentShopping > (pastShopping * 1.5) && pastShopping > 0) {
      insights.add(Insight(
        emoji: '🛍️',
        title: 'Shopping Splurge Alert',
        description:
            'Shopping spend is ₹${currentShopping.toInt()} — over 50% more than last month.',
        severity: InsightSeverity.warning,
        category: InsightCategory.spending,
        actionTip:
            'Implement a 24-hour rule: wait a day before any purchase over ₹1,000.',
      ));
    }

    // 3. Utility Bill Spike
    final currentUtil = currentCategories['Utilities & Bills'] ?? 0;
    final pastUtil = lastCategories['Utilities & Bills'] ?? 0;
    if (currentUtil > (pastUtil * 1.3) && pastUtil > 0) {
      insights.add(Insight(
        emoji: '⚡',
        title: 'Utility Bill Increase',
        description:
            'Utilities at ₹${currentUtil.toInt()} — up from ₹${pastUtil.toInt()} last month.',
        severity: InsightSeverity.info,
        category: InsightCategory.spending,
        actionTip:
            'Check for unused subscriptions or higher AC usage this month.',
      ));
    }

    // 4. Weekend vs Weekday Spending Imbalance
    final weekSplit = SpendingAnalyzer.getWeekdayWeekendSplit(currentMonthTxns);
    final weekendSpend = weekSplit['weekend'] ?? 0;
    final weekdaySpend = weekSplit['weekday'] ?? 0;
    if (weekendSpend > 0 && weekdaySpend > 0) {
      final weekendDays = (daysPassed / 7 * 2).ceil().clamp(1, daysPassed);
      final weekdayDays = (daysPassed - weekendDays).clamp(1, daysPassed);
      final weekendDaily = weekendSpend / weekendDays;
      final weekdayDaily = weekdaySpend / weekdayDays;
      if (weekendDaily > weekdayDaily * 2) {
        insights.add(Insight(
          emoji: '📅',
          title: 'Weekend Spending Spike',
          description:
              'You spend ${(weekendDaily / weekdayDaily).toStringAsFixed(1)}x more per day on weekends than weekdays.',
          severity: InsightSeverity.info,
          category: InsightCategory.spending,
          actionTip:
              'Plan free weekend activities — parks, home workouts, or cooking experiments.',
        ));
      }
    }

    // 5. Single Large Transaction Alert (>20% of monthly income)
    final largestTxn =
        SpendingAnalyzer.findLargestTransaction(currentMonthTxns);
    if (largestTxn != null && currentIncome > 0) {
      final largestAmt = (largestTxn['amount'] as num).toDouble();
      if (largestAmt > currentIncome * 0.2) {
        insights.add(Insight(
          emoji: '💰',
          title: 'Large Transaction Detected',
          description:
              '₹${largestAmt.toInt()} single transaction — that\'s ${((largestAmt / currentIncome) * 100).toInt()}% of your income.',
          severity: InsightSeverity.warning,
          category: InsightCategory.spending,
          actionTip:
              'For large planned expenses, consider splitting into EMIs or saving up separately.',
        ));
      }
    }

    // 6. Subscription Creep (recurring entertainment/utilities)
    final recurring =
        SpendingAnalyzer.findRecurringTransactions(currentMonthTxns);
    if (recurring.length >= 3) {
      double recurringTotal = 0;
      for (final r in recurring) {
        for (final txns in r.values) {
          recurringTotal +=
              txns.fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
        }
      }
      insights.add(Insight(
        emoji: '🔄',
        title: 'Subscription Creep',
        description:
            '${recurring.length} recurring charges detected totaling ₹${recurringTotal.toInt()}.',
        severity: InsightSeverity.info,
        category: InsightCategory.spending,
        actionTip:
            'Audit your subscriptions — cancel anything you haven\'t used in 30 days.',
      ));
    }

    // 7. UPI Micro-Transaction Accumulation
    final microCount =
        SpendingAnalyzer.countMicroTransactions(currentMonthTxns);
    final microTotal =
        SpendingAnalyzer.totalMicroTransactions(currentMonthTxns);
    if (microCount >= 20 && microTotal > 500) {
      insights.add(Insight(
        emoji: '🔬',
        title: 'Micro-Transaction Pile-Up',
        description:
            '$microCount small payments under ₹100 adding up to ₹${microTotal.toInt()}.',
        severity: InsightSeverity.info,
        category: InsightCategory.spending,
        actionTip:
            'These tiny spends are invisible budget leaks. Try a weekly UPI spending cap.',
      ));
    }

    // 8. Category Concentration Risk (>50% in one category)
    if (currentTotal > 0) {
      for (final entry in currentCategories.entries) {
        final percentage = (entry.value / currentTotal) * 100;
        if (percentage > 50) {
          insights.add(Insight(
            emoji: '🎯',
            title: 'Spending Concentration Risk',
            description:
                '${percentage.toInt()}% of all spending is on ${entry.key} (₹${entry.value.toInt()}).',
            severity: InsightSeverity.warning,
            category: InsightCategory.spending,
            actionTip:
                'Diversify your expense categories — heavy concentration makes budgets fragile.',
          ));
          break; // Only report the top concentration
        }
      }
    }

    // ═══════════════════════════════════════════════════════════
    // CATEGORY 2: BUDGET & BURN RATE (5 rules)
    // ═══════════════════════════════════════════════════════════

    // 9. Burn Rate Projection
    if (daysPassed > 3) {
      final burnRate =
          SpendingAnalyzer.calculateDailyBurnRate(currentMonthTxns);
      final projected = burnRate * daysInMonth;
      if (currentIncome > 0 && projected > currentIncome) {
        final overagePercent =
            (((projected - currentIncome) / currentIncome) * 100).toInt();
        insights.add(Insight(
          emoji: '🛑',
          title: 'Critical Burn Rate',
          description:
              'At ₹${burnRate.toInt()}/day, you\'ll overshoot income by $overagePercent% (₹${projected.toInt()} projected vs ₹${currentIncome.toInt()} income).',
          severity: InsightSeverity.critical,
          category: InsightCategory.budget,
          actionTip:
              'Cut daily spending by ₹${((projected - currentIncome) / (daysInMonth - daysPassed)).toInt()} for the rest of the month.',
        ));
      }
    }

    // 10. Mid-Month Budget Checkpoint
    if (daysPassed >= 14 && daysPassed <= 17) {
      final halfMonthRatio =
          currentTotal / (currentIncome > 0 ? currentIncome : currentTotal + 1);
      if (halfMonthRatio > 0.55) {
        insights.add(Insight(
          emoji: '📊',
          title: 'Mid-Month Checkpoint',
          description:
              'You\'ve spent ${(halfMonthRatio * 100).toInt()}% of income by mid-month — pace is hot.',
          severity: InsightSeverity.warning,
          category: InsightCategory.budget,
          actionTip:
              'Tighten spending for the next 2 weeks to finish the month sustainably.',
        ));
      }
    }

    // 11. First-Week Overspend Warning
    if (daysPassed >= 7 && daysPassed <= 10) {
      final firstWeekSpend = currentTotal; // All data so far IS the first week
      if (currentIncome > 0 && firstWeekSpend > currentIncome * 0.35) {
        insights.add(Insight(
          emoji: '🚨',
          title: 'First-Week Overspend',
          description:
              '₹${firstWeekSpend.toInt()} spent in the first week — ${((firstWeekSpend / currentIncome) * 100).toInt()}% of income used.',
          severity: InsightSeverity.warning,
          category: InsightCategory.budget,
          actionTip:
              'The remaining 3 weeks need stricter budgeting. Set daily limits now.',
        ));
      }
    }

    // 12. Daily Spend Velocity Trend
    if (daysPassed > 7 && lastTotal > 0) {
      final currentVelocity = currentTotal / daysPassed;
      final lastVelocity =
          lastTotal / 30; // Approximate last month's daily rate
      if (currentVelocity > lastVelocity * 1.3) {
        insights.add(Insight(
          emoji: '📈',
          title: 'Spending Velocity Up',
          description:
              'Daily average ₹${currentVelocity.toInt()}/day vs ₹${lastVelocity.toInt()}/day last month.',
          severity: InsightSeverity.info,
          category: InsightCategory.budget,
          actionTip:
              'If this pace continues, this month will be ${(((currentVelocity / lastVelocity) - 1) * 100).toInt()}% more expensive.',
        ));
      }
    }

    // 13. Income vs Expense Ratio Alarm
    if (currentIncome > 0 && daysPassed > 15) {
      final ratio = currentTotal / currentIncome;
      if (ratio > 0.9) {
        insights.add(Insight(
          emoji: '⚠️',
          title: 'Income Nearly Exhausted',
          description:
              'You\'ve consumed ${(ratio * 100).toInt()}% of your income with ${daysInMonth - daysPassed} days left.',
          severity: InsightSeverity.critical,
          category: InsightCategory.budget,
          actionTip:
              'Switch to essentials-only spending for the remaining days.',
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // CATEGORY 3: SAVINGS INTELLIGENCE (4 rules)
    // ═══════════════════════════════════════════════════════════

    // 14. Savings Rate
    if (currentIncome > 0 && daysPassed > 20) {
      final savingsRate =
          SpendingAnalyzer.calculateSavingsRate(currentMonthTxns);
      if (savingsRate < 20) {
        insights.add(Insight(
          emoji: '🐖',
          title: 'Low Savings Rate',
          description:
              'Savings rate is ${savingsRate.toInt()}% — below the recommended 20% minimum.',
          severity: InsightSeverity.warning,
          category: InsightCategory.savings,
          actionTip:
              'Automate a SIP on salary day to force-save before discretionary spending.',
        ));
      } else if (savingsRate >= 30) {
        insights.add(Insight(
          emoji: '🏆',
          title: 'Excellent Savings Rate',
          description:
              '${savingsRate.toInt()}% savings rate! You\'re well above the 20% guideline.',
          severity: InsightSeverity.positive,
          category: InsightCategory.savings,
        ));
      }
    }

    // 15. Emergency Fund Check
    if (currentIncome > 0) {
      final monthlyExpenses = currentTotal;
      final currentSavings = currentIncome - currentTotal;
      if (currentSavings < monthlyExpenses * 6 && daysPassed > 20) {
        insights.add(Insight(
          emoji: '🛟',
          title: 'Emergency Fund Gap',
          description:
              'You need ₹${(monthlyExpenses * 6).toInt()} (6 months\' expenses) as an emergency fund.',
          severity: InsightSeverity.info,
          category: InsightCategory.savings,
          actionTip:
              'Start with a liquid fund — even ₹5,000/month builds a safety net.',
        ));
      }
    }

    // 16. Optimal SIP Date Suggestion
    final salaryCredits =
        SpendingAnalyzer.detectSalaryCredits(currentMonthTxns);
    if (salaryCredits.isNotEmpty) {
      final salaryDate = DateTime.tryParse(salaryCredits.first['date'] ?? '');
      if (salaryDate != null) {
        final sipDate = salaryDate.day + 2; // 2 days after salary
        insights.add(Insight(
          emoji: '📅',
          title: 'Optimal SIP Date',
          description:
              'Salary detected on day ${salaryDate.day}. Set SIP auto-debit for day $sipDate — save before you spend.',
          severity: InsightSeverity.info,
          category: InsightCategory.savings,
          actionTip:
              'Move SIP debit to the ${sipDate}th for maximum savings efficiency.',
        ));
      }
    }

    // 17. Savings Improvement Streak
    if (lastTotal > 0 && currentTotal < lastTotal && daysPassed > 20) {
      final improvement =
          (((lastTotal - currentTotal) / lastTotal) * 100).toInt();
      if (improvement > 5) {
        insights.add(Insight(
          emoji: '🔥',
          title: 'Spending Down $improvement%',
          description:
              'You\'re spending ₹${(lastTotal - currentTotal).toInt()} less than last month. Keep it up!',
          severity: InsightSeverity.positive,
          category: InsightCategory.savings,
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // CATEGORY 4: INCOME & CASH FLOW (4 rules)
    // ═══════════════════════════════════════════════════════════

    // 18. Salary Credit Detection
    if (salaryCredits.isNotEmpty) {
      final salaryAmt = (salaryCredits.first['amount'] as num).toDouble();
      insights.add(Insight(
        emoji: '💵',
        title: 'Salary Credited',
        description: '₹${salaryAmt.toInt()} income detected this month.',
        severity: InsightSeverity.info,
        category: InsightCategory.income,
      ));
    }

    // 19. Multiple Income Sources
    final allCredits =
        currentMonthTxns.where((t) => t['type'] == 'Credit').toList();
    if (allCredits.length >= 3) {
      final totalCreditsAmt = SpendingAnalyzer.totalCredit(currentMonthTxns);
      insights.add(Insight(
        emoji: '💎',
        title: 'Multiple Income Streams',
        description:
            '${allCredits.length} income entries totaling ₹${totalCreditsAmt.toInt()} — diversified income is healthy.',
        severity: InsightSeverity.positive,
        category: InsightCategory.income,
      ));
    }

    // 20. Income Volatility Alert (compare to last month)
    final lastIncome = SpendingAnalyzer.totalCredit(lastMonthTxns);
    if (lastIncome > 0 && currentIncome > 0) {
      final volatility =
          ((currentIncome - lastIncome).abs() / lastIncome) * 100;
      if (volatility > 30) {
        insights.add(Insight(
          emoji: '📉',
          title: 'Income Volatility',
          description:
              'Income changed by ${volatility.toInt()}% vs last month (₹${currentIncome.toInt()} vs ₹${lastIncome.toInt()}).',
          severity: InsightSeverity.warning,
          category: InsightCategory.income,
          actionTip:
              'With volatile income, keep 8 months\' expenses as emergency fund instead of 6.',
        ));
      }
    }

    // 21. Cash Flow Gap Warning
    if (currentIncome > 0 && daysPassed > 10) {
      final projectedExpense = (currentTotal / daysPassed) * daysInMonth;
      final gap = currentIncome - projectedExpense;
      if (gap < 0) {
        insights.add(Insight(
          emoji: '🕳️',
          title: 'Cash Flow Gap',
          description:
              'Projected ₹${gap.abs().toInt()} shortfall this month at current pace.',
          severity: InsightSeverity.critical,
          category: InsightCategory.income,
          actionTip:
              'Either increase income or cut ₹${(gap.abs() / (daysInMonth - daysPassed)).toInt()}/day to balance.',
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // CATEGORY 5: LIFESTYLE & BEHAVIORAL (5 rules)
    // ═══════════════════════════════════════════════════════════

    // 22. Darshini vs Swiggy Ratio (Home Cooking Index)
    if (currentFood > 0) {
      // Infer delivery vs dine-in from transaction descriptions if available
      int deliveryCount = 0, dineCount = 0;
      for (final t in currentMonthTxns.where(
          (t) => t['category'] == 'Food & Dining' && t['type'] == 'Debit')) {
        final body = (t['body'] ?? '').toString().toLowerCase();
        if (body.contains('swiggy') ||
            body.contains('zomato') ||
            body.contains('eatsure') ||
            body.contains('box8')) {
          deliveryCount++;
        } else {
          dineCount++;
        }
      }
      if (deliveryCount > 0 && deliveryCount > dineCount * 2) {
        insights.add(Insight(
          emoji: '🏠',
          title: 'Delivery Addiction',
          description:
              '$deliveryCount food deliveries vs $dineCount other food spends. Delivery habit is expensive.',
          severity: InsightSeverity.info,
          category: InsightCategory.lifestyle,
          actionTip:
              'Each home-cooked meal saves ~₹200 vs delivery. Try meal-prepping on Sundays.',
        ));
      }
    }

    // 23. Metro vs Cab Ratio (Transit Efficiency)
    final currentTransit = currentCategories['Transit & Auto'] ?? 0;
    if (currentTransit > 2000) {
      int cabCount = 0, transitCount = 0;
      for (final t in currentMonthTxns.where(
          (t) => t['category'] == 'Transit & Auto' && t['type'] == 'Debit')) {
        final body = (t['body'] ?? '').toString().toLowerCase();
        if (body.contains('uber') ||
            body.contains('ola') ||
            body.contains('rapido')) {
          cabCount++;
        } else {
          transitCount++;
        }
      }
      if (cabCount > transitCount * 3 && cabCount > 5) {
        insights.add(Insight(
          emoji: '🚇',
          title: 'Cab Over Metro',
          description:
              '$cabCount cab rides vs $transitCount public transit. ₹${currentTransit.toInt()} on commute.',
          severity: InsightSeverity.info,
          category: InsightCategory.lifestyle,
          actionTip: 'Swapping 3 cab rides/week for metro saves ~₹2,000/month.',
        ));
      }
    }

    // 24. Late-Night Spending Pattern
    final timeDistrib =
        SpendingAnalyzer.getTimeOfDayDistribution(currentMonthTxns);
    final nightSpend = timeDistrib['night'] ?? 0;
    if (nightSpend > 0 &&
        currentTotal > 0 &&
        (nightSpend / currentTotal) > 0.15) {
      insights.add(Insight(
        emoji: '🌙',
        title: 'Late-Night Spending',
        description:
            '${((nightSpend / currentTotal) * 100).toInt()}% of spending happens between 10 PM–6 AM (₹${nightSpend.toInt()}).',
        severity: InsightSeverity.info,
        category: InsightCategory.lifestyle,
        actionTip:
            'Late-night spending is often impulsive. Try a no-UPI rule after 10 PM.',
      ));
    }

    // 25. Payday Splurge Detection
    if (salaryCredits.isNotEmpty) {
      final splurgeRatio =
          SpendingAnalyzer.firstThreeDaysSpendRatio(currentMonthTxns);
      if (splurgeRatio > 0.3 && daysPassed > 5) {
        insights.add(Insight(
          emoji: '💸',
          title: 'Payday Splurge Detected',
          description:
              '${(splurgeRatio * 100).toInt()}% of monthly spending happened in the first 3 days after salary.',
          severity: InsightSeverity.warning,
          category: InsightCategory.lifestyle,
          actionTip:
              'Before spending post-salary, transfer savings to a separate account first.',
        ));
      }
    }

    // 26. Emotional Spending Detector (high frequency + small amounts in short window)
    if (microCount >= 10) {
      final dayByDay = SpendingAnalyzer.groupByDay(currentMonthTxns);
      int highFrequencyDays = dayByDay.values.where((v) => v > 0).length;
      if (highFrequencyDays > daysPassed * 0.8) {
        insights.add(Insight(
          emoji: '🧠',
          title: 'Habitual Spending Pattern',
          description:
              'You made purchases on $highFrequencyDays of $daysPassed days — near-daily spending habit detected.',
          severity: InsightSeverity.info,
          category: InsightCategory.lifestyle,
          actionTip: 'Try 2 "no-spend days" per week to break the habit loop.',
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // CATEGORY 6: TREND ANALYSIS (4 rules)
    // ═══════════════════════════════════════════════════════════

    // 27. Month-over-Month Total Spend Trend
    if (lastTotal > 0 && daysPassed > 20) {
      final changePercent =
          (((currentTotal - lastTotal) / lastTotal) * 100).toInt();
      if (changePercent > 15) {
        insights.add(Insight(
          emoji: '📈',
          title: 'Spending Up $changePercent% MoM',
          description:
              '₹${currentTotal.toInt()} this month vs ₹${lastTotal.toInt()} last month.',
          severity: InsightSeverity.warning,
          category: InsightCategory.trend,
          actionTip:
              'Review which categories grew the most — focus cuts on the top offender.',
        ));
      } else if (changePercent < -10) {
        insights.add(Insight(
          emoji: '📉',
          title: 'Spending Down ${changePercent.abs()}% MoM',
          description:
              '₹${currentTotal.toInt()} this month vs ₹${lastTotal.toInt()} last month — great discipline!',
          severity: InsightSeverity.positive,
          category: InsightCategory.trend,
        ));
      }
    }

    // 28. Category-Wise Month-over-Month Comparison
    for (final entry in currentCategories.entries) {
      final lastVal = lastCategories[entry.key] ?? 0;
      if (lastVal > 0 && entry.value > lastVal * 2 && entry.value > 1000) {
        insights.add(Insight(
          emoji: '🔺',
          title: '${entry.key} Doubled',
          description:
              '${entry.key}: ₹${entry.value.toInt()} vs ₹${lastVal.toInt()} last month (${(((entry.value - lastVal) / lastVal) * 100).toInt()}% increase).',
          severity: InsightSeverity.warning,
          category: InsightCategory.trend,
          actionTip:
              'Investigate what changed in ${entry.key} spending this month.',
        ));
      }
    }

    // 29. Seasonal Spending Pattern
    final currentMonth = DateTime.now().month;
    if (currentMonth == 10 || currentMonth == 11) {
      insights.add(const Insight(
        emoji: '🪔',
        title: 'Festival Season Alert',
        description:
            'Diwali/Navratri season — historically a high-spending period. Budget accordingly.',
        severity: InsightSeverity.info,
        category: InsightCategory.trend,
        actionTip: 'Set a festival budget cap upfront to avoid January regret.',
      ));
    }
    if (currentMonth == 3) {
      insights.add(const Insight(
        emoji: '📋',
        title: 'Tax Season Reminder',
        description:
            'March = tax-saving deadline. Have you maximized 80C, 80D, and NPS deductions?',
        severity: InsightSeverity.info,
        category: InsightCategory.trend,
        actionTip:
            'Invest in ELSS/PPF before March 31st to save up to ₹46,800 in taxes.',
      ));
    }

    // 30. Expense Growth Rate vs Inflation Benchmark (6% annual ≈ 0.5% monthly)
    if (lastTotal > 0 && daysPassed > 20) {
      final monthlyGrowth = ((currentTotal - lastTotal) / lastTotal) * 100;
      if (monthlyGrowth > 5) {
        insights.add(Insight(
          emoji: '💹',
          title: 'Expense Growth Beats Inflation',
          description:
              'Expenses grew ${monthlyGrowth.toStringAsFixed(1)}% MoM — far above India\'s ~0.5% monthly inflation.',
          severity: InsightSeverity.warning,
          category: InsightCategory.trend,
          actionTip:
              'If expenses grow faster than inflation consistently, your real savings shrink.',
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // CATEGORY 7: POSITIVE REINFORCEMENT (3 rules)
    // ═══════════════════════════════════════════════════════════

    // 31. Savings Streak Congratulation
    if (currentIncome > 0 &&
        currentTotal < currentIncome * 0.7 &&
        daysPassed > 20) {
      insights.add(Insight(
        emoji: '🎉',
        title: 'On Track for Great Savings',
        description:
            'Only ${((currentTotal / currentIncome) * 100).toInt()}% of income spent with ${daysInMonth - daysPassed} days remaining. Impressive!',
        severity: InsightSeverity.positive,
        category: InsightCategory.reinforcement,
      ));
    }

    // 32. Under-Budget Category Celebration
    for (final entry in currentCategories.entries) {
      final lastVal = lastCategories[entry.key] ?? 0;
      if (lastVal > 1000 && entry.value < lastVal * 0.7) {
        insights.add(Insight(
          emoji: '⭐',
          title: '${entry.key} Under Control',
          description:
              '${entry.key} down to ₹${entry.value.toInt()} from ₹${lastVal.toInt()} — ${(((lastVal - entry.value) / lastVal) * 100).toInt()}% reduction!',
          severity: InsightSeverity.positive,
          category: InsightCategory.reinforcement,
        ));
        break; // One celebration is enough
      }
    }

    // 33. No Issues Detected — Give Confidence
    if (insights.isEmpty && currentMonthTxns.isNotEmpty) {
      insights.add(const Insight(
        emoji: '✅',
        title: 'Financial State Optimal',
        description:
            'No anomalies detected. Burn rate is sustainable. You\'re in control.',
        severity: InsightSeverity.positive,
        category: InsightCategory.reinforcement,
      ));
    }

    // Sort by severity: critical → warning → info → positive
    insights.sort((a, b) {
      const order = {
        InsightSeverity.critical: 0,
        InsightSeverity.warning: 1,
        InsightSeverity.info: 2,
        InsightSeverity.positive: 3,
      };
      return order[a.severity]!.compareTo(order[b.severity]!);
    });

    return insights;
  }

  /// Legacy compatibility wrapper — returns List<String> for old callers.
  static List<String> generateProphecies(
    List<Map<String, dynamic>> currentMonthTxns,
    List<Map<String, dynamic>> lastMonthTxns,
  ) {
    return generateInsights(currentMonthTxns, lastMonthTxns)
        .map((i) => i.toString())
        .toList();
  }
}
