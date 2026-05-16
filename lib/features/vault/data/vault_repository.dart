import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../domain/vault_models.dart';

part 'vault_repository.g.dart';

class VaultRepository {
  VaultRepository(this._db);

  final FirebaseFirestore _db;

  Stream<List<VaultItemModel>> watchAll() {
    return _db
        .collection(FirestorePaths.vaultItems)
        .orderBy('customerName')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VaultItemModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<VaultMovementModel>> watchMovements(String customerId) {
    return _db
        .collection(FirestorePaths.vaultMovements)
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => VaultMovementModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> deposit({
    required String customerId,
    required String customerName,
    required int amountCents,
    required String description,
    required String createdBy,
  }) async {
    final itemRef = _db.collection(FirestorePaths.vaultItems).doc(customerId);
    final movRef = _db.collection(FirestorePaths.vaultMovements).doc();

    await _db.runTransaction((txn) async {
      final itemDoc = await txn.get(itemRef);
      final now = DateTime.now();

      if (itemDoc.exists) {
        txn.update(itemRef, {
          'balanceCents': FieldValue.increment(amountCents),
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        txn.set(itemRef, {
          'customerId': customerId,
          'customerName': customerName,
          'balanceCents': amountCents,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      txn.set(movRef, {
        'customerId': customerId,
        'type': 'deposit',
        'amountCents': amountCents,
        'description': description,
        'date': Timestamp.fromDate(now),
        'createdBy': createdBy,
      });
    });
  }

  Future<void> withdraw({
    required String customerId,
    required int amountCents,
    required String description,
    required String createdBy,
  }) async {
    final itemRef = _db.collection(FirestorePaths.vaultItems).doc(customerId);
    final movRef = _db.collection(FirestorePaths.vaultMovements).doc();

    await _db.runTransaction((txn) async {
      final itemDoc = await txn.get(itemRef);
      final now = DateTime.now();

      final currentBalance =
          (itemDoc.data()?['balanceCents'] as int?) ?? 0;
      if (currentBalance < amountCents) {
        throw Exception(
            'Yetersiz kasa emanet bakiyesi. Mevcut: $currentBalance kuruş.');
      }

      txn.update(itemRef, {
        'balanceCents': FieldValue.increment(-amountCents),
        'updatedAt': Timestamp.fromDate(now),
      });

      txn.set(movRef, {
        'customerId': customerId,
        'type': 'withdrawal',
        'amountCents': -amountCents,
        'description': description,
        'date': Timestamp.fromDate(now),
        'createdBy': createdBy,
      });
    });
  }
}

@Riverpod(keepAlive: true)
VaultRepository vaultRepository(Ref ref) {
  return VaultRepository(FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
Stream<List<VaultItemModel>> vaultItemsStream(Ref ref) {
  return ref.watch(vaultRepositoryProvider).watchAll();
}
