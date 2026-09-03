import 'package:flutter/material.dart';
import '../../providers/lists_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/list_item.dart';
import '../../models/shopping_list.dart';
import '../../providers/list_detail_provider.dart';
import '../../widgets/list_item_tile.dart';
import '../../widgets/loading_indicator.dart';
import 'add_edit_item_sheet.dart';
import 'list_members_screen.dart';

class ListDetailScreen extends StatelessWidget {
  final ShoppingList list;
  const ListDetailScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ListDetailProvider(list.id)..init(),
      child: _ListDetailView(list: list),
    );
  }
}

class _ListDetailView extends StatelessWidget {
  final ShoppingList list;
  const _ListDetailView({required this.list});

  Future<void> _shareCode(BuildContext context, String code) async {
    await Share.share('Entre na minha lista de compras "${list.name}" com o código: $code');
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código copiado!')),
      );
    }
  }

  Future<void> _downloadOffline(BuildContext context) async {
    final provider = context.read<ListDetailProvider>();
    await provider.downloadForOffline(list);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista baixada para acesso offline')),
      );
    }
  }

  void _openAddItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ChangeNotifierProvider.value(
            value: context.read<ListDetailProvider>(),
            child: const AddEditItemSheet(),
          ),
        ),
      ),
    );
  }

  void _openEditItem(BuildContext context, ListItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ChangeNotifierProvider.value(
            value: context.read<ListDetailProvider>(),
            child: AddEditItemSheet(existingItem: item),
          ),
        ),
      ),
    );
  }

  Future<void> _leaveOrDeleteList(BuildContext context, bool isOwner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isOwner ? 'Deletar lista?' : 'Sair da lista?'),
        content: Text(isOwner
            ? 'Esta ação apagará a lista para todos os membros e não pode ser desfeita.'
            : 'Você perderá o acesso a esta lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isOwner ? 'Deletar' : 'Sair', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final listsProvider = context.read<ListsProvider>();
    if (isOwner) {
      await listsProvider.deleteList(list.id);
    } else {
      await listsProvider.leaveList(list.id);
    }
    
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListDetailProvider>();
    final currentList = context.watch<ListsProvider>().lists.firstWhere((l) => l.id == list.id, orElse: () => list);
    final isOwner = currentList.ownerId == Supabase.instance.client.auth.currentUser!.id;
    
    if (provider.isDeleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A lista foi deletada.')),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentList.name),
        actions: [
          if (provider.offlineMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, size: 20),
            ),
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: 'Membros',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ListMembersScreen(list: currentList)),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') _copyCode(context, currentList.accessCode);
              if (value == 'share') _shareCode(context, currentList.accessCode);
              if (value == 'download') _downloadOffline(context);
              if (value == 'leave') _leaveOrDeleteList(context, isOwner);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Copiar código')),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(leading: Icon(Icons.share), title: Text('Compartilhar código')),
              ),
              const PopupMenuItem(
                value: 'download',
                child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Baixar para offline')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'leave',
                child: ListTile(
                  leading: Icon(isOwner ? Icons.delete_outline : Icons.exit_to_app, color: Colors.red),
                  title: Text(isOwner ? 'Deletar lista' : 'Sair da lista', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: provider.loading
          ? const LoadingIndicator()
          : Column(
              children: [
                Semantics(
                  button: true,
                  label: 'Código de acesso ${currentList.accessCode}. Toque para copiar.',
                  child: InkWell(
                    onTap: () => _copyCode(context, currentList.accessCode),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Código: ${currentList.accessCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_outlined, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: provider.items.isEmpty
                      ? const Center(child: Text('Nenhum item na lista ainda'))
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: provider.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = provider.items[index];
                            return ListItemTile(
                              item: item,
                              canManage: provider.canManageItems,
                              onToggle: (_) => provider.toggleChecked(item),
                              onEdit: () => _openEditItem(context, item),
                              onDelete: () => provider.deleteItem(item.id),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: provider.canManageItems
          ? FloatingActionButton(
              onPressed: () => _openAddItem(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
