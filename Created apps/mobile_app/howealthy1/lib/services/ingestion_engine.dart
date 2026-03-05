import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/categories.dart';
import '../main.dart'; // Needed to access flutterLocalNotificationsPlugin

class IngestionEngine {
  /// The entry point for the Cinematic Loader. Runs invisibly.
  static Future<void> executeRelentlessIngestion() async {
    try {
      if (!await Permission.sms.isGranted) {
        debugPrint("Operator denied SMS access. Halting ingestion pipeline.");
        return; // Gracefully exit so the app doesn't crash
      }

      final SmsQuery query = SmsQuery();
      final messages =
          await query.querySms(kinds: [SmsQueryKind.inbox], count: 1000);

      // 1. Offload regex and classification to a background Isolate
      final processedTransactions =
          await Isolate.run(() => _heavyClassificationTask(messages));

      if (processedTransactions.isEmpty) return;

      // 2. Atomic Batch Writing to Firestore (Chunked by 500)
      await _writeToFirestoreInBatches(processedTransactions);

      // 3. Fire the legacy budget exhaustion check on the main thread
      await _triggerBudgetExhaustionCheck();
    } catch (e, stack) {
      debugPrint("Ingestion pipeline failure: $e\n$stack");
      // Swallow the error — the app must not crash due to ingestion failure.
    }
  }

  // --- BACKGROUND ISOLATE (Zero UI Thread Impact) ---
  static List<Map<String, dynamic>> _heavyClassificationTask(
      List<SmsMessage> messages) {
    List<Map<String, dynamic>> processedData = [];
    // TD-7: Upgraded regex to support ₹ symbol and Indian comma notation (1,50,000.00)
    RegExp amountRegex =
        RegExp(r"(?:Rs\.?|INR|₹)\s?(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)");

    for (var msg in messages) {
      String sender = msg.address ?? "";
      if (RegExp(r'^[+0-9]+$').hasMatch(sender.replaceAll(" ", ""))) continue;

      String body = msg.body?.toLowerCase() ?? "";
      if (body.contains("lottery") || body.contains("click here")) continue;

      // Null-safe: skip messages with null body or date
      final rawBody = msg.body;
      final msgDate = msg.date;
      if (rawBody == null || msgDate == null) continue;

      var match = amountRegex.firstMatch(rawBody);
      if (match != null) {
        // Strip Indian commas before parsing (e.g., "1,50,000.00" → "150000.00")
        final rawAmount = (match.group(1) ?? '').replaceAll(',', '');
        double amount = double.tryParse(rawAmount) ?? 0;
        if (amount <= 0) continue;
        int timeBucket =
            (msgDate.millisecondsSinceEpoch / (1000 * 60 * 5)).floor();

        String type = (body.contains('credited') || body.contains('received'))
            ? "Credit"
            : "Debit";

        // TD-9: Expanded category detection to 6 categories (mirrors MlClassifierService)
        String category = _classifyCategory(body, type);

        processedData.add({
          'amount': amount,
          'category': category,
          'type': type,
          'body': _redactSmsBody(rawBody), // PII redacted — DPDP Act compliance
          'date': msgDate.toString(),
          'fingerprint':
              "${amount}_$timeBucket", // Unbreakable Deduplication Hash
        });
      }
    }
    return processedData;
  }

  /// Redacts sensitive PII from SMS bodies before storing in Firestore.
  ///
  /// Removes:
  /// - OTP / PIN / passcode digits (4–8 digit codes)
  /// - Partial card numbers (e.g. "XXXX1234" patterns)
  /// - UAN / account number fragments (6+ digit sequences after account keywords)
  ///
  /// DPDP Act 2023 §6 — Data minimization: only necessary data is stored.
  static String _redactSmsBody(String body) {
    String redacted = body;

    // 1. Redact OTP / PIN / passcode digits
    redacted = redacted.replaceAllMapped(
      RegExp(
        r'(?:otp|one.time.password|passcode|pin|verification.code)'
        r'[\s:is]*([0-9]{4,8})',
        caseSensitive: false,
      ),
      (m) => m[0]!.replaceAll(RegExp(r'[0-9]{4,8}'), '****'),
    );

    // 2. Redact masked card numbers  (e.g. XXXX1234, xx-1234, ending 4567)
    redacted = redacted.replaceAll(
      RegExp(r'(?:XX+|x{2,}|\*{2,})[\s-]?([0-9]{4})', caseSensitive: false),
      'XXXX****',
    );

    // 3. Redact standalone 6–12 digit account / UAN numbers after keywords
    redacted = redacted.replaceAllMapped(
      RegExp(
        r'(?:a/c|account|uan|vpa)[\s.#:]*([0-9]{6,12})',
        caseSensitive: false,
      ),
      (m) => m[0]!.replaceAll(RegExp(r'[0-9]{6,12}'), '######'),
    );

    return redacted;
  }

  /// Deterministic category classification using canonical AppCategories taxonomy.
  /// Expanded from 6 to 14 categories and aligned with MlClassifierService.
  static String _classifyCategory(String body, String type) {
    if (type != "Debit") return AppCategories.income;

    if (RegExp(
            r'\b(zomato|swiggy|darshini|nandhini|kfc|mcdonalds|food|restaurant|dominos|pizza|biryani|tiffin|mess|canteen|dosa)\b')
        .hasMatch(body)) {
      return AppCategories.foodDining;
    }
    if (RegExp(
            r'\b(uber|ola|rapido|namma|bmtc|kstdc|metro|auto|irctc|railway|flight|makemytrip|redbus|cab|travel|bus|train)\b')
        .hasMatch(body)) {
      return AppCategories.transitAuto;
    }
    if (RegExp(
            r'\b(bescom|bwssb|jio|airtel|vi|act|broadband|recharge|electricity|water|gas|dth|wifi|postpaid|prepaid|tatapower|adani)\b')
        .hasMatch(body)) {
      return AppCategories.utilitiesBills;
    }
    if (RegExp(
            r'\b(amazon|flipkart|myntra|blinkit|zepto|instamart|meesho|ajio|nykaa|shopping|bigbasket|dmart|grocery|supermarket)\b')
        .hasMatch(body)) {
      return AppCategories.shoppingGroceries;
    }
    if (RegExp(
            r'\b(zerodha|groww|upstox|mutual fund|sip|mf|nps|ppf|epf|investment|dividend|kuvera|smallcase|demat)\b')
        .hasMatch(body)) {
      return AppCategories.investments;
    }
    if (RegExp(
            r'\b(mandap|kalyana\s?mantapa|marriage\s?hall|wedding|venue|banquet|convention|function\s?hall|shaadi|vivah|choultry)\b')
        .hasMatch(body)) {
      return AppCategories.mandapVenue;
    }
    if (RegExp(
            r'\b(puja|pooja|festival|diwali|holi|ganesh|navratri|durga|onam|pongal|eid|christmas|temple|donation|dakshina|prasad)\b')
        .hasMatch(body)) {
      return AppCategories.festivalPuja;
    }
    if (RegExp(
            r'\b(tanishq|kalyan|malabar\s?gold|joyalukkas|jewel|gold|silver|ornament|hallmark|carat|mangalsutra|necklace)\b')
        .hasMatch(body)) {
      return AppCategories.goldJewellery;
    }
    if (RegExp(
            r'\b(tuition|coaching|byjus|unacademy|vedantu|school\s?fee|college\s?fee|exam\s?fee|education|academy|institute)\b')
        .hasMatch(body)) {
      return AppCategories.tuitionCoaching;
    }
    if (RegExp(
            r'\b(maid|domestic|servant|cook|driver\s?salary|helper|watchman|security\s?guard|gardener|nanny|housekeeping)\b')
        .hasMatch(body)) {
      return AppCategories.domesticHelp;
    }
    if (RegExp(
            r'\b(hospital|doctor|medical|pharmacy|apollo|medplus|netmeds|pharmeasy|1mg|health|diagnostic|lab\s?test|fortis|manipal)\b')
        .hasMatch(body)) {
      return AppCategories.medicalPharma;
    }
    if (RegExp(
            r'\b(rent|lease|tenant|landlord|pg\s?charge|hostel|accommodation|house\s?rent|flat\s?rent|room\s?rent)\b')
        .hasMatch(body)) {
      return AppCategories.rent;
    }
    if (RegExp(
            r'\b(emi|loan|home\s?loan|car\s?loan|personal\s?loan|bajaj\s?finserv|hdfc\s?loan|sbi\s?loan|credit\s?card\s?payment|installment)\b')
        .hasMatch(body)) {
      return AppCategories.emiLoans;
    }
    if (RegExp(
            r'\b(insurance|premium|lic|policy|health\s?insurance|term\s?plan|endowment|icici\s?prudential|hdfc\s?life|sbi\s?life|star\s?health|mediclaim)\b')
        .hasMatch(body)) {
      return AppCategories.insurancePremium;
    }

    return AppCategories.uncategorized;
  }

  // --- FIRESTORE BATCH MASTERY ---
  static Future<void> _writeToFirestoreInBatches(
      List<Map<String, dynamic>> transactions) async {
    final db = FirebaseFirestore.instance;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final collectionRef =
        db.collection('users').doc(uid).collection('transactions');

    const int batchSize = 500;
    for (int i = 0; i < transactions.length; i += batchSize) {
      try {
        WriteBatch batch = db.batch();
        int end = (i + batchSize < transactions.length)
            ? i + batchSize
            : transactions.length;
        List<Map<String, dynamic>> chunk = transactions.sublist(i, end);

        for (var txn in chunk) {
          DocumentReference docRef = collectionRef.doc(txn['fingerprint']);
          batch.set(docRef, txn, SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint("Firestore batch write failed at chunk $i: $e");
        // Continue with next batch — don't let one failure kill the pipeline
      }
    }
  }

  // --- BUDGET EXHAUSTION (Legacy Notification Hook) ---
  static Future<void> _triggerBudgetExhaustionCheck() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = FirebaseFirestore.instance;
      var alertsSnapshot =
          await db.collection('users').doc(user.uid).collection('alerts').get();
      if (alertsSnapshot.docs.isEmpty) return;

      DateTime startOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      var txns = await db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .get();

      double currentSpend = 0;
      for (var doc in txns.docs) {
        if (doc['type'] == 'Debit') {
          currentSpend += (doc['amount'] as num).toDouble();
        }
      }

      for (var doc in alertsSnapshot.docs) {
        double limit = (doc['limit'] as num).toDouble();
        List<dynamic> repeatDays = doc['repeatDays'] ?? [];

        if (repeatDays.isNotEmpty &&
            !repeatDays.contains(DateTime.now().weekday)) {
          continue;
        }

        if (currentSpend >= limit) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails('wealth_app_alerts', 'Budget Alerts',
                  importance: Importance.max, priority: Priority.high);
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);

          await flutterLocalNotificationsPlugin.show(
              0,
              "Budget Alert ⚠️",
              "You've spent ₹${currentSpend.toInt()} of your ₹${limit.toInt()} limit.",
              platformChannelSpecifics);
        }
      }
    } catch (e) {
      debugPrint("Budget exhaustion check failed: $e");
    }
  }
}
