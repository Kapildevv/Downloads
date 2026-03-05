import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';

/// Encapsulates all user profile Firestore operations.
///
/// Provides testable access to user profile data stored in
/// the `users/{uid}` document.
class UserRepository extends BaseRepository {
  UserRepository({super.firestore});

  /// Fetches the user profile document.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return safeQuery<Map<String, dynamic>>(
      () async {
        final doc = await db.collection('users').doc(uid).get();
        return doc.data() ?? {};
      },
      operationName: 'UserRepository.getUserProfile',
    );
  }

  /// Updates user profile fields.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await safeQuery(
      () => db.collection('users').doc(uid).set(data, SetOptions(merge: true)),
      operationName: 'UserRepository.updateUserProfile',
    );
  }
}
