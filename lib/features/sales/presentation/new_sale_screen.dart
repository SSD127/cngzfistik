import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/data/customer_repository.dart';
import '../../pistachio_types/data/pistachio_type_repository.dart';
import '../data/sales_repository.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _customerId;
  String? _pistachioTypeId;
  final String _warehouseId = 'depo1';
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _innerGramCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _previewCents = 0;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _innerGramCtrl.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final innerPct = double.tryParse(_innerGramCtrl.text.replaceAll(',', '.')) ?? 0;

    if (qty <= 0 || price <= 0 || innerPct <= 0) {
      setState(() => _previewCents = 0);
      return;
    }
    final pricePerKgCents = (price * 100).round();
    final innerRatio = innerPct / 100.0;
    setState(() {
      _previewCents =
          Currency.calculateSaleAmountCents(qty, pricePerKgCents, innerRatio);
    });
  }

  /// Fıstık cinsi seçilince varsayılan değerleri doldur (kullanıcı değiştirebilir)
  void _onTypeSelected(String typeId) {
    setState(() => _pistachioTypeId = typeId);
    final types = ref.read(pistachioTypesStreamProvider).valueOrNull ?? [];
    final type = types.where((t) => t.id == typeId).firstOrNull;
    if (type != null) {
      _priceCtrl.text =
          (type.currentPricePerKgCents / 100).toStringAsFixed(2);
      _innerGramCtrl.text =
          (type.defaultInnerGramRatio * 100).toStringAsFixed(1);
    }
    _updatePreview();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(currentUserProvider.future);
      final pricePerKgCents =
          (double.parse(_priceCtrl.text.replaceAll(',', '.')) * 100).round();
      final innerRatio =
          double.parse(_innerGramCtrl.text.replaceAll(',', '.')) / 100.0;

      await ref.read(salesRepositoryProvider).createSale(
            customerId: _customerId!,
            pistachioTypeId: _pistachioTypeId!,
            warehouseId: _warehouseId,
            quantityKg:
                double.parse(_qtyCtrl.text.replaceAll(',', '.')),
            pricePerKgCents: pricePerKgCents,
            innerGramRatio: innerRatio,
            createdBy: user?.uid ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satış kaydedildi')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _customerId = null;
          _pistachioTypeId = null;
          _previewCents = 0;
        });
        _qtyCtrl.clear();
        _priceCtrl.clear();
        _innerGramCtrl.clear();
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
      appBar: AppBar(title: const Text('Yeni Satış')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Müşteri seçimi
              customersAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (customers) => DropdownButtonFormField<String>(
                  value: _customerId,
                  decoration: const InputDecoration(labelText: 'Müşteri'),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                                '${c.fullName} — ${Currency.formatCents(c.cashBalanceCents)}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _customerId = v),
                  validator: (v) => v == null ? 'Müşteri seçin' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Fıstık cinsi seçimi
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
                    if (v != null) _onTypeSelected(v);
                  },
                  validator: (v) => v == null ? 'Fıstık cinsi seçin' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Miktar + Fiyat + İç gram — aynı satırda
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Miktar',
                        suffixText: 'kg',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+[,.]?\d{0,3}')),
                      ],
                      onChanged: (_) => _updatePreview(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Miktar girin';
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fiyat/kg (₺)',
                        suffixText: '₺',
                        helperText: 'İç gramı başına',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+[,.]?\d{0,2}')),
                      ],
                      onChanged: (_) => _updatePreview(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Fiyat girin';
                        final n =
                            double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _innerGramCtrl,
                      decoration: const InputDecoration(
                        labelText: 'İç Gram (%)',
                        suffixText: '%',
                        helperText: 'Örn: 45 → %45',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+[,.]?\d{0,1}')),
                      ],
                      onChanged: (_) => _updatePreview(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'İç gram girin';
                        final n =
                            double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0 || n > 100) {
                          return '0–100 arası';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hesap özeti kartı
              if (_previewCents > 0)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Hesaplama:'),
                            Text(
                              '${_qtyCtrl.text} kg × '
                              '${_innerGramCtrl.text}% iç × '
                              '${_priceCtrl.text} ₺/kg',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Toplam Tutar:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Currency.formatCents(_previewCents),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                icon: const Icon(Icons.sell),
                label: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Satışı Kaydet'),
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
