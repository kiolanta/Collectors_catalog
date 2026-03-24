import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collection_model.dart';
import '../repositories/collections_repository.dart';
import '../repositories/collection_links_repository.dart';
import '../repositories/firebase_collections_repository.dart';
import '../repositories/firebase_collection_links_repository.dart';
import '../services/supabase_service.dart';

enum CollectionsLoadingState { initial, loading, loaded, empty, error }

class UserCollectionsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionsRepository _collectionsRepo;
  final CollectionLinksRepository _linksRepo;
  CollectionsLoadingState _state = CollectionsLoadingState.initial;
  List<CollectionModel> _collections = [];
  String? _errorMessage;

  CollectionsLoadingState get state => _state;
  List<CollectionModel> get collections => _collections;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == CollectionsLoadingState.loading;
  bool get isLoaded => _state == CollectionsLoadingState.loaded;
  bool get isEmpty => _state == CollectionsLoadingState.empty;
  bool get hasError => _state == CollectionsLoadingState.error;

  UserCollectionsProvider({
    CollectionsRepository? collectionsRepository,
    CollectionLinksRepository? linksRepository,
  }) : _collectionsRepo =
           collectionsRepository ??
           FirebaseCollectionsRepository(FirebaseFirestore.instance),
       _linksRepo =
           linksRepository ??
           FirebaseCollectionLinksRepository(FirebaseFirestore.instance);

  Future<void> loadCollections() async {
    _state = CollectionsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('🔵 loadCollections: user=${user?.uid}');
      if (user == null) {
        _collections = [];
        _state = CollectionsLoadingState.empty;
        notifyListeners();
        return;
      }

      _collections = await _collectionsRepo.getUserCollections(user.uid);
      debugPrint('🔵 Loaded ${_collections.length} collections');

      _collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _state = _collections.isEmpty
          ? CollectionsLoadingState.empty
          : CollectionsLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _state = CollectionsLoadingState.error;
      _errorMessage = 'Failed to load collections: $e';
      notifyListeners();
    }
  }

  Future<void> addCollection({required String name, String? imageUrl}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final now = DateTime.now();
      final data = {
        'name': name.trim(),
        'userId': user.uid,
        'itemCount': 0,
        'imageUrl': imageUrl?.trim(),
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      };

      debugPrint('🟢 Creating collection: name=$name, userId=${user.uid}');
      final created = await _collectionsRepo.createCollection(
        CollectionModel.fromMap(data, ''),
      );
      debugPrint('🟢 Collection created with id=${created.id}');
      _collections.insert(0, created);
      _state = CollectionsLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add collection: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final collection = _collections.firstWhere(
        (c) => c.id == collectionId,
        orElse: () => throw Exception('Collection not found'),
      );

      final itemIds = await _linksRepo.getItemIdsForCollection(
        userId: user.uid,
        collectionId: collectionId,
      );
      for (final itemId in itemIds) {
        await _linksRepo.removeItemFromCollection(
          userId: user.uid,
          collectionId: collectionId,
          itemId: itemId,
        );
      }

      // Видаляємо саму колекцію з Firestore
      await _collectionsRepo.deleteCollection(collectionId);

      // Видаляємо фото з Supabase Storage якщо воно є
      if (collection.imageUrl != null &&
          collection.imageUrl!.isNotEmpty &&
          !collection.imageUrl!.contains('placeholder')) {
        try {
          await SupabaseService.deleteImage(collection.imageUrl!);
          debugPrint('🗑️ Deleted collection image from Supabase');
        } catch (e) {
          debugPrint('⚠️ Failed to delete collection image: $e');
        }
      }

      _collections.removeWhere((c) => c.id == collectionId);
      _state = _collections.isEmpty
          ? CollectionsLoadingState.empty
          : CollectionsLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete collection: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshItemCount(String collectionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Рахуємо зв'язки в collection_items
      final itemIds = await _linksRepo.getItemIdsForCollection(
        userId: user.uid,
        collectionId: collectionId,
      );
      final newCount = itemIds.length;
      await _firestore.collection('collections').doc(collectionId).update({
        'itemCount': newCount,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      final idx = _collections.indexWhere((c) => c.id == collectionId);
      if (idx != -1) {
        final updated = _collections[idx].copyWith(
          itemCount: newCount,
          updatedAt: DateTime.now(),
        );
        _collections[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }
}
