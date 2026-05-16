import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory { transport, labor, invoice, creditCard, other }

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.date,
    required this.category,
    required this.amountCents,
    required this.description,
    required this.isDeleted,
    required this.createdBy,
    required this.createdAt,
    this.documentUrl,
    this.documentPath,
  });

  final String id;
  final DateTime date;
  final ExpenseCategory category;
  final int amountCents;
  final String description;
  final bool isDeleted;
  final String createdBy;
  final DateTime createdAt;
  final String? documentUrl;
  final String? documentPath;

  String get categoryLabel => switch (category) {
        ExpenseCategory.transport => 'Nakliye',
        ExpenseCategory.labor => 'Hammaliye',
        ExpenseCategory.invoice => 'Fatura',
        ExpenseCategory.creditCard => 'Kredi Kartı',
        ExpenseCategory.other => 'Diğer',
      };

  static ExpenseCategory categoryFromString(String s) => switch (s) {
        'transport' => ExpenseCategory.transport,
        'labor' => ExpenseCategory.labor,
        'invoice' => ExpenseCategory.invoice,
        'credit_card' => ExpenseCategory.creditCard,
        _ => ExpenseCategory.other,
      };

  static String categoryToString(ExpenseCategory c) => switch (c) {
        ExpenseCategory.transport => 'transport',
        ExpenseCategory.labor => 'labor',
        ExpenseCategory.invoice => 'invoice',
        ExpenseCategory.creditCard => 'credit_card',
        ExpenseCategory.other => 'other',
      };

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> data) {
    return ExpenseModel(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      category: categoryFromString(data['category'] as String),
      amountCents: data['amountCents'] as int,
      description: data['description'] as String? ?? '',
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      documentUrl: data['documentUrl'] as String?,
      documentPath: data['documentPath'] as String?,
    );
  }
}
