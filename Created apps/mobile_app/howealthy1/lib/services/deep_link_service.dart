import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'referral_service.dart';

/// Handles incoming deep links for the referral program.
///
/// Listens for App Links (Android) and Universal Links (iOS).
/// When a referral deep link is detected, it stores the code in Hive
/// for processing after the user signs up / logs in.
class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static const String _pendingReferralKey = 'pendingReferralCode';

  // ── Initialization ────────────────────────────────────────
  /// Call once during app startup (in `main.dart` after Firebase init).
  /// Listens for both the initial deep link (cold start) and subsequent
  /// links (warm start).
  static Future<void> initDeepLinks() async {
    try {
      // 1. Handle the initial link that launched the app (cold start)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // 2. Listen for subsequent links while app is running (warm start)
      _appLinks.uriLinkStream.listen(
        (Uri uri) => _handleDeepLink(uri),
        onError: (error) {
          debugPrint('[DeepLinkService] Stream error: $error');
        },
      );

      debugPrint('[DeepLinkService] Deep link listener initialized');
    } catch (e) {
      debugPrint('[DeepLinkService] Error initializing deep links: $e');
    }
  }

  // ── Deep Link Handler ─────────────────────────────────────
  /// Parses the incoming [uri] and extracts the referral code.
  /// Stores it in Hive if the user is not yet logged in, or processes
  /// it immediately if they are.
  static Future<void> _handleDeepLink(Uri uri) async {
    try {
      debugPrint('[DeepLinkService] Received deep link: $uri');

      // Only process referral links
      if (uri.host != 'howealthy.page.link') return;
      if (!uri.path.contains('/refer')) return;

      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        debugPrint('[DeepLinkService] No referral code in link');
        return;
      }

      debugPrint('[DeepLinkService] Extracted referral code: $code');

      // Check if user is already logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Process immediately
        await ReferralService.processReferral(code, currentUser.uid);
      } else {
        // Store for post-login processing
        await _storePendingReferral(code);
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Error handling deep link: $e');
    }
  }

  // ── Pending Referral Storage ──────────────────────────────
  /// Stores a referral code in Hive for processing after sign-up.
  static Future<void> _storePendingReferral(String code) async {
    try {
      final box = Hive.box('oracleBox');
      await box.put(_pendingReferralKey, code.toUpperCase());
      debugPrint('[DeepLinkService] Stored pending referral: $code');
    } catch (e) {
      debugPrint('[DeepLinkService] Error storing pending referral: $e');
    }
  }

  /// Checks for and processes any pending referral code after user login.
  /// Should be called from the post-login flow.
  static Future<void> processPendingReferral(String uid) async {
    try {
      final box = Hive.box('oracleBox');
      final pendingCode = box.get(_pendingReferralKey) as String?;

      if (pendingCode != null && pendingCode.isNotEmpty) {
        await ReferralService.processReferral(pendingCode, uid);
        await box.delete(_pendingReferralKey);
        debugPrint(
            '[DeepLinkService] Processed pending referral: $pendingCode');
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Error processing pending referral: $e');
    }
  }

  /// Returns the pending referral code if one exists, without consuming it.
  static String? getPendingReferralCode() {
    try {
      final box = Hive.box('oracleBox');
      return box.get(_pendingReferralKey) as String?;
    } catch (e) {
      debugPrint('[DeepLinkService] Error reading pending referral: $e');
      return null;
    }
  }
}
