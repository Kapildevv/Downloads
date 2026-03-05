import 'package:flutter/material.dart';
import 'oracle_dashboard.dart';
class LoginPage extends StatelessWidget { const LoginPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OracleDashboard())), child: const Text('Login via Biometrics'))));
}
