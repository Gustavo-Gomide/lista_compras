class ListMember {
  final String id;
  final String listId;
  final String userId;
  final int accessLevel;
  final DateTime joinedAt;
  final String? email;
  final String? displayName;

  ListMember({
    required this.id,
    required this.listId,
    required this.userId,
    required this.accessLevel,
    required this.joinedAt,
    this.email,
    this.displayName,
  });

  factory ListMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return ListMember(
      id: map['id'] as String,
      listId: map['list_id'] as String,
      userId: map['user_id'] as String,
      accessLevel: map['access_level'] as int,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      email: profile?['email'] as String?,
      displayName: profile?['display_name'] as String?,
    );
  }
}
