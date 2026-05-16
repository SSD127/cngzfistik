import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/currency.dart';

part 'monthly_report_screen.g.dart';

@riverpod
Future<Map<String, dynamic>> monthlyReport(
    Ref ref, int year, int month) async {
  final db = FirebaseFirestore.instance;
  final from = DateTime(year, month, 1);
  final to = DateTime(year, month + 1, 1);

  final salesSnap = await db
      .collection(FirestorePaths.sales)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('date', isLessThan: Timestamp.fromDate(to))
      .where('isCancelled', isEqualTo: false)
      .get();

  final purchasesSnap = await db
      .collection(FirestorePaths.purchases)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('date', isLessThan: Timestamp.fromDate(to))
      .where('isCancelled', isEqualTo: false)
      .get();

  final expensesSnap = await db
      .collection(FirestorePaths.expenses)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('date', isLessThan: Timestamp.fromDate(to))
      .where('isDeleted', isEqualTo: false)
      .get();

  final cashInSnap = await db
      .collection(FirestorePaths.cashMovements)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('date', isLessThan: Timestamp.fromDate(to))
      .where('isCancelled', isEqualTo: false)
      .get();

  int totalSalesCents = 0;
  int totalSalesKg = 0;
  for (final d in salesSnap.docs) {
    totalSalesCents += (d.data()['totalAmountCents'] as int? ?? 0);
    totalSalesKg += ((d.data()['quantityKg'] as num? ?? 0) * 1000).round();
  }

  int totalPurchasesCents = 0;
  for (final d in purchasesSnap.docs) {
    totalPurchasesCents += (d.data()['totalAmountCents'] as int? ?? 0);
  }

  int totalExpensesCents = 0;
  for (final d in expensesSnap.docs) {
    totalExpensesCents += (d.data()['amountCents'] as int? ?? 0);
  }

  int totalCashInCents = 0;
  int totalCashOutCents = 0;
  for (final d in cashInSnap.docs) {
    final amount = d.data()['amountCents'] as int? ?? 0;
    if (amount > 0) {
      totalCashInCents += amount;
    } else {
      totalCashOutCents += amount.abs();
    }
  }

  return {
    'salesCount': salesSnap.docs.length,
    'totalSalesCents': totalSalesCents,
    'totalSalesKg': totalSalesKg,
    'purchasesCount': purchasesSnap.docs.length,
    'totalPurchasesCents': totalPurchasesCents,
    'expensesCount': expensesSnap.docs.length,
    'totalExpensesCents': totalExpensesCents,
    'totalCashInCents': totalCashInCents,
    'totalCashOutCents': totalCashOutCents,
    'netCents':
        totalSalesCents - totalPurchasesCents - totalExpensesCents,
  };
}

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late int _year;
  late int _month;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(monthlyReportProvider(_year, _month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Rapor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(monthlyReportProvider(_year, _month)),
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthPicker(
            year: _year,
            month: _month,
            months: _months,
            onPrev: () => setState(() {
              if (_month == 1) {
                _month = 12;
                _year--;
              } else {
                _month--;
              }
            }),
            onNext: () => setState(() {
              if (_month == 12) {
                _month = 1;
                _year++;
              } else {
                _month++;
              }
            }),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (report) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                        title:
                            '${_months[_month - 1]} $_year Özeti'),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (ctx, c) {
                      final cols = c.maxWidth > 600 ? 3 : 1;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _ReportCard(
                            label: 'Satış Geliri',
                            value: Currency.formatCents(
                                report['totalSalesCents'] as int),
                            sub:
                                '${report['salesCount']} satış • ${((report['totalSalesKg'] as int) / 1000).toStringAsFixed(1)} kg',
                            color: Colors.green,
                            icon: Icons.sell,
                          ),
                          _ReportCard(
                            label: 'Alım Gideri',
                            value: Currency.formatCents(
                                report['totalPurchasesCents'] as int),
                            sub: '${report['purchasesCount']} alım',
                            color: Colors.orange,
                            icon: Icons.shopping_cart,
                          ),
                          _ReportCard(
                            label: 'Diğer Giderler',
                            value: Currency.formatCents(
                                report['totalExpensesCents'] as int),
                            sub: '${report['expensesCount']} gider',
                            color: Colors.red,
                            icon: Icons.receipt_long,
                          ),
                          _ReportCard(
                            label: 'Kasa Girişi',
                            value: Currency.formatCents(
                                report['totalCashInCents'] as int),
                            sub: 'Müşterilerden tahsilat',
                            color: Colors.blue,
                            icon: Icons.add_card,
                          ),
                          _ReportCard(
                            label: 'Kasa Çıkışı',
                            value: Currency.formatCents(
                                report['totalCashOutCents'] as int),
                            sub: 'Müşterilere ödeme',
                            color: Colors.purple,
                            icon: Icons.payments,
                          ),
                          _ReportCard(
                            label: 'Net Kar/Zarar',
                            value: Currency.formatCents(
                                report['netCents'] as int),
                            sub: 'Satış − Alım − Gider',
                            color: (report['netCents'] as int) >= 0
                                ? Colors.green
                                : Colors.red,
                            icon: Icons.trending_up,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.year,
    required this.month,
    required this.months,
    required this.onPrev,
    required this.onNext,
  });
  final int year;
  final int month;
  final List<String> months;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(
            '${months[month - 1]} $year',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(sub,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
