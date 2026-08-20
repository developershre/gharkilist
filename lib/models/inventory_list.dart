class InventoryList {
  final int? id;
  final String name;
  final String iconEmoji;
  final bool isDefault;
  final DateTime createdAt;

  InventoryList({
    this.id,
    required this.name,
    this.iconEmoji = '📦',
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  InventoryList copyWith({
    int? id,
    String? name,
    String? iconEmoji,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return InventoryList(
      id: id ?? this.id,
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon_emoji': iconEmoji,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryList.fromMap(Map<String, dynamic> map) {
    return InventoryList(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconEmoji: map['icon_emoji'] as String? ?? '📦',
      isDefault: (map['is_default'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
