import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../data/customer_repository.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../cash/data/cash_repository.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));

    return customerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (customer) {
        if (customer == null) {
          return const Scaffold(body: Center(child: Text('Müşteri bulunamadı.')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(customer.fullName),
            actions: [
              IconButton(
                icon: const Icon(Icons.link),
                tooltip: 'Müşteri linkini kopyala',
                onPressed: () async {
                  final repo = ref.read(customerRepositoryProvider);
                  String? token = await repo.getActiveToken(customerId);
                  token ??= await repo.regenerateToken(customerId);
                  final base = Uri.base;
                  final url = '${base.scheme}://${base.host}'
                      '${base.port != 80 && base.port != 443 && base.port != 0 ? ':${base.port}' : ''}'
                      '/c/$token';
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Link kopyalandı: $url'),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(label: 'Tamam', onPressed: () {}),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet kart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text(customer.phone.isEmpty ? 'Telefon yok' : customer.phone),
                        ),
                        ListTile(
                          leading: const Icon(Icons.account_balance_wallet),
                          title: Text('Kasa Bakiyesi: ${Currency.formatCents(customer.cashBalanceCents)}'),
                          textColor: customer.cashBalanceCents < 0 ? Colors.red : null,
                        ),
                        if (customer.isDebtor)
                          const ListTile(
                            leading: Icon(Icons.warning, color: Colors.red),
                            title: Text('Borçlu Müşteri', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Emanet fıstık listesi
                Text('Emanet Fıstık', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                StreamBuilder(
                  stream: ref.read(inventoryRepositoryProvider).watchByCustomer(customerId),
                  builder: (context, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    final items = snap.data!;
                    if (items.isEmpty) return const Text('Emanet fıstık yok.');
                    return Column(
                      children: items.map((item) {
                        final attrs = item.attributes;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.quantityKg.toStringAsFixed(2)} kg',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Depo: ${item.warehouseId}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                if (attrs.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: attrs.entries.map((e) => Chip(
                                      label: Text('${e.key}: ${e.value}'),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    )).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Kasa hareketleri
                Text('Kasa Hareketleri', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                StreamBuilder(
                  stream: ref.read(cashRepositoryProvider).watchByCustomer(customerId),
                  builder: (context, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    final movements = snap.data!;
                    if (movements.isEmpty) return const Text('Hareket yok.');
                    return Column(
                      children: movements.map((m) => Card(
                        child: ListTile(
                          leading: Icon(
                            m.amountCents >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: m.amountCents >= 0 ? Colors.green : Colors.red,
                          ),
                          title: Text(m.typeLabel),
                          subtitle: Text(m.description),
                          trailing: Text(
                            Currency.formatCents(m.amountCents.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: m.amountCents >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
