import 'package:flutter/material.dart';
class PnLTreemapView extends StatelessWidget {
  final Map<String, double> expenseData;
  final double totalExpense;
  const PnLTreemapView({super.key, required this.expenseData, required this.totalExpense});
  @override Widget build(BuildContext context) => const Center(child: Text('PnL Treemap'));
}
