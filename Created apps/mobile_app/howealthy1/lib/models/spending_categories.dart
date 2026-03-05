import 'package:flutter/material.dart';
import 'package:howealthy1/l10n/app_localizations.dart';

/// India-specific spending categories for Howealthy.
/// Each category has a localization key, icon, and regex keywords for SMS classification.
enum SpendingCategory {
  food,
  transit,
  utilities,
  shopping,
  investments,
  mandap,
  festival,
  gold,
  tuition,
  domesticHelp,
  medical,
  rent,
  emi,
  insurance,
  uncategorized,
}

extension SpendingCategoryExtension on SpendingCategory {
  /// Returns the localized display name for this category.
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SpendingCategory.food:
        return l10n.categoryFood;
      case SpendingCategory.transit:
        return l10n.categoryTransit;
      case SpendingCategory.utilities:
        return l10n.categoryUtilities;
      case SpendingCategory.shopping:
        return l10n.categoryShopping;
      case SpendingCategory.investments:
        return l10n.categoryInvestments;
      case SpendingCategory.mandap:
        return l10n.categoryMandap;
      case SpendingCategory.festival:
        return l10n.categoryFestival;
      case SpendingCategory.gold:
        return l10n.categoryGold;
      case SpendingCategory.tuition:
        return l10n.categoryTuition;
      case SpendingCategory.domesticHelp:
        return l10n.categoryDomesticHelp;
      case SpendingCategory.medical:
        return l10n.categoryMedical;
      case SpendingCategory.rent:
        return l10n.categoryRent;
      case SpendingCategory.emi:
        return l10n.categoryEmi;
      case SpendingCategory.insurance:
        return l10n.categoryInsurance;
      case SpendingCategory.uncategorized:
        return l10n.categoryUncategorized;
    }
  }

  /// Returns the icon for this category.
  IconData get icon {
    switch (this) {
      case SpendingCategory.food:
        return Icons.restaurant;
      case SpendingCategory.transit:
        return Icons.directions_car;
      case SpendingCategory.utilities:
        return Icons.bolt;
      case SpendingCategory.shopping:
        return Icons.shopping_bag;
      case SpendingCategory.investments:
        return Icons.trending_up;
      case SpendingCategory.mandap:
        return Icons.celebration;
      case SpendingCategory.festival:
        return Icons.temple_hindu;
      case SpendingCategory.gold:
        return Icons.diamond;
      case SpendingCategory.tuition:
        return Icons.school;
      case SpendingCategory.domesticHelp:
        return Icons.cleaning_services;
      case SpendingCategory.medical:
        return Icons.local_hospital;
      case SpendingCategory.rent:
        return Icons.home;
      case SpendingCategory.emi:
        return Icons.account_balance;
      case SpendingCategory.insurance:
        return Icons.shield;
      case SpendingCategory.uncategorized:
        return Icons.help_outline;
    }
  }

  /// Returns the internal English key used in Firestore/Hive storage (locale-independent).
  String get storageKey {
    switch (this) {
      case SpendingCategory.food:
        return 'Food & Dining';
      case SpendingCategory.transit:
        return 'Transit & Auto';
      case SpendingCategory.utilities:
        return 'Utilities & Bills';
      case SpendingCategory.shopping:
        return 'Shopping & Groceries';
      case SpendingCategory.investments:
        return 'Investments';
      case SpendingCategory.mandap:
        return 'Mandap & Venue';
      case SpendingCategory.festival:
        return 'Festival & Puja';
      case SpendingCategory.gold:
        return 'Gold & Jewellery';
      case SpendingCategory.tuition:
        return 'Tuition & Coaching';
      case SpendingCategory.domesticHelp:
        return 'Domestic Help';
      case SpendingCategory.medical:
        return 'Medical & Pharma';
      case SpendingCategory.rent:
        return 'Rent';
      case SpendingCategory.emi:
        return 'EMI & Loans';
      case SpendingCategory.insurance:
        return 'Insurance Premium';
      case SpendingCategory.uncategorized:
        return 'Uncategorized';
    }
  }

  /// Look up a SpendingCategory from a Firestore storage key.
  static SpendingCategory fromStorageKey(String key) {
    for (final cat in SpendingCategory.values) {
      if (cat.storageKey == key) return cat;
    }
    return SpendingCategory.uncategorized;
  }
}
