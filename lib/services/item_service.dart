import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/list_item.dart';

class ItemService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Stream em tempo real dos itens da lista (usa Supabase Realtime).
  Stream<List<ListItem>> watchItems(String listId) {
    return _client
        .from('list_items')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId)
        .order('created_at')
        .map((rows) {
          final items = rows.map((r) => ListItem.fromMap(r)).toList();
          items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return items;
        });
  }

  Future<List<ListItem>> fetchItems(String listId) async {
    final rows = await _client.from('list_items').select().eq('list_id', listId).order('created_at');
    final items = (rows as List).map((r) => ListItem.fromMap(r as Map<String, dynamic>)).toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<void> addItem(String listId, String name, double quantity, String unit) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('list_items').insert({
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'created_by': uid,
    });
  }

  Future<void> updateItem(String itemId, {String? name, double? quantity, String? unit}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (quantity != null) data['quantity'] = quantity;
    if (unit != null) data['unit'] = unit;
    if (data.isEmpty) return;
    await _client.from('list_items').update(data).eq('id', itemId);
  }

  Future<void> toggleChecked(String itemId, bool checked) async {
    await _client.from('list_items').update({'checked': checked}).eq('id', itemId);
  }

  Future<void> deleteItem(String itemId) async {
    await _client.from('list_items').delete().eq('id', itemId);
  }
}
