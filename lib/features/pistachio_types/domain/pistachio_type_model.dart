import 'package:cloud_firestore/cloud_firestore.dart';

class PistachioTypeModel {
  const PistachioTypeModel({
    required this.id,
    required this.name,
    required this.defaultInnerGramRatio,
    required this.currentPricePerKgCents,
    required this.isActive,
    required this.createdAt,
    required this.attributeFields,
  });

  final String id;
  final String name;
  final double defaultInnerGramRatio;
  final int currentPricePerKgCents;
  final bool isActive;
  final DateTime createdAt;

  /// Admin'in bu cins için tanımladığı özel alanlar (örn: ["Gramaj %", "Nem %", "Boyut"])
  final List<String> attributeFields;

  factory PistachioTypeModel.fromMap(String id, Map<String, dynamic> data) {
    return PistachioTypeModel(
      id: id,
      name: data['name'] as String,
      defaultInnerGramRatio:
          (data['defaultInnerGramRatio'] as num?)?.toDouble() ?? 0.45,
      currentPricePerKgCents: data['currentPricePerKgCents'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attributeFields: List<String>.from(
          (data['attributeFields'] as List<dynamic>?) ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'defaultInnerGramRatio': defaultInnerGramRatio,
        'currentPricePerKgCents': currentPricePerKgCents,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'attributeFields': attributeFields,
      };
}

class PriceHistoryModel {
  const PriceHistoryModel({
    required this.id,
    required this.pistachioTypeId,
    required this.pricePerKgCents,
    required this.recordedAt,
    required this.recordedBy,
  });

  final String id;
  final String pistachioTypeId;
  final int pricePerKgCents;
  final DateTime recordedAt;
  final String recordedBy;

  factory PriceHistoryModel.fromMap(String id, Map<String, dynamic> data) {
    return PriceHistoryModel(
      id: id,
      pistachioTypeId: data['pistachioTypeId'] as String,
      pricePerKgCents: data['pricePerKgCents'] as int,
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      recordedBy: data['recordedBy'] as String,
    );
  }
}
