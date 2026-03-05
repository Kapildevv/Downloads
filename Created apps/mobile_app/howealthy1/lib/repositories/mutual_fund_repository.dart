import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fund_holding.dart';
import 'base_repository.dart';

/// Encapsulates all mutual fund-related Firestore operations,
/// ensuring zero unhandled exceptions via BaseRepository try/catch.
class MutualFundRepository extends BaseRepository {
  MutualFundRepository({super.firestore});

  /// Real-time stream of all mutual fund holdings for a user.
  Stream<List<FundHolding>> getHoldingsStream(String uid) {
    return db
        .collection('users')
        .doc(uid)
        .collection('mutual_funds')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                FundHolding.fromJson(doc.data()..addAll({'id': doc.id})))
            .toList())
        .handleError((error, stackTrace) {
      debugPrint(
          '[MutualFundRepository.getHoldingsStream] Error: $error\n$stackTrace');
      return <FundHolding>[];
    });
  }

  /// Writes or updates a single fund holding
  Future<void> saveHolding(String uid, FundHolding holding) async {
    await safeQuery(
      () async {
        await db
            .collection('users')
            .doc(uid)
            .collection('mutual_funds')
            .doc(holding.id)
            .set(holding.toJson(), SetOptions(merge: true));
      },
      operationName: 'MutualFundRepository.saveHolding',
    );
  }

  /// Batch update holdings (e.g., after an import or NAV fetch)
  Future<void> saveHoldingsBatch(String uid, List<FundHolding> holdings) async {
    await safeQuery(
      () async {
        WriteBatch batch = db.batch();
        final collectionRef =
            db.collection('users').doc(uid).collection('mutual_funds');
        for (var hold in holdings) {
          batch.set(collectionRef.doc(hold.id), hold.toJson(),
              SetOptions(merge: true));
        }
        await batch.commit();
      },
      operationName: 'MutualFundRepository.saveHoldingsBatch',
    );
  }

  /// Deletes a fund holding
  Future<void> deleteHolding(String uid, String holdingId) async {
    await safeQuery(
      () async {
        await db
            .collection('users')
            .doc(uid)
            .collection('mutual_funds')
            .doc(holdingId)
            .delete();
      },
      operationName: 'MutualFundRepository.deleteHolding',
    );
  }
}

final mutualFundRepositoryProvider = Provider<MutualFundRepository>((ref) {
  return MutualFundRepository();
});
