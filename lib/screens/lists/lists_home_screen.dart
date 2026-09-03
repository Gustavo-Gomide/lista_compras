import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lists_provider.dart';
import '../../models/shopping_list.dart';
import '../list_detail/list_detail_screen.dart';
import '../settings/settings_screen.dart';
import 'create_list_screen.dart';
import 'join_list_screen.dart';

/// Tela inicial onde o usuário visualiza todas as suas listas de compras (as que criou e as que participa).
class ListsHomeScreen extends StatefulWidget {
  const ListsHomeScreen({super.key});

  @override
  State<ListsHomeScreen> createState() => _ListsHomeScreenState();
}

class _ListsHomeScreenState extends State<ListsHomeScreen> {
  // Chaves globais usadas para identificar os widgets que serão destacados no tutorial (ShowCase).
  final GlobalKey _joinListKey = GlobalKey();
  final GlobalKey _createListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Agenda a execução do carregamento das listas e verificação do tutorial para o final do frame inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListsProvider>().loadLists();
      _checkAndShowTutorial();
    });
  }

  /// Verifica no SharedPreferences se o tutorial já foi exibido alguma vez.
  /// Se for a primeira vez (ou se a chave não existir), exibe o tutorial.
  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool tutorialShown = prefs.getBool('tutorial_home_shown') ?? false;

    if (!tutorialShown) {
      if (mounted) {
        // Inicia a apresentação do tutorial na ordem das chaves fornecidas.
        // ignore: deprecated_member_use
        ShowCaseWidget.of(context).startShowCase([_joinListKey, _createListKey]);
        // Marca que o tutorial já foi visto para não exibir novamente.
        await prefs.setBool('tutorial_home_shown', true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuta as mudanças no ListsProvider (estado das listas).
    final listsProvider = context.watch<ListsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas listas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Personalização e conta',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      // RefreshIndicator permite "puxar para baixo" (pull-to-refresh) para atualizar as listas do servidor.
      body: RefreshIndicator(
        onRefresh: () => context.read<ListsProvider>().loadLists(),
        child: _buildBody(listsProvider),
      ),
      // Botoes flutuantes (FABs) empilhados verticalmente usando Column.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Widget do tutorial: Destaca a funcionalidade de entrar com código.
          Showcase(
            key: _joinListKey,
            description: 'Clique aqui se alguém te passou um código para entrar em uma lista existente!',
            child: FloatingActionButton.extended(
              heroTag: 'join',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinListScreen())),
              label: const Text('Entrar com código'),
              icon: const Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          // Widget do tutorial: Destaca a criação de nova lista.
          Showcase(
            key: _createListKey,
            description: 'Crie sua própria lista de compras para começar e compartilhe com quem quiser!',
            child: FloatingActionButton.extended(
              heroTag: 'create',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListScreen())),
              label: const Text('Nova lista'),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o corpo principal da tela de listas, exibindo carregamento, estado vazio ou as listas.
  Widget _buildBody(ListsProvider provider) {
    // Exibe indicador de carregamento caso as listas ainda estejam sendo requisitadas.
    if (provider.loading && provider.lists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Caso não tenha nenhuma lista, exibe uma interface amigável de estado vazio (Empty State).
    if (provider.lists.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.shopping_basket_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Você ainda não tem listas', textAlign: TextAlign.center),
          const Text('Crie uma nova ou entre com um código', textAlign: TextAlign.center),
        ],
      );
    }

    // Exibe a lista (ListView) de todas as listas de compra do usuário.
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 8),
      itemCount: provider.lists.length,
      itemBuilder: (context, index) {
        final ShoppingList list = provider.lists[index];
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.list_alt, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            // Título exibe o nome e, ao lado, se estiver fixada, mostra o ícone de alfinete (push_pin).
            title: Row(
              children: [
                Expanded(child: Text(list.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (provider.isPinned(list.id)) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.push_pin, size: 16)),
              ],
            ),
            subtitle: Text('Código: ${list.accessCode}', maxLines: 1, overflow: TextOverflow.ellipsis),
            // Menu flutuante (...) de opções para cada lista.
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'pin') {
                  await provider.togglePin(list.id);
                } else if (value == 'leave') {
                  await provider.leaveList(list.id);
                } else if (value == 'delete') {
                  await provider.deleteList(list.id);
                }
              },
              itemBuilder: (context) {
                // Verifica se o usuário atual é o dono (owner) da lista
                final isOwner = context.read<AuthProvider>().user?.id == list.ownerId;
                final isPinned = provider.isPinned(list.id);
                return [
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                        const SizedBox(width: 8),
                        Text(isPinned ? 'Desfixar' : 'Fixar'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Se não for dono, pode apenas "Sair da lista".
                  if (!isOwner)
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Sair da lista', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  // Se for dono, pode "Deletar lista".
                  if (isOwner)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Deletar lista', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ];
              },
            ),
            // Ao clicar, entra na lista (vai para ListDetailScreen).
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ListDetailScreen(list: list)),
            ),
          ),
        );
      },
    );
  }
}

