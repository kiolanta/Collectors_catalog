import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_item_model.dart';
import 'items_repository.dart';

class FirebaseItemsRepository implements ItemsRepository {
  final FirebaseFirestore _firestore;
  FirebaseItemsRepository(this._firestore);

  @override
  Future<List<CollectionItemModel>> getPublicItems() async {
    final qs = await _firestore
        .collection('items')
        .where('isPublic', isEqualTo: true)
        .get();
    return qs.docs
        .map((d) => CollectionItemModel.fromMap(d.data(), d.id))
        .toList();
  }

  @override
  Future<List<CollectionItemModel>> searchPublicItems(String query) async {
    final items = await getPublicItems();
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.type.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Stream<List<CollectionItemModel>> watchPublicItems() {
    return _firestore
        .collection('items')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CollectionItemModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  @override
  Future<CollectionItemModel> addItem(CollectionItemModel item) async {
    final ref = await _firestore.collection('items').add(item.toMap());
    return item.copyWith(id: ref.id);
  }

  @override
  Future<void> updateItem(CollectionItemModel item) async {
    await _firestore.collection('items').doc(item.id).update(item.toMap());
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }
}
