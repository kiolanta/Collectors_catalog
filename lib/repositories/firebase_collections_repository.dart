import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_model.dart';
import 'collections_repository.dart';

class FirebaseCollectionsRepository implements CollectionsRepository {
  final FirebaseFirestore _firestore;
  FirebaseCollectionsRepository(this._firestore);

  @override
  Future<List<CollectionModel>> getUserCollections(String userId) async {
    final qs = await _firestore
        .collection('collections')
        .where('userId', isEqualTo: userId)
        .get();
    final collections = qs.docs
        .map((d) => CollectionModel.fromMap(d.data(), d.id))
        .toList();
    print(
      '📦 Firebase repo: found ${collections.length} collections for user $userId',
    );
    return collections;
  }

  @override
  Stream<List<CollectionModel>> watchUserCollections(String userId) {
    return _firestore
        .collection('collections')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CollectionModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  @override
  Future<CollectionModel> createCollection(CollectionModel collection) async {
    print('📦 Firebase repo: creating collection ${collection.name}');
    final ref = await _firestore
        .collection('collections')
        .add(collection.toMap());
    print('📦 Firebase repo: collection created with id=${ref.id}');
    return collection.copyWith(id: ref.id);
  }

  @override
  Future<void> updateCollection(CollectionModel collection) async {
    await _firestore
        .collection('collections')
        .doc(collection.id)
        .update(collection.toMap());
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    await _firestore.collection('collections').doc(collectionId).delete();
  }
}
