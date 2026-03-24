import 'package:cloud_firestore/cloud_firestore.dart';
import 'collection_links_repository.dart';

class FirebaseCollectionLinksRepository implements CollectionLinksRepository {
  final FirebaseFirestore _firestore;
  FirebaseCollectionLinksRepository(this._firestore);

  @override
  Future<void> addItemToCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  }) async {
    final existing = await _firestore
        .collection('collection_items')
        .where('userId', isEqualTo: userId)
        .where('collectionId', isEqualTo: collectionId)
        .where('itemId', isEqualTo: itemId)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Item already in collection');
    }
    await _firestore.collection('collection_items').add({
      'userId': userId,
      'collectionId': collectionId,
      'itemId': itemId,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> removeItemFromCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  }) async {
    final links = await _firestore
        .collection('collection_items')
        .where('userId', isEqualTo: userId)
        .where('collectionId', isEqualTo: collectionId)
        .where('itemId', isEqualTo: itemId)
        .get();
    for (final doc in links.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<String>> getItemIdsForCollection({
    required String userId,
    required String collectionId,
  }) async {
    final qs = await _firestore
        .collection('collection_items')
        .where('userId', isEqualTo: userId)
        .where('collectionId', isEqualTo: collectionId)
        .get();
    return qs.docs.map((d) => d.data()['itemId'] as String).toList();
  }
}
