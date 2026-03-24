import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collection_item_model.dart';
import '../repositories/items_repository.dart';
import '../repositories/collection_links_repository.dart';
import '../repositories/firebase_items_repository.dart';
import '../repositories/firebase_collection_links_repository.dart';
import '../services/supabase_service.dart';

enum LoadingState { initial, loading, loaded, error }

class CollectionsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ItemsRepository _itemsRepo;
  final CollectionLinksRepository _linksRepo;

  LoadingState _loadingState = LoadingState.initial;
  List<CollectionItemModel> _items = [];
  String? _errorMessage;

  LoadingState get loadingState => _loadingState;
  List<CollectionItemModel> get items => _items;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isLoaded => _loadingState == LoadingState.loaded;

  CollectionsProvider({
    ItemsRepository? itemsRepository,
    CollectionLinksRepository? linksRepository,
  }) : _itemsRepo =
           itemsRepository ??
           FirebaseItemsRepository(FirebaseFirestore.instance),
       _linksRepo =
           linksRepository ??
           FirebaseCollectionLinksRepository(FirebaseFirestore.instance);

  Future<void> loadItems() async {
    _loadingState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _itemsRepo.getPublicItems();

      _loadingState = LoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = 'Failed to load items: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadItemsByCollection(String collectionId) async {
    _loadingState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _loadingState = LoadingState.error;
        _errorMessage = 'User not authenticated';
        notifyListeners();
        return;
      }

      final itemIds = await _linksRepo.getItemIdsForCollection(
        userId: userId,
        collectionId: collectionId,
      );

      if (itemIds.isEmpty) {
        _items = [];
        _loadingState = LoadingState.loaded;
        notifyListeners();
        return;
      }

      final itemsSnapshot = await _firestore
          .collection('items')
          .where(FieldPath.documentId, whereIn: itemIds.take(10).toList())
          .get();

      _items = itemsSnapshot.docs
          .map((doc) => CollectionItemModel.fromMap(doc.data(), doc.id))
          .toList();

      _loadingState = LoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = 'Failed to load collection items: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> searchItems(String query) async {
    _loadingState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _itemsRepo.searchPublicItems(query);

      _loadingState = LoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = 'Search failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> addItem(CollectionItemModel item) async {
    try {
      final newItem = await _itemsRepo.addItem(item);
      _items.add(newItem);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add item: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addItemToCollection(String itemId, String collectionId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _linksRepo.addItemToCollection(
        userId: userId,
        collectionId: collectionId,
        itemId: itemId,
      );
      await _updateCollectionItemCount(collectionId);

      debugPrint('✅ Item $itemId added to collection $collectionId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error adding item to collection: $e');
      _errorMessage = 'Failed to add item to collection: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeItemFromCollection(
    String itemId,
    String collectionId,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _linksRepo.removeItemFromCollection(
        userId: userId,
        collectionId: collectionId,
        itemId: itemId,
      );

      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
      await _updateCollectionItemCount(collectionId);
    } catch (e) {
      _errorMessage = 'Failed to remove item from collection: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(CollectionItemModel item) async {
    try {
      await _itemsRepo.updateItem(item);

      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update item: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (!itemDoc.exists) {
        debugPrint('❌ Item not found: $itemId');
        throw Exception('Item not found');
      }

      final item = CollectionItemModel.fromMap(itemDoc.data()!, itemDoc.id);

      if (item.createdBy != userId) {
        debugPrint(
          '❌ Permission denied: user $userId trying to delete item created by ${item.createdBy}',
        );
        throw Exception('You can only delete your own items');
      }

      // Видаляємо всі зв'язки цього item (тільки ті що належать поточному користувачу)
      final links = await _firestore
          .collection('collection_items')
          .where('itemId', isEqualTo: itemId)
          .where('userId', isEqualTo: userId)
          .get();

      final affectedCollectionIds = links.docs
          .map((doc) => doc.data()['collectionId'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      for (var doc in links.docs) {
        try {
          await doc.reference.delete();
          debugPrint('✅ Deleted link: ${doc.id}');
        } catch (e) {
          debugPrint('⚠️ Failed to delete link ${doc.id}: $e');
        }
      }

      // Видаляємо сам item з Firestore
      await _itemsRepo.deleteItem(itemId);
      debugPrint('✅ Item deleted from Firestore');

      // Видаляємо фото з Supabase Storage якщо воно є
      if (item.imageUrl.isNotEmpty && !item.imageUrl.contains('placeholder')) {
        try {
          await SupabaseService.deleteImage(item.imageUrl);
          debugPrint('🗑️ Deleted item image from Supabase');
        } catch (e) {
          debugPrint('⚠️ Failed to delete item image: $e');
        }
      }

      _items.removeWhere((item) => item.id == itemId);

      for (final collectionId in affectedCollectionIds) {
        await _updateCollectionItemCount(collectionId);
      }

      notifyListeners();
      debugPrint('✅ Item successfully deleted from local state');
    } catch (e) {
      debugPrint('❌ Delete item error: $e');
      _errorMessage = 'Failed to delete item: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  List<CollectionItemModel> getFilteredItems({
    String? type,
    String? year,
    String? condition,
    String? searchQuery,
  }) {
    var filtered = List<CollectionItemModel>.from(_items);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                item.type.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (type != null && type != 'All Types' && type.isNotEmpty) {
      filtered = filtered
          .where((item) => item.type.toLowerCase() == type.toLowerCase())
          .toList();
    }

    if (year != null && year != 'All Years' && year.isNotEmpty) {
      filtered = filtered.where((item) => item.year == year).toList();
    }

    if (condition != null && condition != 'All' && condition.isNotEmpty) {
      filtered = filtered
          .where(
            (item) => item.condition.toLowerCase() == condition.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  void sortItems(String sortBy) {
    if (sortBy == 'name') {
      _items.sort((a, b) => a.name.compareTo(b.name));
    } else if (sortBy == 'year') {
      _items.sort((a, b) => int.parse(b.year).compareTo(int.parse(a.year)));
    } else if (sortBy == 'condition') {
      final conditionOrder = {'excellent': 1, 'good': 2, 'fair': 3};
      _items.sort((a, b) {
        final aOrder = conditionOrder[a.condition.toLowerCase()] ?? 4;
        final bOrder = conditionOrder[b.condition.toLowerCase()] ?? 4;
        return aOrder.compareTo(bOrder);
      });
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _updateCollectionItemCount(String collectionId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final qs = await _firestore
          .collection('collection_items')
          .where('collectionId', isEqualTo: collectionId)
          .where('userId', isEqualTo: userId)
          .get();

      await _firestore.collection('collections').doc(collectionId).update({
        'itemCount': qs.docs.length,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }
}
