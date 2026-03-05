import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'milestone_service.dart';

/// Centralized service for tracking growth and marketing metrics.
///
/// Logs events related to referrals, social sharing, WhatsApp subscriptions,
/// and daily active usage. This feeds into the CEO dashboard reporting.
/// All calls are non-blocking and wrap inner errors to prevent UI crashes.
class GrowthMetricsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _metricsCollection = 'analytics';

  // ── Referral Events ───────────────────────────────────────
  /// Tracks when a user generates or copies their referral link.
  static Future<void> trackReferralGenerated(String uid) async {
    await _logEvent('referral_generated', uid, {});
  }

  /// Tracks when a referral successfully converts (new user signs up).
  static Future<void> trackReferralConverted(
      String referrerUid, String newUid) async {
    await _logEvent('referral_converted', referrerUid, {
      'newUserId': newUid,
    });
  }

  // ── Social Share Events ───────────────────────────────────
  /// Tracks when a user shares a milestone card.
  static Future<void> trackMilestoneShared(
      String uid, MilestoneType type, String platform) async {
    await _logEvent('milestone_shared', uid, {
      'milestoneType': type.name,
      'platform': platform, // 'whatsapp', 'instagram', 'twitter', 'other'
    });
  }

  // ── WhatsApp Bot Events ───────────────────────────────────
  /// Tracks when a user opts into the WhatsApp daily summary.
  static Future<void> trackWhatsAppOptIn(String uid, bool isOptingIn) async {
    await _logEvent(
        isOptingIn ? 'whatsapp_opt_in' : 'whatsapp_opt_out', uid, {});
  }

  /// Tracks when a daily summary is successfully generated and sent/scheduled.
  static Future<void> trackSummaryGenerated(
      String uid, int transactionCount) async {
    await _logEvent('daily_summary_generated', uid, {
      'transactionCount': transactionCount,
    });
  }

  // ── DAU / Retention Events ────────────────────────────────
  /// Tracks a Daily Active User event. Should be called on app launch for authenticated users.
  static Future<void> trackDailyActiveUser(String uid) async {
    // We only want to log this once per day per user to save writes.
    // In a production scenario, you'd use a local cache or distinct event stream.
    // Here we use a generic event log.
    await _logEvent('dau_login', uid, {});
  }

  // ── Internal Logger ───────────────────────────────────────
  static Future<void> _logEvent(
      String eventName, String uid, Map<String, dynamic> parameters) async {
    try {
      await _db
          .collection(_metricsCollection)
          .doc('growth')
          .collection('events')
          .add({
        'eventName': eventName,
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'parameters': parameters,
      });
      debugPrint('[GrowthMetrics] Logged: $eventName for user $uid');
    } catch (e) {
      debugPrint('[GrowthMetrics] Error logging custom event $eventName: $e');
    }
  }
}
