import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency.dart';
import '../data/customer_repository.dart';
import '../domain/customer_model.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Müşteriler')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Müşteri'),
        onPressed: () => _showAddCustomerDialog(context, ref),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('Henüz müşteri yok.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: customers.length,
            itemBuilder: (context, i) => _CustomerTile(customer: customers[i]),
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Müşteri'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'Ad'),
                validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Soyad'),
                validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(customerRepositoryProvider).create(
                    firstName: firstNameCtrl.text.trim(),
                    lastName: lastNameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    createdBy: 'admin',
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends ConsumerWidget {
  const _CustomerTile({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(customer.firstName[0])),
        title: Text(customer.fullName),
        subtitle: Text(
          'Kasa: ${Currency.formatCents(customer.cashBalanceCents)}',
          style: TextStyle(
            color: customer.cashBalanceCents < 0 ? Colors.red : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customer.isDebtor)
              const Chip(
                label: Text('Borçlu', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.red,
              ),
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Müşteri linkini kopyala',
              onPressed: () => _copyLink(context, ref),
            ),
          ],
        ),
        onTap: () => context.go('/admin/customers/${customer.id}'),
      ),
    );
  }

  Future<void> _copyLink(BuildContext context, WidgetRef ref) async {
    final token = await ref
        .read(customerRepositoryProvider)
        .getActiveToken(customer.id);
    if (token == null) return;
    final url = 'https://fistik-komisyon.web.app/c/$token';
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link kopyalandı')),
      );
    }
  }
}
