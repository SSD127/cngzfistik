import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/data/customer_repository.dart';
import '../../pistachio_types/data/pistachio_type_repository.dart';
import '../../pistachio_types/domain/pistachio_type_model.dart';
import '../data/inventory_repository.dart';

class InventoryDepositScreen extends ConsumerStatefulWidget {
  const InventoryDepositScreen({super.key});

  @override
  ConsumerState<InventoryDepositScreen> createState() =>
      _InventoryDepositScreenState();
}

class _InventoryDepositScreenState
    extends ConsumerState<InventoryDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _customerId;
  String? _pistachioTypeId;
  String _warehouseId = 'depo1';
  final _qtyCtrl = TextEditingController();

  /// Fıstık cinsinin attributeFields'ına göre dinamik controller'lar
  final Map<String, TextEditingController> _attrCtrls = {};
  List<String> _currentFields = [];

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    for (final c in _attrCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTypeSelected(String typeId, List<PistachioTypeModel> types) {
    final type = types.firstWhere((t) => t.id == typeId);
    // Eski controller'ları temizle
    for (final c in _attrCtrls.values) {
      c.dispose();
    }
    _attrCtrls.clear();

    // Yeni cins için controller'lar oluştur
    for (final field in type.attributeFields) {
      _attrCtrls[field] = TextEditingController();
    }

    setState(() {
      _pistachioTypeId = typeId;
      _currentFields = List.from(type.attributeFields);
    });
  }

  Map<String, dynamic> _collectAttributes() {
    return {
      for (final entry in _attrCtrls.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(currentUserProvider.future);
      await ref.read(inventoryRepositoryProvider).createDeposit(
            customerId: _customerId!,
            pistachioTypeId: _pistachioTypeId!,
            warehouseId: _warehouseId,
            quantityKg:
                double.parse(_qtyCtrl.text.replaceAll(',', '.')),
            attributes: _collectAttributes(),
            createdBy: user?.uid ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emanet fıstık girişi kaydedildi')),
        );
        _formKey.currentState!.reset();
        for (final c in _attrCtrls.values) {
          c.clear();
        }
        setState(() {
          _customerId = null;
          _pistachioTypeId = null;
          _currentFields = [];
        });
        _qtyCtrl.clear();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final typesAsync = ref.watch(pistachioTypesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Emanet Fıstık Girişi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Müşteri
              customersAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (customers) => DropdownButtonFormField<String>(
                  value: _customerId,
                  decoration: const InputDecoration(labelText: 'Müşteri'),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.fullName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _customerId = v),
                  validator: (v) => v == null ? 'Müşteri seçin' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Fıstık Cinsi
              typesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (types) => DropdownButtonFormField<String>(
                  value: _pistachioTypeId,
                  decoration: const InputDecoration(labelText: 'Fıstık Cinsi'),
                  items: types
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _onTypeSelected(v, types);
                  },
                  validator: (v) => v == null ? 'Fıstık cinsi seçin' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Dinamik attribute alanları
              if (_currentFields.isNotEmpty) ...[
                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cins Bilgileri',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        ...(_currentFields.map((field) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                controller: _attrCtrls[field],
                                decoration: InputDecoration(
                                  labelText: field,
                                  isDense: true,
                                ),
                              ),
                            ))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Miktar
              TextFormField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Miktar (kg)',
                  suffixText: 'kg',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[,.]?\d{0,3}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Miktar girin';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Geçerli miktar girin';
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.inventory_2),
                label: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Girişi Kaydet'),
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
