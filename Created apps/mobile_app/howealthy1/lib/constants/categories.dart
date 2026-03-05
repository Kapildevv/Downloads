/// ============================================================
/// Howealthy — Canonical Category Taxonomy v1.0
///
/// SINGLE SOURCE OF TRUTH for all transaction category names.
/// All services (IngestionEngine, MlClassifierService, AnalyticsEngine,
/// ClairvoyanceEngine, peer benchmarks) MUST import from this file.
///
/// Adding a new category? Add it here ONLY. Never hardcode category
/// strings anywhere else in the codebase.
/// ============================================================
library;

class AppCategories {
  AppCategories._(); // Non-instantiable

  // ── Core spending categories ────────────────────────────────
  static const String foodDining = 'Food & Dining';
  static const String transitAuto = 'Transit & Auto';
  static const String utilitiesBills = 'Utilities & Bills';
  static const String shoppingGroceries = 'Shopping & Groceries';
  static const String investments = 'Investments';

  // ── India-specific categories ───────────────────────────────
  static const String mandapVenue = 'Mandap & Venue';
  static const String festivalPuja = 'Festival & Puja';
  static const String goldJewellery = 'Gold & Jewellery';
  static const String tuitionCoaching = 'Tuition & Coaching';
  static const String domesticHelp = 'Domestic Help';
  static const String medicalPharma = 'Medical & Pharma';
  static const String rent = 'Rent';
  static const String emiLoans = 'EMI & Loans';
  static const String insurancePremium = 'Insurance Premium';

  // ── Credit / Income ─────────────────────────────────────────
  static const String income = 'Income';

  // ── Fallback ─────────────────────────────────────────────────
  static const String uncategorized = 'Uncategorized';

  /// Ordered list for TFLite index → category mapping.
  /// Index position is the model output neuron index.
  /// IMPORTANT: Do not reorder — it will break the TFLite classifier.
  static const List<String> tfliteIndexMap = [
    foodDining, // 0
    transitAuto, // 1
    utilitiesBills, // 2
    shoppingGroceries, // 3
    investments, // 4
    mandapVenue, // 5
    festivalPuja, // 6
    goldJewellery, // 7
    tuitionCoaching, // 8
    domesticHelp, // 9
    medicalPharma, // 10
    rent, // 11
    emiLoans, // 12
    insurancePremium, // 13
    uncategorized, // 14
  ];

  /// All valid debit category values — used for Firestore rule validation.
  static const List<String> allDebitCategories = [
    foodDining,
    transitAuto,
    utilitiesBills,
    shoppingGroceries,
    investments,
    mandapVenue,
    festivalPuja,
    goldJewellery,
    tuitionCoaching,
    domesticHelp,
    medicalPharma,
    rent,
    emiLoans,
    insurancePremium,
    uncategorized,
  ];
}
