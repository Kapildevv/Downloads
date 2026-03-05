import 'package:flutter/material.dart';
class ClairvoyanceTile extends StatelessWidget {
  final List<dynamic> insights;
  const ClairvoyanceTile({super.key, required this.insights});
  @override Widget build(BuildContext context) => const ListTile(title: Text('Insights'));
}
