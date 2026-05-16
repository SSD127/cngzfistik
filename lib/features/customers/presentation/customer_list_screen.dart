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
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Müşteriyi sil',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        onTap: () => context.go('/admin/customers/${customer.id}'),
      ),
    );
  }

  Future<void> _copyLink(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(customerRepositoryProvider);
    // Aktif token yoksa otomatik oluştur
    String? token = await repo.getActiveToken(customer.id);
    token ??= await repo.regenerateToken(customer.id);

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
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // Önce silinebilir mi kontrol et
    final check = await ref
        .read(customerRepositoryProvider)
        .canDelete(customer.id);

    if (!context.mounted) return;

    if (!check.canDelete) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.block, color: Colors.red, size: 40),
          title: const Text('Silinemez'),
          content: Text(check.reason ?? 'Bu müşteri silinemez.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    // Onay diyaloğu
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
        title: const Text('Müşteriyi Sil'),
        content: Text(
          '${customer.fullName} adlı müşteriyi silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(customerRepositoryProvider)
          .softDelete(customer.id, 'admin');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${customer.fullName} silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
