import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/transaction_number.dart';

part 'purchases_repository.g.dart';

class PurchasesRepository {
  PurchasesRepository(this._db);

  final FirebaseFirestore _db;

  /// Alım transaction'ı (Gereksinim 7)
  Future<String> createPurchase({
    required String customerId,
    required String pistachioTypeId,
    required String warehouseId,
    required double quantityKg,
    required String source, // 'warehouse' | 'external'
    required String paymentMethod, // 'cash_balance' | 'cash'
    required String createdBy,
  }) async {
    final purchaseRef = _db.collection(FirestorePaths.purchases).doc();
    final receiptRef = _db.collection(FirestorePaths.receipts).doc();
    final counterRef = TransactionNumber.counterRef(_db, 'purchase');
    final receiptCounterRef = TransactionNumber.counterRef(_db, 'receipt');
    final customerRef = _db.collection(FirestorePaths.customers).doc(customerId);
    final typeRef = _db.collection(FirestorePaths.pistachioTypes).doc(pistachioTypeId);
    final summaryId = '${warehouseId}__$pistachioTypeId';
    final summaryRef = _db.collection(FirestorePaths.warehouseSummaries).doc(summaryId);

    await _db.runTransaction((txn) async {
      final customerDoc = await txn.get(customerRef);
      final typeDoc = await txn.get(typeRef);
      final summaryDoc = await txn.get(summaryRef);
      final counterDoc = await txn.get(counterRef);
      final receiptCounterDoc = await txn.get(receiptCounterRef);

      final typeData = typeDoc.data()!;
      final pricePerKgCents = typeData['currentPricePerKgCents'] as int;
      final totalAmountCents = (quantityKg * pricePerKgCents).round();
      final customerData = customerDoc.data()!;
      final currentBalance = customerData['cashBalanceCents'] as int;

      // Kasa bakiyesi kontrolü (Gereksinim 7.2, 7.3)
      if (paymentMethod == 'cash_balance' && currentBalance < totalAmountCents) {
        throw Exception(
            'Yetersiz kasa bakiyesi. Mevcut: ${currentBalance} kuruş, Gerekli: ${totalAmountCents} kuruş.');
      }

      // Depo stok kontrolü (warehouse alımında)
      if (source == 'warehouse') {
        final currentStock =
            (summaryDoc.data()?['totalQuantityKg'] as num?)?.toDouble() ?? 0.0;
        if (currentStock < quantityKg) {
          throw Exception('Depoda yetersiz stok: ${currentStock.toStringAsFixed(2)} kg');
        }
      }

      final purchaseNumber = TransactionNumber.generate(
          txn, counterDoc, AppConstants.purchasePrefix);
      final receiptNumber = TransactionNumber.generate(
          txn, receiptCounterDoc, AppConstants.receiptPrefix);
      final now = DateTime.now();
      final newBalance = paymentMethod == 'cash_balance'
          ? currentBalance - totalAmountCents
          : currentBalance;

      txn.set(purchaseRef, {
        'transactionNumber': purchaseNumber,
        'customerId': customerId,
        'pistachioTypeId': pistachioTypeId,
        'warehouseId': warehouseId,
        'quantityKg': quantityKg,
        'pricePerKgCentsAtTime': pricePerKgCents,
        'totalAmountCents': totalAmountCents,
        'source': source,
        'paymentMethod': paymentMethod,
        'date': Timestamp.fromDate(now),
        'receiptId': receiptRef.id,
        'isCancelled': false,
        'isDeleted': false,
        'createdBy': createdBy,
        'cancellationReason': null,
      });

      txn.set(receiptRef, {
        'receiptNumber': receiptNumber,
        'type': 'purchase',
        'customerId': customerId,
        'customerName': '${customerData['firstName']} ${customerData['lastName']}',
        'date': Timestamp.fromDate(now),
        'pistachioType': typeData['name'],
        'quantityKg': quantityKg,
        'pricePerKgCents': pricePerKgCents,
        'totalAmountCents': totalAmountCents,
        'cashBalanceAfterCents': newBalance,
        'referenceId': purchaseRef.id,
        'createdAt': Timestamp.fromDate(now),
      });

      // Kasa bakiyesi düş (kasa ödemesinde)
      if (paymentMethod == 'cash_balance') {
        txn.update(customerRef, {
          'cashBalanceCents': FieldValue.increment(-totalAmountCents),
          'isDebtor': newBalance < 0,
          'updatedAt': Timestamp.fromDate(now),
        });

        txn.set(_db.collection(FirestorePaths.cashMovements).doc(), {
          'transactionNumber': purchaseNumber,
          'customerId': customerId,
          'type': 'purchase_debit',
          'amountCents': -totalAmountCents,
          'description': 'Alım ödemesi: $purchaseNumber',
          'referenceId': purchaseRef.id,
          'date': Timestamp.fromDate(now),
          'receiptId': receiptRef.id,
          'isCancelled': false,
          'createdBy': createdBy,
        });
      }

      // Depo stoku güncelle
      if (source == 'warehouse') {
        // Depodan alım → stok düşür
        txn.update(summaryRef, {
          'totalQuantityKg': FieldValue.increment(-quantityKg),
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        // Dışarıdan alım → stok artır
        if (summaryDoc.exists) {
          txn.update(summaryRef, {
            'totalQuantityKg': FieldValue.increment(quantityKg),
            'updatedAt': Timestamp.fromDate(now),
          });
        } else {
          txn.set(summaryRef, {
            'warehouseId': warehouseId,
            'pistachioTypeId': pistachioTypeId,
            'totalQuantityKg': quantityKg,
            'updatedAt': Timestamp.fromDate(now),
          });
        }
      }

      // Stok hareketi
      txn.set(_db.collection(FirestorePaths.stockMovements).doc(), {
        'type': 'purchase',
        'warehouseId': warehouseId,
        'customerId': customerId,
        'pistachioTypeId': pistachioTypeId,
        'quantityKg': source == 'warehouse' ? -quantityKg : quantityKg,
        'referenceId': purchaseRef.id,
        'date': Timestamp.fromDate(now),
      });
    });

    return purchaseRef.id;
  }

  Stream<List<Map<String, dynamic>>> watchByCustomer(String customerId) {
    return _db
        .collection(FirestorePaths.purchases)
        .where('customerId', isEqualTo: customerId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}

@Riverpod(keepAlive: true)
PurchasesRepository purchasesRepository(Ref ref) {
  return PurchasesRepository(FirebaseFirestore.instance);
}
