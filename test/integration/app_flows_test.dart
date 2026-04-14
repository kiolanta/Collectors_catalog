// test/integration/app_flows_test.dart
//
// High-level integration tests — run via:
//   flutter test test/integration/app_flows_test.dart
//
// Each test bootstraps a fully rendered widget tree with fake providers
// and simulates a complete user action sequence (create → verify → delete
// → verify, search flow, error recovery).  No real Firebase or network
// calls are made.

import 'dart:async';

import 'package:collectors_catalog/models/collection_item_model.dart';
import 'package:collectors_catalog/models/collection_model.dart';
import 'package:collectors_catalog/pages/collections_page.dart';
import 'package:collectors_catalog/pages/search_page.dart';
import 'package:collectors_catalog/providers/collections_provider.dart';
import 'package:collectors_catalog/providers/user_collections_provider.dart';
import 'package:collectors_catalog/repositories/collection_links_repository.dart';
import 'package:collectors_catalog/repositories/collections_repository.dart';
import 'package:collectors_catalog/repositories/items_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ─── Fake repositories ────────────────────────────────────────────────────────

class _FakeCollectionsRepo implements CollectionsRepository {
  final List<CollectionModel> _store = [];

  @override
  Future<List<CollectionModel>> getUserCollections(String userId) async =>
      List.from(_store);

  @override
  Stream<List<CollectionModel>> watchUserCollections(String userId) =>
      Stream.value(List.from(_store));

  @override
  Future<CollectionModel> createCollection(CollectionModel collection) async {
    final created = collection.copyWith(
      id: 'generated-${_store.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store.add(created);
    return created;
  }

  @override
  Future<void> updateCollection(CollectionModel collection) async {
    final idx = _store.indexWhere((c) => c.id == collection.id);
    if (idx != -1) _store[idx] = collection;
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    _store.removeWhere((c) => c.id == collectionId);
  }
}

class _FakeLinksRepo implements CollectionLinksRepository {
  @override
  Future<void> addItemToCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  }) async {}

  @override
  Future<void> removeItemFromCollection({
    required String userId,
    required String collectionId,
    required String itemId,
  }) async {}

  @override
  Future<List<String>> getItemIdsForCollection({
    required String userId,
    required String collectionId,
  }) async => [];
}

class _FakeItemsRepo implements ItemsRepository {
  final List<CollectionItemModel> _store;
  _FakeItemsRepo(this._store);

  @override
  Future<List<CollectionItemModel>> getPublicItems() async =>
      List.from(_store);

  @override
  Future<List<CollectionItemModel>> searchPublicItems(String query) async {
    if (query.isEmpty) return List.from(_store);
    final q = query.toLowerCase();
    return _store
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.type.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Stream<List<CollectionItemModel>> watchPublicItems() =>
      Stream.value(List.from(_store));

  @override
  Future<CollectionItemModel> addItem(CollectionItemModel item) async =>
      item.copyWith(id: 'new-${DateTime.now().millisecondsSinceEpoch}');

  @override
  Future<void> updateItem(CollectionItemModel item) async {}

  @override
  Future<void> deleteItem(String itemId) async {}
}

/// Provider that bypasses FirebaseAuth — all methods use the fake repo directly.
class _UCProvider extends UserCollectionsProvider {
  final _FakeCollectionsRepo _repo;

  _UCProvider(this._repo)
    : super(
        firestore: FakeFirebaseFirestore(),
        collectionsRepository: _repo,
        linksRepository: _FakeLinksRepo(),
      );

  @override
  Future<void> loadCollections() async {
    final all = await _repo.getUserCollections('test-user');
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setForTesting(
      state: all.isEmpty
          ? CollectionsLoadingState.empty
          : CollectionsLoadingState.loaded,
      collections: all,
    );
  }

  @override
  Future<void> addCollection({required String name, String? imageUrl}) async {
    final now = DateTime.now();
    final created = await _repo.createCollection(
      CollectionModel(
        id: '',
        name: name.trim(),
        userId: 'test-user',
        itemCount: 0,
        imageUrl: imageUrl,
        createdAt: now,
        updatedAt: now,
      ),
    );
    setForTesting(
      state: CollectionsLoadingState.loaded,
      collections: [created, ...collections],
    );
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    await _repo.deleteCollection(collectionId);
    final remaining = collections.where((c) => c.id != collectionId).toList();
    setForTesting(
      state: remaining.isEmpty
          ? CollectionsLoadingState.empty
          : CollectionsLoadingState.loaded,
      collections: remaining,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

CollectionItemModel _item(
  String id,
  String name, {
  String type = 'Coin',
  String year = '2000',
}) => CollectionItemModel(
  id: id,
  name: name,
  year: year,
  type: type,
  condition: 'Good',
  imageUrl: '',
  createdBy: 'u1',
  createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
);

Widget _collectionsApp(UserCollectionsProvider ucProvider) => MaterialApp(
  home: ChangeNotifierProvider<UserCollectionsProvider>.value(
    value: ucProvider,
    child: const CollectionsPage(),
  ),
);

Widget _searchApp(CollectionsProvider cp, UserCollectionsProvider ucp) =>
    MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<CollectionsProvider>.value(value: cp),
          ChangeNotifierProvider<UserCollectionsProvider>.value(value: ucp),
        ],
        child: const SearchPage(),
      ),
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Scenario 1: Create collection → appears in list ──────────────────────
  testWidgets(
    'FLOW 1 — create collection: new collection appears in the list',
    (tester) async {
      final repo = _FakeCollectionsRepo();
      final ucProvider = _UCProvider(repo);

      await tester.pumpWidget(_collectionsApp(ucProvider));
      await tester.pumpAndSettle();

      expect(find.text('No collections yet. Add one!'), findsOneWidget);

      await ucProvider.addCollection(name: 'My Coins');
      await tester.pumpAndSettle();

      expect(find.text('My Coins'), findsOneWidget);
      expect(find.text('No collections yet. Add one!'), findsNothing);
    },
  );

  // ── Scenario 2: Delete collection → disappears from list ─────────────────
  testWidgets(
    'FLOW 2 — delete collection: collection disappears after deletion',
    (tester) async {
      final repo = _FakeCollectionsRepo();
      final ucProvider = _UCProvider(repo);

      await ucProvider.addCollection(name: 'Stamps');
      await ucProvider.addCollection(name: 'Coins');

      await tester.pumpWidget(_collectionsApp(ucProvider));
      await tester.pumpAndSettle();

      expect(find.text('Stamps'), findsOneWidget);
      expect(find.text('Coins'), findsOneWidget);

      final stampsId =
          ucProvider.collections.firstWhere((c) => c.name == 'Stamps').id;
      await ucProvider.deleteCollection(stampsId);
      await tester.pumpAndSettle();

      expect(find.text('Stamps'), findsNothing);
      expect(find.text('Coins'), findsOneWidget);
    },
  );

  // ── Scenario 3: Network error → retry → results load ─────────────────────
  testWidgets(
    'FLOW 3 — network error recovery: Retry button reloads items',
    (tester) async {
      bool shouldThrow = true;

      final switchingRepo = _SwitchingItemsRepo(
        items: [
          _item('1', 'Rare Coin'),
          _item('2', 'Old Stamp', type: 'Stamp'),
        ],
        isError: () => shouldThrow,
      );

      final cp = CollectionsProvider(
        firestore: FakeFirebaseFirestore(),
        itemsRepository: switchingRepo,
        linksRepository: _FakeLinksRepo(),
      );
      final ucp = UserCollectionsProvider(
        firestore: FakeFirebaseFirestore(),
        collectionsRepository: _FakeCollectionsRepo(),
        linksRepository: _FakeLinksRepo(),
      );

      await tester.pumpWidget(_searchApp(cp, ucp));
      await tester.pumpAndSettle();

      // First load fails → error state
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Fix the error and tap Retry
      shouldThrow = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Rare Coin'), findsOneWidget);
      expect(find.text('Old Stamp'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    },
  );

  // ── Scenario 4: Search flow → type query → results filtered ──────────────
  testWidgets(
    'FLOW 4 — search flow: typing filters results; clearing restores all',
    (tester) async {
      final cp = CollectionsProvider(
        firestore: FakeFirebaseFirestore(),
        itemsRepository: _FakeItemsRepo([
          _item('1', 'Rare Coin', type: 'Coin'),
          _item('2', 'Old Stamp', type: 'Stamp'),
          _item('3', 'Silver Medal', type: 'Medal'),
        ]),
        linksRepository: _FakeLinksRepo(),
      );
      final ucp = UserCollectionsProvider(
        firestore: FakeFirebaseFirestore(),
        collectionsRepository: _FakeCollectionsRepo(),
        linksRepository: _FakeLinksRepo(),
      );

      await tester.pumpWidget(_searchApp(cp, ucp));
      await tester.pumpAndSettle();

      expect(find.text('Results (3)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'coin');
      await tester.pumpAndSettle();

      expect(find.text('Results (1)'), findsOneWidget);
      expect(find.text('Rare Coin'), findsOneWidget);
      expect(find.text('Old Stamp'), findsNothing);
      expect(find.text('Silver Medal'), findsNothing);

      // Clear query → all results back
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Results (3)'), findsOneWidget);
    },
  );
}

// ─── Helper repo for scenario 3 ──────────────────────────────────────────────

class _SwitchingItemsRepo implements ItemsRepository {
  final List<CollectionItemModel> items;
  final bool Function() isError;

  _SwitchingItemsRepo({required this.items, required this.isError});

  @override
  Future<List<CollectionItemModel>> getPublicItems() async {
    if (isError()) throw Exception('network error');
    return List.from(items);
  }

  @override
  Future<List<CollectionItemModel>> searchPublicItems(String q) async {
    if (isError()) throw Exception('network error');
    return List.from(items);
  }

  @override
  Stream<List<CollectionItemModel>> watchPublicItems() =>
      Stream.value(List.from(items));

  @override
  Future<CollectionItemModel> addItem(CollectionItemModel item) async =>
      item.copyWith(id: 'new');

  @override
  Future<void> updateItem(CollectionItemModel item) async {}

  @override
  Future<void> deleteItem(String itemId) async {}
}
