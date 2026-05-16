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
  final pageDoc =
      await db.collection(FirestorePaths.customerPages).doc(token).get();
  if (!pageDoc.exists || !(pageDoc.data()!['isActive'] as bool)) return null;

  final customerId = pageDoc.data()!['customerId'] as String;
  final customerDoc =
      await db.collection(FirestorePaths.customers).doc(customerId).get();
  if (!customerDoc.exists) return null;

  final cashSnap = await db
      .collection(FirestorePaths.cashMovements)
      .where('customerId', isEqualTo: customerId)
      .orderBy('date', descending: true)
      .limit(50)
      .get();

  final inventorySnap = await db
      .collection(FirestorePaths.inventoryDeposits)
      .where('customerId', isEqualTo: customerId)
      .get();

  // Fıstık cins adlarını çek
  final typeIds = inventorySnap.docs
      .map((d) => d.data()['pistachioTypeId'] as String)
      .toSet();
  final typeNames = <String, String>{};
  for (final tid in typeIds) {
    final tdoc =
        await db.collection(FirestorePaths.pistachioTypes).doc(tid).get();
    if (tdoc.exists) {
      typeNames[tid] = tdoc.data()!['name'] as String? ?? tid;
    }
  }

  return {
    'customer': {'id': customerId, ...customerDoc.data()!},
    'movements': cashSnap.docs
        .where((d) => d.data()['isCancelled'] != true)
        .map((d) => {'id': d.id, ...d.data()})
        .toList(),
    'inventory': inventorySnap.docs
        .where((d) => d.data()['isDeleted'] != true)
        .map((d) => {'id': d.id, ...d.data()})
        .toList(),
    'typeNames': typeNames,
  };
}

class CustomerPageScreen extends ConsumerWidget {
  const CustomerPageScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(customerPageDataProvider(token));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('CustomerPage error: $e\n$st');
          return _InvalidPage();
        },
        data: (data) => data == null ? _InvalidPage() : _PageContent(data: data),
      ),
    );
  }
}

class _InvalidPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Sayfa bulunamadı veya link geçersiz.'),
          const SizedBox(height: 8),
          Text('Lütfen size gönderilen linki kontrol edin.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>;
    final movements = data['movements'] as List;
    final inventory = data['inventory'] as List;
    final typeNames = data['typeNames'] as Map<String, String>;
    final cashBalance = customer['cashBalanceCents'] as int? ?? 0;
    final name = '${customer['firstName']} ${customer['lastName']}';

    return CustomScrollView(
      slivers: [
        // Üst başlık
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/logo.png',
                              width: 36, height: 36,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.eco, color: Colors.white, size: 36)),
                          const SizedBox(width: 8),
                          const Text('cngzfıstık',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet kartlar
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.account_balance_wallet,
                        label: 'Kasa Bakiyesi',
                        value: Currency.formatCents(cashBalance),
                        color: cashBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Emanet Fıstık',
                        value: inventory.isEmpty
                            ? '0 parti'
                            : '${inventory.length} parti',
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Emanet fıstık
                if (inventory.isNotEmpty) ...[
                  _SectionTitle(title: 'Emanet Fıstık', icon: Icons.inventory_2_outlined),
                  const SizedBox(height: 8),
                  ...inventory.map((item) {
                    final i = item as Map<String, dynamic>;
                    final typeId = i['pistachioTypeId'] as String? ?? '';
                    final typeName = typeNames[typeId] ?? typeId;
                    final qty = (i['quantityKg'] as num).toStringAsFixed(2);
                    final attrs = Map<String, dynamic>.from(
                        i['attributes'] as Map? ?? {});
                    final date = (i['date'] as Timestamp?)?.toDate();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.eco, size: 18, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(typeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('$qty kg',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (attrs.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: attrs.entries
                                    .map((e) => Chip(
                                          label: Text('${e.key}: ${e.value}',
                                              style: const TextStyle(fontSize: 12)),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ))
                                    .toList(),
                              ),
                            ],
                            if (date != null) ...[
                              const SizedBox(height: 4),
                              Text(_fmt(date),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Son işlemler
                if (movements.isNotEmpty) ...[
                  _SectionTitle(title: 'Son İşlemler', icon: Icons.swap_vert),
                  const SizedBox(height: 8),
                  ...movements.map((m) {
                    final mov = m as Map<String, dynamic>;
                    final amount = mov['amountCents'] as int? ?? 0;
                    final isPositive = amount >= 0;
                    final date = (mov['date'] as Timestamp?)?.toDate();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: (isPositive ? Colors.green : Colors.red)
                              .withValues(alpha: 0.1),
                          child: Icon(
                            isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isPositive ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ),
                        title: Text(mov['description'] as String? ?? '',
                            style: const TextStyle(fontSize: 13)),
                        subtitle: date != null
                            ? Text(_fmt(date),
                                style: const TextStyle(fontSize: 11))
                            : null,
                        trailing: Text(
                          '${isPositive ? '+' : '-'}${Currency.formatCents(amount.abs())}',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                if (inventory.isEmpty && movements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aktif işlem bulunmamaktadır.')),
                  ),

                const SizedBox(height: 32),
                Center(
                  child: Text('cngzfıstık — Antep\'in Lezzet Durağı',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
