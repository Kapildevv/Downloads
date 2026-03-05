import 'package:flutter_test/flutter_test.dart';
import 'package:howealthy1/services/whatsapp_bot_service.dart';

void main() {
  group('WhatsAppBotService Tests', () {
    test('formatWhatsAppMessage formats exactly as expected', () {
      final summary = {
        'categoryTotals': {
          'Food': 450.0,
          'Travel': 200.0,
          'Shopping': 1200.0,
        },
        'totalSpent': 1850.0,
        'transactionCount': 5,
        'monthlyBudget': 8000.0,
        'monthlySpent': 1850.0,
        'date': DateTime(2026, 3, 1),
      };

      final message = WhatsAppBotService.formatWhatsAppMessage(summary);

      expect(message, contains('📊 *HoWealthy Daily Summary* — 1 Mar 2026'));
      expect(message, contains('🍔 Food: ₹450'));
      expect(message, contains('🛒 Shopping: ₹1,200')); // Indian comma testing
      expect(message, contains('💰 *Total Spent*: ₹1,850 (5 txns)'));
      expect(message, contains('📉 Budget Left: ₹6,150/₹8,000'));
      expect(message, contains('howealthy.page.link/get'));
    });

    test('formatWhatsAppMessage formats zero-spending days properly', () {
      final summary = {
        'categoryTotals': <String, double>{},
        'totalSpent': 0.0,
        'transactionCount': 0,
        'monthlyBudget': 8000.0,
        'monthlySpent': 1000.0,
        'date': DateTime(2026, 3, 2),
      };

      final message = WhatsAppBotService.formatWhatsAppMessage(summary);

      expect(message, contains('✨ No spending today! Great job saving.'));
      expect(message, isNot(contains('Total Spent'))); // Should skip breakdown
      expect(message, contains('📉 Budget Left: ₹7,000/₹8,000'));
    });

    test('formatWhatsAppMessage displays over-budget warning', () {
      final summary = {
        'categoryTotals': {'Shopping': 5000.0},
        'totalSpent': 5000.0,
        'transactionCount': 1,
        'monthlyBudget': 8000.0,
        'monthlySpent': 9000.0, // Exceeded
        'date': DateTime(2026, 3, 3),
      };

      final message = WhatsAppBotService.formatWhatsAppMessage(summary);

      expect(message, contains('🚨 Budget Left: ₹1,000/₹8,000'));
      expect(message, contains('⚠️ *Budget exceeded!*'));
    });
  });
}
