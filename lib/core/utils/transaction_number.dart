import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

class TransactionNumber {
  TransactionNumber._();

  /// Transaction içinde benzersiz işlem numarası üretir (Gereksinim 27)
  static String generate(Transaction txn, DocumentSnapshot counterDoc, String prefix) {
    final lastNumber = (counterDoc.data() as Map<String, dynamic>)['lastNumber'] as int;
    final newNumber = lastNumber + 1;
    txn.update(counterDoc.reference, {'lastNumber': newNumber});
    return '$prefix-${newNumber.toString().padLeft(6, '0')}';
  }

  static DocumentReference counterRef(FirebaseFirestore db, String type) {
    return db.collection(FirestorePaths.transactionCounters).doc(type);
  }
}
