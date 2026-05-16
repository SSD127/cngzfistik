import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../data/pistachio_type_repository.dart';
import '../domain/pistachio_type_model.dart';

class PistachioTypesScreen extends ConsumerWidget {
  const PistachioTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(pistachioTypesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fıstık Cinsleri ve Kur')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Yeni Cins'),
        onPressed: () => _showAddDialog(context, ref),
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (types) {
          if (types.isEmpty) return const Center(child: Text('Fıstık cinsi yok.'));
          return ListView.builder(
            itemCount: types.length,
            itemBuilder: (context, i) => _TypeTile(type: types[i]),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final ratioCtrl = TextEditingController(text: '0.45');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Fıstık Cinsi'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Cins Adı'),
                validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: ratioCtrl,
                decoration: const InputDecoration(labelText: 'Varsayılan İç Gramaj (0-1)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0 || n > 1) return '0 ile 1 arası girin';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(pistachioTypeRepositoryProvider).create(
                    name: nameCtrl.text.trim(),
                    defaultInnerGramRatio: double.parse(ratioCtrl.text),
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

class _TypeTile extends ConsumerWidget {
  const _TypeTile({required this.type});
  final PistachioTypeModel type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.eco_outlined),
        title: Text(type.name),
        subtitle: Text(
          'Kur: ${Currency.formatCents(type.currentPricePerKgCents)}/kg  |  İç: ${(type.defaultInnerGramRatio * 100).toStringAsFixed(0)}%',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_money),
              tooltip: 'Kur Güncelle',
              onPressed: () => _showPriceDialog(context, ref),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.tune, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Emanet Girişi Alanları',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Alan Ekle'),
                      onPressed: () => _showAddFieldDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (type.attributeFields.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Alan tanımlanmamış. Eklemek için "Alan Ekle" butonuna basın.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: type.attributeFields.map((field) {
                      return Chip(
                        label: Text(field),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeField(ref, field),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeField(WidgetRef ref, String field) async {
    final updated = List<String>.from(type.attributeFields)..remove(field);
    await ref
        .read(pistachioTypeRepositoryProvider)
        .updateAttributeFields(type.id, updated);
  }

  void _showAddFieldDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type.name} — Yeni Alan'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Alan Adı',
            hintText: 'örn: Gramaj %, Nem %, Boyut',
          ),
          autofocus: true,
          onSubmitted: (_) => _saveField(ctx, ref, ctrl.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () => _saveField(ctx, ref, ctrl.text),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveField(
      BuildContext ctx, WidgetRef ref, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || type.attributeFields.contains(trimmed)) {
      Navigator.pop(ctx);
      return;
    }
    final updated = List<String>.from(type.attributeFields)..add(trimmed);
    await ref
        .read(pistachioTypeRepositoryProvider)
        .updateAttributeFields(type.id, updated);
    if (ctx.mounted) Navigator.pop(ctx);
  }

  void _showPriceDialog(BuildContext context, WidgetRef ref) {
    final priceCtrl = TextEditingController(
      text: (type.currentPricePerKgCents / 100).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type.name} — Kur Güncelle'),
        content: TextFormField(
          controller: priceCtrl,
          decoration: const InputDecoration(
              labelText: 'Yeni Kur (TL/kg)', suffixText: '₺'),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final lira =
                  double.tryParse(priceCtrl.text.replaceAll(',', '.'));
              if (lira == null || lira <= 0) return;
              final cents = (lira * 100).round();
              await ref.read(pistachioTypeRepositoryProvider).updatePrice(
                    typeId: type.id,
                    pricePerKgCents: cents,
                    recordedBy: 'admin',
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
