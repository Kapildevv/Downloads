import 'package:flutter/material.dart';
class GlassCard extends StatelessWidget { 
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const GlassCard({super.key, required this.child, this.padding, this.margin});
  @override Widget build(BuildContext context) => Container(margin: margin, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)), padding: padding ?? const EdgeInsets.all(16), child: child);
}
