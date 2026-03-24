import '../models/collection_model.dart';

abstract class CollectionsRepository {
  Future<List<CollectionModel>> getUserCollections(String userId);
  Stream<List<CollectionModel>> watchUserCollections(String userId);

  Future<CollectionModel> createCollection(CollectionModel collection);
  Future<void> updateCollection(CollectionModel collection);
  Future<void> deleteCollection(String collectionId);
}
