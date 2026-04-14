import 'package:collectors_catalog/models/collection_item_model.dart';
import 'package:collectors_catalog/pages/search_page.dart';
import 'package:collectors_catalog/providers/collections_provider.dart';
import 'package:collectors_catalog/repositories/collection_links_repository.dart';
import 'package:collectors_catalog/repositories/items_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// ─── Fakes ────────────────────────────────────────────────────────────────────

/// Repo that never resolves — keeps the provider in loading state permanently.
class _BlockingItemsRepo implements ItemsRepository {
  final _completer = Completer<List<CollectionItemModel>>();

  @override
  Future<List<CollectionItemModel>> getPublicItems() => _completer.future;

  @override
  Future<List<CollectionItemModel>> searchPublicItems(String q) =>
      _completer.future;

  @override
  Stream<List<CollectionItemModel>> watchPublicItems() =>
      Stream.fromFuture(_completer.future);

  @override
  Future<CollectionItemModel> addItem(CollectionItemModel item) async =>
      item.copyWith(id: 'new');

  @override
  Future<void> updateItem(CollectionItemModel item) async {}

  @override
  Future<void> deleteItem(String itemId) async {}
}

class _FakeItemsRepo implements ItemsRepository {
  final List<CollectionItemModel> data;
  final bool shouldThrow;
  _FakeItemsRepo(this.data, {this.shouldThrow = false});

  @override
  Future<List<CollectionItemModel>> getPublicItems() async {
    if (shouldThrow) throw Exception('network error');
    return data;
  }

  @override
  Future<List<CollectionItemModel>> searchPublicItems(String query) async {
    if (shouldThrow) throw Exception('network error');
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
      item.copyWith(id: 'new');

  @override
  Future<void> updateItem(CollectionItemModel item) async {}

  @override
  Future<void> deleteItem(String itemId) async {}
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

Widget _wrapped(CollectionsProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<CollectionsProvider>.value(
      value: provider,
      child: const SearchPage(),
    ),
  );
}

CollectionsProvider _provider(
  List<CollectionItemModel> items, {
  bool shouldThrow = false,
}) => CollectionsProvider(
  firestore: FakeFirebaseFirestore(),
  itemsRepository: _FakeItemsRepo(items, shouldThrow: shouldThrow),
  linksRepository: _FakeLinksRepo(),
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('SearchPage – loading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      // Uses a blocking repo so loadItems() never resolves → stays in loading state.
      final provider = CollectionsProvider(
        firestore: FakeFirebaseFirestore(),
        itemsRepository: _BlockingItemsRepo(),
        linksRepository: _FakeLinksRepo(),
      );

      await tester.pumpWidget(_wrapped(provider));
      await tester
          .pump(); // runs addPostFrameCallback → loadItems() starts, stays pending
      await tester.pump(); // rebuild with loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SearchPage – empty state', () {
    testWidgets('shows "No results found" when list is empty', (tester) async {
      final provider = _provider([]);

      await tester.pumpWidget(_wrapped(provider));
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });

  group('SearchPage – results state', () {
    testWidgets('shows results header with count', (tester) async {
      final provider = _provider([
        _item('1', 'Rare Coin'),
        _item('2', 'Old Stamp', type: 'Stamp'),
      ]);

      await tester.pumpWidget(_wrapped(provider));
      await tester.pumpAndSettle();

      expect(find.text('Results (2)'), findsOneWidget);
    });

    testWidgets('shows item names in list', (tester) async {
      final provider = _provider([
        _item('1', 'Rare Coin'),
        _item('2', 'Old Stamp', type: 'Stamp'),
      ]);

      await tester.pumpWidget(_wrapped(provider));
      await tester.pumpAndSettle();

      expect(find.text('Rare Coin'), findsOneWidget);
      expect(find.text('Old Stamp'), findsOneWidget);
    });
  });

  group('SearchPage – error state', () {
    testWidgets('shows error icon and Retry button on failure', (tester) async {
      final provider = _provider([], shouldThrow: true);

      await tester.pumpWidget(_wrapped(provider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('SearchPage – search field', () {
    testWidgets('search TextField is rendered', (tester) async {
      await tester.pumpWidget(_wrapped(_provider([])));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('typing in search field filters results', (tester) async {
      final provider = _provider([
        _item('1', 'Rare Coin', type: 'Coin'),
        _item('2', 'Old Stamp', type: 'Stamp'),
        _item('3', 'Silver Medal', type: 'Medal'),
      ]);

      await tester.pumpWidget(_wrapped(provider));
      await tester.pumpAndSettle();

      // Type search query
      await tester.enterText(find.byType(TextField), 'Coin');
      await tester.pumpAndSettle();

      expect(find.text('Rare Coin'), findsOneWidget);
      // Stamp and Medal should not appear in results
      expect(find.text('Old Stamp'), findsNothing);
      expect(find.text('Silver Medal'), findsNothing);
      expect(find.text('Results (1)'), findsOneWidget);
    });
  });

  group('SearchPage – filters row', () {
    testWidgets('shows Type, Year and Condition filter dropdowns', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapped(_provider([])));
      await tester.pump();

      expect(find.text('Type'), findsOneWidget);
      // 'Year' appears in both the filter hint and the sort buttons row
      expect(find.text('Year'), findsWidgets);
      expect(find.text('Condition'), findsOneWidget);
    });
  });
}
