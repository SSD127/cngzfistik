import 'package:cloud_firestore/cloud_firestore.dart';

enum CashMovementType {
  deposit,
  withdrawal,
  saleCredit,
  purchaseDebit,
  reversal,
}

class CashMovementModel {
  const CashMovementModel({
    required this.id,
    required this.transactionNumber,
    required this.customerId,
    required this.type,
    required this.amountCents,
    required this.description,
    required this.date,
    required this.isCancelled,
    required this.createdBy,
    this.referenceId,
    this.receiptId,
  });

  final String id;
  final String transactionNumber;
  final String customerId;
  final CashMovementType type;
  final int amountCents;
  final String description;
  final DateTime date;
  final bool isCancelled;
  final String createdBy;
  final String? referenceId;
  final String? receiptId;

  factory CashMovementModel.fromMap(String id, Map<String, dynamic> data) {
    return CashMovementModel(
      id: id,
      transactionNumber: data['transactionNumber'] as String? ?? '',
      customerId: data['customerId'] as String,
      type: _typeFromString(data['type'] as String),
      amountCents: data['amountCents'] as int,
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isCancelled: data['isCancelled'] as bool? ?? false,
      createdBy: data['createdBy'] as String,
      referenceId: data['referenceId'] as String?,
      receiptId: data['receiptId'] as String?,
    );
  }

  static CashMovementType _typeFromString(String type) => switch (type) {
        'deposit' => CashMovementType.deposit,
        'withdrawal' => CashMovementType.withdrawal,
        'sale_credit' => CashMovementType.saleCredit,
        'purchase_debit' => CashMovementType.purchaseDebit,
        _ => CashMovementType.reversal,
      };

  String get typeLabel => switch (type) {
        CashMovementType.deposit => 'Para Girişi',
        CashMovementType.withdrawal => 'Para Çıkışı',
        CashMovementType.saleCredit => 'Satış Geliri',
        CashMovementType.purchaseDebit => 'Alım Ödemesi',
        CashMovementType.reversal => 'İptal/Düzeltme',
      };
}
