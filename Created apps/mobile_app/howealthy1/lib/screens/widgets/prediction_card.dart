import 'package:flutter/material.dart';
class PredictionCard extends StatelessWidget {
  final dynamic prediction;
  const PredictionCard({super.key, required this.prediction});
  @override Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Prediction')));
}
