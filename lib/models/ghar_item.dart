class GharItem {
  final int? id;
  final String title;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;

  GharItem({
    this.id,
    required this.title,
    this.category = 'General',
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GharItem.fromMap(Map<String, dynamic> map) {
    return GharItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'General',
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  GharItem copyWith({
    int? id,
    String? title,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return GharItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
