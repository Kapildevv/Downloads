import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fund_holding.dart';
import '../repositories/mutual_fund_repository.dart';

class SipTrackerService {
  final MutualFundRepository mfRepo;

  SipTrackerService(this.mfRepo);

  /// Analyzes a user's holdings and returns a list of SIPs due within [daysThreshold].
  Future<List<FundHolding>> getUpcomingSips(String uid,
      {int daysThreshold = 3}) async {
    try {
      // Get the current state of holdings
      final holdings = await mfRepo.getHoldingsStream(uid).first;

      final upcoming = <FundHolding>[];
      final now = DateTime.now();

      for (var holding in holdings) {
        if (holding.isSipActive &&
            holding.sipDate != null &&
            holding.sipDate! >= 1 &&
            holding.sipDate! <= 31) {
          int sipDay = holding.sipDate!;

          // Determine the next SIP date. Handle months with fewer days safely.
          int targetMonth = now.month;
          int targetYear = now.year;

          DateTime nextSipDate;
          try {
            nextSipDate = DateTime(targetYear, targetMonth, sipDay);
          } catch (_) {
            // Roll over to the last day of the month if sipDay > exact days in month
            nextSipDate = DateTime(targetYear, targetMonth + 1, 0);
          }

          // If the SIP date has already passed this month, look at next month
          if (nextSipDate.isBefore(DateTime(now.year, now.month, now.day))) {
            targetMonth++;
            if (targetMonth > 12) {
              targetMonth = 1;
              targetYear++;
            }
            try {
              nextSipDate = DateTime(targetYear, targetMonth, sipDay);
            } catch (_) {
              nextSipDate = DateTime(targetYear, targetMonth + 1, 0);
            }
          }

          final difference = nextSipDate
              .difference(DateTime(now.year, now.month, now.day))
              .inDays;
          if (difference >= 0 && difference <= daysThreshold) {
            upcoming.add(holding);
          }
        }
      }
      return upcoming;
    } catch (e, stack) {
      debugPrint(
          '[SipTrackerService] Error checking upcoming SIPs: $e\n$stack');
      return [];
    }
  }

  /// Hooks up upcoming SIPs to the notification system.
  Future<void> scheduleSipReminders(String uid) async {
    final upcoming = await getUpcomingSips(uid);
    for (var sip in upcoming) {
      debugPrint(
          '[SipTrackerService] REMINDER: SIP of ₹${sip.sipAmount ?? 0} for ${sip.fundName} due soon.');
      // NOTE: Hook into `flutter_local_notifications` here to schedule local push alerts.
    }
  }
}

final sipTrackerServiceProvider = Provider<SipTrackerService>((ref) {
  final mfRepo = ref.watch(mutualFundRepositoryProvider);
  return SipTrackerService(mfRepo);
});
