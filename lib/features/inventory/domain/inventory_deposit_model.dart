import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryDepositModel {
  const InventoryDepositModel({
    required this.id,
    required this.customerId,
    required this.pistachioTypeId,
    required this.warehouseId,
    required this.quantityKg,
    required this.date,
    required this.attributes,
    required this.isDeleted,
    required this.createdAt,
    required this.createdBy,
    required this.correctionLog,
  });

  final String id;
  final String customerId;
  final String pistachioTypeId;
  final String warehouseId;
  final double quantityKg;
  final DateTime date;
  final Map<String, dynamic> attributes;
  final bool isDeleted;
  final DateTime createdAt;
  final String createdBy;
  final List<CorrectionEntry> correctionLog;

  factory InventoryDepositModel.fromMap(
      String id, Map<String, dynamic> data) {
    return InventoryDepositModel(
      id: id,
      customerId: data['customerId'] as String,
      pistachioTypeId: data['pistachioTypeId'] as String,
      warehouseId: data['warehouseId'] as String,
      quantityKg: (data['quantityKg'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      attributes:
          Map<String, dynamic>.from(data['attributes'] as Map? ?? {}),
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String,
      correctionLog: (data['correctionLog'] as List<dynamic>? ?? [])
          .map((e) => CorrectionEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CorrectionEntry {
  const CorrectionEntry({
    required this.previousValue,
    required this.newValue,
    required this.correctedAt,
    required this.correctedBy,
  });

  final double previousValue;
  final double newValue;
  final DateTime correctedAt;
  final String correctedBy;

  factory CorrectionEntry.fromMap(Map<String, dynamic> data) {
    return CorrectionEntry(
      previousValue: (data['previousValue'] as num).toDouble(),
      newValue: (data['newValue'] as num).toDouble(),
      correctedAt: (data['correctedAt'] as Timestamp).toDate(),
      correctedBy: data['correctedBy'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'previousValue': previousValue,
        'newValue': newValue,
        'correctedAt': Timestamp.fromDate(correctedAt),
        'correctedBy': correctedBy,
      };
}
