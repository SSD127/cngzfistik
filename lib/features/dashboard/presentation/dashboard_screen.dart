import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/currency.dart';
import '../../customers/data/customer_repository.dart';

part 'dashboard_screen.g.dart';

/// Müşteri istatistiklerini zaten açık olan stream'den hesaplar (ek Firestore isteği yok)
@riverpod
Map<String, dynamic> customerStats(Ref ref) {
  final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];
  int totalCashCents = 0;
  int debtorCount = 0;
  for (final c in customers) {
    totalCashCents += c.cashBalanceCents;
    if (c.cashBalanceCents < 0) debtorCount++;
  }
  return {
    'customerCount': customers.length,
    'totalCashCents': totalCashCents,
    'debtorCount': debtorCount,
  };
}

@riverpod
Future<List<Map<String, dynamic>>> recentSales(Ref ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirestorePaths.sales)
      .orderBy('date', descending: true)
      .limit(5)
      .get();
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(customerStatsProvider);
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(recentSalesProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _StatCard(
                    icon: Icons.people,
                    label: 'Toplam Müşteri',
                    value: '${stats['customerCount']}',
                    color: Colors.blue,
                  ),
                  _StatCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Toplam Kasa',
                    value: Currency.formatCents(stats['totalCashCents'] as int),
                    color: Colors.green,
                  ),
                  _StatCard(
                    icon: Icons.warning_amber,
                    label: 'Borçlu Müşteri',
                    value: '${stats['debtorCount']}',
                    color: Colors.red,
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            Text('Hızlı İşlemler',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAction(
                    icon: Icons.sell,
                    label: 'Yeni Satış',
                    onTap: () => context.go('/admin/sales/new')),
                _QuickAction(
                    icon: Icons.shopping_cart,
                    label: 'Yeni Alım',
                    onTap: () => context.go('/admin/purchases/new')),
                _QuickAction(
                    icon: Icons.add_card,
                    label: 'Para Girişi',
                    onTap: () => context.go('/admin/cash/deposit')),
                _QuickAction(
                    icon: Icons.payments,
                    label: 'Para Ödemesi',
                    onTap: () => context.go('/admin/cash/withdrawal')),
                _QuickAction(
                    icon: Icons.inventory_2,
                    label: 'Emanet Girişi',
                    onTap: () => context.go('/admin/inventory/deposits')),
              ],
            ),
            const SizedBox(height: 24),
            Text('Son Satışlar',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            salesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (sales) => sales.isEmpty
                  ? const Text('Henüz satış yok.')
                  : Column(
                      children: sales.map((s) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.sell_outlined),
                            title:
                                Text(s['transactionNumber'] as String? ?? ''),
                            subtitle: Text(Currency.formatCents(
                                s['totalAmountCents'] as int? ?? 0)),
                            trailing: (s['isCancelled'] as bool? ?? false)
                                ? const Chip(label: Text('İptal'))
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
