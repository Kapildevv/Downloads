import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

/// Service for WhatsApp daily spending summary integration.
///
/// Generates formatted daily spending summaries from Firestore data,
/// opens WhatsApp with pre-filled messages, and schedules reminder
/// notifications. The actual WhatsApp Business API integration
/// requires a Cloud Function (see docs/cloud_function_whatsapp.md).
class WhatsAppBotService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Daily Summary Generation ──────────────────────────────
  /// Generates a daily spending summary for the given [uid].
  /// Returns a map with category totals, overall total, and budget info.
  static Future<Map<String, dynamic>> generateDailySummary(String uid) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query today's transactions
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      // Aggregate by category
      final Map<String, double> categoryTotals = {};
      double totalSpent = 0;
      int transactionCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'Debit') {
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final category = data['category'] as String? ?? 'Other';
          categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          totalSpent += amount;
          transactionCount++;
        }
      }

      // Get monthly budget (if set)
      double? monthlyBudget;
      double monthlySpent = 0;
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        monthlyBudget = (userDoc.data()?['monthlyBudget'] as num?)?.toDouble();

        // Calculate monthly spend
        final startOfMonth = DateTime(now.year, now.month, 1);
        final monthTxns = await _db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .where('date',
                isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
            .where('type', isEqualTo: 'Debit')
            .get();

        for (var doc in monthTxns.docs) {
          monthlySpent += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }
      } catch (e) {
        debugPrint('[WhatsAppBotService] Error fetching budget: $e');
      }

      return {
        'categoryTotals': categoryTotals,
        'totalSpent': totalSpent,
        'transactionCount': transactionCount,
        'monthlyBudget': monthlyBudget,
        'monthlySpent': monthlySpent,
        'date': now,
      };
    } catch (e) {
      debugPrint('[WhatsAppBotService] Error generating summary: $e');
      return {
        'categoryTotals': <String, double>{},
        'totalSpent': 0.0,
        'transactionCount': 0,
        'monthlyBudget': null,
        'monthlySpent': 0.0,
        'date': DateTime.now(),
      };
    }
  }

  // ── Message Formatting ────────────────────────────────────
  /// Formats a daily summary map into a WhatsApp-friendly text message.
  static String formatWhatsAppMessage(Map<String, dynamic> summary) {
    final date = summary['date'] as DateTime;
    final categoryTotals = summary['categoryTotals'] as Map<String, double>;
    final totalSpent = summary['totalSpent'] as double;
    final transactionCount = summary['transactionCount'] as int;
    final monthlyBudget = summary['monthlyBudget'] as double?;
    final monthlySpent = summary['monthlySpent'] as double;

    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';

    final buffer = StringBuffer();
    buffer.writeln('📊 *HoWealthy Daily Summary* — $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━');

    if (transactionCount == 0) {
      buffer.writeln('');
      buffer.writeln('✨ No spending today! Great job saving.');
      buffer.writeln('');
    } else {
      // Category breakdown with emojis
      final categoryEmojis = {
        'Food': '🍔',
        'Travel': '🚗',
        'Shopping': '🛒',
        'Entertainment': '🎬',
        'Bills': '📱',
        'Health': '💊',
        'Education': '📚',
        'Other': '📌',
      };

      // Sort by amount (highest first)
      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sorted) {
        final emoji = categoryEmojis[entry.key] ?? '📌';
        buffer.writeln('$emoji ${entry.key}: ${_formatCurrency(entry.value)}');
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━');
      buffer.writeln(
          '💰 *Total Spent*: ${_formatCurrency(totalSpent)} ($transactionCount txns)');
    }

    if (monthlyBudget != null && monthlyBudget > 0) {
      final budgetLeft = monthlyBudget - monthlySpent;
      final budgetEmoji = budgetLeft > 0 ? '📉' : '🚨';
      buffer.writeln(
          '$budgetEmoji Budget Left: ${_formatCurrency(budgetLeft.abs())}/${_formatCurrency(monthlyBudget)}');
      if (budgetLeft <= 0) {
        buffer.writeln('⚠️ *Budget exceeded!*');
      }
    }

    buffer.writeln('');
    buffer.writeln('Track yours → howealthy.page.link/get');

    return buffer.toString();
  }

  // ── Send via WhatsApp ─────────────────────────────────────
  /// Opens WhatsApp with the formatted message for the given [phoneNumber].
  /// Phone number should include country code (e.g., "919876543210").
  static Future<bool> sendViaWhatsAppLink(
      String phoneNumber, String message) async {
    try {
      // Clean phone number
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final uri = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint('[WhatsAppBotService] Cannot launch WhatsApp URL');
        return false;
      }
    } catch (e) {
      debugPrint('[WhatsAppBotService] Error sending WhatsApp message: $e');
      return false;
    }
  }

  // ── Opt-in Management ─────────────────────────────────────
  /// Saves the user's WhatsApp opt-in preference to Firestore.
  static Future<bool> saveWhatsAppOptIn({
    required String uid,
    required String phoneNumber,
    required bool enabled,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'whatsappOptIn': {
          'enabled': enabled,
          'phoneNumber': phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[WhatsAppBotService] Error saving opt-in: $e');
      return false;
    }
  }

  /// Gets the user's WhatsApp opt-in status.
  static Future<Map<String, dynamic>?> getWhatsAppOptIn(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['whatsappOptIn'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[WhatsAppBotService] Error fetching opt-in: $e');
      return null;
    }
  }

  // ── Notification Reminder ─────────────────────────────────
  /// Schedules a daily notification at 9 PM to remind the user to check summary.
  static Future<void> scheduleNotificationReminder() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'daily_summary_channel',
        'Daily Summary',
        channelDescription: 'Daily spending summary reminder',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // Show a simple notification (for full scheduling, use flutter_local_notifications scheduling API)
      await flutterLocalNotificationsPlugin.show(
        100,
        '📊 Your Daily Summary is Ready!',
        'Tap to see how much you spent today and share it on WhatsApp.',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[WhatsAppBotService] Error scheduling notification: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  static String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    final intAmount = amount.abs().toInt();
    // Indian comma format
    if (intAmount >= 1000) {
      final str = intAmount.toString();
      final len = str.length;
      final buffer = StringBuffer();
      int commaPos = 0;
      for (int i = len - 1; i >= 0; i--) {
        buffer.write(str[i]);
        commaPos++;
        if (commaPos == 3 && i > 0) {
          buffer.write(',');
        } else if (commaPos > 3 && (commaPos - 3) % 2 == 0 && i > 0) {
          buffer.write(',');
        }
      }
      final sign = amount < 0 ? '-' : '';
      return '$sign₹${buffer.toString().split('').reversed.join()}';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
