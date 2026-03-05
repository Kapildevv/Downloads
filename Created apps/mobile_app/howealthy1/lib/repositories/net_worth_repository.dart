import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/net_worth_item.dart';

// Dummy implementation to satisfy compilation until UI/UX thread implements it
class NetWorthNotifier extends StateNotifier<AsyncValue<List<NetWorthItem>>> {
  NetWorthNotifier() : super(const AsyncData([]));

  Future<void> saveItem(NetWorthItem item) async {}
  Future<void> deleteItem(String id) async {}
}

final netWorthProvider =
    StateNotifierProvider<NetWorthNotifier, AsyncValue<List<NetWorthItem>>>(
        (ref) {
  return NetWorthNotifier();
});
