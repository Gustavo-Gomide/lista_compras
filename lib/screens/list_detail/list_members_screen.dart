import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/lists_provider.dart' as import_lists_provider;
import '../../models/list_member.dart';
import '../../models/shopping_list.dart';
import '../../services/member_service.dart';
import '../../services/list_service.dart';
import '../../widgets/access_level_badge.dart';
import '../../widgets/loading_indicator.dart';

class ListMembersScreen extends StatefulWidget {
  final ShoppingList list;
  const ListMembersScreen({super.key, required this.list});

  @override
  State<ListMembersScreen> createState() => _ListMembersScreenState();
}

class _ListMembersScreenState extends State<ListMembersScreen> {
  final _memberService = MemberService();
  final _listService = ListService();
  List<ListMember> _members = [];
  bool _loading = true;
  String _currentCode = '';

  @override
  void initState() {
    super.initState();
    _currentCode = widget.list.accessCode;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _members = await _memberService.fetchMembers(widget.list.id);
    setState(() => _loading = false);
  }

  Future<void> _regenerateCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gerar novo código?'),
        content: const Text('O código atual deixará de funcionar para novos convites.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final newCode = await _listService.regenerateCode(widget.list.id);
    
    if (mounted) {
      setState(() => _currentCode = newCode);
    }
  }

  Future<void> _removeMember(ListMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover membro?'),
        content: Text('${member.displayName ?? member.email} perderá acesso a esta lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _memberService.removeMember(widget.list.id, member.userId);
    _load();
  }

  Future<void> _changeLevel(ListMember member, int level) async {
    await _memberService.setAccessLevel(widget.list.id, member.userId, level);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final currentUserMember = _members.cast<ListMember?>().firstWhere(
      (m) => m?.userId == currentUserId,
      orElse: () => null,
    );
    final isAdmin = widget.list.ownerId == currentUserId || (currentUserMember?.accessLevel ?? 1) >= 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Membros da lista')),
      body: _loading
          ? const LoadingIndicator()
          : ListView(
              children: [
                if (isAdmin)

                ListTile(
                  title: const Text('Código de acesso'),
                  subtitle: Text(
                    _currentCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 0,
                    alignment: WrapAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        tooltip: 'Copiar código',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: _currentCode));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Código copiado!')));
                          }
                        },
                      ),
                      TextButton.icon(
                        onPressed: _regenerateCode,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Novo'),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) const Divider(),
                ..._members.map((m) {
                  final isOwner = m.userId == widget.list.ownerId;
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      m.displayName?.trim().isNotEmpty == true ? m.displayName! : (m.email ?? 'Membro sem perfil'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AccessLevelBadge(level: m.accessLevel),
                        if (isOwner) const Text('(dono)'),
                      ],
                    ),
                    trailing: (!isAdmin || isOwner)
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'remove') _removeMember(m);
                              if (value == 'lvl1') _changeLevel(m, 1);
                              if (value == 'lvl2') _changeLevel(m, 2);
                              if (value == 'lvl3') _changeLevel(m, 3);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'lvl1', child: Text('Nível 1 - Ver e marcar')),
                              PopupMenuItem(value: 'lvl2', child: Text('Nível 2 - Adicionar/editar')),
                              PopupMenuItem(value: 'lvl3', child: Text('Nível 3 - Administrador')),
                              PopupMenuDivider(),
                              PopupMenuItem(value: 'remove', child: Text('Remover da lista')),
                            ],
                          ));
                }),
                const Divider(),
                ListTile(
                  leading: Icon(
                    widget.list.ownerId == Supabase.instance.client.auth.currentUser!.id
                        ? Icons.delete_outline
                        : Icons.exit_to_app,
                    color: Colors.red,
                  ),
                  title: Text(
                    widget.list.ownerId == Supabase.instance.client.auth.currentUser!.id
                        ? 'Deletar lista'
                        : 'Sair da lista',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    final isOwner = widget.list.ownerId == Supabase.instance.client.auth.currentUser!.id;
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

                    final listsProvider = context.read<import_lists_provider.ListsProvider>();
                    if (isOwner) {
                      await listsProvider.deleteList(widget.list.id);
                    } else {
                      await listsProvider.leaveList(widget.list.id);
                    }

                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
