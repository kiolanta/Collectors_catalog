/// Зв'язок між колекцією користувача та публічним item
/// Many-to-many relationship
class UserCollectionItemModel {
  final String id;
  final String userId;
  final String collectionId;
  final String itemId;
  final DateTime addedAt;

  UserCollectionItemModel({
    required this.id,
    required this.userId,
    required this.collectionId,
    required this.itemId,
    required this.addedAt,
  });

  factory UserCollectionItemModel.fromMap(Map<String, dynamic> map, String id) {
    return UserCollectionItemModel(
      id: id,
      userId: map['userId'] ?? '',
      collectionId: map['collectionId'] ?? '',
      itemId: map['itemId'] ?? '',
      addedAt: map['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'collectionId': collectionId,
      'itemId': itemId,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }
}
