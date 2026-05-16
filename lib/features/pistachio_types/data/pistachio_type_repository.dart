import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../domain/pistachio_type_model.dart';

part 'pistachio_type_repository.g.dart';

class PistachioTypeRepository {
  PistachioTypeRepository(this._db);

  final FirebaseFirestore _db;

  Stream<List<PistachioTypeModel>> watchActive() {
    return _db
        .collection(FirestorePaths.pistachioTypes)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PistachioTypeModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<List<PistachioTypeModel>> getAll() async {
    final snap = await _db
        .collection(FirestorePaths.pistachioTypes)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => PistachioTypeModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<String> create({
    required String name,
    required double defaultInnerGramRatio,
  }) async {
    final ref = _db.collection(FirestorePaths.pistachioTypes).doc();
    await ref.set({
      'name': name,
      'defaultInnerGramRatio': defaultInnerGramRatio,
      'currentPricePerKgCents': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(String id, {
    required String name,
    required double defaultInnerGramRatio,
    List<String>? attributeFields,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'defaultInnerGramRatio': defaultInnerGramRatio,
    };
    if (attributeFields != null) {
      data['attributeFields'] = attributeFields;
    }
    await _db.collection(FirestorePaths.pistachioTypes).doc(id).update(data);
  }

  Future<void> updateAttributeFields(String id, List<String> fields) async {
    await _db
        .collection(FirestorePaths.pistachioTypes)
        .doc(id)
        .update({'attributeFields': fields});
  }

  /// Kur güncelle ve geçmişe kaydet (Gereksinim 3.3, 3.4, 3.6)
  Future<void> updatePrice({
    required String typeId,
    required int pricePerKgCents,
    required String recordedBy,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();

    // Mevcut fiyatı güncelle
    batch.update(
      _db.collection(FirestorePaths.pistachioTypes).doc(typeId),
      {'currentPricePerKgCents': pricePerKgCents},
    );

    // Geçmişe kaydet
    final historyRef = _db.collection(FirestorePaths.priceHistory).doc();
    batch.set(historyRef, {
      'pistachioTypeId': typeId,
      'pricePerKgCents': pricePerKgCents,
      'recordedAt': Timestamp.fromDate(now),
      'recordedBy': recordedBy,
    });

    await batch.commit();
  }

  /// En güncel kur (Gereksinim 3.5, Özellik 4)
  Future<int> getLatestPrice(String typeId) async {
    final snap = await _db
        .collection(FirestorePaths.priceHistory)
        .where('pistachioTypeId', isEqualTo: typeId)
        .orderBy('recordedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return 0;
    return snap.docs.first.data()['pricePerKgCents'] as int;
  }

  Future<List<PriceHistoryModel>> getPriceHistory(String typeId) async {
    final snap = await _db
        .collection(FirestorePaths.priceHistory)
        .where('pistachioTypeId', isEqualTo: typeId)
        .orderBy('recordedAt', descending: true)
        .limit(30)
        .get();
    return snap.docs
        .map((d) => PriceHistoryModel.fromMap(d.id, d.data()))
        .toList();
  }
}

@Riverpod(keepAlive: true)
PistachioTypeRepository pistachioTypeRepository(Ref ref) {
  return PistachioTypeRepository(FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
Stream<List<PistachioTypeModel>> pistachioTypesStream(Ref ref) {
  return ref.watch(pistachioTypeRepositoryProvider).watchActive();
}
