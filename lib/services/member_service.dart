import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/list_member.dart';

class MemberService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Busca membros e perfis em duas consultas separadas e junta no
  /// cliente. Evita depender do embedding automático do PostgREST
  /// (list_members -> profiles), que é frágil e foi a causa do nome
  /// não aparecer (caía no fallback do UUID).
  Future<List<ListMember>> fetchMembers(String listId) async {
    final memberRows = await _client
        .from('list_members')
        .select()
        .eq('list_id', listId)
        .order('joined_at');

    final members = (memberRows as List).cast<Map<String, dynamic>>();
    if (members.isEmpty) return [];

    final userIds = members.map((m) => m['user_id'] as String).toSet().toList();

    final profileRows = await _client
        .from('profiles')
        .select('id, email, display_name')
        .inFilter('id', userIds);

    final profilesById = {
      for (final p in (profileRows as List).cast<Map<String, dynamic>>()) p['id'] as String: p,
    };

    return members.map((m) {
      final profile = profilesById[m['user_id']];
      return ListMember.fromMap({...m, 'profiles': profile});
    }).toList();
  }

  Future<void> removeMember(String listId, String userId) async {
    await _client.from('list_members').delete().eq('list_id', listId).eq('user_id', userId);
  }

  Future<void> setAccessLevel(String listId, String userId, int level) async {
    await _client.rpc('set_member_access_level', params: {
      'p_list_id': listId,
      'p_user_id': userId,
      'p_level': level,
    });
  }
}
