import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fund_holding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavFetchService {
  static const String amfiNavUrl =
      'https://www.amfiindia.com/spages/NAVAll.txt';

  /// Fetches the latest NAVs from AMFI.
  /// Keys are lowercase scheme names, values are the NAV doubles.
  Future<Map<String, double>> fetchLatestNavs() async {
    try {
      final response = await http.get(Uri.parse(amfiNavUrl));
      if (response.statusCode == 200) {
        return _parseAmfiData(response.body);
      } else {
        debugPrint(
            '[NavFetchService] Failed to load AMFI data, status: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('[NavFetchService] Error fetching NAVs: $e');
      return {};
    }
  }

  Map<String, double> _parseAmfiData(String data) {
    final Map<String, double> navMap = {};
    final lines = data.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(';');
      // Format: Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Net Asset Value;Date
      if (parts.length >= 5) {
        final schemeName = parts[3].trim().toLowerCase();
        final navString = parts[4].trim();
        final nav = double.tryParse(navString);
        if (schemeName.isNotEmpty && nav != null) {
          navMap[schemeName] = nav;
        }
      }
    }
    return navMap;
  }

  /// Takes an existing list of holdings and updates their currentNav
  /// and currentValue based on the latest AMFI fetch.
  Future<List<FundHolding>> updateHoldingsWithLatestNav(
      List<FundHolding> holdings) async {
    final latestNavs = await fetchLatestNavs();
    if (latestNavs.isEmpty) return holdings; // Return unchanged if fetch failed

    return holdings.map((holding) {
      final searchKey = holding.fundName.toLowerCase().trim();
      double? updatedNav = latestNavs[searchKey];

      if (updatedNav == null) {
        // Try finding a matching scheme name containing the holding's fund name
        for (var entry in latestNavs.entries) {
          // Both directions to account for slight name variations
          if (entry.key.contains(searchKey) || searchKey.contains(entry.key)) {
            updatedNav = entry.value;
            break;
          }
        }
      }

      // If we found a new NAV differing from the local one, update it
      if (updatedNav != null && updatedNav != holding.currentNav) {
        return holding.copyWith(
          currentNav: updatedNav,
          lastUpdated: DateTime.now(),
        );
      }
      return holding; // No change
    }).toList();
  }
}

final navFetchServiceProvider = Provider<NavFetchService>((ref) {
  return NavFetchService();
});
