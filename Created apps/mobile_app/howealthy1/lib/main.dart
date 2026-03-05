import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/oracle_state.dart';
import 'services/encryption_service.dart';
import 'services/secure_storage_service.dart';
import 'screens/welcome_page.dart';
import 'screens/biometric_guard.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (with error handling — fixes BUG-010)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // App can still launch in degraded mode
  }

  // 2. Activate Firebase App Check (SOC 2 Compliance)
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  } catch (e) {
    debugPrint('App Check activation failed: $e');
  }

  // 3. Initialize Notifications
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  // 4. Initialize AES-256 Encryption Engine
  await EncryptionService.initialize();

  // 5. Initialize Hive with Encrypted Storage
  await Hive.initFlutter();
  oracleBox = await SecureStorageService.openEncryptedBox('oracleBox');

  // Launch with Riverpod State Omnipresence
  runApp(const ProviderScope(child: WealthOracleApp()));
}

class WealthOracleApp extends ConsumerWidget {
  const WealthOracleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    User? user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Biometric + PIN Guard sits between app start and Cinematic Loader
      home: user != null ? const BiometricGuard() : const WelcomePage(),
    );
  }
}
