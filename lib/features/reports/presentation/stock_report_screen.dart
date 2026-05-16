import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';

part 'stock_report_screen.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> stockReport(Ref ref) async {
  final db = FirebaseFirestore.instance;

  final summariesSnap =
      await db.collection(FirestorePaths.warehouseSummaries).get();
  final typesSnap = await db.collection(FirestorePaths.pistachioTypes).get();
  final warehousesSnap = await db.collection(FirestorePaths.warehouses).get();

  final typesById = {
    for (final d in typesSnap.docs) d.id: d.data(),
  };
  final warehousesById = {
    for (final d in warehousesSnap.docs) d.id: d.data(),
  };

  return summariesSnap.docs.map((d) {
    final data = d.data();
    final warehouseId = data['warehouseId'] as String;
    final pistachioTypeId = data['pistachioTypeId'] as String;
    return {
      'id': d.id,
      'warehouseName': warehousesById[warehouseId]?['name'] ?? warehouseId,
      'pistachioTypeName': typesById[pistachioTypeId]?['name'] ?? pistachioTypeId,
      'totalQuantityKg': (data['totalQuantityKg'] as num?)?.toDouble() ?? 0.0,
      'updatedAt': data['updatedAt'],
    };
  }).toList()
    ..sort((a, b) =>
        (a['warehouseName'] as String).compareTo(b['warehouseName'] as String));
}

class StockReportScreen extends ConsumerWidget {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Raporu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(stockReportProvider),
          ),
        ],
      ),
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz stok kaydı yok'),
                ],
              ),
            );
          }

          final totalKg = items.fold<double>(
              0.0, (s, i) => s + (i['totalQuantityKg'] as double));

          return Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2),
                    const SizedBox(width: 8),
                    Text(
                      'Toplam Stok: ${totalKg.toStringAsFixed(2)} kg',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text('${items.length} depo/cins kombinasyonu'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final qty = item['totalQuantityKg'] as double;
                    final updatedAt =
                        (item['updatedAt'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: qty > 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: qty > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(item['pistachioTypeName'] as String),
                        subtitle: Text(item['warehouseName'] as String),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${qty.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: qty > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            if (updatedAt != null)
                              Text(
                                _formatDate(updatedAt),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
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

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}
