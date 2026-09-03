import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_list.dart';

class ListService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Todas as listas em que o usuário logado é membro, com o nível de acesso dele.
  Future<List<ShoppingList>> fetchMyLists() async {
    final uid = _client.auth.currentUser!.id;
    final response = await _client
        .from('list_members')
        .select('access_level, lists(*)')
        .eq('user_id', uid);

    final rows = response as List;
    final result = rows.map((row) {
      final listMap = row['lists'] as Map<String, dynamic>;
      return ShoppingList.fromMap(listMap, myAccessLevel: row['access_level'] as int);
    }).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<ShoppingList> createList(String name) async {
    final result = await _client.rpc('create_list', params: {'p_name': name});
    final map = result as Map<String, dynamic>;
    return ShoppingList.fromMap(map, myAccessLevel: 3);
  }

  Future<ShoppingList> joinListByCode(String code) async {
    final result = await _client.rpc('join_list_by_code', params: {'p_code': code});
    final map = result as Map<String, dynamic>;
    return ShoppingList.fromMap(map, myAccessLevel: 1);
  }

  Future<String> regenerateCode(String listId) async {
    final result = await _client.rpc('regenerate_list_code', params: {'p_list_id': listId});
    return result as String;
  }

  Future<void> deleteList(String listId) async {
    await _client.from('lists').delete().eq('id', listId);
  }

  Future<int?> fetchMyAccessLevel(String listId) async {
    final uid = _client.auth.currentUser!.id;
    final response = await _client
        .from('list_members')
        .select('access_level')
        .eq('list_id', listId)
        .eq('user_id', uid)
        .maybeSingle();
    if (response == null) return null;
    return response['access_level'] as int;
  }
}
