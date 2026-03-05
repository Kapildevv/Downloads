import 'net_worth_item.dart';

class NetWorthSummary {
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final String currency;

  NetWorthSummary({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    this.currency = 'INR',
  });

  factory NetWorthSummary.fromItems(List<NetWorthItem> items) {
    double assets = 0;
    double liabilities = 0;

    for (var item in items) {
      if (item.isAsset) {
        assets += item.value;
      } else {
        liabilities += item.value;
      }
    }

    return NetWorthSummary(
      totalAssets: assets,
      totalLiabilities: liabilities,
      netWorth: assets - liabilities,
    );
  }
}
