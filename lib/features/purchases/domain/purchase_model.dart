import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseSource { warehouse, external }
enum PurchasePaymentMethod { cashBalance, cash }

class PurchaseModel {
  const PurchaseModel({
    required this.id,
    required this.transactionNumber,
    required this.customerId,
    required this.pistachioTypeId,
    required this.warehouseId,
    required this.quantityKg,
    required this.pricePerKgCentsAtTime,
    required this.totalAmountCents,
    required this.source,
    required this.paymentMethod,
    required this.date,
    required this.receiptId,
    required this.isCancelled,
    required this.isDeleted,
    required this.createdBy,
    this.cancellationReason,
  });

  final String id;
  final String transactionNumber;
  final String customerId;
  final String pistachioTypeId;
  final String warehouseId;
  final double quantityKg;
  final int pricePerKgCentsAtTime;
  final int totalAmountCents;
  final PurchaseSource source;
  final PurchasePaymentMethod paymentMethod;
  final DateTime date;
  final String receiptId;
  final bool isCancelled;
  final bool isDeleted;
  final String createdBy;
  final String? cancellationReason;

  factory PurchaseModel.fromMap(String id, Map<String, dynamic> data) {
    return PurchaseModel(
      id: id,
      transactionNumber: data['transactionNumber'] as String,
      customerId: data['customerId'] as String,
      pistachioTypeId: data['pistachioTypeId'] as String,
      warehouseId: data['warehouseId'] as String,
      quantityKg: (data['quantityKg'] as num).toDouble(),
      pricePerKgCentsAtTime: data['pricePerKgCentsAtTime'] as int,
      totalAmountCents: data['totalAmountCents'] as int,
      source: data['source'] == 'warehouse'
          ? PurchaseSource.warehouse
          : PurchaseSource.external,
      paymentMethod: data['paymentMethod'] == 'cash_balance'
          ? PurchasePaymentMethod.cashBalance
          : PurchasePaymentMethod.cash,
      date: (data['date'] as Timestamp).toDate(),
      receiptId: data['receiptId'] as String? ?? '',
      isCancelled: data['isCancelled'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdBy: data['createdBy'] as String,
      cancellationReason: data['cancellationReason'] as String?,
    );
  }
}
