/// Користувачі можуть додавати ці елементи до своїх колекцій
class CollectionItemModel {
  final String id;
  final String name;
  final String year;
  final String type;
  final String condition;
  final String imageUrl;
  final String? description;
  final String createdBy; // userId автора, який створив цей item
  final DateTime createdAt;
  final bool isPublic; // чи доступний для пошуку іншим користувачам

  CollectionItemModel({
    required this.id,
    required this.name,
    required this.year,
    required this.type,
    required this.condition,
    required this.imageUrl,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.isPublic = true,
  });

  // Конвертація з Map (для Firestore)
  factory CollectionItemModel.fromMap(Map<String, dynamic> map, String id) {
    return CollectionItemModel(
      id: id,
      name: map['name'] ?? '',
      year: map['year'] ?? '',
      type: map['type'] ?? '',
      condition: map['condition'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'],
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      isPublic: map['isPublic'] ?? true,
    );
  }

  // Конвертація в Map (для Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'year': year,
      'type': type,
      'condition': condition,
      'imageUrl': imageUrl,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isPublic': isPublic,
    };
  }

  // Копіювання з оновленими полями
  CollectionItemModel copyWith({
    String? id,
    String? name,
    String? year,
    String? type,
    String? condition,
    String? imageUrl,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    bool? isPublic,
  }) {
    return CollectionItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      type: type ?? this.type,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
