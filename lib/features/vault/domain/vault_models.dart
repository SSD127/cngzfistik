import 'package:cloud_firestore/cloud_firestore.dart';

enum VaultMovementType { deposit, withdrawal }

class VaultItemModel {
  const VaultItemModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.balanceCents,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final int balanceCents;
  final DateTime updatedAt;

  factory VaultItemModel.fromMap(String id, Map<String, dynamic> data) {
    return VaultItemModel(
      id: id,
      customerId: data['customerId'] as String,
      customerName: data['customerName'] as String? ?? '',
      balanceCents: data['balanceCents'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class VaultMovementModel {
  const VaultMovementModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amountCents,
    required this.description,
    required this.date,
    required this.createdBy,
  });

  final String id;
  final String customerId;
  final VaultMovementType type;
  final int amountCents;
  final String description;
  final DateTime date;
  final String createdBy;

  String get typeLabel => type == VaultMovementType.deposit ? 'Yatırma' : 'Çekme';

  factory VaultMovementModel.fromMap(String id, Map<String, dynamic> data) {
    return VaultMovementModel(
      id: id,
      customerId: data['customerId'] as String,
      type: data['type'] == 'withdrawal'
          ? VaultMovementType.withdrawal
          : VaultMovementType.deposit,
      amountCents: (data['amountCents'] as int).abs(),
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
    );
  }
}
