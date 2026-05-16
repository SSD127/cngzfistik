import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/transaction_number.dart';
import '../domain/cash_movement_model.dart';

part 'cash_repository.g.dart';

class CashRepository {
  CashRepository(this._db);

  final FirebaseFirestore _db;

  /// Para girişi (Gereksinim 8.2, 8.3)
  Future<void> deposit({
    required String customerId,
    required int amountCents,
    required String description,
    required String createdBy,
  }) async {
    final movRef = _db.collection(FirestorePaths.cashMovements).doc();
    final receiptRef = _db.collection(FirestorePaths.receipts).doc();
    final counterRef = TransactionNumber.counterRef(_db, 'cash');
    final receiptCounterRef = TransactionNumber.counterRef(_db, 'receipt');
    final customerRef =
        _db.collection(FirestorePaths.customers).doc(customerId);

    await _db.runTransaction((txn) async {
      final customerDoc = await txn.get(customerRef);
      final counterDoc = await txn.get(counterRef);
      final receiptCounterDoc = await txn.get(receiptCounterRef);

      final txnNumber = TransactionNumber.generate(
          txn, counterDoc, AppConstants.cashPrefix);
      final receiptNumber = TransactionNumber.generate(
          txn, receiptCounterDoc, AppConstants.receiptPrefix);
      final now = DateTime.now();
      final customerData = customerDoc.data()!;
      final newBalance =
          (customerData['cashBalanceCents'] as int) + amountCents;

      txn.set(movRef, {
        'transactionNumber': txnNumber,
        'customerId': customerId,
        'type': 'deposit',
        'amountCents': amountCents,
        'description': description,
        'referenceId': null,
        'date': Timestamp.fromDate(now),
        'receiptId': receiptRef.id,
        'isCancelled': false,
        'createdBy': createdBy,
      });

      txn.set(receiptRef, {
        'receiptNumber': receiptNumber,
        'type': 'cash_deposit',
        'customerId': customerId,
        'customerName':
            '${customerData['firstName']} ${customerData['lastName']}',
        'date': Timestamp.fromDate(now),
        'pistachioType': null,
        'quantityKg': null,
        'pricePerKgCents': null,
        'totalAmountCents': amountCents,
        'cashBalanceAfterCents': newBalance,
        'referenceId': movRef.id,
        'createdAt': Timestamp.fromDate(now),
      });

      txn.update(customerRef, {
        'cashBalanceCents': FieldValue.increment(amountCents),
        'isDebtor': newBalance < 0,
        'updatedAt': Timestamp.fromDate(now),
      });
    });
  }

  /// Para çıkışı / ödeme (Gereksinim 8.4, 8.5, 8.6)
  Future<void> withdraw({
    required String customerId,
    required int amountCents,
    required String createdBy,
  }) async {
    final movRef = _db.collection(FirestorePaths.cashMovements).doc();
    final receiptRef = _db.collection(FirestorePaths.receipts).doc();
    final counterRef = TransactionNumber.counterRef(_db, 'cash');
    final receiptCounterRef = TransactionNumber.counterRef(_db, 'receipt');
    final customerRef =
        _db.collection(FirestorePaths.customers).doc(customerId);

    await _db.runTransaction((txn) async {
      final customerDoc = await txn.get(customerRef);
      final counterDoc = await txn.get(counterRef);
      final receiptCounterDoc = await txn.get(receiptCounterRef);

      final currentBalance =
          (customerDoc.data()!['cashBalanceCents'] as int);
      // Bakiye kontrolü (Gereksinim 8.5, Özellik 7)
      if (currentBalance < amountCents) {
        throw Exception(
            'Yetersiz bakiye. Mevcut: $currentBalance kuruş, Talep: $amountCents kuruş.');
      }

      final txnNumber = TransactionNumber.generate(
          txn, counterDoc, AppConstants.cashPrefix);
      final receiptNumber = TransactionNumber.generate(
          txn, receiptCounterDoc, AppConstants.receiptPrefix);
      final now = DateTime.now();
      final customerData = customerDoc.data()!;
      final newBalance = currentBalance - amountCents;

      txn.set(movRef, {
        'transactionNumber': txnNumber,
        'customerId': customerId,
        'type': 'withdrawal',
        'amountCents': -amountCents,
        'description': 'Para ödemesi',
        'referenceId': null,
        'date': Timestamp.fromDate(now),
        'receiptId': receiptRef.id,
        'isCancelled': false,
        'createdBy': createdBy,
      });

      txn.set(receiptRef, {
        'receiptNumber': receiptNumber,
        'type': 'cash_withdrawal',
        'customerId': customerId,
        'customerName':
            '${customerData['firstName']} ${customerData['lastName']}',
        'date': Timestamp.fromDate(now),
        'pistachioType': null,
        'quantityKg': null,
        'pricePerKgCents': null,
        'totalAmountCents': amountCents,
        'cashBalanceAfterCents': newBalance,
        'referenceId': movRef.id,
        'createdAt': Timestamp.fromDate(now),
      });

      txn.update(customerRef, {
        'cashBalanceCents': FieldValue.increment(-amountCents),
        'isDebtor': newBalance < 0,
        'updatedAt': Timestamp.fromDate(now),
      });
    });
  }

  Stream<List<CashMovementModel>> watchByCustomer(
      String customerId, {DateTime? from, DateTime? to}) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestorePaths.cashMovements)
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true);

    if (from != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => CashMovementModel.fromMap(d.id, d.data()))
        .toList());
  }
}

@Riverpod(keepAlive: true)
CashRepository cashRepository(Ref ref) {
  return CashRepository(FirebaseFirestore.instance);
}
