import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/list_item.dart';
import '../models/shopping_list.dart';
import '../services/item_service.dart';
import '../services/list_service.dart';
import '../services/offline_service.dart';

class ListDetailProvider extends ChangeNotifier {
  final ItemService _itemService = ItemService();
  final ListService _listService = ListService();
  final OfflineService _offlineService = OfflineService();

  final String listId;
  List<ListItem> items = [];
  int myAccessLevel = 1;
  bool loading = true;
  bool offlineMode = false;
  bool isDeleted = false;
  RealtimeChannel? _sub;
  StreamSubscription? _listSub;

  ListDetailProvider(this.listId);

  bool get canManageItems => myAccessLevel >= 2;
  bool get isAdmin => myAccessLevel >= 3;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    try {
      myAccessLevel = await _listService.fetchMyAccessLevel(listId) ?? 1;
      items = await _itemService.fetchItems(listId);
      offlineMode = false;
      _listenRealtime();
    } catch (e) {
      offlineMode = true;
      items = await _offlineService.loadCachedItems(listId);
      final cachedList = await _offlineService.loadCachedList(listId);
      myAccessLevel = cachedList?.myAccessLevel ?? 1;
    }
    loading = false;
    notifyListeners();
  }

  void _listenRealtime() {
    _listSub?.cancel();
    _listSub = Supabase.instance.client
        .from('lists')
        .stream(primaryKey: ['id'])
        .eq('id', listId)
        .listen((rows) {
      if (rows.isEmpty) {
        isDeleted = true;
        notifyListeners();
      }
    });

    _sub?.unsubscribe();
    // Usa channel manual em vez de .stream().eq() porque o Supabase não envia a coluna list_id 
    // no old_record de eventos DELETE por padrão, o que faz o filtro .eq() ignorar os deletes.
    _sub = Supabase.instance.client
        .channel('public:list_items:$listId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'list_items',
          callback: (payload) async {
            if (payload.eventType == PostgresChangeEvent.delete) {
              final oldId = payload.oldRecord['id'];
              items.removeWhere((i) => i.id == oldId);
              notifyListeners();
            } else {
              // Para inserts e updates, podemos verificar o list_id.
              final record = payload.newRecord;
              if (record['list_id'] == listId) {
                if (payload.eventType == PostgresChangeEvent.insert) {
                  items.add(ListItem.fromMap(record));
                } else if (payload.eventType == PostgresChangeEvent.update) {
                  final idx = items.indexWhere((i) => i.id == record['id']);
                  if (idx != -1) {
                    items[idx] = ListItem.fromMap(record);
                  } else {
                    items.add(ListItem.fromMap(record));
                  }
                }
                items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                notifyListeners();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> addItem(String name, double quantity, String unit) {
    return _itemService.addItem(listId, name, quantity, unit);
  }

  Future<void> updateItem(String itemId, {String? name, double? quantity, String? unit}) async {
    final idx = items.indexWhere((i) => i.id == itemId);
    ListItem? oldItem;
    if (idx != -1) {
      oldItem = items[idx];
      items[idx] = oldItem.copyWith(
        name: name ?? oldItem.name,
        quantity: quantity ?? oldItem.quantity,
        unit: unit ?? oldItem.unit,
      );
      notifyListeners();
    }
    
    try {
      await _itemService.updateItem(itemId, name: name, quantity: quantity, unit: unit);
    } catch (e) {
      if (idx != -1 && oldItem != null) {
        items[idx] = oldItem;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> toggleChecked(ListItem item) async {
    // atualização otimista para resposta instantânea na UI
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      items[idx] = item.copyWith(checked: !item.checked);
      notifyListeners();
    }
    try {
      await _itemService.toggleChecked(item.id, !item.checked);
    } catch (e) {
      if (idx != -1) {
        items[idx] = item;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    // Remoção otimista: remove da lista local imediatamente para feedback instantâneo.
    final idx = items.indexWhere((i) => i.id == itemId);
    ListItem? removed;
    if (idx != -1) {
      removed = items.removeAt(idx);
      notifyListeners();
    }

    try {
      await _itemService.deleteItem(itemId);
    } catch (e) {
      // Se falhar, reinsere o item na posição original.
      if (removed != null && idx != -1) {
        items.insert(idx.clamp(0, items.length), removed);
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> downloadForOffline(ShoppingList currentList) async {
    await _offlineService.saveListForOffline(
      ShoppingList(
        id: currentList.id,
        name: currentList.name,
        ownerId: currentList.ownerId,
        accessCode: currentList.accessCode,
        createdAt: currentList.createdAt,
        updatedAt: currentList.updatedAt,
        myAccessLevel: myAccessLevel,
      ),
      items,
    );
  }

  @override
  void dispose() {
    _sub?.unsubscribe();
    _listSub?.cancel();
    super.dispose();
  }
}
