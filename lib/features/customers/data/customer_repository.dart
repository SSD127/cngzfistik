import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/token_generator.dart';
import '../domain/customer_model.dart';

part 'customer_repository.g.dart';

class CustomerRepository {
  CustomerRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.customers);

  Stream<List<CustomerModel>> watchAll() {
    return _col
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CustomerModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<CustomerModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CustomerModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> create({
    required String firstName,
    required String lastName,
    required String phone,
    required String createdBy,
  }) async {
    final now = DateTime.now();
    final docRef = _col.doc();
    final token = TokenGenerator.generate();

    final batch = _db.batch();

    batch.set(docRef, {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'cashBalanceCents': 0,
      'isDebtor': false,
      'isDeleted': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'deletedAt': null,
      'deletedBy': null,
    });

    // Müşteri sayfası token'ı (Gereksinim 2.2, 18.1)
    final pageRef =
        _db.collection(FirestorePaths.customerPages).doc(token);
    batch.set(pageRef, {
      'customerId': docRef.id,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
    return docRef.id;
  }

  Future<void> update(String id,
      {required String firstName,
      required String lastName,
      required String phone}) async {
    await _col.doc(id).update({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Silme öncesi aktif bakiye kontrolü (Gereksinim 2.4, 2.5)
  Future<({bool canDelete, String? reason})> canDelete(String id) async {
    final customer = await getById(id);
    if (customer == null) return (canDelete: true, reason: null);

    if (customer.cashBalanceCents != 0) {
      return (
        canDelete: false,
        reason: 'Müşterinin kasa bakiyesi sıfır değil (${customer.cashBalanceCents} kuruş).'
      );
    }

    // Emanet fıstık kontrolü
    final inventorySnap = await _db
        .collection(FirestorePaths.inventoryDeposits)
        .where('customerId', isEqualTo: id)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (inventorySnap.docs.isNotEmpty) {
      return (
        canDelete: false,
        reason: 'Müşterinin aktif emanet fıstığı var.'
      );
    }

    return (canDelete: true, reason: null);
  }

  /// Soft delete (Gereksinim 20.1, 20.2, 20.3)
  Future<void> softDelete(String id, String deletedBy) async {
    final now = DateTime.now();
    await _col.doc(id).update({
      'isDeleted': true,
      'deletedAt': Timestamp.fromDate(now),
      'deletedBy': deletedBy,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Mevcut token'ı iptal et, yeni token üret (Gereksinim 18.2, 18.3)
  Future<String> regenerateToken(String customerId) async {
    final newToken = TokenGenerator.generate();
    final now = DateTime.now();

    // Eski aktif token'ı bul ve geçersiz kıl
    final oldTokens = await _db
        .collection(FirestorePaths.customerPages)
        .where('customerId', isEqualTo: customerId)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = _db.batch();
    for (final doc in oldTokens.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    // Yeni token oluştur
    final newPageRef =
        _db.collection(FirestorePaths.customerPages).doc(newToken);
    batch.set(newPageRef, {
      'customerId': customerId,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
    return newToken;
  }

  Future<String?> getActiveToken(String customerId) async {
    final snap = await _db
        .collection(FirestorePaths.customerPages)
        .where('customerId', isEqualTo: customerId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }
}

@Riverpod(keepAlive: true)
CustomerRepository customerRepository(Ref ref) {
  return CustomerRepository(FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
Stream<List<CustomerModel>> customersStream(Ref ref) {
  return ref.watch(customerRepositoryProvider).watchAll();
}

@riverpod
Future<CustomerModel?> customerById(Ref ref, String id) {
  return ref.watch(customerRepositoryProvider).getById(id);
}
