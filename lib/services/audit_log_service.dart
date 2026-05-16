import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';

class AuditLogService {
  AuditLogService(this._db);

  final FirebaseFirestore _db;

  /// Audit log yazma — transaction içinde kullanım için (Gereksinim 19)
  static void writeInTransaction(
    Transaction txn,
    FirebaseFirestore db, {
    required String userId,
    required String action,
    required String collection,
    required String documentId,
    Object? previousValue,
    Object? newValue,
  }) {
    final logRef = db.collection(FirestorePaths.auditLogs).doc();
    txn.set(logRef, {
      'userId': userId,
      'action': action,
      'collection': collection,
      'documentId': documentId,
      'previousValue': previousValue,
      'newValue': newValue,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Bağımsız audit log (transaction dışı kritik olaylar için)
  Future<void> write({
    required String userId,
    required String action,
    required String collection,
    required String documentId,
    Object? previousValue,
    Object? newValue,
  }) async {
    await _db.collection(FirestorePaths.auditLogs).add({
      'userId': userId,
      'action': action,
      'collection': collection,
      'documentId': documentId,
      'previousValue': previousValue,
      'newValue': newValue,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
