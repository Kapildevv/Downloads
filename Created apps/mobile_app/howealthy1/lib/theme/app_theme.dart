import 'package:flutter/material.dart';
import 'app_colors.dart';
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.background, elevation: 0),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.savings,
      secondary: AppColors.income,
      error: AppColors.error,
      surface: AppColors.surface,
    ),
  );
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0),
    colorScheme: const ColorScheme.light(
      primary: Colors.teal,
      secondary: Colors.green,
      error: Colors.red,
      surface: Colors.white,
    ),
  );
}
