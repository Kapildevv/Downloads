import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'encryption_service.dart';

/// ============================================================
/// Secure Storage Service
/// Wraps Hive boxes with AES-256 encryption for SOC 2 / RBI
/// compliance. All local financial data is encrypted at rest.
/// ============================================================
class SecureStorageService {
  static const String _hiveKeyStorageKey = 'howealthy_hive_cipher_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Opens a Hive box with AES-256 encryption.
  /// The encryption key is stored in the OS secure keychain.
  static Future<Box> openEncryptedBox(String boxName) async {
    try {
      final encryptionKeyBytes = await _getOrCreateHiveCipherKey();
      return await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKeyBytes),
      );
    } catch (e) {
      // Fallback: if encrypted box fails (e.g., key rotation needed),
      // delete the old box and create a fresh encrypted one.
      // This means losing cached preferences — acceptable for security.
      await Hive.deleteBoxFromDisk(boxName);
      final encryptionKeyBytes = await _getOrCreateHiveCipherKey();
      return await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKeyBytes),
      );
    }
  }

  /// Retrieves or generates the Hive cipher key (32 bytes for AES-256).
  /// Stored in Flutter Secure Storage (Android Keystore / iOS Keychain).
  static Future<List<int>> _getOrCreateHiveCipherKey() async {
    try {
      final storedKey = await _secureStorage.read(key: _hiveKeyStorageKey);

      if (storedKey != null) {
        return base64.decode(storedKey);
      }

      // Generate a new 32-byte key
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _hiveKeyStorageKey,
        value: base64.encode(key),
      );
      return key;
    } catch (e) {
      // If secure storage is unavailable, use the EncryptionService key
      return EncryptionService.getHiveEncryptionKey();
    }
  }
}
