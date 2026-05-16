import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.cashBalanceCents,
    required this.isDebtor,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final int cashBalanceCents;
  final bool isDebtor;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  String get fullName => '$firstName $lastName';

  factory CustomerModel.fromMap(String id, Map<String, dynamic> data) {
    return CustomerModel(
      id: id,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      phone: data['phone'] as String? ?? '',
      cashBalanceCents: data['cashBalanceCents'] as int? ?? 0,
      isDebtor: data['isDebtor'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'cashBalanceCents': cashBalanceCents,
      'isDebtor': isDebtor,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  CustomerModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    int? cashBalanceCents,
    bool? isDebtor,
    bool? isDeleted,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return CustomerModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      cashBalanceCents: cashBalanceCents ?? this.cashBalanceCents,
      isDebtor: isDebtor ?? this.isDebtor,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
