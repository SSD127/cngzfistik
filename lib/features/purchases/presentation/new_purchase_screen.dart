import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../../customers/data/customer_repository.dart';
import '../../pistachio_types/data/pistachio_type_repository.dart';
import '../data/purchases_repository.dart';

class NewPurchaseScreen extends ConsumerStatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  ConsumerState<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends ConsumerState<NewPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _customerId;
  String? _pistachioTypeId;
  String _warehouseId = 'depo1';
  String _source = 'warehouse';
  String _paymentMethod = 'cash_balance';
  final _qtyCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _previewCents = 0;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _updatePreview() {
    if (_pistachioTypeId == null || _qtyCtrl.text.isEmpty) {
      setState(() => _previewCents = 0);
      return;
    }
    final types = ref.read(pistachioTypesStreamProvider).valueOrNull ?? [];
    final type = types.where((t) => t.id == _pistachioTypeId).firstOrNull;
    if (type == null) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    setState(() {
      _previewCents = (qty * type.currentPricePerKgCents).round();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(purchasesRepositoryProvider).createPurchase(
            customerId: _customerId!,
            pistachioTypeId: _pistachioTypeId!,
            warehouseId: _warehouseId,
            quantityKg: double.parse(_qtyCtrl.text),
            source: _source,
            paymentMethod: _paymentMethod,
            createdBy: 'admin',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alım kaydedildi')),
        );
        _formKey.currentState!.reset();
        setState(() { _customerId = null; _pistachioTypeId = null; _previewCents = 0; });
        _qtyCtrl.clear();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final typesAsync = ref.watch(pistachioTypesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Alım')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              customersAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (customers) => DropdownButtonFormField<String>(
                  value: _customerId,
                  decoration: const InputDecoration(labelText: 'Müşteri'),
                  items: customers.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.fullName} — ${Currency.formatCents(c.cashBalanceCents)}'),
                  )).toList(),
                  onChanged: (v) => setState(() => _customerId = v),
                  validator: (v) => v == null ? 'Müşteri seçin' : null,
                ),
              ),
              const SizedBox(height: 16),
              typesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (types) => DropdownButtonFormField<String>(
                  value: _pistachioTypeId,
                  decoration: const InputDecoration(labelText: 'Fıstık Cinsi'),
                  items: types.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.name} — ${Currency.formatCents(t.currentPricePerKgCents)}/kg'),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _pistachioTypeId = v);
                    _updatePreview();
                  },
                  validator: (v) => v == null ? 'Fıstık cinsi seçin' : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _warehouseId,
                decoration: const InputDecoration(labelText: 'Depo ID'),
                onChanged: (v) => _warehouseId = v,
                validator: (v) => v!.isEmpty ? 'Depo girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(labelText: 'Miktar (kg)', suffixText: 'kg'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updatePreview(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Miktar girin';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Geçerli miktar girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _source,
                decoration: const InputDecoration(labelText: 'Kaynak'),
                items: const [
                  DropdownMenuItem(value: 'warehouse', child: Text('Depodan')),
                  DropdownMenuItem(value: 'external', child: Text('Dışarıdan')),
                ],
                onChanged: (v) => setState(() => _source = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Ödeme Yöntemi'),
                items: const [
                  DropdownMenuItem(value: 'cash_balance', child: Text('Kasa Bakiyesinden')),
                  DropdownMenuItem(value: 'cash', child: Text('Nakit')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              if (_previewCents > 0) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tahmini Tutar:'),
                        Text(Currency.formatCents(_previewCents),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Alımı Kaydet'),
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}
