import 'package:flutter/foundation.dart';
import 'gemini_service.dart';
import 'clairvoyance_engine.dart';
import 'spending_analyzer.dart';

/// OracleChatService — Orchestrates conversational Q&A.
///
/// Prepares financial context from transaction data, injects
/// ClairvoyanceEngine insights, and manages conversation flow.
class OracleChatService {
  /// Builds a financial context summary to inject into Gemini prompts.
  static String buildFinancialContext(
    List<Map<String, dynamic>> currentMonthTxns,
    List<Map<String, dynamic>> lastMonthTxns,
  ) {
    try {
      final totalExpense = SpendingAnalyzer.totalDebit(currentMonthTxns);
      final totalIncome = SpendingAnalyzer.totalCredit(currentMonthTxns);
      final savingsRate =
          SpendingAnalyzer.calculateSavingsRate(currentMonthTxns);
      final burnRate =
          SpendingAnalyzer.calculateDailyBurnRate(currentMonthTxns);
      final categories = SpendingAnalyzer.groupByCategory(currentMonthTxns);

      // Generate insights to include
      final insights =
          ClairvoyanceEngine.generateInsights(currentMonthTxns, lastMonthTxns);
      final topInsights = insights
          .take(5)
          .map((i) => '- ${i.title}: ${i.description}')
          .join('\n');

      // Anonymized category breakdown
      final catBreakdown = categories.entries
          .map((e) => '  ${e.key}: ₹${e.value.toInt()}')
          .join('\n');

      return '''
Monthly Income: ₹${totalIncome.toInt()}
Monthly Expenses: ₹${totalExpense.toInt()}
Daily Burn Rate: ₹${burnRate.toInt()}/day
Savings Rate: ${savingsRate.toStringAsFixed(1)}%
Days Elapsed: ${DateTime.now().day}

Category Breakdown:
$catBreakdown

Key Insights:
$topInsights''';
    } catch (e) {
      debugPrint('Failed to build financial context: $e');
      return 'Financial data temporarily unavailable.';
    }
  }

  /// Sends a user message to Oracle with financial context.
  static Future<String> askOracle(
    String userMessage,
    List<Map<String, dynamic>> currentMonthTxns,
    List<Map<String, dynamic>> lastMonthTxns,
  ) async {
    final context = buildFinancialContext(currentMonthTxns, lastMonthTxns);
    return GeminiService.sendMessage(userMessage, financialContext: context);
  }

  /// Quick suggestion chips for the chat UI.
  static List<String> get suggestions => const [
        'How much did I spend on food?',
        'Am I saving enough?',
        'Can I afford a vacation?',
        'How can I reduce my expenses?',
        'Should I invest more in SIPs?',
        'What\'s my biggest expense?',
        'Am I on track for FIRE?',
        'Tax saving tips for this year',
      ];
}
