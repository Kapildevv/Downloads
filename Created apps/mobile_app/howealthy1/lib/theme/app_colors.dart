import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1E1E1E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color income = Colors.greenAccent;
  static const Color expense = Colors.redAccent;
  static const Color savings = Colors.tealAccent;
  static const Color premium = Colors.amberAccent;
  static const Color error = Colors.red;
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  static const Color darkTextTertiary = Colors.white54;
  static const Color lightTextPrimary = Colors.black;
  static const Color lightTextSecondary = Colors.black87;
  static const Color lightTextTertiary = Colors.black54;

  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color darkDivider = Colors.white24;
  static const Color lightDivider = Colors.black26;
  static const Color darkBg = Colors.black;
  static const Color lightBg = Colors.white;
  static const Color primaryGold = Colors.orange;
  static const Color primaryTealAccent = Colors.tealAccent;
  static const Color primaryTeal = Colors.teal;
  static const LinearGradient darkCardGradient =
      LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)]);
  static const LinearGradient premiumGradient =
      LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
  static const LinearGradient incomeGradient =
      LinearGradient(colors: [Colors.greenAccent, Colors.teal]);
  static const LinearGradient expenseGradient =
      LinearGradient(colors: [Colors.redAccent, Colors.deepOrange]);
  static Color forCategory(String category) {
    return Colors.tealAccent;
  }
}
