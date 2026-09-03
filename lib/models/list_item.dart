class ListItem {
  final String id;
  final String listId;
  final String name;
  final double quantity;
  final String unit;
  final bool checked;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ListItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.checked,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListItem.fromMap(Map<String, dynamic> map) => ListItem(
        id: map['id'] as String,
        listId: map['list_id'] as String,
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        checked: map['checked'] as bool,
        createdBy: map['created_by'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'list_id': listId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'checked': checked,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ListItem.fromCacheMap(Map<String, dynamic> map) => ListItem(
        id: map['id'] as String,
        listId: map['list_id'] as String,
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        checked: map['checked'] as bool,
        createdBy: map['created_by'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  ListItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    bool? checked,
  }) =>
      ListItem(
        id: id,
        listId: listId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        checked: checked ?? this.checked,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
