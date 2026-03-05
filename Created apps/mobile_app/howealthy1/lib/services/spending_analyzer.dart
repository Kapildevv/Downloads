/// Analytics helper utilities consumed by ClairvoyanceEngine 2.0.
/// All methods are pure functions — no side effects, no network calls.
library;

class SpendingAnalyzer {
  // ─── Grouping Utilities ───────────────────────────────────

  /// Groups transactions by category, returns {category: totalAmount}.
  static Map<String, double> groupByCategory(
    List<Map<String, dynamic>> txns, {
    String type = 'Debit',
  }) {
    final Map<String, double> result = {};
    for (final t in txns) {
      if (t['type'] != type) continue;
      final cat = t['category'] as String? ?? 'Uncategorized';
      result[cat] = (result[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    return result;
  }

  /// Groups transactions by calendar day (1–31), returns {day: totalAmount}.
  static Map<int, double> groupByDay(List<Map<String, dynamic>> txns) {
    final Map<int, double> result = {};
    for (final t in txns) {
      if (t['type'] != 'Debit') continue;
      final date = parseDate(t['date']);
      if (date == null) continue;
      result[date.day] =
          (result[date.day] ?? 0) + (t['amount'] as num).toDouble();
    }
    return result;
  }

  /// Groups debit transactions by weekday (1=Mon … 7=Sun).
  static Map<int, double> groupByWeekday(List<Map<String, dynamic>> txns) {
    final Map<int, double> result = {};
    for (final t in txns) {
      if (t['type'] != 'Debit') continue;
      final date = parseDate(t['date']);
      if (date == null) continue;
      result[date.weekday] =
          (result[date.weekday] ?? 0) + (t['amount'] as num).toDouble();
    }
    return result;
  }

  // ─── Aggregate Calculators ────────────────────────────────

  /// Total debit spend.
  static double totalDebit(List<Map<String, dynamic>> txns) {
    return txns
        .where((t) => t['type'] == 'Debit')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  /// Total credit income.
  static double totalCredit(List<Map<String, dynamic>> txns) {
    return txns
        .where((t) => t['type'] == 'Credit')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  /// Daily burn rate = total debit / days elapsed.
  static double calculateDailyBurnRate(List<Map<String, dynamic>> txns) {
    final total = totalDebit(txns);
    final daysPassed = DateTime.now().day;
    return daysPassed > 0 ? total / daysPassed : 0;
  }

  /// Savings rate = (income - expenses) / income × 100.
  static double calculateSavingsRate(List<Map<String, dynamic>> txns) {
    final income = totalCredit(txns);
    final expenses = totalDebit(txns);
    if (income <= 0) return 0;
    return ((income - expenses) / income) * 100;
  }

  // ─── Pattern Detection ────────────────────────────────────

  /// Detects salary credits: large credits (>= ₹10,000) in the first 5 days.
  static List<Map<String, dynamic>> detectSalaryCredits(
      List<Map<String, dynamic>> txns) {
    return txns.where((t) {
      if (t['type'] != 'Credit') return false;
      final amount = (t['amount'] as num).toDouble();
      if (amount < 10000) return false;
      final date = parseDate(t['date']);
      return date != null && date.day <= 5;
    }).toList();
  }

  /// Finds recurring transactions with similar amounts (±5%) to the same payee/category.
  static List<Map<String, List<Map<String, dynamic>>>>
      findRecurringTransactions(
    List<Map<String, dynamic>> txns,
  ) {
    final Map<String, List<Map<String, dynamic>>> byCategory = {};
    for (final t in txns.where((t) => t['type'] == 'Debit')) {
      final cat = t['category'] as String? ?? 'Uncategorized';
      byCategory.putIfAbsent(cat, () => []).add(t);
    }

    final List<Map<String, List<Map<String, dynamic>>>> recurring = [];
    for (final entry in byCategory.entries) {
      if (entry.value.length >= 3) {
        // Check if amounts are similar (within 5% of median)
        final amounts = entry.value
            .map((t) => (t['amount'] as num).toDouble())
            .toList()
          ..sort();
        final median = amounts[amounts.length ~/ 2];
        final consistent = entry.value.where((t) {
          final amt = (t['amount'] as num).toDouble();
          return (amt - median).abs() / median <= 0.05;
        }).toList();
        if (consistent.length >= 3) {
          recurring.add({entry.key: consistent});
        }
      }
    }
    return recurring;
  }

  /// Weekend (Sat/Sun) vs Weekday spending split.
  /// Returns {weekend: amount, weekday: amount}.
  static Map<String, double> getWeekdayWeekendSplit(
      List<Map<String, dynamic>> txns) {
    double weekend = 0, weekday = 0;
    for (final t in txns) {
      if (t['type'] != 'Debit') continue;
      final date = parseDate(t['date']);
      if (date == null) continue;
      final amount = (t['amount'] as num).toDouble();
      if (date.weekday >= 6) {
        weekend += amount;
      } else {
        weekday += amount;
      }
    }
    return {'weekend': weekend, 'weekday': weekday};
  }

  /// Distribution by time of day: morning(6-12), afternoon(12-18), evening(18-22), night(22-6).
  static Map<String, double> getTimeOfDayDistribution(
      List<Map<String, dynamic>> txns) {
    final Map<String, double> result = {
      'morning': 0,
      'afternoon': 0,
      'evening': 0,
      'night': 0
    };
    for (final t in txns) {
      if (t['type'] != 'Debit') continue;
      final date = parseDate(t['date']);
      if (date == null) continue;
      final amount = (t['amount'] as num).toDouble();
      if (date.hour >= 6 && date.hour < 12) {
        result['morning'] = result['morning']! + amount;
      } else if (date.hour >= 12 && date.hour < 18) {
        result['afternoon'] = result['afternoon']! + amount;
      } else if (date.hour >= 18 && date.hour < 22) {
        result['evening'] = result['evening']! + amount;
      } else {
        result['night'] = result['night']! + amount;
      }
    }
    return result;
  }

  /// Count of transactions in first 3 days of the month (payday splurge detection).
  static int countFirstThreeDaysTransactions(List<Map<String, dynamic>> txns) {
    return txns.where((t) {
      if (t['type'] != 'Debit') return false;
      final date = parseDate(t['date']);
      return date != null && date.day <= 3;
    }).length;
  }

  /// Spend in the first 3 days as fraction of monthly total.
  static double firstThreeDaysSpendRatio(List<Map<String, dynamic>> txns) {
    final total = totalDebit(txns);
    if (total <= 0) return 0;
    double firstThree = 0;
    for (final t in txns) {
      if (t['type'] != 'Debit') continue;
      final date = parseDate(t['date']);
      if (date != null && date.day <= 3) {
        firstThree += (t['amount'] as num).toDouble();
      }
    }
    return firstThree / total;
  }

  /// Finds the single largest debit transaction.
  static Map<String, dynamic>? findLargestTransaction(
      List<Map<String, dynamic>> txns) {
    Map<String, dynamic>? largest;
    double maxAmt = 0;
    for (final t in txns) {
      if (t['type'] != 'Debit') continue;
      final amt = (t['amount'] as num).toDouble();
      if (amt > maxAmt) {
        maxAmt = amt;
        largest = t;
      }
    }
    return largest;
  }

  /// Number of small UPI transactions (< ₹100).
  static int countMicroTransactions(List<Map<String, dynamic>> txns) {
    return txns.where((t) {
      if (t['type'] != 'Debit') return false;
      return (t['amount'] as num).toDouble() < 100;
    }).length;
  }

  /// Total of micro transactions (< ₹100).
  static double totalMicroTransactions(List<Map<String, dynamic>> txns) {
    return txns
        .where((t) =>
            t['type'] == 'Debit' && (t['amount'] as num).toDouble() < 100)
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  // ─── Internal Helpers ─────────────────────────────────────

  static DateTime? parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    return DateTime.tryParse(dateValue.toString());
  }
}
