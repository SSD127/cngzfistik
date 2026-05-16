import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../domain/expense_model.dart';

part 'expenses_repository.g.dart';

class ExpensesRepository {
  ExpensesRepository(this._db);

  final FirebaseFirestore _db;

  Stream<List<ExpenseModel>> watchAll({ExpenseCategory? category}) {
    // isDeleted Dart tarafında filtreleniyor — composite index gerekmez
    Query<Map<String, dynamic>> query = _db
        .collection(FirestorePaths.expenses)
        .orderBy('date', descending: true);

    return query.snapshots().map((snap) {
      var docs = snap.docs.where((d) => d.data()['isDeleted'] != true);
      if (category != null) {
        final catStr = ExpenseModel.categoryToString(category);
        docs = docs.where((d) => d.data()['category'] == catStr);
      }
      return docs.map((d) => ExpenseModel.fromMap(d.id, d.data())).toList();
    });
  }

  Future<String> create({
    required DateTime date,
    required ExpenseCategory category,
    required int amountCents,
    required String description,
    required String createdBy,
  }) async {
    final ref = _db.collection(FirestorePaths.expenses).doc();
    await ref.set({
      'date': Timestamp.fromDate(date),
      'category': ExpenseModel.categoryToString(category),
      'amountCents': amountCents,
      'description': description,
      'documentUrl': null,
      'documentPath': null,
      'isDeleted': false,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(String id, {
    required DateTime date,
    required ExpenseCategory category,
    required int amountCents,
    required String description,
  }) async {
    await _db.collection(FirestorePaths.expenses).doc(id).update({
      'date': Timestamp.fromDate(date),
      'category': ExpenseModel.categoryToString(category),
      'amountCents': amountCents,
      'description': description,
    });
  }

  Future<void> softDelete(String id, String deletedBy) async {
    await _db.collection(FirestorePaths.expenses).doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': deletedBy,
    });
  }
}

@Riverpod(keepAlive: true)
ExpensesRepository expensesRepository(Ref ref) {
  return ExpensesRepository(FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
Stream<List<ExpenseModel>> expensesStream(Ref ref) {
  return ref.watch(expensesRepositoryProvider).watchAll();
}
