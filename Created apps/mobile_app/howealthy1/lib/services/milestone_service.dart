/// Enum representing the types of wealth milestones users can achieve.
enum MilestoneType {
  netWorth1L('Net Worth ₹1 Lakh', '🏆', 'I just crossed ₹1 Lakh net worth!'),
  netWorth5L('Net Worth ₹5 Lakh', '💎', 'My net worth just hit ₹5 Lakh!'),
  netWorth10L('Net Worth ₹10 Lakh', '🌟', 'I\'ve reached ₹10 Lakh net worth!'),
  netWorth25L(
      'Net Worth ₹25 Lakh', '🚀', 'Quarter crore club! ₹25 Lakh net worth!'),
  netWorth50L(
      'Net Worth ₹50 Lakh', '👑', 'Half crore! ₹50 Lakh net worth milestone!'),
  netWorth1Cr(
      'Net Worth ₹1 Crore', '🏅', 'CROREPATI! My net worth crossed ₹1 Crore!'),
  streak30(
      '30-Day Streak', '🔥', '30 days of tracking expenses without a break!'),
  budgetMaster('Budget Master', '🎯', '3 months of hitting my budget targets!'),
  firstSip('First SIP', '📈', 'Started my first SIP investment journey!'),
  fireProgress(
      'FIRE Milestone', '🔥', 'One step closer to Financial Independence!');

  final String title;
  final String emoji;
  final String shareText;

  const MilestoneType(this.title, this.emoji, this.shareText);
}

/// Data class for a detected milestone.
class Milestone {
  final MilestoneType type;
  final double value;
  final DateTime achievedAt;
  final String formattedValue;

  const Milestone({
    required this.type,
    required this.value,
    required this.achievedAt,
    required this.formattedValue,
  });
}

/// Service for detecting wealth milestones from user data.
///
/// Checks transaction data, net worth, and activity streaks to determine
/// if the user has hit a shareable milestone.
class MilestoneService {
  // ── Net Worth Milestones ──────────────────────────────────
  /// Checks the user's net worth against milestone thresholds.
  /// Returns a list of newly achieved milestones.
  static List<Milestone> checkNetWorthMilestones(
      double netWorth, Set<String> alreadyAchieved) {
    final milestones = <Milestone>[];
    final now = DateTime.now();

    final thresholds = {
      100000: MilestoneType.netWorth1L,
      500000: MilestoneType.netWorth5L,
      1000000: MilestoneType.netWorth10L,
      2500000: MilestoneType.netWorth25L,
      5000000: MilestoneType.netWorth50L,
      10000000: MilestoneType.netWorth1Cr,
    };

    for (final entry in thresholds.entries) {
      final threshold = entry.key;
      final type = entry.value;

      if (netWorth >= threshold && !alreadyAchieved.contains(type.name)) {
        milestones.add(Milestone(
          type: type,
          value: netWorth,
          achievedAt: now,
          formattedValue: _formatIndianCurrency(threshold.toDouble()),
        ));
      }
    }

    return milestones;
  }

  // ── Streak Milestones ─────────────────────────────────────
  /// Checks if the user has achieved a 30-day tracking streak.
  static Milestone? checkStreakMilestone(
      int consecutiveDays, Set<String> alreadyAchieved) {
    if (consecutiveDays >= 30 &&
        !alreadyAchieved.contains(MilestoneType.streak30.name)) {
      return Milestone(
        type: MilestoneType.streak30,
        value: consecutiveDays.toDouble(),
        achievedAt: DateTime.now(),
        formattedValue: '$consecutiveDays days',
      );
    }
    return null;
  }

  // ── Budget Master Milestone ───────────────────────────────
  /// Checks if the user hit their budget for 3 consecutive months.
  static Milestone? checkBudgetMasterMilestone(
      int consecutiveMonthsOnBudget, Set<String> alreadyAchieved) {
    if (consecutiveMonthsOnBudget >= 3 &&
        !alreadyAchieved.contains(MilestoneType.budgetMaster.name)) {
      return Milestone(
        type: MilestoneType.budgetMaster,
        value: consecutiveMonthsOnBudget.toDouble(),
        achievedAt: DateTime.now(),
        formattedValue: '$consecutiveMonthsOnBudget months',
      );
    }
    return null;
  }

  // ── First SIP Milestone ───────────────────────────────────
  /// Returns a milestone if the user recorded their first SIP.
  static Milestone? checkFirstSipMilestone(
      bool hasSip, Set<String> alreadyAchieved) {
    if (hasSip && !alreadyAchieved.contains(MilestoneType.firstSip.name)) {
      return Milestone(
        type: MilestoneType.firstSip,
        value: 1,
        achievedAt: DateTime.now(),
        formattedValue: 'Started!',
      );
    }
    return null;
  }

  // ── Generate Share Message ────────────────────────────────
  /// Generates a formatted share message for the given milestone.
  static String generateShareMessage(Milestone milestone, String referralLink) {
    return '${milestone.type.emoji} ${milestone.type.shareText}\n\n'
        '${milestone.type.emoji} Achievement: ${milestone.type.title}\n'
        '📅 ${_formatDate(milestone.achievedAt)}\n\n'
        'Track your wealth journey too!\n'
        '👉 $referralLink\n\n'
        '#HoWealthy #WealthTracking #FinancialFreedom';
  }

  // ── Helpers ───────────────────────────────────────────────
  static String _formatIndianCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)} Cr';
    }
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)} L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)} K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
