import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/currency.dart';

part 'customer_page_screen.g.dart';

@riverpod
Future<Map<String, dynamic>?> customerPageData(Ref ref, String token) async {
  final db = FirebaseFirestore.instance;
  final pageDoc = await db.collection(FirestorePaths.customerPages).doc(token).get();
  if (!pageDoc.exists || !(pageDoc.data()!['isActive'] as bool)) return null;

  final customerId = pageDoc.data()!['customerId'] as String;
  final customerDoc = await db.collection(FirestorePaths.customers).doc(customerId).get();
  if (!customerDoc.exists) return null;

  final cashSnap = await db
      .collection(FirestorePaths.cashMovements)
      .where('customerId', isEqualTo: customerId)
      .orderBy('date', descending: true)
      .limit(20)
      .get();

  final inventorySnap = await db
      .collection(FirestorePaths.inventoryDeposits)
      .where('customerId', isEqualTo: customerId)
      .where('isDeleted', isEqualTo: false)
      .get();

  return {
    'customer': {'id': customerId, ...customerDoc.data()!},
    'movements': cashSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
    'inventory': inventorySnap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
  };
}

class CustomerPageScreen extends ConsumerWidget {
  const CustomerPageScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(customerPageDataProvider(token));

    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Bilgileri')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Sayfa bulunamadı')),
        data: (data) {
          if (data == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sayfa bulunamadı veya link geçersiz.'),
                ],
              ),
            );
          }

          final customer = data['customer'] as Map<String, dynamic>;
          final movements = data['movements'] as List;
          final inventory = data['inventory'] as List;
          final cashBalance = customer['cashBalanceCents'] as int? ?? 0;
          final hasActivity = cashBalance != 0 || inventory.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${customer['firstName']} ${customer['lastName']}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _SummaryCard(
                              label: 'Kasa Bakiyesi',
                              value: Currency.formatCents(cashBalance),
                              color: cashBalance >= 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            _SummaryCard(
                              label: 'Emanet Fıstık',
                              value: inventory.isEmpty ? '0 parti' : '${inventory.length} parti',
                              color: Colors.brown,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (!hasActivity)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aktif işlem bulunmamaktadır.')),
                  ),

                if (inventory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Emanet Fıstık', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...inventory.map((item) {
                    final i = item as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text('${(i['quantityKg'] as num).toStringAsFixed(2)} kg'),
                        subtitle: Text('Depo: ${i['warehouseId']}'),
                      ),
                    );
                  }),
                ],

                if (movements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Son İşlemler', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...movements.map((m) {
                    final mov = m as Map<String, dynamic>;
                    final amount = mov['amountCents'] as int? ?? 0;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          amount >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: amount >= 0 ? Colors.green : Colors.red,
                        ),
                        title: Text(mov['description'] as String? ?? ''),
                        trailing: Text(
                          Currency.formatCents(amount.abs()),
                          style: TextStyle(
                            color: amount >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
