import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/transaction_repository.dart';

// ── Repository Provider ──
// Single instance of TransactionRepository available app-wide via Riverpod.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// 1. Omnipresent Auth State
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. The Live Transaction Stream — now via repository pattern.
// Uses TransactionRepository instead of raw Firestore calls.
// handleError ensures network failures return an empty list, not a crash.
final transactionsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).value;

  // If no user is authenticated, the stream goes silent.
  if (user == null) return const Stream.empty();

  // Delegate to repository — all error handling is encapsulated there.
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionsStream(user.uid);
});
