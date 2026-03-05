import 'package:flutter/material.dart';
import 'welcome_page.dart';
class CinematicLoader extends StatefulWidget { const CinematicLoader({super.key}); @override State<CinematicLoader> createState() => _S(); }
class _S extends State<CinematicLoader> {
  @override void initState() { super.initState(); Future.delayed(const Duration(seconds: 2), () { if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomePage())); }); }
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)));
}
