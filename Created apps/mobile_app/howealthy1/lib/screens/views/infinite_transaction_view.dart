import 'package:flutter/material.dart';
class InfiniteTransactionView extends StatelessWidget {
  final List<dynamic> transactions;
  const InfiniteTransactionView({super.key, required this.transactions});
  @override Widget build(BuildContext context) => const Center(child: Text('Transactions'));
}
