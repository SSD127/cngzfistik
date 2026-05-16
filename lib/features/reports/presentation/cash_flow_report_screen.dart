import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/currency.dart';
import '../../customers/data/customer_repository.dart';

part 'cash_flow_report_screen.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> cashFlowReport(
    Ref ref, DateTime startDate, DateTime endDate) async {
  final db = FirebaseFirestore.instance;
  final snap = await db
      .collection(FirestorePaths.cashMovements)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .orderBy('date', descending: true)
      .get();

  return snap.docs
      .where((d) => d.data()['isCancelled'] != true)
      .map((d) => {'id': d.id, ...d.data()})
      .toList();
}

class CashFlowReportScreen extends ConsumerStatefulWidget {
  const CashFlowReportScreen({super.key});

  @override
  ConsumerState<CashFlowReportScreen> createState() =>
      _CashFlowReportScreenState();
}

class _CashFlowReportScreenState extends ConsumerState<CashFlowReportScreen> {
  late DateTime _from;
  late DateTime _to;
  String? _filterCustomerId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(cashFlowReportProvider(_from, _to));
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa Hareketlilik Raporu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _pickDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cashFlowReportProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _DateRangeBar(from: _from, to: _to),
          if (customersAsync.hasValue)
            _CustomerFilter(
              customers: customersAsync.value!
                  .map((c) => {'id': c.id, 'name': '${c.firstName} ${c.lastName}'})
                  .toList(),
              selectedId: _filterCustomerId,
              onChanged: (id) => setState(() => _filterCustomerId = id),
            ),
          Expanded(
            child: movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (all) {
                final movements = _filterCustomerId != null
                    ? all
                        .where((m) => m['customerId'] == _filterCustomerId)
                        .toList()
                    : all;

                if (movements.isEmpty) {
                  return const Center(child: Text('Bu dönemde hareket yok'));
                }

                int totalIn = 0;
                int totalOut = 0;
                for (final m in movements) {
                  final amount = m['amountCents'] as int? ?? 0;
                  if (amount > 0) {
                    totalIn += amount;
                  } else {
                    totalOut += amount.abs();
                  }
                }

                return Column(
                  children: [
                    _CashFlowSummary(
                        totalIn: totalIn, totalOut: totalOut),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: movements.length,
                        itemBuilder: (context, i) {
                          final m = movements[i];
                          final amount = m['amountCents'] as int? ?? 0;
                          final isIn = amount > 0;
                          final date =
                              (m['date'] as Timestamp).toDate();
                          return ListTile(
                            leading: Icon(
                              isIn
                                  ? Icons.arrow_circle_down
                                  : Icons.arrow_circle_up,
                              color:
                                  isIn ? Colors.green : Colors.red,
                            ),
                            title: Text(
                                m['description'] as String? ?? ''),
                            subtitle: Text(
                              '${_formatDate(date)} • ${m['transactionNumber'] ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Text(
                              '${isIn ? '+' : '-'}${Currency.formatCents(amount.abs())}',
                              style: TextStyle(
                                color: isIn ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = DateTime(
            picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _DateRangeBar extends StatelessWidget {
  const _DateRangeBar({required this.from, required this.to});
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(
            '${_fmt(from)} — ${_fmt(to)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _CustomerFilter extends StatelessWidget {
  const _CustomerFilter({
    required this.customers,
    required this.selectedId,
    required this.onChanged,
  });
  final List<Map<String, String>> customers;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: selectedId,
        decoration: const InputDecoration(
          labelText: 'Müşteri Filtresi',
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tümü')),
          ...customers.map((c) => DropdownMenuItem(
                value: c['id'],
                child: Text(c['name']!),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _CashFlowSummary extends StatelessWidget {
  const _CashFlowSummary({required this.totalIn, required this.totalOut});
  final int totalIn;
  final int totalOut;

  @override
  Widget build(BuildContext context) {
    final net = totalIn - totalOut;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
                label: 'Giriş',
                value: Currency.formatCents(totalIn),
                color: Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
                label: 'Çıkış',
                value: Currency.formatCents(totalOut),
                color: Colors.red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
                label: 'Net',
                value: Currency.formatCents(net),
                color: net >= 0 ? Colors.blue : Colors.orange),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
