import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/list_item.dart';
import '../../providers/list_detail_provider.dart';

class AddEditItemSheet extends StatefulWidget {
  final ListItem? existingItem;
  const AddEditItemSheet({super.key, this.existingItem});

  @override
  State<AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends State<AddEditItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late String _unit;
  bool _loading = false;

  static const _units = <String, String>{
    'un': 'un (unidade)',
    'kg': 'kg (quilo)',
    'g': 'g (grama)',
    'L': 'L (litro)',
    'ml': 'ml (mililitro)',
    'pct': 'pct (pacote)',
    'cx': 'cx (caixa)',
    'dz': 'dz (dúzia)',
    'maço': 'maço',
    'garrafa': 'garrafa',
    'lata': 'lata',
    'saco': 'saco',
  };

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _qtyController = TextEditingController(text: item != null ? _formatQty(item.quantity) : '1');
    final rawUnit = item?.unit;
    _unit = (rawUnit != null && _units.containsKey(rawUnit)) ? rawUnit : 'un';
  }

  String _formatQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 1;
    if (name.isEmpty) return;

    setState(() => _loading = true);
    final provider = context.read<ListDetailProvider>();
    try {
      if (widget.existingItem == null) {
        await provider.addItem(name, qty, _unit);
      } else {
        await provider.updateItem(widget.existingItem!.id, name: name, quantity: qty, unit: _unit);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.existingItem == null) return;
    setState(() => _loading = true);
    await context.read<ListDetailProvider>().deleteItem(widget.existingItem!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEditing ? 'Editar item' : 'Novo item', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Produto', hintText: 'Ex: Carvão'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                  items: _units.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (isEditing)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover', overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ),
              if (isEditing) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'Salvar' : 'Adicionar', overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
