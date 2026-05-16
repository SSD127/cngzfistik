import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart' show Currency;
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/customers/data/customer_repository.dart';
import '../data/vault_repository.dart';
import '../domain/vault_models.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  String? _selectedCustomerId;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(vaultItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa Emaneti'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showDialog(context, isDeposit: true),
            icon: const Icon(Icons.add),
            label: const Text('Yatır'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showDialog(context, isDeposit: false),
            icon: const Icon(Icons.remove),
            label: const Text('Çek'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz kasa emaneti kaydı yok'),
                ],
              ),
            );
          }

          final totalCents = items.fold<int>(0, (s, i) => s + i.balanceCents);

          return Column(
            children: [
              _SummaryBar(totalCents: totalCents, count: items.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _VaultItemTile(
                      item: item,
                      isSelected: _selectedCustomerId == item.customerId,
                      onTap: () => setState(() {
                        _selectedCustomerId = _selectedCustomerId == item.customerId
                            ? null
                            : item.customerId;
                      }),
                    );
                  },
                ),
              ),
              if (_selectedCustomerId != null)
                _MovementsPanel(customerId: _selectedCustomerId!),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDialog(BuildContext context, {required bool isDeposit}) async {
    final customersAsync = ref.read(customersStreamProvider);
    final customers = customersAsync.valueOrNull ?? [];

    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müşteri bulunamadı')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _VaultDialog(
        isDeposit: isDeposit,
        customers: customers
            .map((c) => {'id': c.id, 'name': '${c.firstName} ${c.lastName}'})
            .toList(),
        onSubmit: (customerId, customerName, amountCents, description) async {
          final user = await ref.read(currentUserProvider.future);
          final repo = ref.read(vaultRepositoryProvider);
          if (isDeposit) {
            await repo.deposit(
              customerId: customerId,
              customerName: customerName,
              amountCents: amountCents,
              description: description,
              createdBy: user?.uid ?? '',
            );
          } else {
            await repo.withdraw(
              customerId: customerId,
              amountCents: amountCents,
              description: description,
              createdBy: user?.uid ?? '',
            );
          }
        },
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.totalCents, required this.count});
  final int totalCents;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.lock),
          const SizedBox(width: 8),
          Text(
            'Toplam Emanet: ${Currency.formatCents(totalCents)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          Text('$count müşteri'),
        ],
      ),
    );
  }
}

class _VaultItemTile extends StatelessWidget {
  const _VaultItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });
  final VaultItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      child: ListTile(
        leading: CircleAvatar(child: Text(item.customerName[0])),
        title: Text(item.customerName),
        subtitle: Text(
          'Son güncelleme: ${_formatDate(item.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          Currency.formatCents(item.balanceCents),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: item.balanceCents >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _MovementsPanel extends ConsumerWidget {
  const _MovementsPanel({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(
      StreamProvider((r) =>
          r.read(vaultRepositoryProvider).watchMovements(customerId)),
    );

    return Container(
      height: 280,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Hareketler',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (movements) {
                if (movements.isEmpty) {
                  return const Center(child: Text('Hareket yok'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movements.length,
                  itemBuilder: (context, i) {
                    final m = movements[i];
                    final isDeposit = m.type == VaultMovementType.deposit;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isDeposit ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      title: Text(m.description.isEmpty ? m.typeLabel : m.description),
                      subtitle: Text(_formatDate(m.date)),
                      trailing: Text(
                        '${isDeposit ? '+' : '-'}${Currency.formatCents(m.amountCents)}',
                        style: TextStyle(
                          color: isDeposit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _VaultDialog extends StatefulWidget {
  const _VaultDialog({
    required this.isDeposit,
    required this.customers,
    required this.onSubmit,
  });
  final bool isDeposit;
  final List<Map<String, String>> customers;
  final Future<void> Function(
      String customerId, String customerName, int amountCents, String description) onSubmit;

  @override
  State<_VaultDialog> createState() => _VaultDialogState();
}

class _VaultDialogState extends State<_VaultDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCustomerId;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isDeposit ? 'Kasa Emanet Yatır' : 'Kasa Emanet Çek'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                decoration: const InputDecoration(labelText: 'Müşteri'),
                items: widget.customers
                    .map((c) => DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['name']!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCustomerId = v),
                validator: (v) => v == null ? 'Müşteri seçin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tutar (₺)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Tutar girin';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Geçerli tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isDeposit ? 'Yatır' : 'Çek'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final customerName = widget.customers
        .firstWhere((c) => c['id'] == _selectedCustomerId)['name']!;
    final amountCents =
        (double.parse(_amountCtrl.text.replaceAll(',', '.')) * 100).round();

    setState(() => _loading = true);
    try {
      await widget.onSubmit(
          _selectedCustomerId!, customerName, amountCents, _descCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
