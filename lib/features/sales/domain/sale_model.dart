import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  const SaleModel({
    required this.id,
    required this.transactionNumber,
    required this.customerId,
    required this.pistachioTypeId,
    required this.warehouseId,
    required this.quantityKg,
    required this.pricePerKgCentsAtTime,
    required this.innerGramRatioAtTime,
    required this.totalAmountCents,
    required this.date,
    required this.receiptId,
    required this.isCancelled,
    required this.isDeleted,
    required this.createdBy,
    this.cancellationReason,
    this.cancelledAt,
  });

  final String id;
  final String transactionNumber;
  final String customerId;
  final String pistachioTypeId;
  final String warehouseId;
  final double quantityKg;
  final int pricePerKgCentsAtTime;
  final double innerGramRatioAtTime;
  final int totalAmountCents;
  final DateTime date;
  final String receiptId;
  final bool isCancelled;
  final bool isDeleted;
  final String createdBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  factory SaleModel.fromMap(String id, Map<String, dynamic> data) {
    return SaleModel(
      id: id,
      transactionNumber: data['transactionNumber'] as String,
      customerId: data['customerId'] as String,
      pistachioTypeId: data['pistachioTypeId'] as String,
      warehouseId: data['warehouseId'] as String,
      quantityKg: (data['quantityKg'] as num).toDouble(),
      pricePerKgCentsAtTime: data['pricePerKgCentsAtTime'] as int,
      innerGramRatioAtTime: (data['innerGramRatioAtTime'] as num).toDouble(),
      totalAmountCents: data['totalAmountCents'] as int,
      date: (data['date'] as Timestamp).toDate(),
      receiptId: data['receiptId'] as String? ?? '',
      isCancelled: data['isCancelled'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdBy: data['createdBy'] as String,
      cancellationReason: data['cancellationReason'] as String?,
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }
}
