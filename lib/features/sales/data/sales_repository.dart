import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/transaction_number.dart';

part 'sales_repository.g.dart';

class SalesRepository {
  SalesRepository(this._db);

  final FirebaseFirestore _db;

  /// Satış transaction'ı (Gereksinim 6, 14, 15, Özellik 8)
  /// [pricePerKgCents]: iç gramı başına TL kuruş (müşteriye özel, elle girilir)
  /// [innerGramRatio]: iç gram oranı (0.0–1.0, örn: 0.45 = %45 iç)
  Future<String> createSale({
    required String customerId,
    required String pistachioTypeId,
    required String warehouseId,
    required double quantityKg,
    required int pricePerKgCents,
    required double innerGramRatio,
    required String createdBy,
  }) async {
    final saleRef = _db.collection(FirestorePaths.sales).doc();
    final cashRef = _db.collection(FirestorePaths.cashMovements).doc();
    final stockRef = _db.collection(FirestorePaths.stockMovements).doc();
    final receiptRef = _db.collection(FirestorePaths.receipts).doc();
    final counterRef = TransactionNumber.counterRef(_db, 'sale');
    final receiptCounterRef = TransactionNumber.counterRef(_db, 'receipt');
    final customerRef = _db.collection(FirestorePaths.customers).doc(customerId);
    final typeRef = _db.collection(FirestorePaths.pistachioTypes).doc(pistachioTypeId);
    final summaryId = '${warehouseId}__$pistachioTypeId';
    final summaryRef = _db.collection(FirestorePaths.warehouseSummaries).doc(summaryId);

    await _db.runTransaction((txn) async {
      // --- Okuma aşaması ---
      final customerDoc = await txn.get(customerRef);
      final typeDoc = await txn.get(typeRef);
      final summaryDoc = await txn.get(summaryRef);
      final counterDoc = await txn.get(counterRef);
      final receiptCounterDoc = await txn.get(receiptCounterRef);

      // Stok kontrolü (Gereksinim 6.3, Özellik 7)
      final currentStock =
          (summaryDoc.data()?['totalQuantityKg'] as num?)?.toDouble() ?? 0.0;
      if (currentStock < quantityKg) {
        throw Exception(
            'Yetersiz stok. Mevcut: ${currentStock.toStringAsFixed(2)} kg');
      }

      final typeData = typeDoc.data()!;

      // Tutar hesaplama: miktar × iç oran × fiyat/kg (Gereksinim 6.2, Özellik 6)
      final totalAmountCents = Currency.calculateSaleAmountCents(
          quantityKg, pricePerKgCents, innerGramRatio);

      final saleNumber =
          TransactionNumber.generate(txn, counterDoc, AppConstants.salePrefix);
      final receiptNumber = TransactionNumber.generate(
          txn, receiptCounterDoc, AppConstants.receiptPrefix);

      final now = DateTime.now();
      final customerData = customerDoc.data()!;
      final newCashBalance =
          (customerData['cashBalanceCents'] as int) + totalAmountCents;

      // --- Yazma aşaması (Gereksinim 14.1) ---
      txn.set(saleRef, {
        'transactionNumber': saleNumber,
        'customerId': customerId,
        'pistachioTypeId': pistachioTypeId,
        'warehouseId': warehouseId,
        'quantityKg': quantityKg,
        'pricePerKgCentsAtTime': pricePerKgCents,
        'innerGramRatioAtTime': innerGramRatio,
        'totalAmountCents': totalAmountCents,
        'date': Timestamp.fromDate(now),
        'receiptId': receiptRef.id,
        'isCancelled': false,
        'isDeleted': false,
        'createdBy': createdBy,
        'cancellationReason': null,
        'cancelledAt': null,
      });

      txn.set(cashRef, {
        'transactionNumber': saleNumber,
        'customerId': customerId,
        'type': 'sale_credit',
        'amountCents': totalAmountCents,
        'description': 'Satış: $saleNumber',
        'referenceId': saleRef.id,
        'date': Timestamp.fromDate(now),
        'receiptId': receiptRef.id,
        'isCancelled': false,
        'createdBy': createdBy,
      });

      txn.set(stockRef, {
        'type': 'sale',
        'warehouseId': warehouseId,
        'customerId': customerId,
        'pistachioTypeId': pistachioTypeId,
        'quantityKg': -quantityKg,
        'referenceId': saleRef.id,
        'date': Timestamp.fromDate(now),
      });

      txn.set(receiptRef, {
        'receiptNumber': receiptNumber,
        'type': 'sale',
        'customerId': customerId,
        'customerName':
            '${customerData['firstName']} ${customerData['lastName']}',
        'date': Timestamp.fromDate(now),
        'pistachioType': typeData['name'],
        'quantityKg': quantityKg,
        'pricePerKgCents': pricePerKgCents,
        'totalAmountCents': totalAmountCents,
        'cashBalanceAfterCents': newCashBalance,
        'referenceId': saleRef.id,
        'createdAt': Timestamp.fromDate(now),
      });

      // Müşteri bakiyesi güncelle
      txn.update(customerRef, {
        'cashBalanceCents': FieldValue.increment(totalAmountCents),
        'isDebtor': newCashBalance < 0,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Depo stoku düşür (Gereksinim 15.4, Özellik 10)
      txn.update(summaryRef, {
        'totalQuantityKg': FieldValue.increment(-quantityKg),
        'updatedAt': Timestamp.fromDate(now),
      });
    });

    return saleRef.id;
  }

  /// İptal / ters kayıt (Gereksinim 24, Özellik 13)
  Future<void> cancelSale({
    required String saleId,
    required String reason,
    required String cancelledBy,
  }) async {
    final saleRef = _db.collection(FirestorePaths.sales).doc(saleId);
    final reversalCashRef = _db.collection(FirestorePaths.cashMovements).doc();
    final reversalStockRef = _db.collection(FirestorePaths.stockMovements).doc();

    await _db.runTransaction((txn) async {
      final saleDoc = await txn.get(saleRef);
      if (!saleDoc.exists) throw Exception('Satış bulunamadı.');
      final data = saleDoc.data()!;
      if (data['isCancelled'] as bool) {
        throw Exception('Bu satış zaten iptal edilmiş.');
      }

      final customerId = data['customerId'] as String;
      final warehouseId = data['warehouseId'] as String;
      final pistachioTypeId = data['pistachioTypeId'] as String;
      final totalAmountCents = data['totalAmountCents'] as int;
      final quantityKg = (data['quantityKg'] as num).toDouble();
      final now = DateTime.now();
      final summaryId = '${warehouseId}__$pistachioTypeId';

      // Ters kayıt — kasa
      txn.set(reversalCashRef, {
        'customerId': customerId,
        'type': 'reversal',
        'amountCents': -totalAmountCents,
        'description': 'Satış iptali: ${data['transactionNumber']}',
        'referenceId': saleId,
        'date': Timestamp.fromDate(now),
        'receiptId': null,
        'isCancelled': false,
        'createdBy': cancelledBy,
      });

      // Ters kayıt — stok
      txn.set(reversalStockRef, {
        'type': 'reversal',
        'warehouseId': warehouseId,
        'customerId': customerId,
        'pistachioTypeId': pistachioTypeId,
        'quantityKg': quantityKg,
        'referenceId': saleId,
        'date': Timestamp.fromDate(now),
      });

      // Satışı iptal işaretle
      txn.update(saleRef, {
        'isCancelled': true,
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(now),
      });

      // Bakiyeleri geri al
      txn.update(
        _db.collection(FirestorePaths.customers).doc(customerId),
        {'cashBalanceCents': FieldValue.increment(-totalAmountCents)},
      );
      txn.update(
        _db.collection(FirestorePaths.warehouseSummaries).doc(summaryId),
        {'totalQuantityKg': FieldValue.increment(quantityKg)},
      );
    });
  }

  Stream<List<Map<String, dynamic>>> watchByCustomer(String customerId) {
    return _db
        .collection(FirestorePaths.sales)
        .where('customerId', isEqualTo: customerId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}

@Riverpod(keepAlive: true)
SalesRepository salesRepository(Ref ref) {
  return SalesRepository(FirebaseFirestore.instance);
}
