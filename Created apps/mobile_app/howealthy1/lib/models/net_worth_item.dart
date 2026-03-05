import 'package:uuid/uuid.dart';

enum AssetCategory {
  realEstate,
  mutualFund,
  stock,
  fixedDeposit,
  gold,
  cash,
  crypto,
  otherAsset
}

enum LiabilityCategory {
  homeLoan,
  vehicleLoan,
  personalLoan,
  creditCard,
  otherLiability
}

class NetWorthItem {
  final String id;
  final String name;
  final double value;
  final bool isAsset;
  final String category;
  final String currency;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  NetWorthItem({
    String? id,
    required this.name,
    required this.value,
    required this.isAsset,
    required this.category,
    this.currency = 'INR',
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now(),
        metadata = metadata ?? {};

  // JSON Serialization for Firestore and Hive
  factory NetWorthItem.fromJson(Map<String, dynamic> json) {
    return NetWorthItem(
      id: json['id'] as String,
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      isAsset: json['isAsset'] as bool,
      category: json['category'] as String,
      currency: json['currency'] as String? ?? 'INR',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'isAsset': isAsset,
      'category': category,
      'currency': currency,
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  NetWorthItem copyWith({
    String? name,
    double? value,
    String? category,
    String? currency,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return NetWorthItem(
      id: id, // ID is immutable
      name: name ?? this.name,
      value: value ?? this.value,
      isAsset: isAsset, // Type is immutable
      category: category ?? this.category,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
