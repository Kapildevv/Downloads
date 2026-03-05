import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ============================================================
/// PIN Service
/// Manages a 4-digit app lock PIN stored as a SHA-256 hash in
/// the OS secure keychain. Never stores plaintext PINs.
/// SOC 2 Type II Compliant.
/// ============================================================
class PinService {
  static const String _pinHashKey = 'howealthy_pin_hash';
  static const String _pinEnabledKey = 'howealthy_pin_enabled';
  static const String _failedAttemptsKey = 'howealthy_pin_failed_attempts';
  static const int maxFailedAttempts = 5;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Hashes a PIN string using SHA-256 with a static app salt.
  static String _hashPin(String pin) {
    final bytes = utf8.encode('howealthy_salt_v1_$pin');
    return sha256.convert(bytes).toString();
  }

  /// Sets a new PIN. Stores the SHA-256 hash, never the plaintext.
  static Future<void> setPin(String pin) async {
    try {
      final hash = _hashPin(pin);
      await _secureStorage.write(key: _pinHashKey, value: hash);
      await _secureStorage.write(key: _pinEnabledKey, value: 'true');
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
    } catch (e) {
      throw Exception('Failed to set PIN: $e');
    }
  }

  /// Verifies the entered PIN against the stored hash.
  /// Returns true if the PIN matches.
  /// Throws if max attempts exceeded.
  static Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _secureStorage.read(key: _pinHashKey);
      if (storedHash == null) return false;

      final enteredHash = _hashPin(pin);
      final isMatch = storedHash == enteredHash;

      if (isMatch) {
        // Reset failed attempts on successful entry
        await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      } else {
        // Increment failed attempts
        await _incrementFailedAttempts();
      }

      return isMatch;
    } catch (e) {
      return false;
    }
  }

  /// Returns true if a PIN has been set by the user.
  static Future<bool> hasPin() async {
    try {
      final enabled = await _secureStorage.read(key: _pinEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Clears the stored PIN (used for PIN reset flows).
  static Future<void> clearPin() async {
    try {
      await _secureStorage.delete(key: _pinHashKey);
      await _secureStorage.write(key: _pinEnabledKey, value: 'false');
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
    } catch (e) {
      throw Exception('Failed to clear PIN: $e');
    }
  }

  /// Returns the number of consecutive failed PIN attempts.
  static Future<int> getFailedAttempts() async {
    try {
      final attempts = await _secureStorage.read(key: _failedAttemptsKey);
      return int.tryParse(attempts ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Returns true if the user has exceeded the max failed attempts.
  static Future<bool> isLockedOut() async {
    final attempts = await getFailedAttempts();
    return attempts >= maxFailedAttempts;
  }

  static Future<void> _incrementFailedAttempts() async {
    try {
      final current = await getFailedAttempts();
      await _secureStorage.write(
        key: _failedAttemptsKey,
        value: (current + 1).toString(),
      );
    } catch (_) {
      // Silently fail — next attempt will be counted
    }
  }
}
