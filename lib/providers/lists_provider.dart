import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_list.dart';
import '../services/list_service.dart';
import '../services/offline_service.dart';

class ListsProvider extends ChangeNotifier {
  final ListService _listService = ListService();
  final OfflineService _offlineService = OfflineService();
  final SupabaseClient _client = Supabase.instance.client;

  List<ShoppingList> _lists = [];
  List<ShoppingList> get lists => _lists;

  List<String> _pinnedIds = [];
  bool isPinned(String listId) => _pinnedIds.contains(listId);

  bool loading = false;
  String? error;

  RealtimeChannel? _membersSub;

  void _listenToMemberships() {
    if (_membersSub != null) return;

    _membersSub = _client
        .channel('public:lists:home')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lists',
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.delete) {
              final oldId = payload.oldRecord['id'];
              if (oldId != null) {
                if (_lists.any((l) => l.id == oldId)) {
                  _lists.removeWhere((l) => l.id == oldId);
                  notifyListeners();
                }
              }
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final newRecord = payload.newRecord;
              final listId = newRecord['id'];
              final idx = _lists.indexWhere((l) => l.id == listId);
              if (idx != -1) {
                final old = _lists[idx];
                _lists[idx] = ShoppingList(
                  id: old.id,
                  name: newRecord['name'] as String? ?? old.name,
                  ownerId: old.ownerId,
                  accessCode: newRecord['access_code'] as String? ?? old.accessCode,
                  createdAt: old.createdAt,
                  updatedAt: old.updatedAt,
                  myAccessLevel: old.myAccessLevel,
                );
                notifyListeners();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> loadLists() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _lists = await _listService.fetchMyLists();
      _pinnedIds = await _offlineService.getPinnedListIds();
      _sortLists();
      _listenToMemberships(); // Começa a escutar alterações (deletes) em tempo real
    } catch (e) {
      // sem conexão / erro: tenta mostrar listas já baixadas para offline
      final ids = await _offlineService.downloadedListIds();
      final cached = <ShoppingList>[];
      for (final id in ids) {
        final l = await _offlineService.loadCachedList(id);
        if (l != null) cached.add(l);
      }
      if (cached.isNotEmpty) {
        _lists = cached;
        _pinnedIds = await _offlineService.getPinnedListIds();
        _sortLists();
        error = 'Sem conexão. Mostrando listas baixadas.';
      } else {
        error = 'Não foi possível carregar suas listas. Verifique sua conexão.';
      }
    }
    loading = false;
    notifyListeners();
  }

  void _sortLists() {
    _lists.sort((a, b) {
      final aPinned = isPinned(a.id);
      final bPinned = isPinned(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  Future<void> togglePin(String listId) async {
    if (_pinnedIds.contains(listId)) {
      _pinnedIds.remove(listId);
    } else {
      _pinnedIds.add(listId);
    }
    await _offlineService.savePinnedListIds(_pinnedIds);
    _sortLists();
    notifyListeners();
  }

  Future<ShoppingList> createList(String name) async {
    final list = await _listService.createList(name);
    _lists.insert(0, list);
    _sortLists();
    notifyListeners();
    return list;
  }

  Future<ShoppingList> joinByCode(String code) async {
    final list = await _listService.joinListByCode(code);
    if (!_lists.any((l) => l.id == list.id)) {
      _lists.insert(0, list);
      _sortLists();
      notifyListeners();
    }
    return list;
  }



  Future<void> leaveList(String listId) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('list_members').delete().eq('list_id', listId).eq('user_id', uid);
    _lists.removeWhere((l) => l.id == listId);
    notifyListeners();
  }

  Future<void> deleteList(String listId) async {
    await _listService.deleteList(listId);
    _lists.removeWhere((l) => l.id == listId);
    notifyListeners();
  }

  @override
  void dispose() {
    _membersSub?.unsubscribe();
    super.dispose();
  }
}
