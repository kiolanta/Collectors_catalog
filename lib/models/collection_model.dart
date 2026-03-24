class CollectionModel {
  final String id;
  final String name;
  final String userId;
  final int itemCount;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionModel({
    required this.id,
    required this.name,
    required this.userId,
    required this.itemCount,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionModel.fromMap(Map<String, dynamic> map, String id) {
    return CollectionModel(
      id: id,
      name: map['name'] ?? '',
      userId: map['userId'] ?? '',
      itemCount: (map['itemCount'] ?? 0) is int
          ? map['itemCount'] ?? 0
          : int.tryParse(map['itemCount'].toString()) ?? 0,
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
      'itemCount': itemCount,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  CollectionModel copyWith({
    String? id,
    String? name,
    String? userId,
    int? itemCount,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      itemCount: itemCount ?? this.itemCount,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
