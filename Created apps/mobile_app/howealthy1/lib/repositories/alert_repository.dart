import 'base_repository.dart';

/// Encapsulates all alert/budget-related Firestore operations.
///
/// Extracted from the monolithic IngestionEngine._triggerBudgetExhaustionCheck
/// to enable testability and separation of concerns.
class AlertRepository extends BaseRepository {
  AlertRepository({super.firestore});

  /// Fetches all budget alert configurations for a user.
  Future<List<Map<String, dynamic>>> getAlerts(String uid) async {
    final result = await safeQueryWithDefault<List<Map<String, dynamic>>>(
      () async {
        final snapshot =
            await db.collection('users').doc(uid).collection('alerts').get();
        return snapshot.docs.map((doc) => doc.data()).toList();
      },
      operationName: 'AlertRepository.getAlerts',
      defaultValue: [],
    );
    return result;
  }
}
