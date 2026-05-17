import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense_model.dart';

class ExpenseReportScreen extends ConsumerStatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  ConsumerState<ExpenseReportScreen> createState() =>
      _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  ExpenseCategory? _selectedCategory;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gider Raporu')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (expenses) {
          final filtered = _selectedCategory != null
              ? expenses
                  .where((e) => e.category == _selectedCategory)
                  .toList()
              : expenses;

          final totals = <ExpenseCategory, int>{};
          for (final e in expenses) {
            totals[e.category] = (totals[e.category] ?? 0) + e.amountCents;
          }

          final byMonth = <String, int>{};
          for (final e in filtered) {
            final key = '${_months[e.date.month - 1]} ${e.date.year}';
            byMonth[key] = (byMonth[key] ?? 0) + e.amountCents;
          }

          final grandTotal =
              filtered.fold<int>(0, (s, e) => s + e.amountCents);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              final categoryPanel = Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategoriler',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _CategoryFilterTile(
                        label: 'Tümü',
                        amount: expenses.fold<int>(0, (s, e) => s + e.amountCents),
                        isSelected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      const Divider(),
                      ...ExpenseCategory.values.map((cat) {
                        final label = switch (cat) {
                          ExpenseCategory.transport => 'Nakliye',
                          ExpenseCategory.labor => 'Hammaliye',
                          ExpenseCategory.invoice => 'Fatura',
                          ExpenseCategory.creditCard => 'Kredi Kartı',
                          ExpenseCategory.other => 'Diğer',
                        };
                        return _CategoryFilterTile(
                          label: label,
                          amount: totals[cat] ?? 0,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() => _selectedCategory = cat),
                        );
                      }),
                    ],
                  ),
                ),
              );

              final listPanel = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                    child: Row(
                      children: [
                        Text(
                          'Toplam: ${Currency.formatCents(grandTotal)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text('${filtered.length} kayıt',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (byMonth.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: byMonth.entries
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(
                                        '${e.key}: ${Currency.formatCents(e.value)}'),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Gider kaydı yok'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final expense = filtered[i];
                              return ListTile(
                                leading: const Icon(Icons.receipt_long),
                                title: Text(expense.description.isEmpty
                                    ? expense.categoryLabel
                                    : expense.description),
                                subtitle: Text(
                                  '${expense.categoryLabel} • ${_formatDate(expense.date)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: Text(
                                  Currency.formatCents(expense.amountCents),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 240, child: categoryPanel),
                    Expanded(child: listPanel),
                  ],
                );
              }

              // Dar ekran: kategori filtresi üstte, liste altta
              return Column(
                children: [
                  categoryPanel,
                  Expanded(child: listPanel),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _CategoryFilterTile extends StatelessWidget {
  const _CategoryFilterTile({
    required this.label,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final int amount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      title: Text(label),
      trailing: Text(
        Currency.formatCents(amount),
        style: const TextStyle(fontSize: 12),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
