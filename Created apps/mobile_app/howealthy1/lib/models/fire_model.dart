class FireParameters {
  final int currentAge;
  final int targetRetirementAge;
  final int lifeExpectancy;
  final double currentMonthlyExpenses;
  final double currentCorpus;
  final double inflationRate; // e.g. 0.06 for 6%
  final double preRetirementReturnRate; // e.g. 0.12 for 12%
  final double postRetirementReturnRate; // e.g. 0.08 for 8%
  final double safeWithdrawalRate; // e.g. 0.04 for 4%

  FireParameters({
    this.currentAge = 30,
    this.targetRetirementAge = 50,
    this.lifeExpectancy = 85,
    this.currentMonthlyExpenses = 50000,
    this.currentCorpus = 0,
    this.inflationRate = 0.06,
    this.preRetirementReturnRate = 0.12,
    this.postRetirementReturnRate = 0.08,
    this.safeWithdrawalRate = 0.04,
  });

  /// The number of years until the target retirement age
  int get yearsToRetirement => targetRetirementAge - currentAge;

  /// The number of years the corpus needs to last
  int get retirementDuration => lifeExpectancy - targetRetirementAge;

  FireParameters copyWith({
    int? currentAge,
    int? targetRetirementAge,
    int? lifeExpectancy,
    double? currentMonthlyExpenses,
    double? currentCorpus,
    double? inflationRate,
    double? preRetirementReturnRate,
    double? postRetirementReturnRate,
    double? safeWithdrawalRate,
  }) {
    return FireParameters(
      currentAge: currentAge ?? this.currentAge,
      targetRetirementAge: targetRetirementAge ?? this.targetRetirementAge,
      lifeExpectancy: lifeExpectancy ?? this.lifeExpectancy,
      currentMonthlyExpenses:
          currentMonthlyExpenses ?? this.currentMonthlyExpenses,
      currentCorpus: currentCorpus ?? this.currentCorpus,
      inflationRate: inflationRate ?? this.inflationRate,
      preRetirementReturnRate:
          preRetirementReturnRate ?? this.preRetirementReturnRate,
      postRetirementReturnRate:
          postRetirementReturnRate ?? this.postRetirementReturnRate,
      safeWithdrawalRate: safeWithdrawalRate ?? this.safeWithdrawalRate,
    );
  }
}
