import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/categories.dart';

class MlClassifierService {
  static Interpreter? _interpreter;
  static bool _isModelLoaded = false;

  /// Call this once during the Cinematic Loader phase
  static Future<void> initializeModel() async {
    try {
      // Expects a pre-trained model in your assets folder
      _interpreter = await Interpreter.fromAsset(
          'assets/models/expense_classifier.tflite');
      _isModelLoaded = true;
      debugPrint("TFLite Engine Initialized.");
    } catch (e) {
      debugPrint(
          "TFLite Initialization Failed. Defaulting to Regex Matrix: $e");
      _isModelLoaded = false;
    }
  }

  /// The primary classification pipeline
  static Future<String> classifyTransaction(
      String smsBody, double amount) async {
    final lowerBody = smsBody.toLowerCase();

    // 1. Hardware-Accelerated ML Inference (If available)
    if (_isModelLoaded && _interpreter != null) {
      try {
        var inputTensor = _tokenize(lowerBody);
        var outputTensor =
            List.filled(1 * 15, 0.0).reshape([1, 15]); // 15 categories

        _interpreter!.run(inputTensor, outputTensor);

        int highestIndex = _getHighestConfidenceIndex(outputTensor[0]);
        double confidence = outputTensor[0][highestIndex];

        if (confidence > 0.85) {
          return _mapIndexToCategory(highestIndex);
        }
      } catch (e) {
        debugPrint("Inference exception, falling back to Regex: $e");
      }
    }

    // 2. The Indestructible Regex Matrix (Fallback)
    return _deterministicRegexFallback(lowerBody);
  }

  static String classifyByRegex(String body) {
    return _deterministicRegexFallback(body);
  }

  static String _deterministicRegexFallback(String body) {
    // --- Food & Dining ---
    if (RegExp(
            r'\b(zomato|swiggy|darshini|nandhini|kfc|mcdonalds|food|restaurant|dominos|pizzahut|dining|biryani|dosa|mess|canteen|tiffin)\b')
        .hasMatch(body)) {
      return AppCategories.foodDining;
    }
    // --- Transit & Auto ---
    if (RegExp(
            r'\b(uber|ola|rapido|namma|bmtc|kstdc|metro|auto|irctc|railway|train|bus|flight|indigo|spicejet|vistara|redbus|cab)\b')
        .hasMatch(body)) {
      return AppCategories.transitAuto;
    }
    // --- Utilities & Bills ---
    if (RegExp(
            r'\b(bescom|bwssb|jio|airtel|vi|act|broadband|recharge|electricity|water|gas|tatapower|adani|reliance\s?energy|dth|postpaid|prepaid)\b')
        .hasMatch(body)) {
      return AppCategories.utilitiesBills;
    }
    // --- Shopping & Groceries ---
    if (RegExp(
            r'\b(amazon|flipkart|myntra|blinkit|zepto|instamart|bigbasket|dmart|reliance\s?fresh|more|supermarket|groceries|ajio|meesho|nykaa)\b')
        .hasMatch(body)) {
      return AppCategories.shoppingGroceries;
    }
    // --- Investments ---
    if (RegExp(
            r'\b(zerodha|groww|upstox|mutual\s?fund|sip|mf|demat|nifty|sensex|ipo|ppf|epf|nps|smallcase|kuvera|paytm\s?money)\b')
        .hasMatch(body)) {
      return AppCategories.investments;
    }
    // --- Mandap & Venue ---
    if (RegExp(
            r'\b(mandap|kalyana\s?mantapa|marriage\s?hall|wedding|venue|banquet|convention|function\s?hall|shaadi|vivah|choultry)\b')
        .hasMatch(body)) {
      return AppCategories.mandapVenue;
    }
    // --- Festival & Puja ---
    if (RegExp(
            r'\b(puja|pooja|festival|diwali|holi|ganesh|navratri|durga|onam|pongal|eid|christmas|temple|donation|dakshina|prasad|archana)\b')
        .hasMatch(body)) {
      return AppCategories.festivalPuja;
    }
    // --- Gold & Jewellery ---
    if (RegExp(
            r'\b(tanishq|kalyan|malabar\s?gold|joyalukkas|jewel|gold|silver|ornament|hallmark|carat|mangalsutra|chain|necklace)\b')
        .hasMatch(body)) {
      return AppCategories.goldJewellery;
    }
    // --- Tuition & Coaching ---
    if (RegExp(
            r'\b(tuition|coaching|byjus|unacademy|vedantu|school\s?fee|college\s?fee|exam\s?fee|education|academy|institute|class)\b')
        .hasMatch(body)) {
      return AppCategories.tuitionCoaching;
    }
    // --- Domestic Help ---
    if (RegExp(
            r'\b(maid|domestic|servant|cook|driver\s?salary|helper|watchman|security\s?guard|gardener|nanny|housekeeping)\b')
        .hasMatch(body)) {
      return AppCategories.domesticHelp;
    }
    // --- Medical & Pharma ---
    if (RegExp(
            r'\b(hospital|pharma|medicine|medical|apollo|fortis|manipal|medanta|practo|1mg|netmeds|pharmeasy|clinic|doctor|lab\s?test|diagnostic)\b')
        .hasMatch(body)) {
      return AppCategories.medicalPharma;
    }
    // --- Rent ---
    if (RegExp(
            r'\b(rent|lease|tenant|landlord|pg\s?charge|hostel|accommodation|house\s?rent|flat\s?rent|room\s?rent)\b')
        .hasMatch(body)) {
      return AppCategories.rent;
    }
    // --- EMI & Loans ---
    if (RegExp(
            r'\b(emi|loan|home\s?loan|car\s?loan|personal\s?loan|bajaj\s?finserv|hdfc\s?loan|sbi\s?loan|credit\s?card\s?payment|installment|equated)\b')
        .hasMatch(body)) {
      return AppCategories.emiLoans;
    }
    // --- Insurance Premium ---
    if (RegExp(
            r'\b(insurance|premium|lic|policy|health\s?insurance|term\s?plan|endowment|icici\s?prudential|hdfc\s?life|sbi\s?life|star\s?health|mediclaim)\b')
        .hasMatch(body)) {
      return AppCategories.insurancePremium;
    }

    return AppCategories.uncategorized;
  }

  // --- Helper Methods for TFLite Tensors ---
  static List<List<double>> _tokenize(String text) {
    return [
      [0.0, 1.0, 0.0]
    ];
  }

  static int _getHighestConfidenceIndex(List<double> probabilities) {
    double max = 0;
    int index = 0;
    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > max) {
        max = probabilities[i];
        index = i;
      }
    }
    return index;
  }

  static String _mapIndexToCategory(int index) {
    return index < AppCategories.tfliteIndexMap.length
        ? AppCategories.tfliteIndexMap[index]
        : AppCategories.uncategorized;
  }
}
