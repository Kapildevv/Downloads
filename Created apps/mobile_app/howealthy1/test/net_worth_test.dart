import 'package:flutter_test/flutter_test.dart';
import 'package:howealthy1/models/net_worth_item.dart';
import 'package:howealthy1/models/net_worth_summary.dart';

void main() {
  group('NetWorth Models and Summary Tests', () {
    test('NetWorthItem serializes and deserializes correctly', () {
      final now = DateTime.now();
      final item = NetWorthItem(
        id: 'test-123',
        name: 'HDFC Savings',
        value: 50000.0,
        isAsset: true,
        category: AssetCategory.cash.name,
        currency: 'INR',
        updatedAt: now,
        metadata: {'bank': 'HDFC', 'accountType': 'Savings'},
      );

      final json = item.toJson();
      expect(json['id'], 'test-123');
      expect(json['name'], 'HDFC Savings');
      expect(json['value'], 50000.0);
      expect(json['metadata']['bank'], 'HDFC');

      final deserialized = NetWorthItem.fromJson(json);
      expect(deserialized.id, 'test-123');
      expect(deserialized.name, 'HDFC Savings');
      expect(deserialized.value, 50000.0);
      expect(deserialized.isAsset, true);
    });

    test('NetWorthSummary calculates totals correctly', () {
      final items = [
        // Assets
        NetWorthItem(
            name: 'House',
            value: 5000000,
            isAsset: true,
            category: AssetCategory.realEstate.name),
        NetWorthItem(
            name: 'Mutual Funds',
            value: 1200000,
            isAsset: true,
            category: AssetCategory.mutualFund.name),
        NetWorthItem(
            name: 'Savings',
            value: 300000,
            isAsset: true,
            category: AssetCategory.cash.name),

        // Liabilities
        NetWorthItem(
            name: 'Home Loan',
            value: 3000000,
            isAsset: false,
            category: LiabilityCategory.homeLoan.name),
        NetWorthItem(
            name: 'Car Loan',
            value: 800000,
            isAsset: false,
            category: LiabilityCategory.vehicleLoan.name),
        NetWorthItem(
            name: 'Credit Card',
            value: 50000,
            isAsset: false,
            category: LiabilityCategory.creditCard.name),
      ];

      final summary = NetWorthSummary.fromItems(items);

      expect(summary.totalAssets, 5000000 + 1200000 + 300000); // 6,500,000
      expect(summary.totalLiabilities, 3000000 + 800000 + 50000); // 3,850,000
      expect(summary.netWorth, 6500000 - 3850000); // 2,650,000
    });

    test('copyWith works correctly with immutable fields', () {
      final item = NetWorthItem(
        id: 'immutable-id',
        name: 'Old Name',
        value: 100.0,
        isAsset: true,
        category: AssetCategory.cash.name,
      );

      final updated = item.copyWith(
        name: 'New Name',
        value: 200.0,
      );

      // Identity should be preserved
      expect(updated.id, 'immutable-id');
      expect(updated.isAsset, true);

      // Changed fields
      expect(updated.name, 'New Name');
      expect(updated.value, 200.0);
    });
  });
}
