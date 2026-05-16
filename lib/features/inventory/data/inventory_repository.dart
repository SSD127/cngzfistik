import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../domain/inventory_deposit_model.dart';

part 'inventory_repository.g.dart';

class InventoryRepository {
  InventoryRepository(this._db);

  final FirebaseFirestore _db;

  /// Emanet fıstık girişi transaction'ı (Gereksinim 5, Özellik 5)
  Future<String> createDeposit({
    required String customerId,
    required String pistachioTypeId,
    required String warehouseId,
    required double quantityKg,
    required Map<String, dynamic> attributes,
    required String createdBy,
  }) async {
    final depositRef = _db.collection(FirestorePaths.inventoryDeposits).doc();
    final stockRef = _db.collection(FirestorePaths.stockMovements).doc();
    final summaryId = '${warehouseId}__$pistachioTypeId';
    final summaryRef =
        _db.collection(FirestorePaths.warehouseSummaries).doc(summaryId);

    await _db.runTransaction((txn) async {
      final now = DateTime.now();

      txn.set(depositRef, {
        'customerId': customerId,
        'pistachioTypeId': pistachioTypeId,
        'warehouseId': warehouseId,
        'quantityKg': quantityKg,
        'date': Timestamp.fromDate(now),
        'attributes': attributes,
        'isDeleted': false,
        'correctionLog': [],
        'createdAt': Timestamp.fromDate(now),
        'createdBy': createdBy,
      });

      txn.set(stockRef, {
        'type': 'deposit',
        'warehouseId': warehouseId,
        'customerId': customerId,
        'pistachioTypeId': pistachioTypeId,
        'quantityKg': quantityKg,
        'referenceId': depositRef.id,
        'date': Timestamp.fromDate(now),
      });

      // Depo özet güncelle (Gereksinim 15.3)
      if (await _summaryExists(summaryId)) {
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
    });

    return depositRef.id;
  }

  /// Düzeltme (Gereksinim 5.4)
  Future<void> correctDeposit({
    required String depositId,
    required double newQuantityKg,
    required String correctedBy,
  }) async {
    final depositRef =
        _db.collection(FirestorePaths.inventoryDeposits).doc(depositId);

    await _db.runTransaction((txn) async {
      final doc = await txn.get(depositRef);
      final data = doc.data()!;
      final oldQty = (data['quantityKg'] as num).toDouble();
      final diff = newQuantityKg - oldQty;
      final now = DateTime.now();
      final warehouseId = data['warehouseId'] as String;
      final pistachioTypeId = data['pistachioTypeId'] as String;
      final summaryId = '${warehouseId}__$pistachioTypeId';

      final correctionEntry = {
        'previousValue': oldQty,
        'newValue': newQuantityKg,
        'correctedAt': Timestamp.fromDate(now),
        'correctedBy': correctedBy,
      };

      txn.update(depositRef, {
        'quantityKg': newQuantityKg,
        'correctionLog': FieldValue.arrayUnion([correctionEntry]),
      });

      txn.update(
        _db.collection(FirestorePaths.warehouseSummaries).doc(summaryId),
        {'totalQuantityKg': FieldValue.increment(diff)},
      );
    });
  }

  Future<bool> _summaryExists(String summaryId) async {
    final doc = await _db
        .collection(FirestorePaths.warehouseSummaries)
        .doc(summaryId)
        .get();
    return doc.exists;
  }

  Stream<List<InventoryDepositModel>> watchByCustomer(String customerId) {
    return _db
        .collection(FirestorePaths.inventoryDeposits)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .where((d) => d.data()['isDeleted'] != true)
          .toList()
        ..sort((a, b) {
          final aDate = (a.data()['date'] as Timestamp?)?.seconds ?? 0;
          final bDate = (b.data()['date'] as Timestamp?)?.seconds ?? 0;
          return bDate.compareTo(aDate);
        });
      return docs
          .map((d) => InventoryDepositModel.fromMap(d.id, d.data()))
          .toList();
    });
  }
}

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(Ref ref) {
  return InventoryRepository(FirebaseFirestore.instance);
}
