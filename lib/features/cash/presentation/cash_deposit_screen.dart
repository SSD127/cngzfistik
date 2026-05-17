import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../../customers/data/customer_repository.dart';
import '../data/cash_repository.dart';

class CashDepositScreen extends ConsumerStatefulWidget {
  const CashDepositScreen({super.key});

  @override
  ConsumerState<CashDepositScreen> createState() => _CashDepositScreenState();
}

class _CashDepositScreenState extends ConsumerState<CashDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _customerId;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final liralar = double.parse(_amountCtrl.text.replaceAll(',', '.'));
      final cents = (liralar * 100).round();
      await ref.read(cashRepositoryProvider).deposit(
            customerId: _customerId!,
            amountCents: cents,
            description: _descCtrl.text.trim().isEmpty
                ? 'Nakit para girişi'
                : _descCtrl.text.trim(),
            createdBy: 'admin',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Para girişi kaydedildi')),
        );
        _formKey.currentState!.reset();
        setState(() { _customerId = null; });
        _amountCtrl.clear();
        _descCtrl.clear();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Para Girişi')),
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
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'Tutar (TL)', suffixText: '₺'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Tutar girin';
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Geçerli tutar girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Açıklama (isteğe bağlı)'),
                  ),
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
                    icon: const Icon(Icons.add_card),
                    label: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet'),
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
