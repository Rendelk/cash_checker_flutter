class CategoryItem {
  final String id;
  final String name;
  final String type; // income | expense
  final int createdAtMs;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'createdAtMs': createdAtMs,
    };
  }

  factory CategoryItem.fromMap(Map<String, Object?> m) {
    return CategoryItem(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}