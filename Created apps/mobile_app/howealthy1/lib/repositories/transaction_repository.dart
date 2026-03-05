import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';

/// Encapsulates all transaction-related Firestore operations.
///
/// Replaces raw Firestore calls scattered across IngestionEngine and
/// data_pipeline.dart with a clean, testable abstraction. Every operation
/// is wrapped in try/catch via [BaseRepository].
class TransactionRepository extends BaseRepository {
  TransactionRepository({super.firestore});

  /// Default page size for transaction streams.
  /// Prevents unbounded Firestore reads as transaction history grows.
  static const int kDefaultPageSize = 200;

  /// Returns a real-time stream of the most recent [pageSize] user transactions,
  /// ordered by date descending. Pagination prevents unbounded memory usage
  /// as transaction history grows over months.
  ///
  /// For infinite scroll, use [loadMoreTransactions] with the last document.
  Stream<List<Map<String, dynamic>>> getTransactionsStream(
    String uid, {
    int pageSize = kDefaultPageSize,
  }) {
    return db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(pageSize) // ← Prevents unbounded reads (Batch 6 — Performance)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error, stackTrace) {
      debugPrint(
          '[TransactionRepository.getTransactionsStream] Error: $error\n$stackTrace');
      return <Map<String, dynamic>>[];
    });
  }

  /// Loads the next page of transactions for infinite scroll.
  ///
  /// Pass the [lastDocument] from the previous page to get the next [pageSize] records.
  Future<List<Map<String, dynamic>>> loadMoreTransactions(
    String uid, {
    required DocumentSnapshot lastDocument,
    int pageSize = kDefaultPageSize,
  }) async {
    return safeQueryWithDefault<List<Map<String, dynamic>>>(
      () async {
        final snapshot = await db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .orderBy('date', descending: true)
            .startAfterDocument(lastDocument)
            .limit(pageSize)
            .get();
        return snapshot.docs.map((doc) => doc.data()).toList();
      },
      operationName: 'TransactionRepository.loadMoreTransactions',
      defaultValue: [],
    );
  }

  /// Writes transactions in batches of [batchSize] to Firestore.
  /// Continues to next batch on failure — never kills the pipeline.
  Future<void> writeBatch(
    String uid,
    List<Map<String, dynamic>> transactions, {
    int batchSize = 500,
  }) async {
    final collectionRef =
        db.collection('users').doc(uid).collection('transactions');

    for (int i = 0; i < transactions.length; i += batchSize) {
      try {
        WriteBatch batch = db.batch();
        int end = (i + batchSize < transactions.length)
            ? i + batchSize
            : transactions.length;
        List<Map<String, dynamic>> chunk = transactions.sublist(i, end);

        for (var txn in chunk) {
          DocumentReference docRef = collectionRef.doc(txn['fingerprint']);
          batch.set(docRef, txn, SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('[TransactionRepository.writeBatch] Batch at $i failed: $e');
        // Continue with next batch
      }
    }
  }

  /// Fetches transactions from start of current month for budget checks.
  Future<List<Map<String, dynamic>>> getMonthlyTransactions(String uid) async {
    final result = await safeQueryWithDefault<List<Map<String, dynamic>>>(
      () async {
        DateTime startOfMonth =
            DateTime(DateTime.now().year, DateTime.now().month, 1);
        final snapshot = await db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .where('date',
                isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
            .get();
        return snapshot.docs.map((doc) => doc.data()).toList();
      },
      operationName: 'TransactionRepository.getMonthlyTransactions',
      defaultValue: [],
    );
    return result;
  }
}
