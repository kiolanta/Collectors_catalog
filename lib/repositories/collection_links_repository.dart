abstract class CollectionLinksRepository {
  Future<void> addItemToCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  });

  Future<void> removeItemFromCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  });

  Future<List<String>> getItemIdsForCollection({
    required String userId,
    required String collectionId,
  });
}
