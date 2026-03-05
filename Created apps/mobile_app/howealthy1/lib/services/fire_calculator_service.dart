import 'dart:math';
import '../models/fire_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FireCalculationResult {
  final double
      futureMonthlyExpenses; // Inflation-adjusted expenses at retirement
  final double targetCorpus; // Total corpus needed at retirement age
  final double
      requiredMonthlyInvestment; // Monthly SIP needed to reach target corpus
  final bool
      isFirePossible; // True if current Corpus covers it without investments, or if SIP is feasible
  final List<double>
      projectedCorpusByYear; // Corpus growth over years to retirement

  FireCalculationResult({
    required this.futureMonthlyExpenses,
    required this.targetCorpus,
    required this.requiredMonthlyInvestment,
    required this.isFirePossible,
    required this.projectedCorpusByYear,
  });
}

class FireCalculatorService {
  /// Calculates all FIRE metrics based on the provided [FireParameters]
  FireCalculationResult calculateFire(FireParameters params) {
    // 1. Calculate Future Expenses at Retirement (adjusted for inflation)
    final int yearsToRetirement = max(0, params.yearsToRetirement);

    // FV = PV * (1 + r)^n
    final double futureMonthlyExpenses = params.currentMonthlyExpenses *
        pow(1 + params.inflationRate, yearsToRetirement);

    final double futureAnnualExpenses = futureMonthlyExpenses * 12;

    // 2. Calculate Target Corpus
    // Using the Safe Withdrawal Rate rule (e.g., 4% rule -> 25x annual expenses)
    // Target = Annual Expenses / Safe Withdrawal Rate
    final double targetCorpus =
        futureAnnualExpenses / params.safeWithdrawalRate;

    // 3. Project Growth of Current Corpus
    // How much the current saved money will grow by retirement age
    final double futureValueOfCurrentCorpus = params.currentCorpus *
        pow(1 + params.preRetirementReturnRate, yearsToRetirement);

    // 4. Calculate the Shortfall
    final double corpusShortfall = targetCorpus - futureValueOfCurrentCorpus;

    double requiredMonthlyInvestment = 0;
    bool isFirePossible = true;

    // 5. Calculate Required Monthly Investment (SIP)
    if (corpusShortfall > 0 && yearsToRetirement > 0) {
      // Future Value of an Annuity formula:
      // FV = P * (((1 + r)^n - 1) / r) * (1 + r) -- for beginning of period
      // Solving for P (monthly payment):
      // Monthly Rate
      double r = params.preRetirementReturnRate / 12;
      double n = yearsToRetirement * 12;

      // P = FV * r / (((1 + r)^n - 1) * (1 + r))
      requiredMonthlyInvestment =
          (corpusShortfall * r) / ((pow(1 + r, n) - 1) * (1 + r));
    } else if (corpusShortfall > 0 && yearsToRetirement <= 0) {
      // Already at retirement age but short on funds
      isFirePossible = false;
    }

    // 6. Generate the projection curve
    final List<double> projectedCorpusByYear = [];
    double runningCorpus = params.currentCorpus;
    double monthlySip = requiredMonthlyInvestment;

    // Add current year
    projectedCorpusByYear.add(runningCorpus);

    for (int i = 1; i <= yearsToRetirement; i++) {
      // Grow the corpus for a year
      runningCorpus = runningCorpus * (1 + params.preRetirementReturnRate);

      // Add the SIP contributions + growth for that year
      // Approximate annual contribution FV = SIP * 12 * (1 + r/2)
      runningCorpus +=
          (monthlySip * 12) * (1 + (params.preRetirementReturnRate / 2));

      projectedCorpusByYear.add(runningCorpus);
    }

    return FireCalculationResult(
      futureMonthlyExpenses: futureMonthlyExpenses,
      targetCorpus: targetCorpus,
      requiredMonthlyInvestment: max(0, requiredMonthlyInvestment),
      isFirePossible: isFirePossible,
      projectedCorpusByYear: projectedCorpusByYear,
    );
  }
}

final fireCalculatorServiceProvider = Provider<FireCalculatorService>((ref) {
  return FireCalculatorService();
});
