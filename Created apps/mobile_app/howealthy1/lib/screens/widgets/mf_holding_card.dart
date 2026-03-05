import 'package:flutter/material.dart';

class MfHoldingCard extends StatelessWidget {
  final dynamic holding;
  final VoidCallback onTap;

  const MfHoldingCard({super.key, required this.holding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Card(
        child: ListTile(title: Text('Holdings')),
      ),
    );
  }
}
