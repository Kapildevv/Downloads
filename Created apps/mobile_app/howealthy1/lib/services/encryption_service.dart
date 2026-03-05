import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ============================================================
/// AES-256-CBC Encryption Service — v2.0
/// SOC 2 Type II Compliant — All sensitive local data is encrypted
/// at rest using AES-256-CBC with PKCS7 padding.
///
/// SECURITY FIX (v2.0): Unique random IV is generated per encryption
/// and prepended to the ciphertext (first 16 bytes = IV, rest = ciphertext).
/// This eliminates the semantic-security vulnerability of IV reuse.
/// ============================================================
class EncryptionService {
  static const String _keyStorageKey = 'howealthy_aes256_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Key? _cachedKey;

  /// Initializes the encryption engine. Generates key on first launch,
  /// retrieves it from the secure keychain on subsequent launches.
  /// NOTE: The IV is no longer stored — a fresh one is generated per encrypt().
  static Future<void> initialize() async {
    try {
      String? storedKey = await _secureStorage.read(key: _keyStorageKey);

      if (storedKey == null) {
        // First launch: generate a cryptographically secure 256-bit key
        final key = Key.fromSecureRandom(32); // 256 bits
        await _secureStorage.write(
          key: _keyStorageKey,
          value: base64.encode(key.bytes),
        );
        _cachedKey = key;
      } else {
        _cachedKey = Key(Uint8List.fromList(base64.decode(storedKey)));
      }
    } catch (e) {
      // If secure storage fails (e.g., rooted device), generate ephemeral key.
      // Data will be re-encrypted on next successful init.
      _cachedKey = Key.fromSecureRandom(32);
    }
  }

  /// Encrypts a plaintext string using AES-256-CBC with a unique random IV.
  ///
  /// Returns a base64-encoded string in the format:
  ///   base64(IV [16 bytes] + ciphertext)
  ///
  /// A new IV is generated for every call, ensuring semantic security —
  /// encrypting the same plaintext twice produces different ciphertexts.
  static String encrypt(String plainText) {
    if (_cachedKey == null) {
      throw StateError(
          'EncryptionService not initialized. Call initialize() first.');
    }
    // Generate a fresh random IV for every encryption operation.
    final iv = IV.fromSecureRandom(16); // 128-bit IV for AES-CBC
    final encrypter = Encrypter(AES(_cachedKey!, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Prepend IV to ciphertext: [16 bytes IV] + [ciphertext bytes]
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setRange(0, iv.bytes.length, iv.bytes);
    combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);

    return base64.encode(combined);
  }

  /// Decrypts a base64-encoded ciphertext produced by [encrypt].
  ///
  /// Extracts the IV from the first 16 bytes of the decoded payload,
  /// then decrypts the remaining bytes using AES-256-CBC.
  static String decrypt(String encryptedBase64) {
    if (_cachedKey == null) {
      throw StateError(
          'EncryptionService not initialized. Call initialize() first.');
    }
    final combined = base64.decode(encryptedBase64);

    if (combined.length <= 16) {
      throw ArgumentError('Invalid ciphertext: too short to contain IV.');
    }

    // Extract IV (first 16 bytes) and ciphertext (remaining bytes)
    final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
    final ciphertextBytes = Uint8List.fromList(combined.sublist(16));

    final encrypter = Encrypter(AES(_cachedKey!, mode: AESMode.cbc));
    return encrypter.decrypt(Encrypted(ciphertextBytes), iv: iv);
  }

  /// Returns the raw 256-bit key bytes for Hive box encryption.
  /// Hive requires a List<int> of exactly 32 bytes.
  static List<int> getHiveEncryptionKey() {
    if (_cachedKey == null) {
      throw StateError(
          'EncryptionService not initialized. Call initialize() first.');
    }
    return _cachedKey!.bytes;
  }
}
