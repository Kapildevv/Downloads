import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Service managing the in-app referral program.
///
/// Handles referral code generation, link creation, processing incoming
/// referrals, and tracking referral statistics. All Firestore calls are
/// wrapped in try/catch per the zero-unhandled-exceptions rule.
class ReferralService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Constants ──────────────────────────────────────────────
  static const String _referralCollection = 'referrals';
  static const String _usersCollection = 'users';
  static const String _deepLinkHost = 'howealthy.page.link';
  static const int _referralCodeLength = 8;
  static const int _referrerRewardPoints = 50;
  static const int _refereeRewardPoints = 25;

  // ── Referral Code Generation ──────────────────────────────
  /// Generates a deterministic, unique 8-char referral code from [uid].
  /// Stores it in Firestore and returns the code.
  /// Returns `null` on failure.
  static Future<String?> generateReferralCode(String uid) async {
    try {
      // Check if user already has a code
      final userDoc = await _db.collection(_usersCollection).doc(uid).get();
      final existingCode = userDoc.data()?['referralCode'] as String?;
      if (existingCode != null && existingCode.isNotEmpty) {
        return existingCode;
      }

      // Generate deterministic code from UID hash
      final hash = sha256.convert(utf8.encode('howealthy_$uid')).toString();
      final code = hash.substring(0, _referralCodeLength).toUpperCase();

      // Store in user document
      await _db.collection(_usersCollection).doc(uid).set({
        'referralCode': code,
        'referralCodeCreatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[ReferralService] Generated code $code for uid $uid');
      return code;
    } catch (e) {
      debugPrint('[ReferralService] Error generating referral code: $e');
      return null;
    }
  }

  // ── Deep Link Creation ────────────────────────────────────
  /// Creates a shareable referral link embedding the [code].
  static String getReferralLink(String code) {
    return 'https://$_deepLinkHost/refer?code=$code';
  }

  /// Creates a pre-formatted WhatsApp share message with the referral link.
  static String getWhatsAppShareMessage(String code, String userName) {
    final link = getReferralLink(code);
    return '🏦 Hey! I use HoWealthy to track my expenses & build wealth. '
        'Join me and get ₹25 reward points!\n\n'
        '👉 $link\n\n'
        '— $userName';
  }

  /// Creates a pre-formatted SMS share message.
  static String getSmsShareMessage(String code) {
    final link = getReferralLink(code);
    return 'Track your money like a pro! Join HoWealthy: $link';
  }

  // ── Process Incoming Referrals ────────────────────────────
  /// Validates [code] and credits both the referrer and the new user [newUserUid].
  /// Returns `true` if the referral was successfully processed.
  static Future<bool> processReferral(String code, String newUserUid) async {
    try {
      // 1. Find the referrer by code
      final referrerQuery = await _db
          .collection(_usersCollection)
          .where('referralCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (referrerQuery.docs.isEmpty) {
        debugPrint('[ReferralService] Invalid referral code: $code');
        return false;
      }

      final referrerUid = referrerQuery.docs.first.id;

      // 2. Prevent self-referral
      if (referrerUid == newUserUid) {
        debugPrint('[ReferralService] Self-referral blocked for $newUserUid');
        return false;
      }

      // 3. Check if this user was already referred
      final existingReferral = await _db
          .collection(_referralCollection)
          .where('refereeUid', isEqualTo: newUserUid)
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        debugPrint('[ReferralService] User $newUserUid already referred');
        return false;
      }

      // 4. Create the referral record & credit both parties (batch write)
      final batch = _db.batch();

      // Referral record
      final referralDoc = _db.collection(_referralCollection).doc();
      batch.set(referralDoc, {
        'referrerUid': referrerUid,
        'refereeUid': newUserUid,
        'code': code.toUpperCase(),
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Credit referrer
      batch.update(_db.collection(_usersCollection).doc(referrerUid), {
        'rewardPoints': FieldValue.increment(_referrerRewardPoints),
        'totalReferrals': FieldValue.increment(1),
      });

      // Credit referee
      batch.update(_db.collection(_usersCollection).doc(newUserUid), {
        'rewardPoints': FieldValue.increment(_refereeRewardPoints),
        'referredBy': referrerUid,
      });

      await batch.commit();
      debugPrint(
          '[ReferralService] Referral processed: $referrerUid → $newUserUid');
      return true;
    } catch (e) {
      debugPrint('[ReferralService] Error processing referral: $e');
      return false;
    }
  }

  // ── Referral Statistics ───────────────────────────────────
  /// Returns referral stats for the given [uid].
  /// Returns a map with `totalReferrals`, `rewardPoints`, and `referralCode`.
  static Future<Map<String, dynamic>> getReferralStats(String uid) async {
    try {
      final userDoc = await _db.collection(_usersCollection).doc(uid).get();
      final data = userDoc.data() ?? {};

      final referralsQuery = await _db
          .collection(_referralCollection)
          .where('referrerUid', isEqualTo: uid)
          .get();

      return {
        'referralCode': data['referralCode'] ?? '',
        'totalReferrals': referralsQuery.docs.length,
        'rewardPoints': data['rewardPoints'] ?? 0,
        'referredBy': data['referredBy'],
      };
    } catch (e) {
      debugPrint('[ReferralService] Error fetching stats: $e');
      return {
        'referralCode': '',
        'totalReferrals': 0,
        'rewardPoints': 0,
        'referredBy': null,
      };
    }
  }

  /// Stream of referral documents for real-time leaderboard updates.
  static Stream<QuerySnapshot> referralStream(String uid) {
    return _db
        .collection(_referralCollection)
        .where('referrerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
