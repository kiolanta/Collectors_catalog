import '../models/collection_item_model.dart';

abstract class ItemsRepository {
  Future<List<CollectionItemModel>> getPublicItems();
  Future<List<CollectionItemModel>> searchPublicItems(String query);
  Stream<List<CollectionItemModel>> watchPublicItems();

  Future<CollectionItemModel> addItem(CollectionItemModel item);
  Future<void> updateItem(CollectionItemModel item);
  Future<void> deleteItem(String itemId);
}
