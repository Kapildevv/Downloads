import 'package:uuid/uuid.dart';

class FundHolding {
  final String id;
  final String fundName;
  final String? folioNumber;
  final double units;
  final double averageNav;
  final double currentNav;
  final double investedAmount;
  final double currentValue; // Computed locally based on units and currentNav
  final DateTime lastUpdated;
  final bool isSipActive;
  final double? sipAmount;
  final int? sipDate;

  FundHolding({
    String? id,
    required this.fundName,
    this.folioNumber,
    required this.units,
    required this.averageNav,
    required this.currentNav,
    required this.investedAmount,
    DateTime? lastUpdated,
    this.isSipActive = false,
    this.sipAmount,
    this.sipDate,
  })  : id = id ?? const Uuid().v4(),
        currentValue = units * currentNav,
        lastUpdated = lastUpdated ?? DateTime.now();

  double get absoluteReturn => currentValue - investedAmount;
  double get returnPercentage =>
      investedAmount > 0 ? (absoluteReturn / investedAmount) * 100 : 0.0;

  factory FundHolding.fromJson(Map<String, dynamic> json) {
    return FundHolding(
      id: json['id'] as String?,
      fundName: json['fundName'] as String,
      folioNumber: json['folioNumber'] as String?,
      units: (json['units'] as num).toDouble(),
      averageNav: (json['averageNav'] as num).toDouble(),
      currentNav: (json['currentNav'] as num).toDouble(),
      investedAmount: (json['investedAmount'] as num).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      isSipActive: json['isSipActive'] as bool? ?? false,
      sipAmount: json['sipAmount'] != null
          ? (json['sipAmount'] as num).toDouble()
          : null,
      sipDate: json['sipDate'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fundName': fundName,
      'folioNumber': folioNumber,
      'units': units,
      'averageNav': averageNav,
      'currentNav': currentNav,
      'investedAmount': investedAmount,
      'currentValue': currentValue, // Stored for easier querying/analytics
      'lastUpdated': lastUpdated.toIso8601String(),
      'isSipActive': isSipActive,
      'sipAmount': sipAmount,
      'sipDate': sipDate,
    };
  }

  FundHolding copyWith({
    String? fundName,
    String? folioNumber,
    double? units,
    double? averageNav,
    double? currentNav,
    double? investedAmount,
    DateTime? lastUpdated,
    bool? isSipActive,
    double? sipAmount,
    int? sipDate,
  }) {
    return FundHolding(
      id: id,
      fundName: fundName ?? this.fundName,
      folioNumber: folioNumber ?? this.folioNumber,
      units: units ?? this.units,
      averageNav: averageNav ?? this.averageNav,
      currentNav: currentNav ?? this.currentNav,
      investedAmount: investedAmount ?? this.investedAmount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSipActive: isSipActive ?? this.isSipActive,
      sipAmount: sipAmount ?? this.sipAmount,
      sipDate: sipDate ?? this.sipDate,
    );
  }
}
