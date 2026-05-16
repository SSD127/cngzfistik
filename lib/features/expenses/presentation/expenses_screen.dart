import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../data/expenses_repository.dart';
import '../domain/expense_model.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Giderler')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Yeni Gider'),
        onPressed: () => _showAddDialog(context, ref),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (expenses) {
          if (expenses.isEmpty) return const Center(child: Text('Henüz gider yok.'));
          
          // Kategori toplamları
          final totals = <ExpenseCategory, int>{};
          for (final e in expenses) {
            totals[e.category] = (totals[e.category] ?? 0) + e.amountCents;
          }

          return Column(
            children: [
              // Özet
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Özet', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...totals.entries.map((e) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key == ExpenseCategory.transport ? 'Nakliye' :
                                 e.key == ExpenseCategory.labor ? 'Hammaliye' :
                                 e.key == ExpenseCategory.invoice ? 'Fatura' :
                                 e.key == ExpenseCategory.creditCard ? 'Kredi Kartı' : 'Diğer'),
                            Text(Currency.formatCents(e.value),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Toplam', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              Currency.formatCents(totals.values.fold(0, (a, b) => a + b)),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, i) {
                    final expense = expenses[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(expense.description),
                        subtitle: Text('${expense.categoryLabel} • ${expense.date.day}.${expense.date.month}.${expense.date.year}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(Currency.formatCents(expense.amountCents),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, expense.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var selectedCategory = ExpenseCategory.transport;
    var selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Yeni Gider'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ExpenseCategory>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: ExpenseCategory.values.map((c) {
                      final label = switch(c) {
                        ExpenseCategory.transport => 'Nakliye',
                        ExpenseCategory.labor => 'Hammaliye',
                        ExpenseCategory.invoice => 'Fatura',
                        ExpenseCategory.creditCard => 'Kredi Kartı',
                        ExpenseCategory.other => 'Diğer',
                      };
                      return DropdownMenuItem(value: c, child: Text(label));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Tutar (TL)', suffixText: '₺'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                      if (n == null || n <= 0) return 'Geçerli tutar girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text('Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final lira = double.parse(amountCtrl.text.replaceAll(',', '.'));
                await ref.read(expensesRepositoryProvider).create(
                      date: selectedDate,
                      category: selectedCategory,
                      amountCents: (lira * 100).round(),
                      description: descCtrl.text.trim(),
                      createdBy: 'admin',
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gideri Sil'),
        content: const Text('Bu gider kaydı silinecek. Emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(expensesRepositoryProvider).softDelete(id, 'admin');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
