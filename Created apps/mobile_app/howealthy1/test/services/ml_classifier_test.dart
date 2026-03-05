// ml_classifier_test.dart
//
// ISOLATED TEST FILE — Kept separate from ai_models_test.dart because
// tflite_flutter v0.10.4 has a known SDK incompatibility that causes a
// compile-time failure in certain Dart SDK versions:
//   Error: 'UnmodifiableUint8ListView' isn't defined for the type 'Tensor'
//
// This file tests ONLY the pure-Dart classifyByRegex() path which does not
// trigger TFLite initialization. The TFLite inference path is tested via
// integration tests only.
//
// ACTION REQUIRED: Upgrade tflite_flutter to v0.10.4+1 or higher once
// a version compatible with the current Dart SDK is published.

import 'package:flutter_test/flutter_test.dart';
import 'package:howealthy1/services/ml_classifier_service.dart';
import 'package:howealthy1/constants/categories.dart';

void main() {
  group('MlClassifierService — Regex Fallback (isolated)', () {
    test('identifies Food & Dining merchants', () {
      expect(MlClassifierService.classifyByRegex('paid zomato'),
          AppCategories.foodDining);
      expect(MlClassifierService.classifyByRegex('swiggy order delivered'),
          AppCategories.foodDining);
    });

    test('identifies Medical & Pharma merchants', () {
      expect(MlClassifierService.classifyByRegex('apollo pharmacy'),
          AppCategories.medicalPharma);
      expect(MlClassifierService.classifyByRegex('netmeds delivery'),
          AppCategories.medicalPharma);
    });

    test('identifies Shopping & Groceries', () {
      expect(MlClassifierService.classifyByRegex('amazon order'),
          AppCategories.shoppingGroceries);
    });

    test('identifies Investments', () {
      expect(MlClassifierService.classifyByRegex('zerodha funds'),
          AppCategories.investments);
    });

    test('identifies Transit & Auto', () {
      expect(MlClassifierService.classifyByRegex('uber ride'),
          AppCategories.transitAuto);
    });

    test('identifies Insurance Premium', () {
      expect(MlClassifierService.classifyByRegex('lic premium paid'),
          AppCategories.insurancePremium);
    });

    test('returns Uncategorized for unknown merchants', () {
      expect(MlClassifierService.classifyByRegex('random text'),
          AppCategories.uncategorized);
    });
  });
}
