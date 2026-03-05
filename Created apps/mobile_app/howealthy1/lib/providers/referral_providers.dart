import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/referral_service.dart';
import 'data_pipeline.dart';

/// Provider that fetches or generates the current user's referral code.
/// Returns `null` if the user is not logged in or code generation fails.
final referralCodeProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return null;

  return await ReferralService.generateReferralCode(user.uid);
});

/// Provider that fetches the current user's referral statistics.
/// Returns a map with `totalReferrals`, `rewardPoints`, `referralCode`, and `referredBy`.
final referralStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    return {
      'referralCode': '',
      'totalReferrals': 0,
      'rewardPoints': 0,
      'referredBy': null,
    };
  }

  return await ReferralService.getReferralStats(user.uid);
});

/// Provider for the user's shareable referral link.
final referralLinkProvider = FutureProvider<String>((ref) async {
  final code = await ref.watch(referralCodeProvider.future);
  if (code == null || code.isEmpty) return '';
  return ReferralService.getReferralLink(code);
});

/// Provider for the display name used in share messages.
final shareNameProvider = Provider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.displayName ?? 'A HoWealthy User';
});
