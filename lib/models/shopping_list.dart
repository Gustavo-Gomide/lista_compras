/// Modelo de dados que representa uma lista de compras no sistema.
/// 
/// Contém informações básicas como nome, ID do dono e o código de acesso
/// usado para compartilhamento com outros usuários.
class ShoppingList {
  /// Identificador único da lista (UUID gerado pelo Supabase).
  final String id;
  
  /// Nome de exibição da lista (ex: "Mercado do mês").
  final String name;
  
  /// Identificador único (UUID) do criador/dono da lista.
  final String ownerId;
  
  /// Código alfanumérico curto gerado para permitir que outros entrem na lista.
  final String accessCode;
  
  /// Data e hora em que a lista foi criada.
  final DateTime createdAt;
  
  /// Data e hora da última alteração na lista.
  final DateTime updatedAt;
  
  /// Nível de acesso do usuário logado nesta lista (0 = Leitura, 1 = Edição, 2 = Admin).
  final int? myAccessLevel;

  /// Construtor padrão para inicializar todos os campos da lista.
  ShoppingList({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.accessCode,
    required this.createdAt,
    required this.updatedAt,
    this.myAccessLevel,
  });

  /// Construtor de fábrica (factory) que cria um objeto [ShoppingList]
  /// a partir de um [Map] retornado pelo banco de dados (Supabase).
  ///
  /// Opcionalmente, pode receber o [myAccessLevel] separadamente, 
  /// já que ele costuma vir de uma tabela de relacionamento (membros).
  factory ShoppingList.fromMap(Map<String, dynamic> map, {int? myAccessLevel}) => ShoppingList(
        id: map['id'] as String,
        name: map['name'] as String,
        ownerId: map['owner_id'] as String,
        accessCode: map['access_code'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        myAccessLevel: myAccessLevel,
      );

  /// Converte a instância atual em um [Map] estruturado para salvar
  /// no banco de dados local (cache) ou SharedPreferences.
  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'name': name,
        'owner_id': ownerId,
        'access_code': accessCode,
        'created_at': createdAt.toIso8601String(), // Converte data para string no padrão ISO
        'updated_at': updatedAt.toIso8601String(),
        'my_access_level': myAccessLevel,
      };

  /// Construtor de fábrica para recriar o objeto a partir de dados em cache (armazenamento local).
  factory ShoppingList.fromCacheMap(Map<String, dynamic> map) => ShoppingList(
        id: map['id'] as String,
        name: map['name'] as String,
        ownerId: map['owner_id'] as String,
        accessCode: map['access_code'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        myAccessLevel: map['my_access_level'] as int?,
      );
}
