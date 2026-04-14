import 'package:collectors_catalog/models/collection_item_model.dart';
import 'package:collectors_catalog/providers/collections_provider.dart';
import 'package:collectors_catalog/repositories/collection_links_repository.dart';
import 'package:collectors_catalog/repositories/items_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class FakeItemsRepository implements ItemsRepository {
  List<CollectionItemModel> data;
  FakeItemsRepository(this.data);

  @override
  Future<List<CollectionItemModel>> getPublicItems() async => data;

  @override
  Future<List<CollectionItemModel>> searchPublicItems(String query) async {
    if (query.isEmpty) return data;
    final q = query.toLowerCase();
    return data
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.type.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Stream<List<CollectionItemModel>> watchPublicItems() => Stream.value(data);

  @override
  Future<CollectionItemModel> addItem(CollectionItemModel item) async =>
      item.copyWith(id: 'new-id');

  @override
  Future<void> updateItem(CollectionItemModel item) async {}

  @override
  Future<void> deleteItem(String itemId) async {}
}

class FakeLinksRepository implements CollectionLinksRepository {
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

CollectionItemModel _item({
  required String id,
  required String name,
  required String year,
  required String type,
  required String condition,
}) => CollectionItemModel(
  id: id,
  name: name,
  year: year,
  type: type,
  condition: condition,
  imageUrl: '',
  createdBy: 'u1',
  createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late CollectionsProvider provider;
  late List<CollectionItemModel> items;

  setUp(() {
    items = [
      _item(
        id: '1',
        name: 'Rare Coin',
        year: '1998',
        type: 'Coin',
        condition: 'Excellent',
      ),
      _item(
        id: '2',
        name: 'Old Stamp',
        year: '2000',
        type: 'Stamp',
        condition: 'Good',
      ),
      _item(
        id: '3',
        name: 'Silver Card',
        year: '1998',
        type: 'Card',
        condition: 'Fair',
      ),
    ];

    provider = CollectionsProvider(
      firestore: FakeFirebaseFirestore(),
      itemsRepository: FakeItemsRepository(items),
      linksRepository: FakeLinksRepository(),
    );
  });

  group('CollectionsProvider initial state', () {
    test('loadingState is initial', () {
      expect(provider.loadingState, LoadingState.initial);
    });

    test('items list is empty before loadItems()', () {
      expect(provider.items, isEmpty);
    });
  });

  group('CollectionsProvider.loadItems()', () {
    test('transitions to loaded and fills items', () async {
      await provider.loadItems();

      expect(provider.loadingState, LoadingState.loaded);
      expect(provider.items.length, 3);
    });

    test('error repo sets error state with message', () async {
      final errorRepo = _ThrowingItemsRepository();
      final p = CollectionsProvider(
        firestore: FakeFirebaseFirestore(),
        itemsRepository: errorRepo,
        linksRepository: FakeLinksRepository(),
      );

      await p.loadItems();

      expect(p.loadingState, LoadingState.error);
      expect(p.errorMessage, contains('test error'));
    });
  });

  group('CollectionsProvider.getFilteredItems()', () {
    setUp(() async => await provider.loadItems());

    test('no filters returns all items', () {
      expect(provider.getFilteredItems().length, 3);
    });

    test('filter by type returns matching items', () {
      final result = provider.getFilteredItems(type: 'Coin');
      expect(result.length, 1);
      expect(result.first.name, 'Rare Coin');
    });

    test('filter by year returns matching items', () {
      final result = provider.getFilteredItems(year: '1998');
      expect(result.length, 2);
    });

    test('filter by condition returns matching items', () {
      final result = provider.getFilteredItems(condition: 'Good');
      expect(result.length, 1);
      expect(result.first.type, 'Stamp');
    });

    test('searchQuery filters by name', () {
      final result = provider.getFilteredItems(searchQuery: 'coin');
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('searchQuery filters by type', () {
      final result = provider.getFilteredItems(searchQuery: 'stamp');
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('All Types / All Years / All sentinel values skip filter', () {
      final result = provider.getFilteredItems(
        type: 'All Types',
        year: 'All Years',
        condition: 'All',
      );
      expect(result.length, 3);
    });

    test('combined type + year narrows result', () {
      final result = provider.getFilteredItems(type: 'Coin', year: '1998');
      expect(result.length, 1);
      expect(result.first.name, 'Rare Coin');
    });
  });

  group('CollectionsProvider.sortItems()', () {
    setUp(() async => await provider.loadItems());

    test('sort by name produces alphabetical order', () {
      provider.sortItems('name');
      final names = provider.items.map((i) => i.name).toList();
      expect(names, ['Old Stamp', 'Rare Coin', 'Silver Card']);
    });

    test('sort by year produces descending order', () {
      provider.sortItems('year');
      final years = provider.items.map((i) => i.year).toList();
      expect(years.first, '2000');
    });

    test('sort by condition uses excellent < good < fair order', () {
      provider.sortItems('condition');
      final conditions = provider.items.map((i) => i.condition).toList();
      expect(conditions, ['Excellent', 'Good', 'Fair']);
    });
  });

  group('CollectionsProvider.clearError()', () {
    test('resets errorMessage to null', () async {
      final p = CollectionsProvider(
        firestore: FakeFirebaseFirestore(),
        itemsRepository: _ThrowingItemsRepository(),
        linksRepository: FakeLinksRepository(),
      );
      await p.loadItems();
      expect(p.errorMessage, isNotNull);

      p.clearError();
      expect(p.errorMessage, isNull);
    });
  });
}

class _ThrowingItemsRepository implements ItemsRepository {
  @override
  Future<List<CollectionItemModel>> getPublicItems() async =>
      throw Exception('test error');

  @override
  Future<List<CollectionItemModel>> searchPublicItems(String query) async =>
      throw Exception('test error');

  @override
  Stream<List<CollectionItemModel>> watchPublicItems() =>
      Stream.error(Exception('test error'));

  @override
  Future<CollectionItemModel> addItem(CollectionItemModel item) async =>
      throw Exception('test error');

  @override
  Future<void> updateItem(CollectionItemModel item) async {}

  @override
  Future<void> deleteItem(String itemId) async {}
}
