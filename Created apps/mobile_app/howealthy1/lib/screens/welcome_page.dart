import 'package:flutter/material.dart';
import 'login_page.dart';
class WelcomePage extends StatelessWidget { const WelcomePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())), child: const Text('Enter Howealthy'))));
}
