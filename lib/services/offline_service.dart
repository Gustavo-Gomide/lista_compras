import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';
import '../models/list_item.dart';

/// Guarda uma cópia local (somente no dispositivo do usuário) de listas
/// baixadas para acesso offline. Ao voltar online, a tela de detalhe
/// volta a usar dados em tempo real do Supabase.
class OfflineService {
  static String _listKey(String listId) => 'offline_list_$listId';
  static String _itemsKey(String listId) => 'offline_items_$listId';
  static const _downloadedIndexKey = 'offline_downloaded_lists';
  static const _pinnedListsKey = 'pinned_lists';

  Future<List<String>> getPinnedListIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pinnedListsKey) ?? [];
  }

  Future<void> savePinnedListIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pinnedListsKey, ids);
  }

  Future<void> saveListForOffline(ShoppingList list, List<ListItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey(list.id), jsonEncode(list.toCacheMap()));
    await prefs.setString(_itemsKey(list.id), jsonEncode(items.map((e) => e.toCacheMap()).toList()));

    final index = prefs.getStringList(_downloadedIndexKey) ?? [];
    if (!index.contains(list.id)) {
      index.add(list.id);
      await prefs.setStringList(_downloadedIndexKey, index);
    }
  }

  Future<bool> isDownloaded(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_listKey(listId));
  }

  Future<List<String>> downloadedListIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_downloadedIndexKey) ?? [];
  }

  Future<ShoppingList?> loadCachedList(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_listKey(listId));
    if (raw == null) return null;
    return ShoppingList.fromCacheMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<ListItem>> loadCachedItems(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemsKey(listId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ListItem.fromCacheMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> removeOffline(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_listKey(listId));
    await prefs.remove(_itemsKey(listId));
    final index = prefs.getStringList(_downloadedIndexKey) ?? [];
    index.remove(listId);
    await prefs.setStringList(_downloadedIndexKey, index);
  }
}
