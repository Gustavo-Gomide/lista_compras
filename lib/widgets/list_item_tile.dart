import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../core/customization/customization_provider.dart';
import '../models/list_item.dart';
import 'custom_checkbox.dart';

class ListItemTile extends StatelessWidget {
  final ListItem item;
  final bool canManage;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ListItemTile({
    super.key,
    required this.item,
    required this.canManage,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  Widget build(BuildContext context) {
    final customization = context.watch<CustomizationProvider>().model;

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CustomCheckbox(
        value: item.checked,
        onChanged: onToggle,
        checkedSvg: customization.checkedSvg,
        uncheckedSvg: customization.uncheckedSvg,
        semanticLabel: item.name,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.checked ? TextDecoration.lineThrough : null,
          color: item.checked ? Theme.of(context).disabledColor : null,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_formatQty(item.quantity)} ${item.unit}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: canManage
          ? Semantics(
              button: true,
              label: 'Editar ${item.name}',
              child: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            )
          : null,
      onTap: () => onToggle(!item.checked),
    );

    if (!canManage) return tile;

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Remover',
          ),
        ],
      ),
      child: tile,
    );
  }
}
