import 'package:flutter_test/flutter_test.dart';
import 'package:howealthy1/models/fire_model.dart';
import 'package:howealthy1/services/fire_calculator_service.dart';

void main() {
  group('FireCalculatorService Tests', () {
    late FireCalculatorService service;

    setUp(() {
      service = FireCalculatorService();
    });

    test('calculates FIRE metrics correctly for standard parameters', () {
      final params = FireParameters(
        currentAge: 30,
        targetRetirementAge: 50,
        lifeExpectancy: 85,
        currentMonthlyExpenses: 50000,
        currentCorpus: 0,
        inflationRate: 0.06,
        preRetirementReturnRate: 0.12,
        postRetirementReturnRate: 0.08,
        safeWithdrawalRate: 0.04,
      );

      final result = service.calculateFire(params);

      // Future Monthly Expenses = 50000 * (1.06)^20 ≈ 160356.77
      expect(result.futureMonthlyExpenses, closeTo(160356.77, 10.0));

      // Target Corpus = (160356.77 * 12) / 0.04 ≈ 48107032
      expect(result.targetCorpus, closeTo(48107032.0, 100.0));

      // With 0 current corpus, required monthly investment should be positive
      expect(result.requiredMonthlyInvestment, greaterThan(0));
      // expected around 48148 based on beginning of period compounding logic
      expect(result.requiredMonthlyInvestment, closeTo(48148, 5));

      expect(result.isFirePossible, true);

      // Projected curve should have 21 elements (year 0 to 20)
      expect(result.projectedCorpusByYear.length, 21);
    });

    test('handles already achieved FIRE target', () {
      final params = FireParameters(
        currentAge: 30,
        targetRetirementAge: 50,
        currentMonthlyExpenses: 50000,
        currentCorpus: 5000000, // Large current corpus
        preRetirementReturnRate: 0.15,
      );

      final result = service.calculateFire(params);

      // With high returns and large corpus, required investment over 20 years might be 0
      // 5M * (1.15)^20 ≈ 81.8M which is > 48.1M
      expect(result.requiredMonthlyInvestment, 0.0);
      expect(result.isFirePossible, true);
    });

    test('handles retirement age already reached with shortfall', () {
      final params = FireParameters(
        currentAge: 50,
        targetRetirementAge: 50,
        currentMonthlyExpenses: 50000,
        currentCorpus: 100000, // Very low corpus, no time left
      );

      final result = service.calculateFire(params);

      // Cannot achieve FIRE if there is a shortfall and 0 years left
      expect(result.isFirePossible, false);
      expect(result.requiredMonthlyInvestment, 0.0);
    });
  });
}
