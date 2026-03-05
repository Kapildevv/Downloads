import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Base repository providing common Firestore error handling.
///
/// All repositories extend this to get standardized try/catch wrappers,
/// ensuring zero unhandled exceptions from database operations.
abstract class BaseRepository {
  final FirebaseFirestore _db;

  BaseRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  /// Wraps a Firestore operation in try/catch and returns null on failure.
  Future<T?> safeQuery<T>(
    Future<T> Function() operation, {
    required String operationName,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      debugPrint('[$operationName] Firestore error: $e\n$stack');
      return null;
    }
  }

  /// Wraps a Firestore operation in try/catch and returns a default value on failure.
  Future<T> safeQueryWithDefault<T>(
    Future<T> Function() operation, {
    required String operationName,
    required T defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      debugPrint('[$operationName] Firestore error: $e\n$stack');
      return defaultValue;
    }
  }
}
