import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fire_model.dart';
import 'base_repository.dart';

class FireRepository extends BaseRepository {
  FireRepository({super.firestore});

  /// Fetches saved FIRE parameters for the given user ID.
  /// If none exist, returns a default [FireParameters] object.
  Future<FireParameters> getFireParameters(String uid) async {
    final result = await safeQueryWithDefault<Map<String, dynamic>?>(
      () async {
        final doc = await db
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('fire_calculator')
            .get();
        if (doc.exists) return doc.data();
        return null;
      },
      operationName: 'FireRepository.getFireParameters',
      defaultValue: null,
    );

    if (result == null || result.isEmpty) {
      return FireParameters();
    }

    return FireParameters(
      currentAge: result['currentAge'] ?? 30,
      targetRetirementAge: result['targetRetirementAge'] ?? 50,
      lifeExpectancy: result['lifeExpectancy'] ?? 85,
      currentMonthlyExpenses:
          (result['currentMonthlyExpenses'] as num?)?.toDouble() ?? 50000,
      // currentCorpus is actively synced from NetWorthRepo, but we can store a cached one
      currentCorpus: (result['currentCorpus'] as num?)?.toDouble() ?? 0,
      inflationRate: (result['inflationRate'] as num?)?.toDouble() ?? 0.06,
      preRetirementReturnRate:
          (result['preRetirementReturnRate'] as num?)?.toDouble() ?? 0.12,
      postRetirementReturnRate:
          (result['postRetirementReturnRate'] as num?)?.toDouble() ?? 0.08,
      safeWithdrawalRate:
          (result['safeWithdrawalRate'] as num?)?.toDouble() ?? 0.04,
    );
  }

  /// Saves the user's customized FIRE parameters to Firestore.
  Future<void> saveFireParameters(String uid, FireParameters params) async {
    await safeQuery(
      () async {
        await db
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('fire_calculator')
            .set({
          'currentAge': params.currentAge,
          'targetRetirementAge': params.targetRetirementAge,
          'lifeExpectancy': params.lifeExpectancy,
          'currentMonthlyExpenses': params.currentMonthlyExpenses,
          'currentCorpus': params.currentCorpus,
          'inflationRate': params.inflationRate,
          'preRetirementReturnRate': params.preRetirementReturnRate,
          'postRetirementReturnRate': params.postRetirementReturnRate,
          'safeWithdrawalRate': params.safeWithdrawalRate,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      },
      operationName: 'FireRepository.saveFireParameters',
    );
  }
}

final fireRepositoryProvider = Provider<FireRepository>((ref) {
  return FireRepository();
});

// A placeholder notifier for the integration layer, tying FireRepository
// to the actual NetWorth value.
class FireParametersNotifier extends StateNotifier<AsyncValue<FireParameters>> {
  final FireRepository _repo;
  final String _uid;

  FireParametersNotifier(this._repo, this._uid) : super(const AsyncLoading()) {
    _loadParams();
  }

  Future<void> _loadParams() async {
    try {
      final params = await _repo.getFireParameters(_uid);
      state = AsyncData(params);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateParams(FireParameters newParams) async {
    // Optimistic UI update
    state = AsyncData(newParams);

    // Background persist
    await _repo.saveFireParameters(_uid, newParams);
  }
}

// In a real app, 'uid' should be injected dynamically.
final fireParamsProvider =
    StateNotifierProvider<FireParametersNotifier, AsyncValue<FireParameters>>(
        (ref) {
  final repo = ref.watch(fireRepositoryProvider);
  return FireParametersNotifier(repo, 'current_user_id');
});
